package flashx.textLayout.model.style
{
	import flash.utils.Proxy;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.utils.BoxModelStyleUtil;

	dynamic public class BoxModelUnitStyle extends Proxy implements IBoxModelUnitStyle
	{
		public function BoxModelUnitStyle() {}
		
		/**
		 * @private
		 * 
		 * Modifies the TableStyle based on defined criteria for property values. 
		 * @param boxStyle IBoxModelUnitStyle
		 */
		protected function modifyOnValueCriteria( boxStyle:IBoxModelUnitStyle ):void
		{
			// abstract.
		}
		
		/**
		 * @private
		 * 
		 * Evaluates the property value of a unit defined in an array of values for a property. 
		 * @param value *
		 * @return Array
		 */
		protected function evaluateUnitValue( value:* ):Array
		{
			if( value is String )
			{
				value = value.split( " " );
			}
			return value;
		}
		
		/**
		 * @private
		 * 
		 * Determines property value for border units. 
		 * @param units Array
		 * @return Array
		 */
		protected function normalizeUnits( units:Array ):Array
		{
			if( units.length == 1 )
			{
				units = units.concat( [units[0], units[0], units[0]] );
			}
			else if( units.length == 2 )
			{
				units = units.concat( [units[0], units[1]] );
			}
			else if( units.length == 3 )
			{
				units = units.concat( [units[1]] );
			}
			return units;
		}
		
		/**
		 * @private
		 * 
		 * Determines the property value for units defined in borderWidths. 
		 * @param units Array
		 * @return Array
		 */
		protected function normalizeIntUnits( units:Array ):Array
		{
			units = normalizeUnits( units );
			return BoxModelStyleUtil.convertBorderUnits( units );
		}
		
		/**
		 * @private
		 * 
		 * Determined the property value for units defined in borderColor. 
		 * @param units Array
		 * @return Array
		 */
		protected function normalizeColorUnits( units:Array ):Array
		{
			units = normalizeUnits( units );
			return BoxModelStyleUtil.convertColorUnits( units );
		}
		
		/**
		 * Sets the propety value to undefined based on type. 
		 * @param property String
		 */
		public function undefineStyleProperty( property:String ):void
		{
			if( this[property] is Number ) this[property] = Number.NaN;
			else
			{
				this[property] = undefined;
			}
		}
		
		/**
		 * Determines the value validity based on type. 
		 * @param value Object
		 * @return Boolean
		 */
		public function isUndefined( value:Object ):Boolean
		{
			if( value is Number ) return isNaN(Number(value));
			else if( value is String ) return value == null;
			else if( value is Array ) return value == null;
			return true;
		}
		
		/**
		 * Merges previously held property style with overlay style. 
		 * @param style IBoxModelUnitStyle
		 */
		public function merge( style:IBoxModelUnitStyle ):void
		{
			// abstract.
		}
		
		/**
		 * Pretty printing. 
		 * @return String
		 */
		public function toString():String
		{
			// abstract.
			return getQualifiedClassName( this );
		}
	}
}