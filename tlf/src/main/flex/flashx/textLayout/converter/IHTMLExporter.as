package flashx.textLayout.converter
{
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.format.ExportStyleHelper;
	import flashx.textLayout.format.IExportStyleHelper;

	/**
	 * IHTMLExporter is an interface for exporting a list of FlowElements to a a valid fragment. 
	 * @author toddanderson
	 */
	public interface IHTMLExporter
	{
		/**
		 * Exports whole text flow based on conversion type. 
		 * @param source TextFlow
		 * @param conversionType String
		 * @return Object
		 */
		function export(source:TextFlow, conversionType:String):Object
			
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
		function get exportStyleHelper():IExportStyleHelper;
	}
}