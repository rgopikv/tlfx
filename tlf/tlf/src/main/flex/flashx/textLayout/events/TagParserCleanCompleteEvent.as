package flashx.textLayout.events
{
	import flash.events.Event;
	
	/**
	 * TagParserCleanCompleteEvent is an event related to completion of a ITagCleaner implementation. 
	 * @author toddanderson
	 */
	public class TagParserCleanCompleteEvent extends Event
	{
		public var xml:XML;
		public static const CLEAN_COMPLETE:String = "cleanComplete";
		
		/**
		 * Constructor. 
		 * @param xml The cleaned XML
		 */
		public function TagParserCleanCompleteEvent( xml:XML )
		{
			super( TagParserCleanCompleteEvent.CLEAN_COMPLETE, true );
			this.xml = xml;
		}
		
		/**
		 * @inherit
		 */
		override public function clone():Event
		{
			return new TagParserCleanCompleteEvent( xml );
		}
	}
}