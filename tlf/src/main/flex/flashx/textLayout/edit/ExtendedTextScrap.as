package flashx.textLayout.edit
{
	import flashx.textLayout.edit.helpers.SelectionHelper;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.list.ListElementX;
	import flashx.textLayout.elements.list.ListItemElementX;
	import flashx.textLayout.tlf_internal;

	public class ExtendedTextScrap
	{
		private static function getTextFlowDeepCopy( textFlow:TextFlow, absoluteStart:int, absoluteEnd:int ):TextFlow
		{
			use namespace tlf_internal;
			var tf:TextFlow = textFlow.deepCopy( absoluteStart, absoluteEnd ) as TextFlow;
			tf.normalize();
			return tf;
		}
		
		private static function isParentListItem( element:FlowElement ):Boolean
		{
			var parent:FlowElement = element.parent;
			while( parent != null )
			{
				if( parent is ListItemElementX ) return true;
				parent = parent.parent;
			}
			return false;
		}
		
		private static function assembleScrapForSelectedListItems( textFlow:TextFlow, newTextFlow:TextFlow, absoluteStart:int, absoluteEnd:int ):TextScrap
		{
			use namespace tlf_internal;
			if (newTextFlow.textLength > 0)
			{
				var scrap:TextScrap = new TextScrap( newTextFlow );
				var srcElem:FlowElement = textFlow.findLeaf( absoluteStart );
				var copyElem:FlowElement = newTextFlow.getFirstLeaf();
				while (copyElem && srcElem)
				{
					if ((absoluteStart - srcElem.getAbsoluteStart()) > 0)
					{
						// Limit beginning to to only the list item and not a flow of its children.
						if( !ExtendedTextScrap.isParentListItem( copyElem ) )
						{
							copyElem.original = ( copyElem is SpanElement ) ? true : copyElem.original;
							scrap.addToBeginMissing(copyElem);
						}
					}
					
					// Because of the way items are insert from a TextScrp on paste, we need to cut off at the list level so it is inserted correct.
					if( copyElem.parent is ListElementX ) break;
					copyElem = copyElem.parent;
					srcElem = srcElem.parent;
				}
				
				srcElem = textFlow.findLeaf(absoluteEnd - 1);
				copyElem = newTextFlow.getLastLeaf();
				if ((copyElem is SpanElement) && (!(srcElem is SpanElement)))
				{
					copyElem = newTextFlow.findLeaf(newTextFlow.textLength - 2);
				}
				
				while (copyElem && srcElem)
				{
					if (absoluteEnd < (srcElem.getAbsoluteStart() + srcElem.textLength))
					{
						// Limit beginning to to only the list item and not a flow of its children.
						if( !ExtendedTextScrap.isParentListItem( copyElem ) )
						{
							copyElem.original = ( copyElem is SpanElement ) ? true : copyElem.original;
							scrap.addToEndMissing(copyElem);
						}
					}
					// Because of the way items are insert from a TextScrp on paste, we need to cut off at the list level so it is inserted correct.
					if( copyElem.parent is ListElementX ) break;
					copyElem = copyElem.parent;
					srcElem = srcElem.parent;
				}
				return scrap;
			}
			return null;	
		}
		
		private static function assembleScrapForSelectedListContent( textFlow:TextFlow, newTextFlow:TextFlow, absoluteStart:int, absoluteEnd:int ):TextScrap
		{
			use namespace tlf_internal;
			if (newTextFlow.textLength > 0)
			{
				var listContent:Array = ( newTextFlow.getFirstLeaf().parent as ListItemElementX ).nonListRelatedContent;
				newTextFlow.mxmlChildren = listContent;
				newTextFlow.normalize();
				var scrap:TextScrap = new TextScrap( newTextFlow );
				
				var srcElem:FlowElement = textFlow.findLeaf(absoluteStart);
				var copyElem:FlowElement = newTextFlow.getFirstLeaf();
				while (copyElem && srcElem)
				{
					if ((absoluteStart - srcElem.getAbsoluteStart()) > 0)
					{
						copyElem.original = true;// ( copyElem is SpanElement ) ? true : copyElem.original;
						scrap.addToBeginMissing(copyElem);
					}
					copyElem = copyElem.parent;
					srcElem = srcElem.parent;
				}
				
				srcElem = textFlow.findLeaf(absoluteEnd - 1);
				copyElem = newTextFlow.getLastLeaf();
				if ((copyElem is SpanElement) && (!(srcElem is SpanElement)))
				{
					copyElem = newTextFlow.findLeaf(newTextFlow.textLength - 2);
				}
				
				while (copyElem && srcElem)
				{
					if (absoluteEnd < (srcElem.getAbsoluteStart() + srcElem.textLength))
					{
						copyElem.original = true;//( copyElem is SpanElement ) ? true : copyElem.original;
						scrap.addToEndMissing(copyElem);
					}
					copyElem = copyElem.parent;
					srcElem = srcElem.parent;
				}
				
				return scrap;
			}
			return null;
		}
		
		public static function createExtendedTextScrap( textFlow:TextFlow, selectionState:SelectionState ):TextScrap
		{
			var scrap:TextScrap;
			// TODO: If we have selected in a list, we need to create the Scrap customly.
			var selectedListItems:Array = SelectionHelper.getSelectedListItems( textFlow );
			var selectedLists:Array = SelectionHelper.getSelectedLists( textFlow );
			var isSelectionInList:Boolean = selectedListItems.length > 0;
			if( isSelectionInList )
			{
				var newTextFlow:TextFlow;
				newTextFlow = ExtendedTextScrap.getTextFlowDeepCopy( textFlow, selectionState.absoluteStart, selectionState.absoluteEnd );
				// If we are in just a single list item.
				if( selectedListItems.length == 1 )
				{
					// Check if we have selected the whole thing.
					//	If so we are placing the list item onto the clipboard.
					var fullySelectedListItems:Array = SelectionHelper.cachedListItems;
					if( selectedListItems.length == fullySelectedListItems.length )
					{
						scrap = ExtendedTextScrap.assembleScrapForSelectedListItems( textFlow, newTextFlow, selectionState.absoluteStart, selectionState.absoluteEnd );
					}
						// Else we are only placing the selected content on the clipboard.
					else
					{
						var selectedItem:ListItemElementX = selectedListItems[0];
						scrap = ExtendedTextScrap.assembleScrapForSelectedListContent( textFlow, newTextFlow, selectionState.absoluteStart, selectionState.absoluteEnd );
					} 
				}
					// Else if we have copied within a single list with multiple items.
				else
				{
					scrap = ExtendedTextScrap.assembleScrapForSelectedListItems( textFlow, newTextFlow, selectionState.absoluteStart, selectionState.absoluteEnd );
				}
			}
				// Go about using default logic.
			else
			{
				scrap = TextScrap.createTextScrap( selectionState );		
			}
			return scrap;
		}
	}
}