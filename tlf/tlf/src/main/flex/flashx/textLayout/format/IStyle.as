package flashx.textLayout.format
{
	/**
	 * IStyle is currently a placeholder to assign and retrieve style infomration from an HTML element tag. 
	 * @author toddanderson
	 */
	public interface IStyle
	{
		/**
		 * Converts current styles into valid style attribute for HTML. 
		 * @return String
		 */
		function serializeAttribute():String;
		/**
		 * Converts attribute value for style into properties.  
		 * @param styleAttribute String
		 */
		function deserializeAttribute( styleAttribute:String ):void;
		/**
		 * Returns a list of style attributes that should be stripped from the element when applying @style attribute. 
		 * @return Array
		 */
		function getStrippedStyles():Array;
	}
}