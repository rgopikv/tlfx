package flashx.textLayout.elements
{
	public interface IManagedInlineGraphicSource
	{
		function applyCascadingFormat():void;
		
		function get inlineGraphicElement():InlineGraphicElement;
		function set inlineGraphicElement( value:InlineGraphicElement ):void;
	}
}