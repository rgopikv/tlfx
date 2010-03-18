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
			var selection:SelectionState = IEditManager(tf.interactionManager).getSelectionState();
			
			var selectedLists:Array = ListHelper.getSelectedListElements(tf);
			var newSelection:SelectionState;
			
			var selectionStart:int = selection.absoluteStart;
			var selectionEnd:int = selection.absoluteEnd;
			
			for each (var list:ListElement in selectedLists)
			{				
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
						newSelection = new SelectionState(tf, li.getAbsoluteStart() - 1, li.getAbsoluteStart() - 1);
						tf.interactionManager.setSelectionState(newSelection);
						
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
					
					tf.flowComposer.updateAllControllers();
				}
				else
				{					
					
					
					// If the whole list (including all items in sub-lists)
					// is contained within the selection we can just get rid of the list.
					if (ListHelper.isEveryItemInListCompletelySelected(tf, list))
					{
						list.parent.removeChild(list);
					}
					// Otherwise we need to look at the list items.
					else
					{
						var item:ListItemElement;
						var completeItemsRemoved:int;
						var previousItem:ListItemElement;
						
						//trace("removing individual list items");
						// Check if all the item has been selected.
						// If it has get rid of it from the list and the selectedItems array.
						for (var i:int = 0; i < selectedItems.length; i++)
						{							
							item = ListItemElement(selectedItems[i]);
	
							// If it has then delete the whole item from it's list.
							if (ListHelper.isListItemCompletelySelected(selection, item))
							{
								//trace("list item is completely selected - removing it entirely");
								//newSelection = new SelectionState(tf, item.getAbsoluteStart() - 1, item.getAbsoluteStart() - 1);
								//tf.interactionManager.setSelectionState(newSelection);
								selectionEnd -= item.getText().length;
								item.list.removeChild(item);
								selectedItems.splice(i, 1);
								i--;
								selection = new SelectionState(tf, selectionStart, selectionEnd);
								tf.interactionManager.setSelectionState(selection);
								
								completeItemsRemoved++;
							}
						}
						
						for each (item in selectedItems)
						{	
							//trace("removing part of a list item");
							var deleteSelection:SelectionState;
							var deleteStart:int;
							var deleteEnd:int;
							var previousSelectionWidth:int;
							var nudge:int = item.mode == ListElement.ORDERED ? 3 : 2;
							
							var itemStart:int = item.getElementRelativeStart(tf);
							
							// If the entire selection is contained within a single list item...
							if (item.getAbsoluteStart() + 2 < selection.absoluteStart &&
								item.getAbsoluteStart() + item.textLength > selection.absoluteEnd)
							{
								//trace("removing the middle of a list item " + nudge);
								
								deleteStart = (selection.absoluteStart - itemStart) - nudge;
								deleteEnd = (selection.absoluteEnd - itemStart) - nudge;
								
								var first:String = item.rawText.substr(0, deleteStart);
								var last:String = item.rawText.substr(deleteEnd, (item.getAbsoluteStart() + item.textLength) - itemStart);

								item.text = first + last;
							}
							// Otherwise the selection either starts or ends in this list item...
							else
							{
								if (item.getAbsoluteStart() + nudge > selection.absoluteStart)
								{
									//trace("Start with the selection end " + selection.absoluteEnd + " " + selectionEnd + " " + itemStart + " " + nudge + " " + previousSelectionWidth);	

									deleteStart = ((selectionEnd - itemStart) - nudge) - completeItemsRemoved;
								}
								else
								{
									//trace("start with the item start");
									deleteStart = 0;
								}

								if ((item.getAbsoluteStart() + item.textLength) + previousSelectionWidth < selection.absoluteEnd)
								{
									//trace("ending with the selection start");
									deleteEnd = (selection.absoluteStart - itemStart) - nudge;
								}
								else
								{									
									//trace("ending with the item end " + item.getText().length + " " + nudge);
									deleteEnd = item.textLength;
								}
								
								previousSelectionWidth = (item.getText().length - nudge) - deleteEnd;
								var newStr:String = item.rawText.substr(deleteStart, deleteEnd);
								
								//trace(deleteStart + " " + deleteEnd + " " + previousSelectionWidth + " == " + newStr);
								
								if (previousItem)
								{
									previousItem.text = previousItem.rawText + newStr;
									list.removeChild(item);
									list.updateList();
								}
								else
								{
									item.text = newStr;
									previousItem = item;
								}
								
								selectionEnd -= previousSelectionWidth;
							}
							
							tf.flowComposer.updateAllControllers();
						}	
					}
					
					newSelection = new SelectionState(tf, selection.absoluteStart, selection.absoluteStart);
					tf.interactionManager.setSelectionState(newSelection);
					tf.flowComposer.updateAllControllers();
				}
			}		
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