package flashx.textLayout.edit.helpers
{
	import flashx.textLayout.edit.ExtendedEditManager;
	import flashx.textLayout.edit.IEditManager;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.ListElement;
	import flashx.textLayout.elements.ListItemElement;
	import flashx.textLayout.elements.ParagraphElement;
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
				try {
					from.removeChildAt( startingAt + i );
				} catch ( e:* ) {
					trace('Couldn\'t remove child at ' + int(startingAt + i) + ' from ' + from);
				}
				i--;
			}
		}
		
		public static function processDeleteKey( tf:TextFlow ):void
		{
			/*
			KK
			This needs to be fixed.
			The endIndex being received doesn't always match up with what it should be, causing in deletion of extra items.
			*/
			
			var editManager:IEditManager = tf.interactionManager as IEditManager;
			var selectionState:SelectionState = editManager.getSelectionState();
			
			var startElem:FlowLeafElement = tf.findLeaf( editManager.absoluteStart );
			var endElem:FlowLeafElement = tf.findLeaf( editManager.absoluteEnd );
			
			var startItem:ListItemElement = startElem.getParentByType( ListItemElement ) as ListItemElement;
			var endItem:ListItemElement = endElem.getParentByType( ListItemElement ) as ListItemElement;
			
			var startList:ListElement = startItem ? startItem.getParentByType( ListElement ) as ListElement : null;
			var endList:ListElement = endItem ? endItem.getParentByType( ListElement ) as ListElement : null;
			
			var lists:Array = SelectionHelper.getSelectedLists( tf );
			var listItems:Array = [];
			
			for ( var i:int = 0; i < lists.length; i++ )
			{
				listItems = listItems.concat( ListHelper.getSelectedListItemsInList( lists[i] as ListElement, selectionState ) );
			}
			
			//	Make sure list exists
			if ( startList )
			{
				//	Make sure there is a start item
				if ( startItem )
				{
					var startIndex:int = startList.getChildIndex( startItem );
					var startText:String = startItem.text;
					var startRel:int = editManager.absoluteStart - startItem.span.getElementRelativeStart( tf ) - startItem.seperatorLength;
					
					//	Make sure there is an end item
					if ( endItem )
					{
						var endIndex:int = endList.getChildIndex( endItem );
						var endText:String = endItem.text;
						var endRel:int = editManager.absoluteEnd - endItem.span.getElementRelativeStart( tf ) - endItem.seperatorLength;
						
						// At least 1 whole character selected
						if ( editManager.isRangeSelection() )
						{
							//	Multiline selection
							if ( startItem != endItem )
							{
								if ( endList )
								{
									//	Multiple lists selected
									if ( startList != endList )
									{
										//	TODO:	Fix
										//		ListElements can be held by things OTHER than the TextFlow, meaning that the following will not work
										
										//	Get indexes of lists in order to determine how many lists should be edited
										var startListIndex:int = tf.getChildIndex( startList );
										var endListIndex:int = tf.getChildIndex( endList );
										
										var j:int = 0;
										for ( i = startListIndex; i <= endListIndex; i++ )
										{
											//	If same as start, start at first selected item
											if ( i == startListIndex )
											{
												for ( j = startIndex; j < startList.numListElements; j++ )
												{
													startList.removeChildAt(j);
												}
												//ListItemElementEnterHelper.deleteItems( startList, startIndex, (startList.numChildren-1)-startIndex );
											}
											//	If same as end, end at last selected item
											else if ( i == endListIndex )
											{
												for ( j = 0; j <= endIndex; j++ )
													endList.removeChildAt(j);
												//ListItemElementEnterHelper.deleteItems( endList, 0, endIndex );
											}
											//	Delete all others
											else
											{
												tf.removeChild( tf.getChildAt(i) );
											}
										}
									}
									//	Single list selected
									else
									{
										for ( i = 1; i < listItems.length; i++ )
										{
											( listItems[i] as ListItemElement ).parent.removeChild( listItems[i] as ListItemElement );
										}
									}
								}
								else
								{
									//	Should never happen, error prevention
									if ( endIndex >= startList.numChildren )
									{
										ListItemElementEnterHelper.deleteItems( startList, startIndex, (startList.numChildren-1)-startIndex );
									}
									else
									{
										ListItemElementEnterHelper.deleteItems( startList, startIndex, endIndex-startIndex );
									}
								}
//								ListItemElementEnterHelper.deleteItems( list, startIndex, endIndex-startIndex );
								startItem.text = startText.substring(0, startRel) + endText.substring(endRel, endText.length);
							}
							//	Single line selection
							else
							{
								editManager.deleteText( new SelectionState( tf, editManager.absoluteStart, editManager.absoluteEnd, tf.format ) );
								startItem.text = startText.substring(0, startRel) + endText.substring(endRel, endText.length);
							}
						}
						//	Single point of contact
						else
						{
							//	Backspace 1 char
							editManager.deletePreviousCharacter( new SelectionState( tf, editManager.absoluteStart, editManager.absoluteEnd, tf.format ) );
						}
					}
					//	Just a start item
					else
					{
						if ( editManager.isRangeSelection() )
						{
							editManager.deleteText( new SelectionState( tf, editManager.absoluteStart, editManager.absoluteEnd, tf.format ) );
							startItem.text = startText.substring(0, startRel);
						}
						else
						{
							editManager.deletePreviousCharacter( new SelectionState( tf, editManager.absoluteStart, editManager.absoluteEnd, tf.format ) );
						}
					}
				}
			}	
		}
		
		public static function processReturnKey( extendedEditManager:ExtendedEditManager, startItem:ListItemElement ):void
		{
			var endElem:FlowElement = extendedEditManager.textFlow.findLeaf( extendedEditManager.absoluteEnd );
			var endItem:ListItemElement = endElem.getParentByType( ListItemElement ) as ListItemElement;
			
			if ( startItem.getParentByType( ListElement ) )
			{
				var list:ListElement = startItem.getParentByType( ListElement ) as ListElement;
				
				//	Keep track of initial text values
				var startText:String = startItem.text;
				var endText:String = endItem ? endItem.text : '';
				
				//	Find the relative start and end positions of the absoluteStart and absoluteEnd positions
				var relStart:int = extendedEditManager.absoluteStart - startItem.span.getElementRelativeStart( extendedEditManager.textFlow ) - startItem.seperatorLength;
				var relEnd:int = extendedEditManager.absoluteEnd - endItem.span.getElementRelativeStart( extendedEditManager.textFlow ) - endItem.seperatorLength;
				
				//	Child indexes
				var startIndex:int = list.getChildIndex(startItem);
				var endIndex:int = list.getChildIndex(endItem);
				
				//	Instantiate new list item element
				var newListItem:ListItemElement = new ListItemElement();
				newListItem.mode = startItem.mode;
				newListItem.paragraphStartIndent = startItem.paragraphStartIndent;
				
				//	If there is an actual selection
				if ( extendedEditManager.isRangeSelection() )
				{
					//	Multiple lines
					if ( endItem && startItem != endItem )
					{
						//	Change start item's text to be 0 - start of selection
						startItem.text = startText.substring(0, relStart);
						//	Delete all items UP TO the end of selection INCLUDING the item containing the selection
						ListItemElementEnterHelper.deleteItems(list, startIndex, endIndex-startIndex);
						//	Set the text of the new item to be end of selection - end of end text
						newListItem.text = endText.substring(relEnd, endText.length);
						//	Add new child after start item
						list.addChildAt(startIndex+1, newListItem);
					}
					//	Single line
					else
					{
						startItem.text = startText.substring(0, relStart);
						newListItem.text = endText.substring(relEnd, endText.length);
						list.addChildAt( startIndex+1, newListItem );
					}
				}
				//	No selection, just single anchor / active position
				else
				{
					startItem.text = startText.substring(0, relStart);
					newListItem.text = endText.substring(relEnd, endText.length);
					list.addChildAt( startIndex+1, newListItem );
				}
				
				var anchorPos:int = newListItem.span.getElementRelativeStart( extendedEditManager.textFlow ) + newListItem.span.text.length;
				
				extendedEditManager.setSelectionState( new SelectionState( extendedEditManager.textFlow, anchorPos, anchorPos, extendedEditManager.textFlow.format ) );
			}
		}
	}
}