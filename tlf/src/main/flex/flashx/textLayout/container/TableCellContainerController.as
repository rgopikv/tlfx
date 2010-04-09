package flashx.textLayout.container
{
	import flash.display.Sprite;
	
	import flashx.textLayout.elements.table.ITableElementManager;
	
	/**
	 * TableCellContainerController is a basic extension of ContainerController to enable type checking of related cell controller to a table.
	 * Cells for display of textual content form the TextFlow are added as the containers for this controller. 
	 * @author toddanderson
	 */
	public class TableCellContainerController extends ContainerController
	{
		private var _tableManager:ITableElementManager;
		
		/**
		 * Constructor. 
		 * @param container Sprite
		 * @param compositionWidth Number
		 * @param compositionHeight Number
		 */
		public function TableCellContainerController(container:Sprite, compositionWidth:Number=100, compositionHeight:Number=100)
		{
			super(container, compositionWidth, compositionHeight);
		}
		
		/**
		 * Accessor/Modifier for managing ITableElementManager implementation that manages te flow composers for a TableElement 
		 * @return ITableElementManager
		 */
		public function get tableManager():ITableElementManager
		{
			return _tableManager;
		}
		public function set tableManager( value:ITableElementManager ):void
		{
			_tableManager = value;
		}
	}
}