package flashx.textLayout.utils
{
	/**
	 * FragmentAttributeUtil is a util class to handle attributes and fragments. 
	 * @author toddanderson
	 */
	public class FragmentAttributeUtil
	{
		/**
		 * Applies attributes to a node based on attribute key/value pairs. 
		 * @param fragment XML
		 * @param attributes Object
		 */
		static public function assignAttributes( node:XML, attributes:Object ):void
		{
			var property:String;
			for( property in attributes )
			{
				node["@" + property] = attributes[property];
			}
		}
		
		/**
		 * Removes all current attributes on the fragment and places only those specified in keepAttributes. 
		 * @param node XML
		 * @param keepAttributes Object
		 */
		static public function removeAttributesFromFragment( node:XML, keepAttributes:Object ):void
		{
			var atts:XMLList = node.@*;
			var i:int;
			for( i = 0; i < atts.length(); i++ )
			{
				delete node.@[atts[i].name()];
			}
			FragmentAttributeUtil.assignAttributes( node, keepAttributes );
		}
		
		/**
		 * Verifies that an attribute is available on the node. 
		 * @param node XML
		 * @param attributeName String
		 * @return Boolean
		 */
		static public function exists( node:XML, attributeName:String ):Boolean
		{
			var attribute:String = node["@" + attributeName];
			return attribute != null && attribute.length > 0;
		}
	}
}