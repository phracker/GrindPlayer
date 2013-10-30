package ru.kutu.grindplayer.views.mediators {
	
	import org.osmf.media.MediaResourceBase;
	import org.osmf.media.PluginInfoResource;
	import org.osmf.events.MediaPlayerCapabilityChangeEvent;
	import org.osmf.events.LoadEvent;
	import org.osmf.traits.LoadState;
	
	import ru.kutu.grind.config.PlayerConfiguration;
	import ru.kutu.grindplayer.config.MyGrindPlayerConfiguration;
	
	CONFIG::OPEN_HLS {
		import org.denivip.osmf.plugins.HLSPluginInfo;
	}
	
	public class MyPlayerViewMediator extends PlayerViewMediator {
		
		[Inject] public var playerConfiguration:PlayerConfiguration;
		
		override public function initialize():void {
			super.initialize();
			
			player.addEventListener(LoadEvent.LOAD_STATE_CHANGE, onLoadStateChange);
			player.addEventListener(MediaPlayerCapabilityChangeEvent.CAN_SEEK_CHANGE, onCanSeekShange);
		}
		
		private function onLoadStateChange(e:LoadEvent):void {
			
			var configuration:MyGrindPlayerConfiguration = playerConfiguration as MyGrindPlayerConfiguration;
			
			if (e.loadState == LoadState.READY) {
				if (configuration.playingPosition > 0) {
					player.play();
					player.pause();
				}
			}
		}
		
		private function onCanSeekShange(e:MediaPlayerCapabilityChangeEvent):void {
			
			var configuration:MyGrindPlayerConfiguration = playerConfiguration as MyGrindPlayerConfiguration;
			
			if (player.canSeek) {
				if (configuration.playingPosition > 0) {
					player.seek(configuration.playingPosition);
					configuration.playingPosition = -1;
					player.play();
				}
			}
		}
		
		override protected function processConfiguration(flashvars:Object):void {
			
			if (flashvars.src == null && flashvars.streamId != null) {
				flashvars.hdsUrl = "http://wtbtshdflash-f.akamaihd.net/z/" + flashvars.streamId + "/manifest.f4m";
				flashvars.hlsUrl = "http://wtbtshdflash-f.akamaihd.net/i/" + flashvars.streamId + "/master.m3u8";
				flashvars.src = flashvars.hdsUrl;
			}
			
			super.processConfiguration(flashvars);
		}
		
		override protected function addCustomPlugins(pluginConfigurations:Vector.<MediaResourceBase>):void {
			super.addCustomPlugins(pluginConfigurations);
			
			CONFIG::OPEN_HLS {
				pluginConfigurations.push(new PluginInfoResource(new HLSPluginInfo()));
			}
		}
		
	}
	
}
