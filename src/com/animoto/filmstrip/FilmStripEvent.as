package com.animoto.filmstrip
{
	import flash.display.BitmapData;
	import flash.events.Event;

	public class FilmStripEvent extends Event
	{
		public static const RENDER_STARTED: String = "renderStarted";
		public static const FRAME_RENDERED: String = "frameRendered";
		public static const RENDER_STOPPED: String = "renderStopped";
		
		public var data: BitmapData;
		public var stats: String;
		
		public function FilmStripEvent(type:String, data:BitmapData=null, stats:String=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.data = data;
			this.stats = stats;
		}
		
		override public function clone():Event {
			return new FilmStripEvent(type, data, stats, bubbles, cancelable);
		}
	}
}