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
		 * Defines the weight of rules to use during computation of style. 
		 * @param weightedRules Array An Array of style rule names.
		 */
		function defineWeight( weightedRules:Array ):void;
		
		/**
		 * Defined the wieght rules explicitly expreseed on inline style of element. 
		 * @param rules Array An Array of style rule names.
		 */
		function defineExplicitWeight( rules:Array ):void;
		
		/**
		 * Pretty printing. 
		 * @return String
		 */
		function toString():String;
	}
}