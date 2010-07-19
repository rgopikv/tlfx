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
		 * @param format ITextLayoutFormat The format to base the element styles on.
		 * @return Boolean
		 */
		function applyStyleAttributesFromElement( node:XML, element:FlowElement, format:ITextLayoutFormat = null ):Boolean;
		/**
		 * Constrcuts @style attribute based on differing styles between parent and child formatting. 
		 * @param node XML
		 * @param parentFormat ITextLayoutFormat
		 * @param elementFormat ITextLayoutFormat
		 * @param element FlowElement
		 * @return Boolean
		 */
		function applyStyleAttributesFromDifferingStyles( node:XML, parentFormat:ITextLayoutFormat, elementFormat:ITextLayoutFormat, element:FlowElement = null ):Boolean;
		
		/**
		 * Accessor/Modifier for default format of content to base differing styles off of. 
		 * @return ITextLayoutFormat
		 */
		function get defaultFormat():ITextLayoutFormat;
		function set defaultFormat( value:ITextLayoutFormat ):void
	}
}