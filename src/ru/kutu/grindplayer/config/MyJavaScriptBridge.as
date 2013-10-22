/**
 * This code written by HAN-GIL, LEE
 * To ensure BufferTime when AkamaiAdvancedPlugin is used
 */

package ru.kutu.grindplayer.config {
	
	import flash.net.NetStream;
	
	import org.osmf.events.MediaPlayerStateChangeEvent;
	import org.osmf.events.LoadEvent;
	import org.osmf.events.TimeEvent;
	import org.osmf.media.MediaPlayerState;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.traits.LoadState;
	import org.osmf.net.NetStreamLoadTrait;
	
	import robotlegs.bender.framework.api.ILogger;
	
	public class MyJavaScriptBridge extends JavaScriptBridge {
		
		[Inject] public var logger:ILogger;
		
		private var netStream:NetStream = null;
		
		public function MyJavaScriptBridge() {
			super();
		}
		
		[PostConstruct]
		override public function init():void {
			super.init();
			
			player.addEventListener(MediaPlayerStateChangeEvent.MEDIA_PLAYER_STATE_CHANGE, onPlayerStateChangeForBufferTimeAdjustment);
			player.addEventListener(LoadEvent.LOAD_STATE_CHANGE, onLoadStateChangeToGetNetStream);
			player.addEventListener(TimeEvent.CURRENT_TIME_CHANGE, onCurrentTimeChangeForBufferTimeAdjustment);
		}
		
		
		private function onPlayerStateChangeForBufferTimeAdjustment(e:MediaPlayerStateChangeEvent):void
		{
			if (e.state == MediaPlayerState.PAUSED)
			{
				if ( netStream != null ) {
					if (netStream.bufferTime != player.bufferTime) {
						CONFIG::LOGGING {
							logger.info("NetStream BufferTime: " + netStream.bufferTime);
						}
						
						netStream.bufferTime = player.bufferTime;
					}
					CONFIG::LOGGING {
						logger.info("Player State: " + player.state + "," + player.bufferTime + "," + netStream.bufferTime);
					}
				}
			}
		}
		
		private function onLoadStateChangeToGetNetStream(e:LoadEvent):void {
			if (e.loadState == LoadState.READY) {
				var nsLoadTrait:NetStreamLoadTrait = player.media.getTrait(MediaTraitType.LOAD) as NetStreamLoadTrait;
				netStream = nsLoadTrait.netStream;
			}
		}
		
		private function onCurrentTimeChangeForBufferTimeAdjustment(event:TimeEvent):void {
			if ( netStream != null ) {
				if (player.state != MediaPlayerState.BUFFERING) {
					netStream.bufferTime = player.bufferTime;
				} else {
					netStream.bufferTime = 2;
				}
			}
		}
	}
	
}
