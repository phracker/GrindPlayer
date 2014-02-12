/**
 * Written By Lee,Han-gil
 */
package ru.kutu.grindplayer.views.mediators {
	
	import flash.events.Event;
	import flash.net.URLLoader; 
    import flash.net.URLRequest; 
	import flash.net.URLLoaderDataFormat;
	
	import org.osmf.media.MediaPlayer;
	import org.osmf.media.MediaPlayerState;
	import org.osmf.media.MediaElement;
	import org.osmf.events.LoadEvent;
	import org.osmf.events.MediaElementEvent;
	import org.osmf.events.MediaPlayerStateChangeEvent;
	import org.osmf.events.MediaPlayerCapabilityChangeEvent;
	import org.osmf.net.DynamicStreamingItem;
	import org.osmf.net.DynamicStreamingResource;
	import org.osmf.traits.DynamicStreamTrait;
	import org.osmf.traits.LoadState;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.player.chrome.utils.MediaElementUtils;
	
	import ru.kutu.grind.config.PlayerConfiguration;
	import ru.kutu.grind.vos.QualitySelectorVO;
	import ru.kutu.grind.vos.SelectorVO;
	import ru.kutu.grind.views.mediators.QualityMenuBaseMediator;
	import ru.kutu.grind.events.ControlBarMenuChangeEvent;
	import ru.kutu.grind.events.LoadMediaEvent;
	import ru.kutu.grind.events.MediaElementChangeEvent;
	
	import ru.kutu.grindplayer.config.MyGrindPlayerConfiguration;
	
	import robotlegs.bender.framework.api.ILogger;
	
	public class MyQualityMenuMediator extends QualityMenuBaseMediator {
		
		[Inject] public var playerConfiguration:PlayerConfiguration;
		[Inject] public var logger:ILogger;
		
		private var _dynamicTraitInHds:Boolean;
		
		private var duration:Number = 0;
		private var seekTo:Number = 0;
		
		override public function initialize():void {
			super.initialize();
			player.addEventListener(LoadEvent.LOAD_STATE_CHANGE, onLoadStateChange);
			player.addEventListener(MediaPlayerCapabilityChangeEvent.CAN_SEEK_CHANGE, onCanSeekShange);
		}
		
		private function onCanSeekShange(e:MediaPlayerCapabilityChangeEvent):void {
			
			var configuration:MyGrindPlayerConfiguration = playerConfiguration as MyGrindPlayerConfiguration;
			
			if (player.canSeek) {
				if (seekTo > 0) {
					logger.debug(" * Seek to: " + seekTo + ", duration before: " + duration + ", current: " + player.duration);
					
					seekTo += player.duration - duration;
					
					logger.debug(" * Seek to(adjusted): " + seekTo);
					
					player.seek(seekTo);
					seekTo = 0;
					player.play();
				}
			}
		}
		
		private function onLoadStateChange(e:LoadEvent):void {
			
			if (e.loadState == LoadState.READY) {
				
				if (seekTo > 0) {
					player.play();
					player.stop();
				}
				
				var dynamicTrait:DynamicStreamTrait = player.media.getTrait(MediaTraitType.DYNAMIC_STREAM) as DynamicStreamTrait;
				if(!dynamicTrait) {
					view.visible = true;
					view.setSelectors(selectors);
					_dynamicTraitInHds = false;
					loadHlsMetaPlaylist();
				}
			}
		}
		
		override protected function onNumStreamChange(event:Event = null):void {
			
			var configuration:MyGrindPlayerConfiguration = playerConfiguration as MyGrindPlayerConfiguration;
			
			super.onNumStreamChange();
			
			if (isHdsStream()) {
				_dynamicTraitInHds = true;
				
				// test whether it has audio only source
				var hasAudioOnlyStream:Boolean = false;
				for (var i:int = 0; i < selectors.length; i++) {
					var vo:QualitySelectorVO = selectors[i] as QualitySelectorVO;
					if (vo.height == 0) hasAudioOnlyStream = true;
				}
				if (!hasAudioOnlyStream) loadHlsMetaPlaylist();
				
			} else {
				// if selectors has just one video stream ("Auto, Video, Audio Only")
				// then remove "Auto" menu
				if (configuration.hlsUrl != null && selectors.length == 3) {
					selectors.shift();
				}
			}
		}
		
		protected function loadHlsMetaPlaylist():void {
			
			var configuration:MyGrindPlayerConfiguration = playerConfiguration as MyGrindPlayerConfiguration;
			
			if (configuration.hlsUrl != null) {
				var request:URLRequest = new URLRequest();
				request.url = configuration.hlsUrl;
				
				var loader:URLLoader = new URLLoader();
				loader.dataFormat = URLLoaderDataFormat.TEXT;
				loader.addEventListener(Event.COMPLETE, onCcompleteLoadHLSMetaPlaylist); 
				
				try {
					loader.load(request);
				} catch (error:Error) {
					logger.warn("Unable to load HLS Meta Playlist URL");
				}
			}
		}
		
		protected function onCcompleteLoadHLSMetaPlaylist(event:Event):void {
			
			var loader:URLLoader = URLLoader(event.target);
			var lines:Array = loader.data.split(/\r?\n/);
			
			if (lines[0] != '#EXTM3U') { return; }
			
			var items:Array = new Array();
			var index:uint;
			var dynamicItem:DynamicStreamingItem;
			
			for (var i:int = 1; i < lines.length; i++) {
				var line:String = String(lines[i]).replace(/^([\s|\t|\n]+)?(.*)([\s|\t|\n]+)?$/gm, "$2");
				if (line.indexOf("#EXT-X-STREAM-INF:") == 0) {
					
					var bw:Number;
					if (line.search(/BANDWIDTH=(\d+)/) > 0) {
						bw = parseFloat(line.match(/BANDWIDTH=(\d+)/)[1]) / 1000;
					}
					
					var width:int = -1;
					var height:int = -1;
					if(line.search(/RESOLUTION=(\d+)x(\d+)/) > 0){
						width = parseInt(line.match(/RESOLUTION=(\d+)x(\d+)/)[1]);
						height = parseInt(line.match(/RESOLUTION=(\d+)x(\d+)/)[2]);
					}
					
					var streamName:String = height + "p " + bw + "kbps";
					dynamicItem = new DynamicStreamingItem(streamName, bw, width, height);
					
					items.push({
						index: index++
						, height: dynamicItem.height
						, bitrate: dynamicItem.bitrate
						, dynamicItem: dynamicItem
					});
				}
			}
			
			items.sortOn(["height", "bitrate"], Array.DESCENDING | Array.NUMERIC);
			
			if (!_dynamicTraitInHds) {
				selectors.length = 0;
				view.selectedIndex = 0;
			}
			
			for each (var item:Object in items) {
				if (!_dynamicTraitInHds || item.height < 0) {
					selectors.push(new QualitySelectorVO(item.index, processLabelForSelectorVO(item), item.bitrate, item.height));
					break;
				}
			}
		}
		
		override protected function onMenuChange(event:ControlBarMenuChangeEvent):void {
			
			var configuration:MyGrindPlayerConfiguration = playerConfiguration as MyGrindPlayerConfiguration;
			var vo:QualitySelectorVO = selectors[view.selectedIndex] as QualitySelectorVO;
			
			if (vo) {
				logger.debug(" * player.currentTime: " + player.currentTime);
				if (isHdsStream()) {
					if (vo.label != "Auto" && vo.height == -1) { // Audio Only
						configuration.src = configuration.hlsUrl;
						configuration.initailQualityIndex = 0;
						duration = player.duration;
						seekTo = player.currentTime;
						player.seek(player.currentTime-1);
						eventDispatcher.dispatchEvent(new LoadMediaEvent(LoadMediaEvent.LOAD_MEDIA));
					} else {
						super.onMenuChange(event);
					}
				} else {
					if (vo.label == "Auto") {
						configuration.initailQualityIndex = 0;
						ls.qualityAutoSwitch = true;
					} else {
						// selector includes Audo and HLS stream has one more items so -2 is needed
						configuration.initailQualityIndex = selectors.length - view.selectedIndex - 2;
						ls.qualityAutoSwitch = false;
					}
					
					configuration.src = configuration.hdsUrl;
					duration = player.duration;
					seekTo = player.currentTime;
					eventDispatcher.dispatchEvent(new LoadMediaEvent(LoadMediaEvent.LOAD_MEDIA));
				}
			}
		}
		
		override protected function selectInitialIndex():void {
			
			var configuration:MyGrindPlayerConfiguration = playerConfiguration as MyGrindPlayerConfiguration;
			var dynamicResource:DynamicStreamingResource = MediaElementUtils.getResourceFromParentOfType(media, DynamicStreamingResource) as DynamicStreamingResource;
			var preferIndex:int = configuration.initailQualityIndex;
			
			if(preferIndex > -1) {
				var autoSwitch:Boolean = ls.qualityAutoSwitch && isHdsStream();
				if (preferIndex != dynamicResource.initialIndex) {
					dynamicResource.initialIndex = preferIndex;
					player.autoDynamicStreamSwitch = false;
					player.switchDynamicStreamIndex(preferIndex);
				}
				player.autoDynamicStreamSwitch = autoSwitch;
			} else {
				super.selectInitialIndex();
			}
		}
		
		private function isHdsStream():Boolean {
			
			var configuration:MyGrindPlayerConfiguration = playerConfiguration as MyGrindPlayerConfiguration;
			return configuration.src.lastIndexOf("f4m") == ( configuration.src.length - "f4m".length ) ;
		}
	}
	
}
