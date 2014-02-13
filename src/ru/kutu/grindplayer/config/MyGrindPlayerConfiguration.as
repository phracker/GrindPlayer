/**
 * Written By Lee,Han-gil
 */
package ru.kutu.grindplayer.config {
	import flash.net.NetGroupReplicationStrategy;

	public class MyGrindPlayerConfiguration extends GrindPlayerConfiguration {
		
		public var streamId:String = null;
		public var akamaiDomainName:String = null;
		
		public var hlsUrl:String = null;
		public var hdsUrl:String = null;
		
		public var bufferTime:Number = 360;
		public var initialBufferTime:Number = 30;
		
		// Quality Select from N to 0
		// If set to -1 than it will be set "AUTO"
		// If set to -2 than it will be start Audio Only with HLS
		public var initialQualityIndex:Number = -1;
		
		public function MyGrindPlayerConfiguration() {
			// Grind Framework set the resource stream type default value to "LiveOrRecorded". But it cause wrong value when HLS plugin is used.
			resource = {};
		}
	}

}
