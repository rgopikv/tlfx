package flashx.textLayout.model.style
{
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.elements.list.ListItemModeEnum;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.utils.ListStyleShorthandUtil;
	
	public class ListStyle implements IListStyle
	{
		protected var _mode:int;
		
		protected var _listStyle:*;
		protected var _listStyleType:*;
		protected var _listStyleImage:*;
		protected var _listStylePosition:*;
		
		//	[KK]	Formatting for normal styling
		protected var _format:TextLayoutFormat;
		
		protected var _style:IListStyle;
		protected var _isDirty:Boolean;
		
		private static var _description:Vector.<String>;
		
		public function ListStyle( mode:int )
		{
			_mode = mode;
		}
		
		public function getComputedStyle():IListStyle
		{
			if( !_style || _isDirty )
			{
				_style = new ListStyle( _mode );
				// Fill with explicit value properties.
				_style.listStyleType = ( _listStyleType ) ? _listStyleType : getDefaultListStyleType();
				_style.listStyleImage = ( _listStyleImage ) ? _listStyleImage : getDefaultListStyleImage();
				_style.listStylePosition = ( _listStylePosition ) ? _listStylePosition : getDefaultListStylePosition();
				
				//	[KK]	Instantiate formatting
				_format = new TextLayoutFormat();
				
				// Move on to merge with shorthand property.
				if( _listStyle )
				{
					var shorthand:ListStyleShorthand;
					shorthand = ListStyleShorthandUtil.deserializeShorthand( _listStyle );
					if( !_listStyleType && shorthand.type ) _style.listStyleType = shorthand.type;
					if( !_listStyleImage && shorthand.image ) _style.listStyleImage = shorthand.image;
					if( !_listStylePosition && shorthand.position ) _style.listStylePosition = shorthand.position;
				}
			}
			return _style;
		}
		
		protected function getDefaultListStyleType():String
		{
			if( _mode == ListItemModeEnum.ORDERED )
				return ListStyleEnum.ORDERED_DECIMAL;
			else if( mode == ListItemModeEnum.UNORDERED )
				return ListStyleEnum.UNORDERED_DISC;
			
			return null;
		}
		
		protected function getDefaultListStyleImage():String
		{
			return null;
		}
		
		protected function getDefaultListStylePosition():String
		{
			return ListStyleEnum.POSITION_INSIDE;
		}
		
		/**
		 * Determines the value validity based on type. 
		 * @param value Object
		 * @return Boolean
		 */
		public function isUndefined( property:String ):Boolean
		{
			return ( this[property] ) ? false : true;
		}
		
		/**
		 * Sets the propety value to undefined based on type. 
		 * @param property String
		 */
		public function undefineStyleProperty( property:String ):void
		{
			this[property] = undefined;
		}
		
		public function setStyle( style:*, value:* ):void
		{
			try {
				_format[style.toString()] = value;
			} catch (e:*) {
				trace( '[KK] {' + getQualifiedClassName(this) + '} :: Couldn\'t set style: ' + style + ' with value ' + value + '.' );
			}
		}
		public function getStyle( style:* ):*
		{
			try {
				return _format[style.toString()];
			} catch (e:*) {
				return null;
			}
			return null;
		}
		
		public function get listStyle():*
		{
			return _listStyle;
		}
		public function set listStyle( value:* ):void
		{
			if( _listStyle == value ) return;
			
			_listStyle = value;
			_isDirty = true;
		}
		
		public function get listStyleType():*
		{
			return _listStyleType;
		}
		public function set listStyleType( value:* ):void
		{
			if( _listStyleType == value ) return;
			
			_listStyleType = value;
			_isDirty = true;
		}
		
		public function get listStyleImage():*
		{
			return _listStyleImage;
		}
		public function set listStyleImage( value:* ):void
		{
			if( _listStyleImage == value ) return;
			
			_listStyleImage = value;
			_isDirty = true;
		}
		
		public function get listStylePosition():*
		{
			return _listStylePosition;
		}
		public function set listStylePosition( value:* ):void
		{
			if( _listStylePosition == value ) return;
			
			_listStylePosition
			_isDirty = true;
		}
		
		public function get mode():int
		{
			return _mode;
		}
		public function set mode( value:int ):void
		{
			if( _mode == value ) return;
			
			_mode = value;
			_isDirty = true;
		}
		
		/**
		 * Pretty printing. 
		 * @return String
		 */
		public function toString():String
		{
			return "======================\n" +
				"|| List Style\n" +
				"======================\n" +
				"listStyleType: " + _listStyleType + "\n" +
				"listStyleImage: " + _listStyleImage + "\n" +
				"listStylePosition: " + _listStylePosition;
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
				var propertyList:XMLList = describeType( ListStyle )..accessor;
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