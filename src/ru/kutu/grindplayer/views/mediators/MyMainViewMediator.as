/**
 * Written By Lee,Han-gil
 */
package ru.kutu.grindplayer.views.mediators {
	
	import flash.net.NetStream;
	import flash.utils.setTimeout;
	import flash.utils.Timer;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	
	import org.osmf.net.StreamType;
	import org.osmf.net.NetStreamLoadTrait;
	import org.osmf.events.LoadEvent;
	import org.osmf.events.SeekEvent;
	import org.osmf.events.TimeEvent;
	import org.osmf.events.MediaErrorEvent;
	import org.osmf.events.MediaPlayerCapabilityChangeEvent;
	import org.osmf.events.MediaPlayerStateChangeEvent;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.traits.LoadState;
	import org.osmf.media.MediaPlayerState;
	
	import org.osmf.player.chrome.utils.MediaElementUtils;
	
	import ru.kutu.grind.events.LoadMediaEvent;
	import ru.kutu.grind.config.PlayerConfiguration;
	import ru.kutu.grind.views.mediators.MainViewBaseMediator;
	
	import ru.kutu.grindplayer.config.MyGrindPlayerConfiguration;
	
	public class MyMainViewMediator extends MainViewBaseMediator {
		
		private static var INIT_BUFFER_TIME_CHECKER_INTERVAL:uint = 200;
		private static var FAILOVER_BUFFER_TIME:uint = 4;
		
		[Inject] public var playerConfiguration:PlayerConfiguration;
		
		private var configuration:MyGrindPlayerConfiguration;
		
		private var netStream:NetStream = null;
		
		private var streamType:String = null;
		private var currentTime:Number = 0;
		private var duration:Number = 0;
		private var seekTo:Number = 0;
		
		private var initBufferTimeCheckerTimer:Timer;
		private var isFirstLoad:Boolean = true;
		
		override public function initialize():void {
			super.initialize();
			
			configuration = playerConfiguration as MyGrindPlayerConfiguration;
			
			player.addEventListener(TimeEvent.CURRENT_TIME_CHANGE, onCurrentTimeChange);
			player.addEventListener(MediaPlayerCapabilityChangeEvent.CAN_SEEK_CHANGE, onCanSeekShange);
			
			player.addEventListener(LoadEvent.LOAD_STATE_CHANGE, onLoadStateChange);
			player.addEventListener(TimeEvent.COMPLETE, onComplete);
			
			initBufferTimeCheckerTimer = new Timer(INIT_BUFFER_TIME_CHECKER_INTERVAL);
			initBufferTimeCheckerTimer.addEventListener(TimerEvent.TIMER, onInitBufferTimeCheckerTimer);
		}
		
		private function onCurrentTimeChange(event:TimeEvent):void {
			
			if (player.state == MediaPlayerState.PLAYING) {
				// After media failed, currentTime will be set zero.
				// So before failing, this value should be saved for retrying.
				currentTime = player.currentTime;
			}
			
			if ( netStream != null ) {
				if (player.state != MediaPlayerState.BUFFERING) {
					netStream.bufferTime = player.bufferTime;
				}
			}
		}
		
		override protected function onMediaPlayerStateChange(e:MediaPlayerStateChangeEvent):void {
			
			logger.debug(" * PlayerState: " + e.state);
			
			switch (e.state) {
				case MediaPlayerState.PAUSED:
					if ( netStream != null ) {
						if (netStream.bufferTime != player.bufferTime) {
							netStream.bufferTime = player.bufferTime;
						}
					}
					break;
			}
			
			super.onMediaPlayerStateChange(e);
		}
		
		private function onInitBufferTimeCheckerTimer(event:TimerEvent):void {
			netStream.bufferTime = player.bufferTime;
			logger.debug(" * ---- init: " + configuration.initialBufferTime + ", set: " + netStream.bufferTime + ", cur: " + netStream.bufferLength);
		}
		
		private function onCanSeekShange(e:MediaPlayerCapabilityChangeEvent):void {
			if (player.canSeek) {
				if (seekTo > 0) {
					logger.debug(" * Seek, seekTo: " + secondsToHMSString(seekTo));
					player.seek(seekTo);
					seekTo = 0;
					player.play();
				}
			}
		}
		
		private function onLoadStateChange(e:LoadEvent):void {
			
			logger.debug(" * LoadState: " + e.loadState);
			
			if (e.loadState == LoadState.READY) {
				
				var nsLoadTrait:NetStreamLoadTrait = player.media.getTrait(MediaTraitType.LOAD) as NetStreamLoadTrait;
				
				logger.debug(" * Loaded StreamType: " + MediaElementUtils.getStreamType(player.media));
				
				if (streamType == StreamType.DVR && MediaElementUtils.getStreamType(player.media) == StreamType.RECORDED) {
					nsLoadTrait.unload();
					view.error();
					view.errorText = "The stream is ended. Waiting to start stream again ...";
					logger.debug(" * The stream is ended");
					setTimeout(dispatchLoadEvent, 5000);
					return;
				}
				
				if (duration > player.duration && streamType == StreamType.DVR) {
					nsLoadTrait.unload();
					view.error();
					view.errorText = "Streammer is disconnected. Waiting streammer to connect ...";
					logger.debug(" * Streammer is disconnected.");
					setTimeout(dispatchLoadEvent, 5000);
					return;
				}
				
				if (seekTo > 0) {
					player.play();
					player.stop();
				}
				
				netStream = nsLoadTrait.netStream;
				
				if (netStream != null) {
					if (isFirstLoad) {
						netStream.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
						player.bufferTime = configuration.initialBufferTime;
						initBufferTimeCheckerTimer.start();
						
						// In the case of live stream,
						// if pause and play within 2 second,
						// playing position go to start point.
						if (configuration.initialBufferTime > 2) {
							player.pause();
							setTimeout(player.play, 2000);
						}
						isFirstLoad = false;
					}
				}
				
				if (streamType == null) {
					streamType = MediaElementUtils.getStreamType(player.media);
				}
			}
		}
		
		override protected function onMediaError(event:MediaErrorEvent):void {
			super.onMediaError(event);
			
			view.errorText = "Trying to connect ...";
			setTimeout(dispatchLoadEvent, 5000);
		}
		
		private function onNetStatus(event:NetStatusEvent):void {
			logger.debug(" * NetStatus: " + event.info.code);
			
			var nsLoadTrait:NetStreamLoadTrait = player.media.getTrait(MediaTraitType.LOAD) as NetStreamLoadTrait;
			
			switch (event.info.code) {
				case "NetStream.Buffer.Empty":
					// A value of duration should be saved at the point of problem occured.
					duration = player.duration;
					
					if (isHlsStream()) {
						// HLS Plugin has a bug to seek forward after reconnect.
						// So instead of using reconnect feature of plugin,
						// player try to reload.
						logger.debug(" * It is HLS Stream, unload and reload are required");
						nsLoadTrait.unload();
						setTimeout(dispatchLoadEvent, 500);
					}
					break;
					
				case "NetStream.Seek.Notify":
					player.bufferTime = configuration.initialBufferTime;
					netStream.bufferTime = configuration.initialBufferTime;
					break;
					
				case "NetStream.Buffer.Full":
					configuration.initialBufferTime = FAILOVER_BUFFER_TIME;
					initBufferTimeCheckerTimer.stop();
					player.bufferTime = configuration.bufferTime;
					break;
					
				case "NetStream.Play.StreamNotFound":
				case "NetStream.Play.LiveStall":
					// If this event is arrised, the media never fail
					// and it can be stopped this point after a few minutes.
					nsLoadTrait.unload();
					dispatchLoadEvent();
					break;
					
				case "NetStream.Play.Transition":
					break;
			}
		}
		
		private function onComplete(e:TimeEvent):void {
			if (streamType == StreamType.DVR) {
				var nsLoadTrait:NetStreamLoadTrait = player.media.getTrait(MediaTraitType.LOAD) as NetStreamLoadTrait;
				
				nsLoadTrait.unload();
				view.error();
				view.errorText = "The stream is ended. Waiting to start stream again ...";
				logger.debug(" * onComplete event");
				setTimeout(dispatchLoadEvent, 5000);
			}
		}
		
		protected function dispatchLoadEvent():void {
			seekTo = currentTime - 1;
			logger.debug(" * dispatchLoadEvent");
			eventDispatcher.dispatchEvent(new LoadMediaEvent(LoadMediaEvent.LOAD_MEDIA));
		}
		
		private function secondsToHMSString(seconds:Number):String {
			var hour:uint = seconds / (60 * 60);
			var min:uint = (seconds - (hour * 60 * 60)) / 60;
			var sec:uint = seconds % 60;
			return hour +":" + min + ":" + sec;
		}
		
		private function isHlsStream():Boolean {
			
			return configuration.src.lastIndexOf("m3u8") == ( configuration.src.length - "m3u8".length ) ;
		}
	}
}