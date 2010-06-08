package flashx.textLayout.model.style
{
	import flash.utils.describeType;
	import flash.utils.flash_proxy;
	
	import flashx.textLayout.utils.BoxModelStyleUtil;
	import flashx.textLayout.utils.BoxModelUnitShorthandUtil;
	import flashx.textLayout.utils.ColorValueUtil;
	import flashx.textLayout.utils.StyleAttributeUtil;

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
			
			_weightedRules = [];
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
				
				var borderStyleList:Array = getDefaultBorderStyle();
				var borderWidthList:Array = getDefaultBorderWidth();
				var borderColorList:Array = getDefaultBorderColor();
				
				var i:int;
				for( i = 0; i < _weightedRules.length; i++ )
				{
					modifyStyleOnRule( _style, _weightedRules[i] );
				}
				
				normalizeBorderStyleStyle( _style, borderStyleList );
				normalizeBorderWidthStyle( _style, borderWidthList );
				normalizeBorderColorStyle( _style, borderColorList );
				modifyOnValueCriteria( _style );
				_isDirty = false;
			}
			return _style;
		}
		
		public function getDeterminedStyle():IBorderStyle
		{
			var style:IBorderStyle = copy();
			var i:int;
			for( i = 0; i < _weightedRules.length; i++ )
			{
				modifyStyleOnRule( style, _weightedRules[i] );
			}
			return style;
		}
		
		public function getDeterminedBorderWidth():Array
		{
			var boxBorder:BoxBorder;
			var shorthandModel:BoxModelShorthand;
			var propertyName:String;
			var value:*;
			var i:int;
			for( i = 0; i < _weightedRules.length; i++ )
			{
				propertyName = _weightedRules[i];
				if( !hasOwnProperty( propertyName ) ) continue;
				
				value = this[propertyName];
				shorthandModel = BoxModelUnitShorthandUtil.deserializeShortHand( value );
				if( !shorthandModel.width ) continue;
				
				if( boxBorder == null ) boxBorder = new BoxBorder();
				if( propertyName == "border" )
				{
					boxBorder.top = boxBorder.bottom = boxBorder.left = boxBorder.right = shorthandModel.width;
				}
				else if( propertyName == "borderTop" )
				{
					boxBorder.top = shorthandModel.width;
				}
				else if( propertyName == "borderRight" )
				{
					boxBorder.right = shorthandModel.width;
				}
				else if( propertyName == "borderBottom" )
				{
					boxBorder.bottom = shorthandModel.width;
				}
			}
			return (boxBorder) ? boxBorder.toBorderModel() : null;
		}
		
		/**
		 * @private
		 * 
		 * Modified specific styles on supplied style based on rule property name. 
		 * @param style IBorderStyle
		 * @param propertyName String
		 */
		protected function modifyStyleOnRule( style:IBorderStyle, propertyName:String ):void
		{
			var styleArray:Array;
			var shorthandModel:BoxModelShorthand;
			var value:* = this[propertyName];
			switch( propertyName )
			{
				case "borderStyle":
					styleArray = normalizeUnits( evaluateUnitValue( value ) );
					style.borderTopStyle = styleArray[0];
					style.borderRightStyle = styleArray[1];
					style.borderBottomStyle = styleArray[2];
					style.borderLeftStyle = styleArray[3];
					break;
				case "borderWidth":
					styleArray = normalizeIntUnits( evaluateUnitValue( value ) );
					style.borderTopWidth = styleArray[0];
					style.borderRightWidth = styleArray[1];
					style.borderBottomWidth = styleArray[2];
					style.borderLeftWidth = styleArray[3];
					break;
				case "borderColor":
					styleArray = normalizeColorUnits( evaluateUnitValue( value ) );
					style.borderTopColor = styleArray[0];
					style.borderRightColor = styleArray[1];
					style.borderBottomColor = styleArray[2];
					style.borderLeftColor = styleArray[3];
					break;
				case "border":
					shorthandModel = BoxModelUnitShorthandUtil.deserializeShortHand( value );
					if( shorthandModel.style )
					{
						style.borderTopStyle = shorthandModel.style;
						style.borderRightStyle = shorthandModel.style;
						style.borderBottomStyle = shorthandModel.style;
						style.borderLeftStyle = shorthandModel.style;
					}
					if( shorthandModel.width )
					{
						style.borderTopWidth = shorthandModel.width;
						style.borderRightWidth = shorthandModel.width;
						style.borderBottomWidth = shorthandModel.width;
						style.borderLeftWidth = shorthandModel.width;
					}
					if( shorthandModel.color )
					{
						style.borderTopColor = shorthandModel.color;
						style.borderRightColor = shorthandModel.color;
						style.borderBottomColor = shorthandModel.color;
						style.borderLeftColor = shorthandModel.color;
					}
					break;
				case "borderTop":
					shorthandModel = BoxModelUnitShorthandUtil.deserializeShortHand( value );
					if( shorthandModel.style ) style.borderTopStyle = shorthandModel.style;
					if( shorthandModel.width ) style.borderTopWidth = shorthandModel.width;
					if( shorthandModel.color ) style.borderTopColor = shorthandModel.color;
					break;
				case "borderRight":
					shorthandModel = BoxModelUnitShorthandUtil.deserializeShortHand( value );
					if( shorthandModel.style ) style.borderRightStyle = shorthandModel.style;
					if( shorthandModel.width ) style.borderRightWidth = shorthandModel.width;
					if( shorthandModel.color ) style.borderRightColor = shorthandModel.color;
					break;
				case "borderBottom":
					shorthandModel = BoxModelUnitShorthandUtil.deserializeShortHand( value );
					if( shorthandModel.style ) style.borderBottomStyle = shorthandModel.style;
					if( shorthandModel.width ) style.borderBottomWidth = shorthandModel.width;
					if( shorthandModel.color ) style.borderBottomColor = shorthandModel.color;
					break;
				case "borderLeft":
					shorthandModel = BoxModelUnitShorthandUtil.deserializeShortHand( value );
					if( shorthandModel.style ) style.borderLeftStyle = shorthandModel.style;
					if( shorthandModel.width ) style.borderLeftWidth = shorthandModel.width;
					if( shorthandModel.color ) style.borderLeftColor = shorthandModel.color;
					break;
				default:
					style[propertyName] = this[propertyName];
					break;
			}
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
				case BorderStyleEnum.NONE:
				case BorderStyleEnum.HIDDEN:
				case BorderStyleEnum.UNDEFINED:
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
				return ( presetStyle != BorderStyleEnum.UNDEFINED ) ? presetStyle : _defaultStyle;
			
			return BorderStyleEnum.UNDEFINED; 
		}
		
		protected function normalizeBorderStyleStyle( style:IBorderStyle, list:Array ):void
		{
			if( style.borderTopStyle != undefined ) list[0] = style.borderTopStyle;
			if( style.borderRightStyle != undefined ) list[1] = style.borderRightStyle;
			if( style.borderBottomStyle != undefined ) list[2] = style.borderBottomStyle;
			if( style.borderLeftStyle != undefined ) list[3] = style.borderLeftStyle;
			
			style.borderTopStyle = list[0];
			style.borderRightStyle = list[1];
			style.borderBottomStyle = list[2];
			style.borderLeftStyle = list[3];
			
			style.borderStyle = list;
		}
		
		protected function normalizeBorderWidthStyle( style:IBorderStyle, list:Array ):void
		{
			if( style.borderTopWidth != undefined ) list[0] = BoxModelStyleUtil.normalizeBorderUnit( style.borderTopWidth );
			if( style.borderRightWidth != undefined ) list[1] = BoxModelStyleUtil.normalizeBorderUnit( style.borderRightWidth );
			if( style.borderBottomWidth != undefined ) list[2] = BoxModelStyleUtil.normalizeBorderUnit( style.borderBottomWidth );
			if( style.borderLeftWidth != undefined ) list[3] = BoxModelStyleUtil.normalizeBorderUnit( style.borderLeftWidth );
			
			style.borderTopWidth = list[0];
			style.borderRightWidth = list[1];
			style.borderBottomWidth = list[2];
			style.borderLeftWidth = list[3];
			
			style.borderWidth = list;
		}
		
		protected function normalizeBorderColorStyle( style:IBorderStyle, list:Array ):void
		{
			if( style.borderTopColor != undefined ) list[0] = style.borderTopColor;
			if( style.borderRightColor != undefined ) list[1] = style.borderRightColor;
			if( style.borderBottomColor != undefined ) list[2] = style.borderBottomColor;
			if( style.borderLeftColor != undefined ) list[3] = style.borderLeftColor;
			
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
			return [BorderStyleEnum.UNDEFINED, BorderStyleEnum.UNDEFINED, BorderStyleEnum.UNDEFINED, BorderStyleEnum.UNDEFINED];
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
		
		override public function defineWeight( weightedRules:Array ):void
		{
			var definition:Vector.<String> = BorderStyle.definition;
			_weightedRules = [];
			var i:int;
			var propertyRule:String;
			for( i = 0; i < weightedRules.length; i++ )
			{
				propertyRule = StyleAttributeUtil.camelize( weightedRules[i] );
				if( definition.indexOf( propertyRule ) != -1 )
					_weightedRules.push( propertyRule );
			}
		}
		
		protected function copy():IBorderStyle
		{
			var style:IBorderStyle = new BorderStyle( _defaultStyle, _defaultColor, _defaultWidth );
			style.defineWeight( _weightedRules );
			var description:Vector.<String> = BorderStyle.definition;
			var property:String;
			for each( property in description )
			{
				if( this[property] )
					style[property] = this[property];
			}
			return style;
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

class BoxBorder {
	
	public var top:int;
	public var left:int;
	public var right:int;
	public var bottom:int;
	
	public function BoxBorder() {}
	
	public function toBorderModel():Array
	{
		return [top, right, bottom, left];
	}
}