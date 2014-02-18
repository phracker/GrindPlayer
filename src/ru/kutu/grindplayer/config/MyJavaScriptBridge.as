/**
 * Written By Lee,Han-gil
 */
package ru.kutu.grindplayer.config {
	
	import flash.external.ExternalInterface;
	
	import robotlegs.bender.framework.api.ILogger;
	
	public class MyJavaScriptBridge extends JavaScriptBridge {
		
		[Inject] public var logger:ILogger;
		
		public function MyJavaScriptBridge() {
			super();
		}
		
		override protected function createJSBridge():void {
			super.createJSBridge();
			
			ExternalInterface.addCallback("setBufferTime", setBufferTime);
		}
		
		protected function setBufferTime(bufferTime:Number):void {
			logger.debug(" * setBufferTime: " + player.currentTime);
			(playerConfiguration as MyGrindPlayerConfiguration).bufferTime = bufferTime;
			player.bufferTime = bufferTime;
		}
	}
	
}
