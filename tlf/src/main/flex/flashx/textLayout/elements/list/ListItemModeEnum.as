package flashx.textLayout.elements.list
{
	/**
	 * An enumeration of list states.
	 *  
	 * @author dominickaccattato
	 * 
	 */
	public class ListItemModeEnum
	{
		public static const INIT:int = 0;		// used to represent when content is initialized
		public static const UNDEFINED:int = 1;	// un-bullet/number the list
		public static const ORDERED:int = 2;	// number the list
		public static const UNORDERED:int = 3;	// bullet the list
	}
}