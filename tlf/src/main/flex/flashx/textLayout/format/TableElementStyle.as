package flashx.textLayout.format
{
	import flash.utils.describeType;
	
	import flashx.textLayout.model.attribute.Attribute;
	import flashx.textLayout.utils.ColorValueUtil;
	import flashx.textLayout.utils.TableStyleUtil;

	public class TableElementStyle
	{
		protected var _borderStyle:Array;
		protected var _borderWidth:Array;
		protected var _borderColor:Array;
		protected var _borderCollapse:String;
		protected var _borderSpacing:Number;
		protected var _backgroundColor:Number = Number.NaN;
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
				_style = new TableElementStyle( normalizeBorderUnits( _borderStyle || getDefaultBorderStyle() ), 
												normalizeBorderWidthUnits( _borderWidth || getDefaultBorderWidth() ),
												normalizeBorderColorUnits( _borderColor || getDefaultBorderColor() ), 
												( _borderSpacing || 2 ), 
												( _borderCollapse || getDefaultBorderCollapse() ) );
				_style.padding = _padding || 0;
				_style.backgroundColor = ColorValueUtil.normalizeForLayoutFormat(_backgroundColor.toString());
				_style.verticalAlign = _verticalAlign || TableVerticalAlignEnum.TOP;
				_isDirty = false;
			}
			return _style;
		}
		
		protected function evaluateUnitValue( value:* ):Array
		{
			if( value is String )
			{
				value = value.split( "," );
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
		
		public function getDefaultBorderStyle():Array
		{
			return [TableBorderStyleEnum.OUTSET, TableBorderStyleEnum.OUTSET, TableBorderStyleEnum.OUTSET, TableBorderStyleEnum.OUTSET];
		}
		
		public function getDefaultBorderWidth():Array
		{
			return [1, 1, 1, 1];
		}
		
		public function getDefaultBorderColor():Array
		{
			return [0xDDDDDD, 0xAAAAAA, 0xDDDDDD, 0xAAAAAA];
		}
		
		public function getDefaultBorderCollapse():String
		{
			return TableElementStyle.COLLAPSE_SEPARATE;
		}
		
		public function get borderStyle():Array
		{
			return _borderStyle;
		}
		public function set borderStyle( value:* ):void
		{
			if( _borderStyle == value ) return;
			
			value = evaluateUnitValue( value );
			_borderStyle = value;
			_isDirty = true;
		}
		
		public function get borderColor():Array
		{
			return _borderColor;
		}
		public function set borderColor( value:* ):void
		{
			if( _borderColor == value ) return;
			
			value = evaluateUnitValue( value );
			_borderColor = value;
			_isDirty = true;
		}
		
		public function get borderWidth():Array
		{
			return _borderWidth;
		}
		public function set borderWidth( value:* ):void
		{
			if( _borderWidth == value ) return;
			
			value = evaluateUnitValue( value );
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
		
		public function get borderSpacing():Number
		{
			return _borderSpacing;
		}
		public function set borderSpacing( value:Number ):void
		{
			if( _borderSpacing == value ) return;
			
			_borderSpacing = value;
			_isDirty = true;
		}
		
		public function get backgroundColor():Number
		{
			return _backgroundColor;
		}
		public function set backgroundColor( value:Number ):void
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