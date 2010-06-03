package flashx.textLayout.model.style
{
	public interface IBoxModelUnitStyle
	{
		/**
		 * Sets the propety value to undefined based on type. 
		 * @param property String
		 */
		function undefineStyleProperty( property:String ):void;
		
		/**
		 * Determines the value validity based on type. 
		 * @param value Object
		 * @return Boolean
		 */
		function isUndefined( value:Object ):Boolean;
		
		/**
		 * Merges previously held property style with overlay style. 
		 * @param style IBoxModelUnitStyle
		 */
		function merge( style:IBoxModelUnitStyle ):void;
		
		/**
		 * Pretty printing. 
		 * @return String
		 */
		function toString():String;
	}
}