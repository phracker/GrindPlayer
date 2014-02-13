/**
 * Written By Lee,Han-gil
 */
package ru.kutu.grindplayer.config {
	
	import flash.external.ExternalInterface;
	
	import ru.kutu.grind.events.LoadMediaEvent;
	
	import robotlegs.bender.framework.api.ILogger;
	
	public class MyJavaScriptBridge extends JavaScriptBridge {
		
		[Inject] public var logger:ILogger;
		
		public function MyJavaScriptBridge() {
			super();
		}
		
		/**
		 * Example for add custom function
		 */
		/*
		override protected function createJSBridge():void {
			super.createJSBridge();
			
			ExternalInterface.addCallback("reload", reload);
		}
		
		protected function reload():void {
			logger.debug(" * CurrentTime: " + player.currentTime);
			eventDispatcher.dispatchEvent(new LoadMediaEvent(LoadMediaEvent.LOAD_MEDIA));
		}
		//*/		
	}
	
}
