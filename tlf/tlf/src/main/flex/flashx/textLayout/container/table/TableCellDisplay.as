package flashx.textLayout.container.table
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	import flashx.textLayout.container.ISizableContainer;
	
	/**
	 * TableCellDisplay is a basic extension of Sprite used mainly for type checking when referencing containersw within a textflow. 
	 * @author toddanderson
	 */
	public class TableCellDisplay extends Sprite
	{
		/**
		 * displayContainer is a reference to the cell container that holds this display on its display list. 
		 */
		protected var _displayContainer:ICellContainer;
		/**
		 * Master is a reference to the master display on which this cell resides.
		 * Used mainly as a reference point to tie back ContainerController target displays to TableElement 
		 */
		public var master:DisplayObjectContainer;
		
		/**
		 * Constructor.
		 * @param ICellContainer Reference to the ICellContainer implementation that holds this instance on its display list.
		 */
		public function TableCellDisplay( displayContainer:ICellContainer ) 
		{
			_displayContainer = displayContainer;
		}
		
		/**
		 * Returns the cell container that holds this cell display in its display list. 
		 * @return ICellContainer
		 */
		public function getDisplayContainer():ICellContainer
		{
			return _displayContainer;
		}
	}
}