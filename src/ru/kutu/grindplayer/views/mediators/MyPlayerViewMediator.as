/**
 * Written By Lee,Han-gil
 */
package ru.kutu.grindplayer.views.mediators {
	
	import org.osmf.media.MediaResourceBase;
	import org.osmf.media.PluginInfoResource;
	
	CONFIG::OPEN_HLS {
		import org.denivip.osmf.plugins.HLSPluginInfo;
	}
	
	public class MyPlayerViewMediator extends PlayerViewMediator {
		
		override protected function processConfiguration(flashvars:Object):void {
			
			if (flashvars.src == null && flashvars.streamId != null && flashvars.akamaiDomainName != null) {
				flashvars.hdsUrl = "http://" + flashvars.akamaiDomainName + "/z/" + flashvars.streamId + "/manifest.f4m";
				flashvars.hlsUrl = "http://" + flashvars.akamaiDomainName + "/i/" + flashvars.streamId + "/master.m3u8";
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
