package ru.kutu.grindplayer.views.mediators {
	
	import org.osmf.events.MetadataEvent;
	import org.osmf.media.MediaElement;
	import org.osmf.net.StreamType;
	
	import robotlegs.bender.framework.api.ILogger;
	
	public class MyScrubBarMediator extends ScrubBarMediator {
		
		[Inject] public var logger:ILogger;
		
		override protected function updateEnabled():void {
			view.enabled = isStartPlaying && streamType == StreamType.RECORDED;
			view.visible = streamType == StreamType.RECORDED;
		}
	}	
}
