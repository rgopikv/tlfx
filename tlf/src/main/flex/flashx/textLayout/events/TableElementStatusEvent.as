package flashx.textLayout.events
{
	import flash.events.Event;
	
	import flashx.textLayout.elements.table.TableElement;
	
	/**
	 * TableElementStatusEvent is an event object notifying clients of the status of a table element.
	 * This is dispatched through a TextFlow reference in TableElement 
	 * @author toddanderson
	 */
	public class TableElementStatusEvent extends Event
	{
		public var tableElement:TableElement;
		public static const INITIALIZED:String = "initialized";
		
		public function TableElementStatusEvent( type:String, tableElement:TableElement )
		{
		 	super( type );
			this.tableElement = tableElement;
		}
	}
}