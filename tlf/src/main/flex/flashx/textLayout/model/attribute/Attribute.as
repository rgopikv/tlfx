package flashx.textLayout.model.attribute
{
	import flash.utils.ByteArray;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.utils.DimensionTokenUtil;
	
	/**
	 * Attribute is a class repesentation of a base map of attributes associated with an HTML element. 
	 * @author toddanderson
	 */
	dynamic public class Attribute extends Proxy implements IAttribute
	{
		/**
		 * Dynamic map to hold attributes. 
		 */
		protected var attributes:Object;
		
		protected var defaultAttributes:Object;
		protected var _defaultedAttribute:IAttribute;
		
		protected var _formattableAttribute:IAttribute;
		
		protected var _dimensionAttributeList:Array;
		
		/**
		 * Flat list of attributes to be used in for... loops accessing property on this dynamic instance.
		 */
		protected var flatList:Array; 
		
		/**
		 * Constructor.
		 */
		public function Attribute() 
		{
			attributes = {};
			defaultAttributes = getDefault();
			_dimensionAttributeList = getDimensionAttributes();
		}
		
		protected function getDefault():Object
		{
			// abstract.
			return {};
		}
		
		protected function getDimensionAttributes():Array
		{
			// abstract.
			return [];
		}
		
		/**
		 * Override to store dynamic style in key/value pair 
		 * @param name * The key.
		 * @param value * The value to associate with key.
		 */
		override flash_proxy function setProperty(name:*, value:*):void
		{
			var propertyName:String = ( name is QName ) ? ( name as QName ).localName : name;
			attributes[propertyName] = ( isNaN( value ) ) ? value : Number( value );
		}
		
		/**
		 * Override to return value paired with key. 
		 * @param name * The key.
		 * @return * The associated value.
		 */
		override flash_proxy function getProperty(name:*):*
		{
			var propertyName:String = ( name is QName ) ? ( name as QName ).localName : name;
			var value:*;
			
			if( isUndefined( propertyName ) )
				value = defaultAttributes[propertyName];
			else 
				value = attributes[propertyName];
			
			return value;
		}
		
		override flash_proxy function deleteProperty(name:*):Boolean
		{
			var propertyName:String = ( name is QName ) ? ( name as QName ).localName : name;
			delete attributes[propertyName];
			return true;
		}
		
		/**
		 * Override to return item from the flat list of attributes. 
		 * @param index int
		 * @return int
		 */
		override flash_proxy function nextNameIndex( index:int ):int 
		{
			// initial call
			if( index == 0 ) 
			{
				flatList = new Array();
				
				var property:String;
				for( property in attributes ) 
				{
					flatList.push(property);
				}
			}
			
			if( index < flatList.length ) 
			{
				return index + 1;
			} 
			else 
			{
				return 0;
			}
		}
		
		/**
		 * Override to return name of property from flat list of attributes. 
		 * @param index int
		 * @return String
		 */
		override flash_proxy function nextName( index:int ):String 
		{
			return flatList[index - 1];
		}
		
		/**
		 * Returns flag of holding property value. 
		 * @param property String
		 * @return Boolean
		 */
		public function hasAttributeProperty( property:String ):Boolean
		{
			return attributes[property] != null;
		}
		
		/**
		 * Sets new values on attributes based on supplied values. 
		 * @param atts Object Key/value pairs.
		 */
		public function modifyAttributes( atts:Object ):void
		{
			var property:String;
			for( property in atts )
			{
				attributes[property] = atts[property];
			}
		}
		/**
		 * Cones and returns an object. 
		 * @param object Object
		 * @return Object
		 */
		public static function clone( object:Object ):Object
		{
			var copy:ByteArray = new ByteArray();
			copy.writeObject( object );
			copy.position = 0;
			return copy.readObject();
		}
		
		/**
		 * Cleans attribute map if default values held for property.
		 */
		public function getDefinedAttributes():IAttribute
		{
			var attribute:IAttribute = new Attribute();
			var property:String;
			for( property in attributes )
			{
				attribute[property] = attributes[property];
			}
			return attribute;
		}
		
		public function getDefaultAttributes():IAttribute
		{
			if( _defaultedAttribute == null )
			{
				var attribute:IAttribute = new Attribute();
				var property:String;
				for( property in defaultAttributes )
				{
					attribute[property] = defaultAttributes[property];
				}
				_defaultedAttribute = attribute;
			}
			return _defaultedAttribute;
		}
		
		public function getFormattableAttributes():IAttribute
		{
			// abstract.
			return _formattableAttribute;
		}
		
		public function isUndefined( property:String ):Boolean
		{
			return !hasAttributeProperty( property );
		}
	}
}