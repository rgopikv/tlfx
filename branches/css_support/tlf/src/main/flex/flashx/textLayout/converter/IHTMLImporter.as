package flashx.textLayout.converter
{
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.TextFlow;

	/**
	 * IHTMLImporter is a basic interface for extended html importers. 
	 * @author toddanderson
	 */
	public interface IHTMLImporter
	{
		/**
		 * Creates a TextFlow instance based on the supplied source. 
		 * @param source String HTML markup
		 * @return TextFlow
		 */
		function importToFlow( source:String ):TextFlow;
		
		/**
		 * Creates a FlowElement based on fragment. 
		 * @param fragment String
		 * @return FlowElement
		 */
		function parseFragment( fragment:String ):FlowElement;
	}
}