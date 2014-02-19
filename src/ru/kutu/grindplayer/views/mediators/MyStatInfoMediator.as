package ru.kutu.grindplayer.views.mediators {
	
	public class MyStatInfoMediator extends StatInfoMediator {
		override public function initialize():void {
			CONFIG::DEBUG {
				super.initialize();
			}
		}
	}
}