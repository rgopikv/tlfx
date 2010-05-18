package flashx.textLayout.format
{
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.formats.ITextLayoutFormat;

	public interface IExportStyleHelper
	{
		/**
		 * Applies inline style attribute to element. Returns flag of inline styles applied to the xml node.
		 * @param node XML
		 * @param element FlowElement
		 * @return Boolean
		 */
		function applyStyleAttributesFromElement( node:XML, element:FlowElement ):Boolean;
		/**
		 * Constrcuts @style attribute based on differing styles between parent and child formatting. 
		 * @param node XML
		 * @param parentFormat ITextLayoutFormat
		 * @param elementFormat ITextLayoutFormat
		 * @param element FlowElement
		 * @return Boolean
		 */
		function applyStyleAttributesFromDifferingStyles( node:XML, parentFormat:ITextLayoutFormat, elementFormat:ITextLayoutFormat, element:FlowElement = null ):Boolean;
	}
}