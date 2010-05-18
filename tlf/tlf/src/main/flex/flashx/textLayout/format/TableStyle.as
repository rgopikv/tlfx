package flashx.textLayout.format
{
	import flash.utils.Dictionary;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	/**
	 * TableStyle is a dynamic proxy class that exposes generic methods to access styles related to a Table object. 
	 * @author toddanderson
	 */
	dynamic public class TableStyle extends Proxy implements IStyle
	{
		private var map:Dictionary;
		
		/**
		 * Constructor.
		 */
		public function TableStyle() 
		{ 
			super(); 
			map = new Dictionary( true );
		}
		
		/**
		 * Override to store dynamic style in key/value pair 
		 * @param name * The key.
		 * @param value * The value to associate with key.
		 */
		override flash_proxy function setProperty(name:*, value:*):void
		{
			map[name] = ( isNaN( value ) ) ? value : Number( value );
		}
		
		/**
		 * Override to return value paired with key. 
		 * @param name * The key.
		 * @return * The associated value.
		 */
		override flash_proxy function getProperty(name:*):*
		{
			return map[name];
		}
		
		public function deserializeAttribute( styleAttribute:String ):void
		{
			// TODO: Regex for parsing style attribute.
		}
		
		public function serializeAttribute():String
		{
			return null;
		}
		
		public function getStrippedStyles():Array
		{
			return [];
		}
	}
}