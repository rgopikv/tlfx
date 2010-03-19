package flashx.textLayout.edit.helpers
{
	import flashx.textLayout.edit.IEditManager;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.ListElement;
	import flashx.textLayout.elements.ListItemElement;
	import flashx.textLayout.elements.TextFlow;

	public class ListHelper
	{
		public static function getSelectedListElements(tf:TextFlow):Array 
		{
			// First pass gives us every ListElement. 
			var firstPass:Array = SelectionHelper.getSelectedLists(tf);
			
			var selectedLists:Array = [];
			
			var selectionState:SelectionState = IEditManager(TextFlow(tf).interactionManager).getSelectionState();
			
			// Now we need to filter for only those ListElements whose 
			// ListItemElements are within the SelectionState.
			for each (var list:ListElement in firstPass)
			{
				for each (var item:* in list.mxmlChildren)
				{
					if (item is ListItemElement)
					{
						var listItem:ListItemElement = ListItemElement(item);
						
						// If it's at least partially within the selection bounds then add it to the list.
						if ((listItem.getAbsoluteStart() + listItem.textLength) > selectionState.absoluteStart &&
							selectionState.absoluteEnd > listItem.getAbsoluteStart())
						{			
							selectedLists.push(list);
							break;
						}
					}
				}
			}
			
			return selectedLists;
		}
		
		public static function getSelectedListItemElements(tf:TextFlow):Array 
		{
			// First pass gives us every ListElement. 
			var firstPass:Array = SelectionHelper.getSelectedLists(tf);
			
			var selectedListItems:Array = [];
			
			var selectionState:SelectionState = IEditManager(TextFlow(tf).interactionManager).getSelectionState();
			
			// Now we need to filter for only those ListElements whose 
			// ListItemElements are within the SelectionState.
			for each (var list:ListElement in firstPass)
			{
				selectedListItems = selectedListItems.concat(getSelectedListItemsInList(list, selectionState));
			}
			
			return selectedListItems;
		}
		
		public static function getSelectedListItemsInList(list:ListElement, selectionState:SelectionState):Array 
		{
			var selectedListItems:Array = [];
			
			for each (var item:* in list.mxmlChildren)
			{
				if (item is ListItemElement)
				{
					var listItem:ListItemElement = ListItemElement(item);
					
					// If it's at least partially within the selection bounds then add it to the list.
					if ((listItem.getAbsoluteStart() + listItem.textLength) > selectionState.absoluteStart &&
						selectionState.absoluteEnd > listItem.getAbsoluteStart())
					{			
						selectedListItems.push(listItem);
					}
				}
			}
			
			return selectedListItems;
		}
		
		public static function getListIndent(list:ListElement):int 
		{
			for (var i:int = 0; i < list.numChildren; i++)
			{
				var item:FlowElement = FlowElement(list.getChildAt(i));
				
				if (item is ListItemElement)
				{
					return item.paragraphStartIndent;
				}
			}
			
			return -1;
		}
		
		public static function isEveryItemInListCompletelySelected(tf:TextFlow, list:ListElement):Boolean 
		{			
			var selection:SelectionState = IEditManager(tf.interactionManager).getSelectionState();
						
			return (selection.absoluteStart < list.getAbsoluteStart()) && (selection.absoluteEnd > list.getAbsoluteStart() + list.textLength);
		}
		
		public static function isListItemCompletelySelected(selection:SelectionState, listItem:ListItemElement):Boolean 
		{
			var nudge:int = (listItem.mode == ListElement.ORDERED) ? 3 : 2;
			var selectionStart:int = selection.absoluteStart;
			var selectionEnd:int = selection.absoluteEnd;
			var itemStart:int = listItem.getAbsoluteStart() + nudge;
			var itemEnd:int = listItem.getAbsoluteStart() + listItem.textLength - 1;
			
			return (selectionStart <= itemStart) && (selectionEnd >= itemEnd);
		}
	}
}