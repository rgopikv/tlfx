package flashx.textLayout.model.attribute
{
	import flash.utils.ByteArray;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import flashx.textLayout.formats.TextLayoutFormat;
	
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
		/**
		 * Flat list of attributes to be used in for... loops accessing property on this dynamic instance.
		 */
		protected var flatList:Array; 
		
		/**
		 * Constructor.
		 */
		public function Attribute() {}
		
		/**
		 * Override to store dynamic style in key/value pair 
		 * @param name * The key.
		 * @param value * The value to associate with key.
		 */
		override flash_proxy function setProperty(name:*, value:*):void
		{
			attributes[name] = ( isNaN( value ) ) ? value : Number( value );
		}
		
		/**
		 * Override to return value paired with key. 
		 * @param name * The key.
		 * @return * The associated value.
		 */
		override flash_proxy function getProperty(name:*):*
		{
			return attributes[name];
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
		public function hasProperty( property:String ):Boolean
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
		 * Applies any propetty values to a TextLayoutFormat that relate to an element attribute. 
		 * @param format TextLayoutFormat
		 */
		public function applyAttributesToFormat( format:TextLayoutFormat ):void
		{
			// abstract
		}
		
		/**
		 * Cleans attribute map if default values held for property.
		 */
		public function getStrippedAttributes():Object
		{
			// abstract
			return null;
		}
		
		public function isUndefined( property:String ):Boolean
		{
			var filled:Boolean = hasProperty( property );
			var nonDefaultProperties:Object = getStrippedAttributes();
			var propertyValueIsNotDefault:Boolean = ( nonDefaultProperties[property] != null );
			return !filled && !propertyValueIsNotDefault;
		}
	}
}