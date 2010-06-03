package flashx.textLayout.model.style
{
	/**
	 * ITableStyle is a base style implementation describing format and methods not available on the TextLayoutFormat but needed for display context of table elements. 
	 * @author toddanderson
	 */
	public interface ITableStyle extends IBoxModelUnitStyle
	{
		/**
		 * Returns the computed style based on supplied values and default values. 
		 * @return ITableStyle
		 */
		function getComputedStyle():ITableStyle;
		
		/**
		 * Accessor/Modifier for the border collapse property. 
		 * @return String
		 */
		function get borderCollapse():String;
		function set borderCollapse( value:String ):void;
		/**
		 * Accessor/Modifier for the border spacing property. 
		 * @return *
		 */
		function get borderSpacing():*;
		function set borderSpacing( value:* ):void;
		/**
		 * Accessor/Modifier fro the background color property. 
		 * @return *
		 */
		function get backgroundColor():*;
		function set backgroundColor( value:* ):void;
		/**
		 * Accessor/Modifier for the vertical align property. 
		 * @return String
		 */
		function get verticalAlign():String;
		function set verticalAlign( value:String ):void;
		
		function get width():*;
		function set width( value:* ):void;
		
		function get height():*;
		function set height( value:* ):void;
		
		function getBorderStyle():IBorderStyle;
		function getPaddingStyle():IPaddingStyle;
	}
}