package flashx.textLayout.model.style
{
	import flash.utils.describeType;
	import flash.utils.flash_proxy;
	
	import flashx.textLayout.utils.BoxModelStyleUtil;
	import flashx.textLayout.utils.ColorValueUtil;

	use namespace flash_proxy;
	dynamic public class BorderStyle extends BoxModelUnitStyle implements IBorderStyle
	{
		protected var _border:*;
		protected var _borderLeft:*;
		protected var _borderRight:*;
		protected var _borderTop:*;
		protected var _borderBottom:*;
		
		protected var _borderColor:*;
		protected var _borderLeftColor:*;
		protected var _borderRightColor:*;
		protected var _borderTopColor:*;
		protected var _borderBottomColor:*;
		
		protected var _borderStyle:*;
		protected var _borderLeftStyle:*;
		protected var _borderRightStyle:*;
		protected var _borderTopStyle:*;
		protected var _borderBottomStyle:*;
		
		protected var _borderWidth:*;
		protected var _borderLeftWidth:*;
		protected var _borderRightWidth:*;
		protected var _borderTopWidth:*;
		protected var _borderBottomWidth:*;
		
		protected var _style:IBorderStyle;
		protected var _isDirty:Boolean;
		
		protected var _defaultStyle:String;
		protected var _defaultColor:uint;
		protected var _defaultWidth:int;
		
		private static var _description:Vector.<String>;
		
		public function BorderStyle( defaultBorderStyle:String, defaultBorderColor:uint, defaultBorderWidth:int, border:* = undefined )
		{
			_defaultStyle = defaultBorderStyle;
			_defaultColor = defaultBorderColor;
			_defaultWidth = defaultBorderWidth;
			_border = border;
		}
		
		/**
		 * Override to store dynamic style in key/value pair 
		 * @param name * The key.
		 * @param value * The value to associate with key.
		 */
		override flash_proxy function setProperty(name:*, value:*):void
		{
			var propertyName:String = ( name is QName ) ? name.localName : name.toString();
			if( BorderStyle.definition.indexOf( propertyName ) != -1 )
				this[propertyName] = value;
		}
		
		/**
		 * Override to return value paired with key. 
		 * @param name * The key.
		 * @return * The associated value.
		 */
		override flash_proxy function getProperty(name:*):*
		{
			var propertyName:String = ( name is QName ) ? name.localName : name.toString();
			if( BorderStyle.definition.indexOf( propertyName ) != -1 ) return this[name];
			return null;
		}
		
		/**
		 * Returns the computed style of this instance in a new instance based on predefined properties and defaults. 
		 * @return IBorderStyle
		 */
		public function getComputedStyle( forceNew:Boolean = false ):IBorderStyle
		{
			if( ( !_style || _isDirty ) || forceNew )
			{
				_style = new BorderStyle( _defaultStyle, _defaultColor, _defaultWidth );
				var borderStyleList:Array = ( _borderStyle ) ? normalizeUnits( evaluateUnitValue( _borderStyle ) ) : getDefaultBorderStyle();
				var borderWidthList:Array = ( _borderWidth ) ? normalizeIntUnits( evaluateUnitValue( _borderWidth ) ) : getDefaultBorderWidth();
				var borderColorList:Array = ( _borderColor ) ? normalizeColorUnits( evaluateUnitValue( _borderColor ) ) : getDefaultBorderColor();
				
				normalizeBorderStyleStyle( _style, borderStyleList );
				normalizeBorderWidthStyle( _style, borderWidthList );
				normalizeBorderColorStyle( _style, borderColorList );
				modifyOnValueCriteria( _style );
				_isDirty = false;
			}
			return _style;
		}
		
		/**
		 * @private
		 * 
		 * Modifies the TableStyle based on defined criteria for property values. 
		 * @param boxStyle IBoxModelUnitStyle
		 */
		override protected function modifyOnValueCriteria( boxStyle:IBoxModelUnitStyle ):void
		{
			// nothing.
			var borderStyle:BorderStyle = ( boxStyle as BorderStyle );
			var modifiedBorderWidth:Array = [];
			var modifiedBorderStyle:Array = [];
			var widths:Array = borderStyle.borderWidth as Array;
			var styles:Array = borderStyle.borderStyle as Array;
			var i:int;
			// Modify width values based on style.
			for( i = 0; i < widths.length; i++ )
			{
				modifiedBorderWidth.push( computeBorderWidthBasedOnStyle( styles[i], widths[i] ) );
			}
			for( i = 0; i < styles.length; i++ )
			{	
				modifiedBorderStyle.push( computeBorderStyleBasedOnWidth( modifiedBorderWidth[i], styles[i] ) );
			}
			normalizeBorderWidthStyle( borderStyle, modifiedBorderWidth );
			normalizeBorderStyleStyle( borderStyle, modifiedBorderStyle );
		}
		
		/**
		 * @private
		 * 
		 * Determines the property border width of a unit based on border style. 
		 * @param style String
		 * @param presetValue Number
		 * @return Number
		 */
		public function computeBorderWidthBasedOnStyle( style:String, presetValue:Number ):Number
		{
			switch( style )
			{
				case TableBorderStyleEnum.NONE:
				case TableBorderStyleEnum.HIDDEN:
				case TableBorderStyleEnum.UNDEFINED:
					return presetValue;
				default:
					return ( presetValue == 0 ) ? 3 : presetValue;
					break;
			}
			return 0;
		}
		
		public function computeBorderStyleBasedOnWidth( width:int, presetStyle:String ):String
		{
			if( width > 0 )
				return ( presetStyle != TableBorderStyleEnum.UNDEFINED ) ? presetStyle : _defaultStyle;
			
			return TableBorderStyleEnum.UNDEFINED; 
		}
		
		protected function normalizeBorderStyleStyle( style:IBorderStyle, list:Array ):void
		{
			if( _borderTopStyle != undefined ) list[0] = BoxModelStyleUtil.normalizeBorderUnit( _borderTopStyle );
			if( _borderRightStyle != undefined ) list[1] = BoxModelStyleUtil.normalizeBorderUnit( _borderRightStyle );
			if( _borderBottomStyle != undefined ) list[2] = BoxModelStyleUtil.normalizeBorderUnit( _borderBottomStyle );
			if( _borderLeftStyle != undefined ) list[3] = BoxModelStyleUtil.normalizeBorderUnit( _borderLeftStyle );
			
			style.borderTopStyle = list[0];
			style.borderRightStyle = list[1];
			style.borderBottomStyle = list[2];
			style.borderLeftStyle = list[3];
			
			style.borderStyle = list;
		}
		
		protected function normalizeBorderWidthStyle( style:IBorderStyle, list:Array ):void
		{
			if( _borderTopWidth != undefined ) list[0] = BoxModelStyleUtil.normalizeBorderUnit( _borderTopWidth );
			if( _borderRightWidth != undefined ) list[1] = BoxModelStyleUtil.normalizeBorderUnit( _borderRightWidth );
			if( _borderBottomWidth != undefined ) list[2] = BoxModelStyleUtil.normalizeBorderUnit( _borderBottomWidth );
			if( _borderLeftWidth != undefined ) list[3] = BoxModelStyleUtil.normalizeBorderUnit( _borderLeftWidth );
			
			style.borderTopWidth = list[0];
			style.borderRightWidth = list[1];
			style.borderBottomWidth = list[2];
			style.borderLeftWidth = list[3];
			
			style.borderWidth = list;
		}
		
		protected function normalizeBorderColorStyle( style:IBorderStyle, list:Array ):void
		{
			if( _borderTopColor != undefined ) list[0] = ColorValueUtil.normalizeForLayoutFormat( _borderTopColor );
			if( _borderRightColor != undefined ) list[1] = ColorValueUtil.normalizeForLayoutFormat( _borderRightColor );
			if( _borderBottomColor != undefined ) list[2] = ColorValueUtil.normalizeForLayoutFormat( _borderBottomColor );
			if( _borderLeftColor != undefined ) list[3] = ColorValueUtil.normalizeForLayoutFormat( _borderLeftColor );
			
			style.borderTopColor = list[0];
			style.borderRightColor = list[1];
			style.borderBottomColor = list[2];
			style.borderLeftColor = list[3];
			
			style.borderColor= list;
		}
		
		/**
		 * @private
		 * 
		 * Returns the default border style array. 
		 * @return Array
		 */
		protected function getDefaultBorderStyle():Array
		{
			return [TableBorderStyleEnum.UNDEFINED, TableBorderStyleEnum.UNDEFINED, TableBorderStyleEnum.UNDEFINED, TableBorderStyleEnum.UNDEFINED];
		}
		
		/**
		 * @private
		 * 
		 * Returns the default border width array. 
		 * @return Array
		 */
		protected function getDefaultBorderWidth():Array
		{
			return [_defaultWidth, _defaultWidth, _defaultWidth, _defaultWidth];
		}
		
		/**
		 * @private
		 * 
		 * Returns the default border color array. 
		 * @return Array
		 */
		protected function getDefaultBorderColor():Array
		{
			return [_defaultColor, _defaultColor, _defaultColor, _defaultColor];
		}

		public function get borderBottomWidth():*
		{
			return _borderBottomWidth;
		}
		public function set borderBottomWidth(value:*):void
		{
			if( _borderBottomWidth == value ) return;
			
			_isDirty = true;
			_borderBottomWidth = value;
		}

		public function get borderTopWidth():*
		{
			return _borderTopWidth;
		}
		public function set borderTopWidth(value:*):void
		{
			if( _borderTopWidth == value ) return;
			
			_isDirty = true;
			_borderTopWidth = value;
		}

		public function get borderRightWidth():*
		{
			return _borderRightWidth;
		}
		public function set borderRightWidth(value:*):void
		{
			if( _borderRightWidth == value ) return;
			
			_isDirty = true;
			_borderRightWidth = value;
		}

		public function get borderLeftWidth():*
		{
			return _borderLeftWidth;
		}
		public function set borderLeftWidth(value:*):void
		{
			if( _borderLeftWidth == value ) return;
			
			_isDirty = true;
			_borderLeftWidth = value;
		}

		public function get borderWidth():*
		{
			return _borderWidth;
		}
		public function set borderWidth(value:*):void
		{
			if( _borderWidth == value ) return;
			
			_isDirty = true;
			_borderWidth = value;
		}

		public function get borderBottomStyle():*
		{
			return _borderBottomStyle;
		}
		public function set borderBottomStyle(value:*):void
		{
			if( _borderBottomStyle == value ) return;
			
			_isDirty = true;
			_borderBottomStyle = value;
		}

		public function get borderTopStyle():*
		{
			return _borderTopStyle;
		}
		public function set borderTopStyle(value:*):void
		{
			if( _borderTopStyle == value ) return;
			
			_isDirty = true;
			_borderTopStyle = value;
		}

		public function get borderRightStyle():*
		{
			return _borderRightStyle;
		}
		public function set borderRightStyle(value:*):void
		{
			if( _borderRightStyle == value ) return;
			
			_isDirty = true;
			_borderRightStyle = value;
		}

		public function get borderLeftStyle():*
		{
			return _borderLeftStyle;
		}
		public function set borderLeftStyle(value:*):void
		{
			if( _borderLeftStyle == value ) return;
			
			_isDirty = true;
			_borderLeftStyle = value;
		}

		public function get borderStyle():*
		{
			return _borderStyle;
		}
		public function set borderStyle(value:*):void
		{
			if( _borderStyle == value ) return;
			
			_isDirty = true;
			_borderStyle = value;
		}

		public function get borderBottomColor():*
		{
			return _borderBottomColor;
		}
		public function set borderBottomColor(value:*):void
		{
			if( _borderBottomColor == value ) return;
			
			_isDirty = true;
			_borderBottomColor = value;
		}

		public function get borderTopColor():*
		{
			return _borderTopColor;
		}
		public function set borderTopColor(value:*):void
		{
			if( _borderTopColor == value ) return;
			
			_isDirty = true;
			_borderTopColor = value;
		}

		public function get borderRightColor():*
		{
			return _borderRightColor;
		}
		public function set borderRightColor(value:*):void
		{
			if( _borderRightColor == value ) return;
			
			_isDirty = true;
			_borderRightColor = value;
		}

		public function get borderLeftColor():*
		{
			return _borderLeftColor;
		}
		public function set borderLeftColor(value:*):void
		{
			if( _borderLeftColor == value ) return;
			
			_isDirty = true;
			_borderLeftColor = value;
		}

		public function get borderColor():*
		{
			return _borderColor;
		}
		public function set borderColor(value:*):void
		{
			if( _borderColor == value ) return;
			
			_isDirty = true;
			_borderColor = value;
		}

		public function get borderBottom():*
		{
			return _borderBottom;
		}
		public function set borderBottom(value:*):void
		{
			if( _borderBottom == value ) return;
			
			_isDirty = true;
			_borderBottom = value;
		}

		public function get borderTop():*
		{
			return _borderTop;
		}
		public function set borderTop(value:*):void
		{
			if( _borderTop == value ) return;
			
			_isDirty = true;
			_borderTop = value;
		}

		public function get borderRight():*
		{
			return _borderRight;
		}
		public function set borderRight(value:*):void
		{
			if( _borderRight == value ) return;
			
			_isDirty = true;
			_borderRight = value;
		}

		public function get borderLeft():*
		{
			return _borderLeft;
		}
		public function set borderLeft(value:*):void
		{
			if( _borderLeft == value ) return;
			
			_isDirty = true;
			_borderLeft = value;
		}

		public function get border():*
		{
			return _border;
		}
		public function set border(value:*):void
		{
			if( _border == value ) return;
			
			_isDirty = true;
			_border = value;
		}
		
		/**
		 * Merges previously held property style with overlay style. 
		 * @param style IBorderStyle
		 */
		override public function merge( style:IBoxModelUnitStyle ):void
		{
			var description:Vector.<String> = BorderStyle.definition;
			var property:String;
			var borderStyle:BorderStyle = style as BorderStyle;
			if( !borderStyle ) return;
			
			for each( property in description )
			{
				if( isUndefined( this[property] ) )
					this[property] = borderStyle[property];
			}
		}
		
		/**
		 * Pretty printing. 
		 * @return String
		 */
		override public function toString():String
		{
			return "======================\n" +
				"|| Border Style\n" +
				"======================\n" +
				"border: " + _border + "\n" +
				"borderStyleLeft: " + _borderLeftStyle + "\n" +
				"borderStyleRight: " + _borderRightStyle + "\n" +
				"borderStyleBottom: " + _borderBottomStyle + "\n" +
				"borderStyleTop: " + _borderTopStyle + "\n" +
				"borderColor: " + _borderColor + "\n" +
				"borderColorLeft: " + _borderLeftColor + "\n" +
				"borderColorRight: " + _borderRightColor + "\n" +
				"borderColorBottom: " + _borderBottomColor + "\n" +
				"borderColorTop: " + _borderTopColor + "\n" +
				"borderWidth: " + _borderWidth + "\n" +
				"borderWidthLeft: " + _borderLeftWidth + "\n" +
				"borderWidthRight: " + _borderRightWidth + "\n" +
				"borderWidthBottom: " + _borderBottomWidth + "\n" +
				"borderWidthTop: " + _borderTopWidth + "\n"
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
				var propertyList:XMLList = describeType( BorderStyle )..accessor;
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