package flashx.textLayout.model.style
{
	/**
	 * ITableStyle is a base style implementation describing format and methods not available on the TextLayoutFormat but needed for display context of table elements. 
	 * @author toddanderson
	 */
	public interface ITableStyle
	{
		/**
		 * Returns the computed style based on supplied values and default values. 
		 * @return ITableStyle
		 */
		function getComputedStyle():ITableStyle;
		/**
		 * Returns the cummulative height of the top and bottom borders based on set values. 
		 * @return Number
		 */
		function getComputedHeightOfBorders():Number;
		/**
		 * Returns the cummulative width of the left and right borders based on set values. 
		 * @return Number
		 */
		function getComputedWidthOfBorders():Number;
		
		/**
		 * Accessor/Modifier for border style property. 
		 * @return *
		 */
		function get borderStyle():*;
		function set borderStyle( value:* ):void;
		/**
		 * Accessor/Modifier for the border color property. 
		 * @return *
		 */
		function get borderColor():*;
		function set borderColor( value:* ):void;
		/**
		 * Accessor/Modifier for the border width property. 
		 * @return *
		 */
		function get borderWidth():*;
		function set borderWidth( value:* ):void;
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
		/**
		 * Accessor/Modifier for the padding property. 
		 * @param value Number
		 */
		function get padding():Number;
		function set padding( value:Number ):void;
		
		/**
		 * Undefines property value for property. 
		 * @param property String
		 */
		function undefineStyleProperty( property:String ):void;
		/**
		 * Determines the validity of propety value base don criteria. 
		 * @param value Object
		 * @return Boolean
		 */
		function isUndefined( value:Object ):Boolean;
		/**
		 * Merges previous held style property values with overlay style. 
		 * @param overlay ITableStyle
		 */
		function merge( overlay:ITableStyle ):void;
		/**
		 * Pretty printing of property/value pairs. 
		 * @return String
		 */
		function toString():String;
	}
}