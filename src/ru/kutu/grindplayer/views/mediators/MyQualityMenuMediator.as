package ru.kutu.grindplayer.views.mediators {
	
	import flash.events.Event;
	
	import flash.errors.*; 
    import flash.events.*; 
	import flash.net.URLLoader; 
    import flash.net.URLRequest; 
	import flash.net.URLLoaderDataFormat;
	
	import org.osmf.media.MediaPlayer;
	import org.osmf.media.MediaPlayerState;
	import org.osmf.events.MediaPlayerStateChangeEvent;
	
	import org.osmf.net.DynamicStreamingResource;
	import org.osmf.player.chrome.utils.MediaElementUtils;
	import org.osmf.traits.DynamicStreamTrait;
	
	import ru.kutu.grind.config.PlayerConfiguration;
	import ru.kutu.grind.vos.QualitySelectorVO;
	import ru.kutu.grind.vos.SelectorVO;
	import ru.kutu.grind.views.mediators.QualityMenuBaseMediator;
	import ru.kutu.grind.events.ControlBarMenuChangeEvent;
	import ru.kutu.grind.events.LoadMediaEvent;
	
	import ru.kutu.grindplayer.config.MyGrindPlayerConfiguration;
	
	import robotlegs.bender.framework.api.ILogger;
	
	public class MyQualityMenuMediator extends QualityMenuBaseMediator {
		
		[Inject] public var playerConfiguration:PlayerConfiguration;
		[Inject] public var logger:ILogger;
		
		override protected function onNumStreamChange(event:Event = null):void {
			super.onNumStreamChange(event);
			
			var configuration:MyGrindPlayerConfiguration = playerConfiguration as MyGrindPlayerConfiguration;
			
			if (isHdsStream() && configuration.hlsUrl != null) {
				var request:URLRequest = new URLRequest();
				request.url = configuration.hlsUrl
				var loader:URLLoader = new URLLoader();
				loader.dataFormat = URLLoaderDataFormat.TEXT;
				loader.addEventListener(Event.COMPLETE, completeHandler); 
				try
				{ 
					loader.load(request);
				}
				catch (error:Error) 
				{ 
					trace("Unable to load URL");
				}
			}
		}
		
		private function completeHandler(event:Event):void 
		{ 
			var loader:URLLoader = URLLoader(event.target);
			var lines:Array = loader.data.split(/\r?\n/);
			if (lines[0] != '#EXTM3U') { return; }
			
			var label:String = null;
			
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
					
					trace(bw + "," + width + "x" + height);
					
					if (width < 0) {
						label = bw + "kbps";
					}
				}
			}
			
			if (label != null) {
				selectors.push(new QualitySelectorVO(selectors.length, label));
			}
		}
		
		override protected function onMenuChange(event:ControlBarMenuChangeEvent):void {
			
			var configuration:MyGrindPlayerConfiguration = playerConfiguration as MyGrindPlayerConfiguration;
			
			var vo:SelectorVO = selectors[view.selectedIndex];
			
			if (vo) {
				if (streamItems.length >= view.selectedIndex) {
					if (isHdsStream()) {
						super.onMenuChange(event);
					} else {
						configuration.src = configuration.hdsUrl;
						if (view.selectedIndex == 0) { // select auto
							configuration.initailQualityIndex = 0;
							ls.qualityAutoSwitch = true;
						} else {
							configuration.initailQualityIndex = streamItems.length - view.selectedIndex - 1; // HLS stream has one more items
							ls.qualityAutoSwitch = false;
						}
						configuration.initailQualityIndex = 0;
						configuration.playingPosition = player.currentTime;
						eventDispatcher.dispatchEvent(new LoadMediaEvent(LoadMediaEvent.LOAD_MEDIA));
					}
				} else {
					configuration.hdsUrl = configuration.src;
					configuration.src = configuration.hlsUrl;
					configuration.initailQualityIndex = 0;
					configuration.playingPosition = player.currentTime;
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
