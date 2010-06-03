package flashx.textLayout.model.style
{
	import flash.utils.describeType;
	import flash.utils.flash_proxy;
	
	import flashx.textLayout.utils.BoxModelStyleUtil;

	use namespace flash_proxy;
	dynamic public class PaddingStyle extends BoxModelUnitStyle implements IPaddingStyle
	{
		protected var _padding:*;
		protected var _paddingLeft:*;
		protected var _paddingRight:*;
		protected var _paddingTop:*;
		protected var _paddingBottom:*;
		
		protected var _style:IPaddingStyle;
		protected var _isDirty:Boolean;
		
		protected var _defaultPadding:int;
		
		private static var _description:Vector.<String>;
		
		public function PaddingStyle( defaultPadding:int, padding:* = undefined )
		{
			_defaultPadding = defaultPadding;
			_padding = padding;
			
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
			if( PaddingStyle.definition.indexOf( propertyName ) != -1 )
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
			if( PaddingStyle.definition.indexOf( propertyName ) != -1 ) return this[name];
			return null;
		}
		
		/**
		 * Returns the computed style of this instance in a new instance based on predefined properties and defaults. 
		 * @return IBorderStyle
		 */
		public function getComputedStyle( forceNew:Boolean = false ):IPaddingStyle
		{
			if( ( !_style || _isDirty ) || forceNew )
			{
				_style = new PaddingStyle( _defaultPadding );
				var paddingList:Array = ( _padding ) ? normalizeIntUnits( evaluateUnitValue( _padding ) ) : getDefaultPadding();
				
				normalizePaddingStyle( _style, paddingList );
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
		}
		
		/**
		 * @private
		 * 
		 * Returns the default padding.  
		 * @return Array
		 */
		protected function getDefaultPadding():Array
		{
			return [_defaultPadding, _defaultPadding, _defaultPadding, _defaultPadding];
		}
		
		protected function normalizePaddingStyle( style:IPaddingStyle, list:Array ):void
		{
			if( _paddingTop != undefined ) list[0] = BoxModelStyleUtil.normalizeBorderUnit( _paddingTop );
			if( _paddingRight != undefined ) list[1] = BoxModelStyleUtil.normalizeBorderUnit( _paddingRight );
			if( _paddingBottom != undefined ) list[2] = BoxModelStyleUtil.normalizeBorderUnit( _paddingBottom );
			if( _paddingLeft != undefined ) list[3] = BoxModelStyleUtil.normalizeBorderUnit( _paddingLeft );
			
			style.paddingTop = list[0];
			style.paddingRight = list[1];
			style.paddingBottom = list[2];
			style.paddingLeft = list[3];
			
			style.padding = list;
		}
		
		public function get paddingBottom():*
		{
			return _paddingBottom;
		}
		public function set paddingBottom(value:*):void
		{
			if( _paddingBottom == value ) return;
				
			_isDirty = true;
			_paddingBottom = value;
		}

		public function get paddingTop():*
		{
			return _paddingTop;
		}
		public function set paddingTop(value:*):void
		{
			if( _paddingTop == value ) return;
				
			_isDirty = true;
			_paddingTop = value;
		}

		public function get paddingRight():*
		{
			return _paddingRight;
		}
		public function set paddingRight(value:*):void
		{
			if( _paddingRight == value ) return;
			
			_isDirty = true;
			_paddingRight = value;
		}
		
		public function get paddingLeft():*
		{
			return _paddingLeft;
		}
		public function set paddingLeft(value:*):void
		{
			if( _paddingLeft == value ) return;
			
			_isDirty = true;
			_paddingLeft = value;
		}

		public function get padding():*
		{
			return _padding;
		}
		public function set padding(value:*):void
		{
			if( _padding == value ) return;
			
			_isDirty = true;
			_padding = value;
		}
		
		/**
		 * Merges previously held property style with overlay style. 
		 * @param style IBorderStyle
		 */
		override public function merge( style:IBoxModelUnitStyle ):void
		{
			var description:Vector.<String> = PaddingStyle.definition;
			var property:String;
			var paddingStyle:PaddingStyle = ( style as PaddingStyle );
			if( !paddingStyle ) return;
			
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
		override public function toString():String
		{
			return "======================\n" +
					"|| Padding Style\n" +
					"======================\n" +
					"padding: " + _padding + "\n" +
					"paddingLeft: " + _paddingLeft + "\n" +
					"paddingRight: " + _paddingRight + "\n" +
					"paddingTop: " + _paddingTop + "\n" +
					"paddingBottom: " + _paddingBottom;
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
				var propertyList:XMLList = describeType( PaddingStyle )..accessor;
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