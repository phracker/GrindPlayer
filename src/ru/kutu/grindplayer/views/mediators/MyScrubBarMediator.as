/**
 * Written By Lee,Han-gil
 */
package ru.kutu.grindplayer.views.mediators {
	
	import flash.events.TimerEvent;
	import flash.net.NetStream;
	import flash.utils.Timer;
	
	import org.osmf.events.LoadEvent;
	import org.osmf.events.TimeEvent;
	import org.osmf.events.MetadataEvent;
	import org.osmf.events.BufferEvent;
	import org.osmf.events.MediaPlayerStateChangeEvent;
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaPlayerState;
	import org.osmf.net.StreamType;
	import org.osmf.net.NetStreamLoadTrait;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.traits.LoadState;
	
	import org.osmf.player.chrome.utils.MediaElementUtils;
	
	import robotlegs.bender.framework.api.ILogger;
	
	public class MyScrubBarMediator extends ScrubBarMediator {
		
		protected static var UPDATE_INTERVAL:uint = 1000;
		
		[Inject] public var logger:ILogger;
		
		protected var netStream:NetStream = null;
		protected var updateTimer:Timer;
		
		override public function initialize():void {
			super.initialize();
			
			player.addEventListener(LoadEvent.LOAD_STATE_CHANGE, onLoadStateChange);
			
			updateTimer = new Timer(UPDATE_INTERVAL);
			updateTimer.addEventListener(TimerEvent.TIMER, onUpdateTimer);
			
			updateTimer.start();
		}
		
		private function onLoadStateChange(e:LoadEvent):void {
			if (e.loadState == LoadState.READY) {
				var lt:NetStreamLoadTrait;
				if (media.hasTrait(MediaTraitType.LOAD)) {
					lt = media.getTrait(MediaTraitType.LOAD) as NetStreamLoadTrait;
					if (lt) {
						netStream = lt.netStream;
					}
				}
			}
		}
		
		protected function onUpdateTimer(event:TimerEvent):void {
			if(netStream) {
				view.percentLoaded = (player.currentTime + netStream.bufferLength) / player.duration;
			}
		}
		
		override protected function updateEnabled():void {
			var streamType:String = MediaElementUtils.getStreamType(player.media);
			view.enabled = isStartPlaying && streamType == StreamType.RECORDED;
			view.visible = streamType == StreamType.RECORDED;
		}
	}
}
