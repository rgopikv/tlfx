package flashx.textLayout.events.list
{
	import flash.events.Event;
	
	import flashx.textLayout.elements.list.ListElementX;
	import flashx.textLayout.elements.list.ListItemElementX;
	
	public class ListElementEvent extends Event
	{
		public var listItem:ListItemElementX;
		public var list:ListElementX;
		
		public static const ITEM_ADDED:String = "itemAdded";
		public static const ITEM_REMOVED:String = "itemRemoved";
		public static const UPDATE:String = "update";
		
		public function ListElementEvent( type:String, listItem:ListItemElementX, list:ListElementX )
		{
			super( type );
			this.list = list;
			this.listItem = listItem;
		}
		
		override public function clone():Event
		{
			return new ListElementEvent( type, listItem, list );
		}
	}
}