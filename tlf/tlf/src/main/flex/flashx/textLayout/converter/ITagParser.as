package flashx.textLayout.converter
{
	import flash.events.IEventDispatcher;
	
	import flashx.textLayout.elements.table.TableElement;

	/**
	 * ITagParser parses a valid HTML markup into a model representation. 
	 * @author toddanderson
	 */
	public interface ITagParser extends ITagCleaner
	{
		/**
		 * Parses specific fragment of HTML based on implementations specification. 
		 * @param fragment String
		 */
		function parse( fragment:String, tableElement:TableElement ):*;
	}
}