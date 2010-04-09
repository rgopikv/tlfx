package flashx.textLayout.converter
{
	/**
	 * IHTMLExporter is an interface for exporting a list of FlowElements to a a valid fragment. 
	 * @author toddanderson
	 */
	public interface IHTMLExporter
	{
		/**
		 * Adds FlowElements to a fragment. 
		 * @param node XML
		 * @param elements Array
		 */
		function exportElementsToFragment( node:XML, elements:Array /* FlowElement[] */ ):void;		
	}
}