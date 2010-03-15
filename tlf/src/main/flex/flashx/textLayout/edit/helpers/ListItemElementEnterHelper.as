package flashx.textLayout.edit.helpers
{
	import flashx.textLayout.edit.ExtendedEditManager;
	import flashx.textLayout.edit.IEditManager;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.ListElement;
	import flashx.textLayout.elements.ListItemElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	
	public class ListItemElementEnterHelper
	{
		public function ListItemElementEnterHelper()
		{
			//
		}
		
		private static function deleteItems( from:ListElement, startingAt:uint, number:uint ):void
		{
			var i:int = number;
			while( i > 0 )
			{
				from.removeChildAt( startingAt + i );
				i--;
			}
		}
		
		public static function processDeleteKey( tf:TextFlow ):void
		{
			/*var list:ListElement;
			var startIndex:int = extendedEditManager.textFlow.getChildIndex( startElement );
			var endIndex:int = extendedEditManager.textFlow.getChildIndex( endElement );
			var startPos:int = startElement.getElementRelativeStart( extendedEditManager.textFlow );
			var endPos:int = endElement.getElementRelativeStart( extendedEditManager.textFlow );
			
			var startIndexRelative:int;
			var endIndexRelative:int;
			
			var startPosRelative:int;
			var endPosRelative:int;
			
			var startItem:ListItemElement;
			var endItem:ListItemElement;
			
			var startText:String;
			var endText:String;
			
			var newSelectionState:SelectionState;*/
			
			var selection:SelectionState = IEditManager(tf.interactionManager).getSelectionState();
			
			var selectedLists:Array = ListHelper.getSelectedListElements(tf);
			
			for each (var list:ListElement in selectedLists)
			{
				trace("Checking a ListElement");
				
				var selectedItems:Array = ListHelper.getSelectedListItemsInList(list, selection);
				
				// if the selection doesn't contain any chars...
				if (selection.absoluteStart == selection.absoluteEnd)
				{						
					var li:ListItemElement = ListItemElement(selectedItems[0]);
					
					// Check if we're ahead of the first character of raw text - after the bullet.
					// If so just delete as normal.
					if (selection.absoluteStart > li.getAbsoluteStart() + 2)
					{
						IEditManager(tf.interactionManager).deletePreviousCharacter();
					}
					// Otherwise we need to remove the whole list item.
					else
					{
						list.removeChild(li);

						// If that was the only item in the list then
						// get rid of the whole list, too.
						// Otherwise just update to ensure the numbers match etc.
						if (list.numListElements > 0)
						{
							list.updateList();
						}
						else
						{
							list.parent.removeChild(list);
						}
					}
				}
				else
				{					
					// If the whole list (including all items in sub-lists)
					// is contained within the selection we can just get rid of the list.
					if (ListHelper.isEveryItemInListCompletelySelected(tf, list))
					{
						list.parent.removeChild(list);
					}/*
					// Otherwise we need to look at the list items.
					else
					{
						trace("removing individual list items");
						// Check if all the item has been selected.
						for each (var item:ListItemElement in selectedItems)
						{							
							trace("Checking a ListItemElement");
							// If it has then delete the whole item from it's list.
							if (ListHelper.isListItemCompletelySelected(selection, item))
							{
								trace("list item is completely selected - removing it entirely");
								item.list.removeChild(item);
							}
							// Otherwise just remove the selected text.
							else
							{		
								var deleteSelection:SelectionState;
								var deleteStart:int;
								var deleteEnd:int;
								
								if (item.getAbsoluteStart() + 2 > selection.absoluteStart)
								{
									trace("Start with the item start");	
									deleteStart = item.getAbsoluteStart();
								}
								else
								{
									trace("start with the selection start");
									deleteStart = selection.absoluteStart;
								}
								
								if (item.getAbsoluteStart() + item.textLength < selection.absoluteEnd)
								{
									deleteEnd = item.getAbsoluteStart() + item.textLength;
								}
								else
								{
									deleteEnd = selection.absoluteEnd;
								}
								
								deleteSelection = new SelectionState(tf, deleteStart, deleteEnd);
								IEditManager(tf.interactionManager).deleteText(deleteSelection);
							}
						}
					}*/
				}
				//tf.flowComposer.updateAllControllers();
				//tf.interactionManager.setSelectionState(new SelectionState(tf, selection.absoluteStart, selection.absoluteStart));
			}
			
			//	Delete up to the absolute start position
			/*if ( startElement.parent is ListItemElement )
			{
				var endSelectedText:String;
				startItem = startElement.parent as ListItemElement;
				list = startItem.list;
				startIndexRelative = list.getChildIndex( startItem );
				startPosRelative = startItem.getElementRelativeStart( list );
				if ( endElement.parent is ListItemElement )
				{
					endItem = endElement.parent as ListItemElement;
					endIndexRelative = list.getChildIndex( endItem );
					endPosRelative = endItem.getElementRelativeStart( list );
					
					endSelectedText = endItem.text.substr(0, extendedEditManager.absoluteEnd - endPos);
					
					//	create new selection state & use the edit manager to delete the text, as it creates far less hassle
					newSelectionState = new SelectionState( extendedEditManager.textFlow, extendedEditManager.absoluteStart, endPos + endSelectedText.length, extendedEditManager.textFlow.format );
					extendedEditManager.deleteText( newSelectionState );
					
					//	force an update to fix the #'s
//					list.update();
				}
				else
				{
					endSelectedText = endElement.text.substr(0, extendedEditManager.absoluteEnd - endPos);	//	correct
					
					var offset:int = list.mode == ListElement.UNORDERED ? 4 : 5;
					var newStartText:String = startItem.rawText.substr(0, extendedEditManager.absoluteStart-startPos-offset);	//	works
					startItem.text = newStartText;
					
					
					
					newSelectionState = new SelectionState( extendedEditManager.textFlow, extendedEditManager.absoluteStart, endPos + endSelectedText.length - 1, extendedEditManager.textFlow.format );
					extendedEditManager.deleteText( newSelectionState );
					
//					list.update();
				}
			}
			//	Delete down to the position previous the beginning of the list item,
			//	Delete all list items between 
			else if ( endElement.parent is ListItemElement )
			{
				//	Impossible that they're both ListItemElements
				//	Delete everything before
				//	Normal delete for ListItemElements
				trace("Hello");
			}
			else
			{
				trace('Why was this called? That doesn\'t make any sense!');
			}*/
		}
		
		public static function processReturnKey( extendedEditManager:ExtendedEditManager, startItem:ListItemElement ):void
		{
			var endElem:FlowElement = extendedEditManager.textFlow.findLeaf( extendedEditManager.absoluteEnd );
			var endItem:ListItemElement = endElem is ListItemElement ? endElem as ListItemElement : null;
			
			if ( startItem.parent )
			{
				var list:ListElement = startItem.parent as ListElement;
				
				var startTextPosition:uint = startItem.getElementRelativeStart( extendedEditManager.textFlow );
				//	End position based on either the ListItem or FlowLeafElement representation of the item at the end of the selection
				var endTextPosition:uint =	endItem ?
					endItem.getElementRelativeStart( extendedEditManager.textFlow )
					:
					endElem.getElementRelativeStart( extendedEditManager.textFlow );
				
				var startRel:uint = extendedEditManager.absoluteStart - startTextPosition;	//	absolute start minus item's start provides offset
				var endRel:uint = extendedEditManager.absoluteEnd - endTextPosition;		//	absolute end minus item's end
				
				var adjustOffset:uint = startItem.mode == ListElement.UNORDERED ? 3 : 4;
				
				startRel -= adjustOffset;
				endRel -= adjustOffset;
				
				var newStr:String = '';
				
				var startText:String = startItem.rawText;
				var endText:String = new String();
				
				if ( endItem )
				{
					endText = endItem.rawText;
				}
				else
				{
					if ( endElem is SpanElement )
					{
						endText = ( endElem as SpanElement ).text
					}
					else if ( endElem is LinkElement )
					{
						endText = ( endElem as LinkElement ).href;
					}
					
					//	can't do ParagraphElements or DivElements as they have no text
				}
				
				var startPos:int = list.getChildIndex( startItem );
				var endPos:int = list.getChildIndex( endItem ? endItem : endElem );
				
				var newElement:ListItemElement = new ListItemElement();
				newElement.paragraphStartIndent = startItem.paragraphStartIndent;
				var strStart:int = startRel;
				
				//	At least 1 whole character is selected (i.e. end of selection != start of selection)
				if ( extendedEditManager.isRangeSelection() )
				{
					//	Multiple lines
					if ( startItem != endElem )
					{
						var numToDelete:int;
						//	All ListItemElements
						if ( endItem )
						{
							startItem.text = startText.substring( 0, startRel-1 );
							
							ListItemElementEnterHelper.deleteItems( list, startPos, (endPos - startPos) );
							
							endItem.text = startText.substring( 0, startRel-1 );
							
							newStr = endText.substring( endRel, endText.length );
						}
						//	Multiple types
						else
						{
							//	Reset the text for the items beyond the list elements
							var newSelectionState:SelectionState = new SelectionState( extendedEditManager.textFlow, extendedEditManager.absoluteStart, extendedEditManager.absoluteEnd, extendedEditManager.textFlow.format);
							extendedEditManager.deleteText( newSelectionState );
							
							//	Reset the starting element's text
							startItem.text = startText.substring( 0, startRel-1 );
						}
					}
					//	Single line
					else
					{
						startItem.text = startText.substring( 0, startRel );
						
						newStr = endText.substring( endRel, endText.length );
					}
				}
				//	No selection
				else
				{
					var currChar:String = extendedEditManager.textFlow.getText( extendedEditManager.absoluteStart, extendedEditManager.absoluteEnd + 1 );
					var prevChar:String = extendedEditManager.textFlow.getText( extendedEditManager.absoluteStart - 1, extendedEditManager.absoluteEnd );
					
					// TODO: Still need to strip whitespace from the start of newElement.text.
					// Currently, if a new list item is created by breaking a previous list element
					// after a space the new line item starts with a space. 
					var strEnd:int = startRel;
					
					if ( currChar == ' ' )
					{
						strStart = strEnd = startRel + 1;
					}
					else
					{
						if ( prevChar == ' ' ) 
						{
							if (startRel > startText.length)
							{
								strStart = strEnd = 0;
							}
						}
						else
						{
							strStart = strEnd = startRel + 1;
						}
					}

					startItem.text = startText.substring( 0, strEnd );
				}
				
				newElement.text = startText.substring( strStart, startText.length );
				
				//	Last child
				if ( startPos == list.numChildren-1 )
				{
					list.addChild( newElement );
				}
				else
				{
					list.addChildAt( startPos+1, newElement );
				}
				
				extendedEditManager.notifyInsertOrDelete( extendedEditManager.absoluteStart, extendedEditManager.absoluteEnd-extendedEditManager.absoluteStart );
				
				var newAnchorPosition:int = newElement.getElementRelativeStart( extendedEditManager.textFlow ) + newElement.text.length;
				extendedEditManager.setSelectionState( new SelectionState( extendedEditManager.textFlow, newAnchorPosition, newAnchorPosition, extendedEditManager.textFlow.format ) );
				
				extendedEditManager.textFlow.flowComposer.updateAllControllers();
			}
		}
	}
}