package flashx.textLayout.events.table
{
	import flash.events.Event;
	
	/**
	 * TableCellContainerEvent is a generic event related to notifications from a TableCellContainer object. 
	 * @author toddanderson
	 */
	public class TableCellContainerEvent extends Event
	{
		public var cellHeight:Number;
		public var yOffset:Number;
		public static const CELL_RESIZE:String = "cellResize";
		
		/**
		 * Constructor.
		 *  
		 * @param type String The event type.
		 * @param cellHeight Number The target cell container height.
		 * @param yOffset Number The offset of any operations that invoke the dispatching of this event.
		 */
		public function TableCellContainerEvent( type:String, cellHeight:Number, yOffset:Number )
		{
			super( type );
			this.cellHeight = cellHeight;
			this.yOffset = yOffset;
		}
		
		/**
		 * @inherit
		 */
		override public function clone():Event
		{
			return new TableCellContainerEvent( this.type, this.cellHeight, this.yOffset );
		}
	}
}