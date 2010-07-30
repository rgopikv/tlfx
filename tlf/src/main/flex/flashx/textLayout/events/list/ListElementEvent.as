package flashx.textLayout.events.list
{
	import flash.events.Event;
	
	import flashx.textLayout.elements.list.ListElementX;
	import flashx.textLayout.elements.list.ListItemBaseElement;
	import flashx.textLayout.elements.list.ListItemElementX;
	
	public class ListElementEvent extends Event
	{
		public var listItem:ListItemBaseElement;
		public var list:ListElementX;
		
		public static const ITEM_ADDED:String = "itemAdded";
		public static const ITEM_REMOVED:String = "itemRemoved";
		public static const UPDATE:String = "update";
		public static const MODE_CHANGED:String = "modeChanged";
		
		public function ListElementEvent( type:String, listItem:ListItemBaseElement, list:ListElementX )
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