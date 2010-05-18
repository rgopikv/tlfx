package flashx.textLayout.converter
{
	import flash.events.IEventDispatcher;

	/**
	 * ITagCleaner is an interface for implentations that handle cleaning a tag for parsing. 
	 * @author toddanderson
	 * 
	 */
	public interface ITagCleaner extends IEventDispatcher
	{
		/**
		 * Performs any cleaning instructions on a fragment to get it ready for parsing. 
		 * @param fragment String
		 */
		function clean( fragment:String ):void;
		/**
		 * Performs any tear down/clenup instructions
		 */
		function dismantle():void;
	}
}