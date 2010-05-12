package flashx.textLayout.format
{
	import flash.utils.describeType;
	
	import flashx.textLayout.model.attribute.Attribute;
	import flashx.textLayout.utils.ColorValueUtil;
	import flashx.textLayout.utils.StyleAttributeUtil;
	import flashx.textLayout.utils.TableStyleUtil;

	public class TableElementStyle
	{
		protected var _borderStyle:*;
		protected var _borderWidth:*;
		protected var _borderColor:*;
		protected var _borderCollapse:String;
		protected var _borderSpacing:* = Number.NaN;
		protected var _backgroundColor:* = Number.NaN;
		protected var _verticalAlign:String;
		protected var _padding:Number = Number.NaN;
		
		protected var _style:TableElementStyle;
		protected var _isDirty:Boolean;
		
		private static var _description:Vector.<String>;
		
		public static const COLLAPSE_SEPARATE:String = "separate";
		public static const COLLAPSE_COLLAPSE:String = "collapse";
		
		public function TableElementStyle( borderStyle:Array = null, borderWidth:Array = null, 
										   borderColor:Array = null, borderSpacing:Number = Number.NaN, 
										   borderCollapse:String = null )
		{
			this.borderStyle = borderStyle;
			this.borderWidth = borderWidth;
			this.borderColor = borderColor;
			this.borderSpacing = borderSpacing;
			this.borderCollapse = borderCollapse;
		}
		
		public function getComputedStyle():TableElementStyle
		{
			if( !_style || _isDirty )
			{
				_style = new TableElementStyle();
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
		
		public function getComputedHeightOfBorderSpacing():Number
		{
			var computedStyle:TableElementStyle = getComputedStyle();
			return computedStyle.borderWidth[0] + computedStyle.borderWidth[2] + ( computedStyle.borderSpacing * 2 );
		}
		
		public function getComputedWidthOfBorderSpacing():Number
		{
			var computedStyle:TableElementStyle = getComputedStyle();
			return computedStyle.borderWidth[1] + computedStyle.borderWidth[3] + ( computedStyle.borderSpacing * 2 );
		}
		
		protected function modifyOnValueCriteria( tableElementStyle:TableElementStyle ):void
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
		
		protected function evaluateUnitValue( value:* ):Array
		{
			if( value is String )
			{
				value = value.split( " " );
			}
			return value;
		}
		
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
		
		protected function normalizeBorderWidthUnits( units:Array ):Array
		{
			units = normalizeBorderUnits( units );
			return TableStyleUtil.convertBorderUnits( units );
		}
		
		protected function normalizeBorderColorUnits( units:Array ):Array
		{
			units = normalizeBorderUnits( units );
			return TableStyleUtil.convertColorUnits( units );
		}
		
		protected function getDefaultBorderStyle():Array
		{
			return [TableBorderStyleEnum.NONE, TableBorderStyleEnum.NONE, TableBorderStyleEnum.NONE, TableBorderStyleEnum.NONE];
		}
		
		protected function getDefaultBorderWidth():Array
		{
			return [0, 0, 0, 0];
		}
		
		protected function getDefaultBorderColor():Array
		{
			return [0x808080, 0x808080, 0x808080, 0x808080];
		}
		
		protected function getDefaultBorderCollapse():String
		{
			return TableElementStyle.COLLAPSE_SEPARATE;
		}
		
		protected function getDefaultBorderSpacing():Number
		{
			return 2;
		}
		
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
		
		public function undefineStyleProperty( property:String ):void
		{
			if( this[property] is Number ) this[property] = Number.NaN;
			else
			{
				this[property] = null;
			}
		}
		
		public function isUndefined( value:Object ):Boolean
		{
			if( value is Number ) return isNaN(Number(value));
			else if( value is String ) return value == null;
			else if( value is Array ) return value == null;
			return true;
		}
		
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
		
		static public function get definition():Vector.<String>
		{
			if( !_description )
			{
				_description = new Vector.<String>();
				var property:String;
				var propertyList:XMLList = describeType( TableElementStyle )..accessor;
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