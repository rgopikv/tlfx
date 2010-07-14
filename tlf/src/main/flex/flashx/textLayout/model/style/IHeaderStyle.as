package flashx.textLayout.model.style
{
	public interface IHeaderStyle
	{
		function getComputedLineHeight( fontSizeValue:* ):Number;
		function isUndefined( property:String ):Boolean;
		function undefineStyleProperty( property:String ):void;
		
		function get lineHeight():*;
		function set lineHeight( value:* ):void;
	}
}