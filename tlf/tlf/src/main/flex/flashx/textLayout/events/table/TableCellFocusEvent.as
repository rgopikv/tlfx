package flashx.textLayout.events.table
{
	import flash.events.Event;
	
	import flashx.textLayout.container.ContainerController;
	
	/**
	 * The TableCellFocusEvent is a specified event related to any focus given to a specified TableCellContainer. 
	 * @author toddanderson
	 */
	public class TableCellFocusEvent extends Event
	{
		public var controller:ContainerController;
		public static const REQUEST_FOCUS:String = "requestFocus";
		
		/**
		 * Constructor.
		 *  
		 * @param controller ContainerController The target container controller instance for the issuing Table Cell.
		 */
		public function TableCellFocusEvent( controller:ContainerController )
		{
			super( TableCellFocusEvent.REQUEST_FOCUS );
			this.controller = controller;
		}
		
		/**
		 * @inherit
		 */
		override public function clone():Event
		{
			return new TableCellFocusEvent( this.controller );
		}
	}
}