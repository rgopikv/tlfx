package flashx.textLayout.model.style
{
	public interface IListStyle
	{
		function getComputedStyle():IListStyle;
		function isUndefined( property:String ):Boolean;
		function undefineStyleProperty( property:String ):void;
		function clone():IListStyle;
		function toString():String;
		
		function get listStyle():*;
		function set listStyle( value:* ):void;
		function get listStyleType():*;
		function set listStyleType( value:* ):void;
		function get listStyleImage():*;
		function set listStyleImage( value:* ):void;
		function get listStylePosition():*;
		function set listStylePosition( value:* ):void;
		
		function get mode():int;
		function set mode( value:int ):void;
	}
}