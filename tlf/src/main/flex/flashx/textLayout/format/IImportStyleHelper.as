package flashx.textLayout.format
{
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.formats.ITextLayoutFormat;

	public interface IImportStyleHelper
	{
		/**
		 * Returns a populated ITextLayoutFormat instance with style formatting based on @style attribute. 
		 * @param styleAttribute String The contents of the @style attribute.
		 * @param heldFormat ITextLayoutFormat The optional previously applied format. 
		 * @return ITextLayoutFormat
		 */
		function getFormatFromStyleAttribute( styleAttribute:String, heldFormat:ITextLayoutFormat = null ):ITextLayoutFormat;
		/**
		 * Marks element as pending style application based on inline @style attirbute from node XML. 
		 * @param node XML
		 * @param element FlowElement
		 */
		function assignInlineStyle( node:XML, element:FlowElement ):void;
		
		/**
		 * Marks the element as no longer requiring changes to styles. 
		 * @param element FlowElement
		 */
		function removeElementFromUpdate( element:FlowElement ):void;
		
		/**
		 * Cycles through pending elements that need to styles applied and updates their formats.
		 */
		function apply():void;
		
		function clean():void;
	}
}