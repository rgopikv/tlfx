package flashx.textLayout.elements
{
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.model.style.InlineStyles;

	public interface IManagedInlineGraphicSource
	{
		function applyCascadingFormat():void;
		function updateFormatFromComputedStyle( elementFormat:ITextLayoutFormat, computedStyle:Object ):void;
		function copy( targetInlineGraphicElement:InlineGraphicElement = null ):IManagedInlineGraphicSource;
		function stop():void;
		function load():void;
		
		function get inlineGraphicElement():InlineGraphicElement;
		function set inlineGraphicElement( value:InlineGraphicElement ):void;
	}
}