package ru.kutu.grindplayer.views.mediators {
	
	import flash.system.Capabilities;
	
	public class MyStatInfoMediator extends StatInfoMediator {
		override public function initialize():void {
			var stackTrace:String = new Error().getStackTrace();
			if (stackTrace && stackTrace.search(/:[0-9]+]$/m) > -1) {
				super.initialize();
			}
		}
	}
}