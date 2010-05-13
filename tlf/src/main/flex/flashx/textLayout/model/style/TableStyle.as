package flashx.textLayout.model.style
{
	import flash.utils.describeType;
	
	import flashx.textLayout.model.attribute.Attribute;
	import flashx.textLayout.utils.ColorValueUtil;
	import flashx.textLayout.utils.StyleAttributeUtil;
	import flashx.textLayout.utils.TableStyleUtil;

	/**
	 * TableStyle is an ITableStyle implementation exposes properties and method son handling property values related to a table element. 
	 * @author toddanderson
	 */
	public class TableStyle implements ITableStyle
	{
		protected var _borderStyle:*;
		protected var _borderWidth:*;
		protected var _borderColor:*;
		protected var _borderCollapse:String;
		protected var _borderSpacing:* = Number.NaN;
		protected var _backgroundColor:* = Number.NaN;
		protected var _verticalAlign:String;
		protected var _padding:Number = Number.NaN;
		
		protected var _style:TableStyle;
		protected var _isDirty:Boolean;
		
		private static var _description:Vector.<String>;
		
		/**
		 * Constructor. 
		 * @param borderStyle Array
		 * @param borderWidth Array
		 * @param borderColor Array
		 * @param borderSpacing Number
		 * @param borderCollapse String
		 */
		public function TableStyle( borderStyle:Array = null, borderWidth:Array = null, 
										   borderColor:Array = null, borderSpacing:Number = Number.NaN, 
										   borderCollapse:String = null )
		{
			this.borderStyle = borderStyle;
			this.borderWidth = borderWidth;
			this.borderColor = borderColor;
			this.borderSpacing = borderSpacing;
			this.borderCollapse = borderCollapse;
		}
		
		/**
		 * Returns the computed style of this instance in a new instance based on predefined properties and defaults. 
		 * @return ITableStyle
		 */
		public function getComputedStyle():ITableStyle
		{
			if( !_style || _isDirty )
			{
				_style = new TableStyle();
				_style.borderStyle = ( _borderStyle ) ? normalizeBorderUnits( evaluateUnitValue( _borderStyle ) ) : getDefaultBorderStyle();
				_style.borderWidth = ( _borderWidth ) ? normalizeBorderWidthUnits( evaluateUnitValue( _borderWidth ) ) : getDefaultBorderWidth();
				_style.borderColor = ( _borderColor ) ? normalizeBorderColorUnits( evaluateUnitValue( _borderColor ) ) : getDefaultBorderColor();
				_style.borderSpacing = ( _borderSpacing ) ? TableStyleUtil.normalizeBorderUnit(_borderSpacing) : getDefaultBorderSpacing();
				_style.padding = _padding || 0;
				_style.backgroundColor = ( !isUndefined( _backgroundColor ) ) ? ColorValueUtil.normalizeForLayoutFormat(_backgroundColor) : Number.NaN;
				_style.verticalAlign = _verticalAlign || TableVerticalAlignEnum.TOP;
				modifyOnValueCriteria( _style );
				_isDirty = false;
			}
			return _style;
		}
		
		/**
		 * Returns the cummulative height based on top and bottom border widths. 
		 * @return Number
		 */
		public function getComputedHeightOfBorders():Number
		{
			var computedStyle:ITableStyle = getComputedStyle();
			return computedStyle.borderWidth[0] + computedStyle.borderWidth[2];
		}
		
		/**
		 * Returns the cummulative width based on left and right border widths. 
		 * @return Number
		 */
		public function getComputedWidthOfBorders():Number
		{
			var computedStyle:ITableStyle = getComputedStyle();
			return computedStyle.borderWidth[1] + computedStyle.borderWidth[3];
		}
		
		/**
		 * @private
		 * 
		 * Modifies the TableStyle based on defined criteria for property values. 
		 * @param tableElementStyle TableStyle
		 */
		protected function modifyOnValueCriteria( tableElementStyle:TableStyle ):void
		{
			var modifiedBorderWidth:Array = [];
			var widths:Array = tableElementStyle.borderWidth as Array;
			var styles:Array = tableElementStyle.borderStyle as Array;
			var i:int;
			// Modify width values based on style.
			for( i = 0; i < widths.length; i++ )
			{
				modifiedBorderWidth.push( computeBorderWidthBasedOnStyle( styles[i], widths[i] ) );
			}
			tableElementStyle.borderWidth = modifiedBorderWidth;
			// Modify border spacing based on style.
//			var hasStyle:Boolean;
//			i = styles.length;
//			while( --i > -1 )
//			{
//				if( styles[i] != TableBorderStyleEnum.NONE && styles[i] != TableBorderStyleEnum.HIDDEN )
//				{
//					hasStyle = true;
//					break;
//				}
//			}
//			tableElementStyle.borderSpacing = hasStyle ? tableElementStyle.borderSpacing : 0;
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
		protected function normalizeBorderUnits( units:Array ):Array
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
		protected function normalizeBorderWidthUnits( units:Array ):Array
		{
			units = normalizeBorderUnits( units );
			return TableStyleUtil.convertBorderUnits( units );
		}
		
		/**
		 * @private
		 * 
		 * Determined the property value for units defined in borderColor. 
		 * @param units Array
		 * @return Array
		 */
		protected function normalizeBorderColorUnits( units:Array ):Array
		{
			units = normalizeBorderUnits( units );
			return TableStyleUtil.convertColorUnits( units );
		}
		
		/**
		 * @private
		 * 
		 * Returns the default border style array. 
		 * @return Array
		 */
		protected function getDefaultBorderStyle():Array
		{
			return [TableBorderStyleEnum.NONE, TableBorderStyleEnum.NONE, TableBorderStyleEnum.NONE, TableBorderStyleEnum.NONE];
		}
		
		/**
		 * @private
		 * 
		 * Returns the default border width array. 
		 * @return Array
		 */
		protected function getDefaultBorderWidth():Array
		{
			return [0, 0, 0, 0];
		}
		
		/**
		 * @private
		 * 
		 * Returns the default border color array. 
		 * @return Array
		 */
		protected function getDefaultBorderColor():Array
		{
			return [0x808080, 0x808080, 0x808080, 0x808080];
		}
		
		/**
		 * @private
		 * 
		 * Returns the default border collapse. 
		 * @return String
		 */
		protected function getDefaultBorderCollapse():String
		{
			return TableCollapseStyleEnum.COLLAPSE_SEPARATE;
		}
		
		/**
		 * @private
		 * 
		 * Returns the default border spacing. 
		 * @return Number
		 */
		protected function getDefaultBorderSpacing():Number
		{
			return 2;
		}
		
		/**
		 * @private
		 * 
		 * Determines the property border width of a unit based on border style. 
		 * @param style String
		 * @param presetValue Number
		 * @return Number
		 */
		protected function computeBorderWidthBasedOnStyle( style:String, presetValue:Number ):Number
		{
			switch( style )
			{
				case TableBorderStyleEnum.NONE:
				case TableBorderStyleEnum.HIDDEN:
					return 0;
				default:
					return ( presetValue == 0 ) ? 3 : presetValue;
					break;
			}
			return 0;
		}
		
		/**
		 * @see ITableStyle#borderStyle
		 */
		public function get borderStyle():*
		{
			return _borderStyle;
		}
		public function set borderStyle( value:* ):void
		{
			if( _borderStyle == value ) return;
			
			_borderStyle = value;
			_isDirty = true;
		}
		/**
		 * @see ITableStyle#borderColor
		 */
		public function get borderColor():*
		{
			return _borderColor;
		}
		public function set borderColor( value:* ):void
		{
			if( _borderColor == value ) return;
			
			_borderColor = value;
			_isDirty = true;
		}
		/**
		 * @see ITableStyle#borderWidth
		 */
		public function get borderWidth():*
		{
			return _borderWidth;
		}
		public function set borderWidth( value:* ):void
		{
			if( _borderWidth == value ) return;
			
			_borderWidth = value;
			_isDirty = true;
		}
		/**
		 * @see ITableStyle#borderCollapse
		 */
		public function get borderCollapse():String
		{
			return _borderCollapse;
		}
		public function set borderCollapse( value:String ):void
		{
			if( _borderCollapse == value ) return;
			
			_borderCollapse = value;
			_isDirty = true;
		}
		/**
		 * @see ITableStyle#borderSpacing
		 */
		public function get borderSpacing():*
		{
			return _borderSpacing;
		}
		public function set borderSpacing( value:* ):void
		{
			if( _borderSpacing == value ) return;
			
			_borderSpacing = value;
			_isDirty = true;
		}
		/**
		 * @see ITableStyle#backgroundColor
		 */
		public function get backgroundColor():*
		{
			return _backgroundColor;
		}
		public function set backgroundColor( value:* ):void
		{
			if( _backgroundColor == value ) return;
			
			_backgroundColor = value;
			_isDirty = true;
		}
		/**
		 * @see ITableStyle#verticalAlign
		 */
		public function get verticalAlign():String
		{
			return _verticalAlign;
		}
		public function set verticalAlign( value:String ):void
		{
			if( _verticalAlign == value ) return;
			
			_verticalAlign = value;
			_isDirty = true;
		}
		/**
		 * @see ITableStyle#padding
		 */
		public function get padding():Number
		{
			return _padding;
		}
		public function set padding( value:Number ):void
		{
			if( _padding == value ) return;
			
			_padding = value;
			_isDirty = true;
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
				this[property] = null;
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
		 * @param style ITableStyle
		 */
		public function merge( style:ITableStyle ):void
		{
			var description:Vector.<String> = TableStyle.definition;
			var property:String;
			for each( property in description )
			{
				if( isUndefined( this[property] ) )
					this[property] = style[property];
			}
		}
		
		/**
		 * Pretty printing. 
		 * @return String
		 */
		public function toString():String
		{
			return "borderWidth: " + _borderWidth + "\n" +
				"borderStyle: " + _borderStyle + "\n" +
				"borderColor: " + _borderColor + "\n" +
				"borderCollapse: " + _borderCollapse + "\n" +
				"borderSpacing: " + _borderSpacing + "\n" +
				"backgroundColor: " + _backgroundColor + "\n" +
				"padding: " + _padding + "\n" +
				"verticalAlign: " + _verticalAlign + "\n";
		}
		
		/**
		 * Returns the list of property definitions related to this class for ease of traverse. 
		 * @return Vector.<String>
		 */
		static public function get definition():Vector.<String>
		{
			if( !_description )
			{
				_description = new Vector.<String>();
				var property:String;
				var propertyList:XMLList = describeType( TableStyle )..accessor;
				var i:int;
				for( i = 0; i < propertyList.length(); i++ )
				{
					if( !(propertyList[i].@access == "readwrite") ) continue;
					property = propertyList[i].@name;
					_description.push( property );
				}
			}
			return _description;
		}
	}
}