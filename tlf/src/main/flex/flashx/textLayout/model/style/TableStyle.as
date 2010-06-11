package flashx.textLayout.model.style
{
	import flash.utils.describeType;
	import flash.utils.flash_proxy;
	
	import flashx.textLayout.model.attribute.Attribute;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.BoxModelStyleUtil;
	import flashx.textLayout.utils.ColorValueUtil;
	import flashx.textLayout.utils.StyleAttributeUtil;

	use namespace flash_proxy;
	/**
	 * TableStyle is an ITableStyle implementation exposes properties and method son handling property values related to a table element. 
	 * @author toddanderson
	 */
	dynamic public class TableStyle extends BoxModelUnitStyle implements ITableStyle
	{
		protected var _borderCollapse:String;
		protected var _borderSpacing:* = Number.NaN;
		protected var _backgroundColor:* = Number.NaN;
		protected var _padding:*;
		protected var _verticalAlign:String;
		protected var _width:*;
		protected var _height:*;
		
		protected var _style:TableStyle;
		protected var _borderStyle:IBorderStyle;
		protected var _paddingStyle:IPaddingStyle;
		
		protected var _isDirty:Boolean;
		
		protected var _defaultBorderStyle:String = BorderStyleEnum.OUTSET;
		protected var _defaultBorderColor:uint = 0x808080;
		protected var _defaultBorderWidth:int = 0;
		protected var _defaultPadding:int = 0;
		
		protected var _exportablePropertyList:Array;
		
		private static var _description:Vector.<String>;
		private static var _fullDescription:Vector.<String>;
		
		/**
		 * Constructor.
		 */
		public function TableStyle( border:* = undefined, padding:* = undefined ) 
		{
			_borderStyle = new BorderStyle( getDefaultBorderStyle(), _defaultBorderColor, _defaultBorderWidth, border );
			_paddingStyle = new PaddingStyle( _defaultPadding, padding );
			
			_weightedRules = [];
			_exportablePropertyList = ["width", "height"];
		}
		
		protected function getDefaultBorderStyle():String
		{
			return _defaultBorderStyle;
		}
		
		/**
		 * Override to store dynamic style in key/value pair 
		 * @param name * The key.
		 * @param value * The value to associate with key.
		 */
		override flash_proxy function setProperty(name:*, value:*):void
		{
			var propertyName:String = ( name is QName ) ? name.localName : name.toString();
			if( TableStyle.definition.indexOf( propertyName ) != -1 )
				this[propertyName] = value;
			else
			{
				if( propertyName.indexOf( "border" ) != -1 )
				{
					_borderStyle[propertyName] = value;
				}
				else if( propertyName.indexOf( "padding" ) != -1 )
				{
					_paddingStyle[propertyName] = value;
				}
			}
		}
		
		/**
		 * Override to return value paired with key. 
		 * @param name * The key.
		 * @return * The associated value.
		 */
		override flash_proxy function getProperty(name:*):*
		{
			var propertyName:String = ( name is QName ) ? name.localName : name.toString();
			if( TableStyle.definition.indexOf( propertyName ) != -1 ) return this[name];
			else
			{
				if( propertyName.indexOf( "border" ) != -1 )
				{
					return _borderStyle[name];
				}
				else if( propertyName.indexOf( "padding" ) != -1 )
				{
					return _paddingStyle[propertyName];
				}
			}
			return null;
		}
		
		/**
		 * Returns the computed style of this instance in a new instance based on predefined properties and defaults. 
		 * @return ITableStyle
		 */
		public function getComputedStyle():ITableStyle
		{
			if( !_style || _isDirty )
			{
				// Create computed style based on defined properties.
				_style = new TableStyle();
				_style.borderSpacing = ( _borderSpacing ) ? BoxModelStyleUtil.normalizeBorderUnit(_borderSpacing) : getDefaultBorderSpacing();
				_style.backgroundColor = ( !isUndefined( _backgroundColor ) ) ? ColorValueUtil.normalizeForLayoutFormat(_backgroundColor) : Number.NaN;
				_style.verticalAlign = _verticalAlign || TableVerticalAlignEnum.TOP;
				modifyOnValueCriteria( _style );
				_isDirty = false;
			}
			// compute styles for border qand padding.
			use namespace tlf_internal;
			_style.setBorderStyle( _borderStyle.getComputedStyle() );
			_style.setPaddingStyle( _paddingStyle.getComputedStyle() );
			return _style;
		}
		
		public function getDeterminedStyle():ITableStyle
		{
			var style:TableStyle = copy() as TableStyle;
			use namespace tlf_internal;
			style.setBorderStyle( _borderStyle.getDeterminedStyle() );
			style.setPaddingStyle( _paddingStyle.getDeterminedStyle() );
			return style;
		}
		
		public function getExportableStyle():Object
		{
			var exportableStyle:Object = {};
			var i:int = _exportablePropertyList.length;
			var property:String;
			while( --i > -1 )
			{
				property = _exportablePropertyList[i];
				if( this[property] )
					exportableStyle[property] = this[property];
			}
			return exportableStyle;
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
		
		public function get width():*
		{
			return _width;
		}
		public function set width( value:* ):void
		{
			if( _width == value ) return;
			
			_width = value;
			_isDirty = true;
		}
		
		public function get height():*
		{
			return _height;
		}
		public function set height( value:* ):void
		{
			if( _height == value ) return;
			
			_height = value;
			_isDirty = true;
		}
		
		public function getBorderStyle():IBorderStyle
		{
			return _borderStyle;
		}
		tlf_internal function setBorderStyle( value:IBorderStyle ):void
		{
			_borderStyle = value;
		}
		
		public function getPaddingStyle():IPaddingStyle
		{
			return _paddingStyle;
		}
		tlf_internal function setPaddingStyle( value:IPaddingStyle ):void
		{
			_paddingStyle = value;
		}
		
		/**
		 * Merges previously held property style with overlay style. 
		 * @param style ITableStyle
		 */
		override public function merge( style:IBoxModelUnitStyle ):void
		{
			var description:Vector.<String> = TableStyle.definition;
			var property:String;
			var tableStyle:TableStyle = ( style as TableStyle );
			if( !tableStyle ) return;
			
			for each( property in description )
			{
				if( isUndefined( this[property] ) )
					this[property] = tableStyle[property];
			}
			_borderStyle.merge( tableStyle.getBorderStyle() );
			_paddingStyle.merge( tableStyle.getPaddingStyle() );
		}
		
		override public function defineWeight( weightedRules:Array ):void
		{
			_weightedRules = weightedRules.concat( _explicitWeightedRules );
			_borderStyle.defineWeight( weightedRules );	
		}
		
		override public function defineExplicitWeight( rules:Array ):void
		{
			_explicitWeightedRules = rules;
			_weightedRules = _weightedRules.concat( _explicitWeightedRules );
			_borderStyle.defineExplicitWeight( rules );
		}
		
		public function copy():ITableStyle
		{
			var style:ITableStyle = new TableStyle();
			var description:Vector.<String> = TableStyle.definition;
			var property:String;
			for each( property in description )
			{
				if( this[property] )
					style[property] = this[property];
			}
			
			style.defineWeight( _weightedRules );
			use namespace tlf_internal;
			( style as TableStyle ).setBorderStyle( _borderStyle );
			( style as TableStyle ).setPaddingStyle( _paddingStyle );
			return style;
		}
		
		/**
		 * Pretty printing. 
		 * @return String
		 */
		override public function toString():String
		{
			return "======================\n" +
				"|| Table Style\n" +
				"======================\n" +
				"borderCollapse: " + _borderCollapse + "\n" +
				"borderSpacing: " + _borderSpacing + "\n" +
				"backgroundColor: " + _backgroundColor + "\n" +
				"verticalAlign: " + _verticalAlign + "\n" + 
				_borderStyle.toString() + "\n" +
				_paddingStyle.toString();
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
		
		/**
		 * Returns full property list definitions of this and child styles, such as border and padding. 
		 * @return Vector.<String>
		 */
		static public function get fullDefinition():Vector.<String>
		{
			if( !_fullDescription )
			{
				_fullDescription = TableStyle.definition;
				_fullDescription = _fullDescription.concat( BorderStyle.definition );
				_fullDescription = _fullDescription.concat( PaddingStyle.definition );
			}
			return _fullDescription;
		}
	}
}