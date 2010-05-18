package flashx.textLayout.events
{
	import flash.events.Event;
	
	/**
	 * TagParserCleanProgressEvent is an event object representing the progress of a clean pass through table parsing. 
	 * @author toddanderson
	 */
	public class TagParserCleanProgressEvent extends Event
	{
		public var message:String;
		public var percent:Number;
		public static const CLEAN_PROGRESS:String = "cleanProgress";
		
		/**
		 * Constructor.
		 * @param message String
		 * @param percent Number
		 */
		public function TagParserCleanProgressEvent( message:String, percent:Number )
		{
			super( TagParserCleanProgressEvent.CLEAN_PROGRESS, true );
			this.message = message;
			this.percent = percent;
		}
		
		/**
		 * @inherit
		 */
		override public function clone():Event
		{
			return new TagParserCleanProgressEvent( message, percent );
		}
	}
}