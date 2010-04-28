package flashx.textLayout.converter
{
	import flashx.textLayout.format.ExportStyleHelper;

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
		
		/**
		 * Returns the export style helper instanced used by the exporter. 
		 * @return ExportStyleHelper
		 */
		function get exportStyleHelper():ExportStyleHelper;
	}
}