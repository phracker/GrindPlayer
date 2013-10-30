package ru.kutu.grindplayer.config {

	public class MyGrindPlayerConfiguration extends GrindPlayerConfiguration {
		
		public var streamId:String = null;
		public var akamaiDomainName:String = null;
		public var hlsUrl:String = null;
		public var hdsUrl:String = null;
		public var initailQualityIndex:Number = -1;
		public var playingPosition:Number = 0;
		
		public function MyGrindPlayerConfiguration() {
			// Grind Framework set the resource stream type default value to "LiveOrRecorded". But it cause wrong value when HLS plugin is used.
			resource = {};
		}
	}

}
