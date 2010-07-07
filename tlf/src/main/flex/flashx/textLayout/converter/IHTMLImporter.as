package flashx.textLayout.converter
{
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.format.IImportStyleHelper;

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
		function importToFlow( source:String, updateStyles:Boolean = true ):TextFlow;
		
		/**
		 * Creates a FlowElement based on fragment. 
		 * @param fragment String
		 * @return FlowElement
		 */
		function parseFragment( fragment:String ):FlowElement;
		
		/**
		 * Creates an Array of FlowElements based on fragment. 
		 * @param fragment String
		 * @return Array
		 */
		function parseFragmentToArray( fragment:String ):Array;
		
		/**
		 * Returns the instance of the import style helper used to apply styles to elements parsed. 
		 * @return ImportStyleHelper
		 */
		function get importStyleHelper():IImportStyleHelper;
	}
}