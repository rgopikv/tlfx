package flashx.textLayout.edit
{
	import flash.accessibility.Accessibility;
	import flash.desktop.ClipboardFormats;
	import flash.display.BlendMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TextEvent;
	import flash.ui.Keyboard;
	
	import flashx.textLayout.container.AutosizableContainerController;
	import flashx.textLayout.container.TableCellContainerController;
	import flashx.textLayout.container.table.ICellContainer;
	import flashx.textLayout.container.table.TableDisplayContainer;
	import flashx.textLayout.conversion.ConversionType;
	import flashx.textLayout.conversion.TextConverter;
	import flashx.textLayout.converter.IHTMLExporter;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.edit.helpers.ListHelper;
	import flashx.textLayout.edit.helpers.ListItemElementEnterHelper;
	import flashx.textLayout.edit.helpers.SelectionHelper;
	import flashx.textLayout.elements.BreakElement;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.InlineGraphicElement;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.ListElement;
	import flashx.textLayout.elements.ListItemElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.list.ListElementX;
	import flashx.textLayout.elements.list.ListItemElementX;
	import flashx.textLayout.elements.list.ListPaddingElement;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.operations.CutOperation;
	import flashx.textLayout.operations.ExtendedCopyOperation;
	import flashx.textLayout.operations.PasteOperation;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.TextLayoutFormatUtils;
	import flashx.undo.IUndoManager;
	
	use namespace tlf_internal;
	
	public class ExtendedEditManager extends EditManager
	{
		protected var _htmlImporter:IHTMLImporter;
		protected var _htmlExporter:IHTMLExporter;
		protected var _extendedClipboard:ExtendedTextClipboard;
		
		public function ExtendedEditManager( htmlImporter:IHTMLImporter, htmlExporter:IHTMLExporter, undoManager:IUndoManager=null)
		{
			super(undoManager);
			_htmlImporter = htmlImporter;
			_htmlExporter = htmlExporter;
			_extendedClipboard = new ExtendedTextClipboard( _htmlImporter, _htmlExporter );
		}
		
		private function getLastIndentedListItem( start:ListItemElementX, ignore:ListItemElementX = null ):ListItemElementX
		{
			var list:ListElementX = start.parent as ListElementX;
			
			if ( list )
			{
				for ( var i:int = list.getChildIndex(start)-1; i > -1; i-- )
				{
					var item:ListItemElementX = list.getChildAt(i) as ListItemElementX;
					if ( item && item.indent < start.indent && item != ignore )
						return item;
				}
			}
			return null;
		}
		
		override public function keyDownHandler(event:KeyboardEvent):void
		{
			var items:Array = SelectionHelper.getSelectedListItems( textFlow, true );
			var lists:Array = SelectionHelper.getSelectedLists( textFlow );
			
			var startItem:ListItemElementX;
			var endItem:ListItemElementX;
			
			var endElement:FlowElement;
			
			var p:ParagraphElement;
			
			var item:ListItemElementX;
			var prevItem:ListItemElementX;
			var nextItem:ListItemElementX;
			
			var nextElement:FlowElement;
			
			var list:ListElementX;
			var endList:ListElementX;
			
			var start:int;
			var end:int;
			
			var i:int;
			var j:int;
			
			var tl:int;
			
			var transferItems:Vector.<ListItemElementX> = new Vector.<ListItemElementX>();
			var transferChildren:Vector.<FlowElement> = new Vector.<FlowElement>();
			
			switch ( event.keyCode )
			{
				case Keyboard.TAB:
					if ( items.length > 0 )
					{
						for each ( item in items )
						{
							list = item.parent as ListElementX;
							
							//	Get the item with the previous indent (if possible)
							prevItem = getLastIndentedListItem(item);
							
							if ( event.shiftKey )
							{
								//	Update children with > indent
								for ( i = list.getChildIndex(item)+1; i < list.numChildren; i++ )
								{
									startItem = list.getChildAt(i) as ListItemElementX;
									if ( startItem )
									{
										if ( startItem.indent > item.indent )
										{
											endItem = getLastIndentedListItem(startItem, item);
											if ( endItem && endItem.mode != startItem.mode && Math.max(0, startItem.indent-24) <= endItem.indent )
												startItem.mode = endItem.mode;
											startItem.indent = Math.max(0, startItem.indent-24);
										}
										else
											break;
									}
									else
										break;
								}
								
								if ( prevItem )
								{
									//	Only change mode if prevItem.mode differs and if the change will make it the same (or less [SHOULD NEVER HAPPEN]) indent as prevItem
									if ( prevItem.mode != item.mode && Math.max(0, item.indent-24) <= prevItem.indent )
										item.mode = prevItem.mode;
									item.indent = Math.max(0, item.indent-24);
								}
								else
									item.indent = Math.max(0, item.indent-24);
							}
							else
							{
								//	Update children with > indent
								for ( i = list.getChildIndex(item)+1; i < list.numChildren; i++ )
								{
									startItem = list.getChildAt(i) as ListItemElementX;
									if ( startItem )
									{
										if ( startItem.indent > item.indent )
											startItem.indent = Math.min(240, startItem.indent+24);
										else
											break;
									}
									else
										break;
								}
								
								item.indent = Math.min(240, item.indent+24);
							}
						}
						
						for each ( list in lists )
							list.update();
						
						textFlow.flowComposer.updateAllControllers();
						return;
					}
					else
					{
						super.keyDownHandler(event);
						return;
					}
					break;
				case Keyboard.ENTER:
					if ( items.length > 0 )
					{
						startItem = items[0] as ListItemElementX;
						endItem = items[items.length-1] as ListItemElementX;
						
						list = startItem.parent as ListElementX;
						endList = endItem.parent as ListElementX;
						
						start = list.getChildIndex(startItem)+1;
						end = endList.getChildIndex(endItem);
						
						var newItem:ListItemElementX;
						
						var first:ListItemElementX;
						var last:ListItemElementX;
						
						if ( startItem.modifiedTextLength == 0 )
						{
							for ( i = 0; i < list.numChildren; i++ )
							{
								if ( list.getChildAt(i) is ListItemElementX )
								{
									first = list.getChildAt(i) as ListItemElementX;
									break;
								}
							}
							
							for ( i = list.numChildren-1; i > -1; i-- )
							{
								if ( list.getChildAt(i) is ListItemElementX )
								{
									last = list.getChildAt(i) as ListItemElementX;
									break;
								}
							}
							
							p = new ParagraphElement();
							
							if ( startItem == first )
								list.parent.addChildAt( list.parent.getChildIndex(list), p );
							else if ( startItem == last )
								list.parent.addChildAt( list.parent.getChildIndex(list)+1, p );
							else
							{
								start = list.getChildIndex(startItem);
								
								endList = new ListElementX();
								list.parent.addChildAt( list.parent.getChildIndex(list)+1, endList );
								
								list.parent.addChildAt( list.parent.getChildIndex(list)+1, p );
								
								for ( i = list.numChildren-1; i > start; i-- )
								{
									if ( list.getChildAt(i) is ListItemElementX )
										endList.addChildAt( 0, list.removeChildAt(i) );
								}
								
								endList.update();
							}
							
							list.removeChild(startItem);
							list.update();
							
							//	Set selection state to beginning in order to prevent a TLF bug which caused nothing after the (now) split list(s) to be selectable
							
							setSelectionState( new SelectionState( textFlow, 0, 0 ) );
							
							//	update after every set selection in order to force a refresh for the same TLF bug
							
							textFlow.flowComposer.updateAllControllers()
							
							setSelectionState( new SelectionState( textFlow, p.getAbsoluteStart(), p.getAbsoluteStart() ) );
							
							textFlow.flowComposer.updateAllControllers()
							
							return;
						}
						
						
						//	Single list
						if ( list == endList )
						{
							//	Multiline
							if ( startItem != endItem )
							{
								deleteText( new SelectionState( textFlow, absoluteStart, absoluteEnd ) );
								
								//	AbsoluteStart is cursor position, subtract from that the startItem's actual start (start of text)
								//	Then add on the length of the seperator span (usually 3 or 4, depending on mode)
								newItem = startItem.splitAtPosition( absoluteStart-startItem.actualStart+startItem.seperatorLength ) as ListItemElementX;
								newItem.mode = startItem.mode;
								newItem.indent = startItem.indent;
								newItem.correctChildren();
							}
							//	Single line
							else
							{
								deleteText( new SelectionState( textFlow, absoluteStart, absoluteEnd ) );
								
								//	AbsoluteStart is cursor position, subtract from that the startItem's actual start (start of text)
								//	Then add on the length of the seperator span (usually 3 or 4, depending on mode)
								newItem = startItem.splitAtPosition( absoluteStart-startItem.actualStart+startItem.seperatorLength ) as ListItemElementX;
								newItem.mode = startItem.mode;
								newItem.indent = startItem.indent;
								newItem.correctChildren();
							}
							
							list.update();
							
							setSelectionState( new SelectionState( textFlow, newItem.actualStart+newItem.text.length-1, newItem.actualStart+newItem.text.length-1 ) );
							
							textFlow.flowComposer.updateAllControllers();
						}
						//	Multiple lists
						else
						{
							//	Delete text between lists
							deleteText( new SelectionState( textFlow, list.getAbsoluteStart() + list.textLength, endList.getAbsoluteStart() ) );
							
							//	Handle removing / reseting items
							for ( i = items.length-1; i > -1; i-- )
							{
								item = items[i];
								
								//	Reset text (start)
								if ( i == 0 )
								{
									deleteText( new SelectionState( textFlow, absoluteStart, item.actualStart + item.text.length ) );
								}
								//	Reset text (end)
								else if ( i == items.length-1 )
								{
									deleteText( new SelectionState( textFlow, item.actualStart, absoluteEnd ) );
								}
								//	Delete
								else
								{
									item.parent.removeChild(item);
								}
							}
							
							//	Children to shift from endList to list
							var children:Vector.<ListItemElementX> = new Vector.<ListItemElementX>();
							
							for ( i = endList.numChildren-2; i > 0; i-- )
								children.push( endList.removeChildAt(i) as ListItemElementX );
							
							//	New child from hitting enter
							newItem = new ListItemElementX();
							newItem.mode = startItem.mode;
							newItem.indent = startItem.indent;
							children.push( newItem );
							
							children.reverse();
							
							var lastItem:ListItemElementX = list.getChildAt(list.numChildren-2) as ListItemElementX;
							var firstItem:ListItemElementX = children[0];
							
							var increaseIndent:Boolean = lastItem.mode != firstItem.mode;
							
							for ( i = 0; i < children.length; i++ )
							{
								if ( increaseIndent )
									children[i].indent += 24;
								list.addChild( children[i] );
							}
							
							list.update();
							
							notifyInsertOrDelete( list.getAbsoluteStart(), list.textLength );
							
							var selPoint:uint = Math.min( newItem.actualStart+newItem.text.length-1, textFlow.textLength-1 );
							setSelectionState( new SelectionState( textFlow, selPoint, selPoint ) );
						}
					}
					else
					{
						super.keyDownHandler(event);
						return;
					}
					break;
				case Keyboard.BACKSPACE:
					if ( items.length > 0 )
					{
						startItem = items[0] as ListItemElementX;
						list = startItem.parent as ListElementX;
						
						var copiedChildren:Array = list.mxmlChildren.slice();
						
						start = list.getChildIndex( startItem );
						
						//	Single point of contact
						if ( absoluteStart == absoluteEnd )
						{
							//	At start
							if ( absoluteStart <= startItem.actualStart )
							{
								//	If element before starting list is a ListElementX, join
								var prevElement:FlowElement = list.parent.getChildAt( list.parent.getChildIndex(list)-1 );
								if ( prevElement )
								{
									if ( prevElement is ListElementX )
									{
										endList = prevElement as ListElementX;
										
										var addAt:int;
										
										//	Get index to add items from bottom list to top list
										for ( i = endList.numChildren-1; i > -1; i-- )
										{
											if ( endList.getChildAt(i) is ListItemElementX )
											{
												addAt = i+1;
												break;
											}
										}
										
										//	Merge lists
										for ( i = list.numChildren-1; i > -1; i-- )
										{
											if ( list.getChildAt(i) is ListItemElementX )
												endList.addChildAt( addAt ? addAt : endList.numChildren, list.removeChildAt(i) as ListItemElementX );
										}
										
										list.parent.removeChild( list );
										
										item = endList.getChildAt(addAt-1) as ListItemElementX;
										setSelectionState( new SelectionState( textFlow, item.actualStart + item.modifiedTextLength, item.actualStart + item.modifiedTextLength ) );0
										textFlow.flowComposer.updateAllControllers();
										return;
									}
								}
								
								//	Add new list after current list
								var newList:ListElementX = new ListElementX();
								list.parent.addChildAt( list.parent.getChildIndex(list)+1, newList );
								
								//	Switch all children AFTER the start child to the new list
								for ( i = list.numChildren-1; i > start; i-- )
								{
									if ( list.getChildAt(i) is ListItemElementX )
										newList.addChildAt(0, list.removeChildAt(i));
								}
								
								newList.update();
								
								//	Add new paragraph right after current list
								p = new ParagraphElement();
								list.parent.addChildAt( list.parent.getChildIndex(list)+1, p );
								
								//	Transfer children
								extractChildrenToParagraphElement( startItem, p );
								
								//	Remove original child
								startItem.parent.removeChild(startItem);
								
								cleanEmptyLists( textFlow );
							}
							//	No text
							else if ( startItem.text.length == 0 )
							{
								if ( start-1 < 0 )
								{
									i = 0;
									while ( i++ < list.numChildren )
									{
										if ( list.getChildAt(i) is ListItemElementX )
										{
											prevItem = list.getChildAt(i) as ListItemElementX;
											break;
										}
									}
									setSelectionState( new SelectionState( textFlow, prevItem.actualStart, prevItem.actualStart ));
								}
								else
								{
									//	Convoluted logic to get the item that the selection should jump to.
									//	Let me explain...
									//	Attempt to get the item at the NEW start position (start of original selection child index -1)
									prevItem = list.getChildAt(start-1) as ListItemElementX;
									
									//	If null (or not a ListItemElementX)
									if ( !prevItem )
									{
										//	Set i to be the NEW start position
										i = start-1;
										
										//	i is 0
										if ( i == 0 )
										{
											//	Check to see if item at index 0 is ListItemElementX
											if ( list.getChildAt(0) is ListItemElementX )
												prevItem = list.getChildAt(0) as ListItemElementX;
											else
											{
												//	Go through all children to get the FIRST instance of a ListItemElementX
												while ( i++ < list.numChildren )
												{
													if ( list.getChildAt(i) is ListItemElementX )
													{
														prevItem = list.getChildAt(i) as ListItemElementX;
														break;
													}
												}
											}
										}
										//	i is NOT 0
										else
										{
											var iclone:int = i;
											
											//	Starting at i, peruse backwards through all children looking for the first (if any) ListItemElementX it can find
											while ( i-- > -1)
											{
												if ( list.getChildAt(i) is ListItemElementX )
												{
													prevItem = list.getChildAt(i) as ListItemElementX;
													break;
												}
											}
											
											//	In case it didn't find any
											//	e.g. start at 1 go down to 0 and still no list item remains
											//	This shouldn't happen, but it has been put here as error prevention
											if ( !prevItem )
											{
												//	Start at original position of i (original selection child index -1) and progress to find the fist instance of ListItemElementX
												while ( iclone++ < list.numChildren )
												{
													if ( list.getChildAt(iclone) is ListItemElementX )
													{
														prevItem = list.getChildAt(iclone) as ListItemElementX;
														break;
													}
												}
											}
										}
									}
									
									var cameBefore:Boolean = (list.getChildIndex(prevItem) < start);
									
									list.removeChildAt(start);
									list.update();
									textFlow.flowComposer.updateAllControllers();
									
									//												 -1 because it's returning start of list denoter + it's text length
									tl = cameBefore ? prevItem.text.length : -1;
									
									setSelectionState( new SelectionState( textFlow, prevItem.actualStart + tl, prevItem.actualStart + tl ) );
								}
							}
							else
							{
								super.keyDownHandler(event);
								return;
							}
						}
						//	Selection
						else
						{
							//	Get the offset of the start of the item from the start of the selection
							start = startItem.actualStart - absoluteStart;
							
							deleteText( getSelectionState() );
							
							tl = 1;
							
							//	If >= 0 it means they've selected all the way to the beginning OR are selecting inside the list denoter
							if ( start >= 0 )
							{
								//	Make sure it still exists
								if ( startItem && startItem.parent == list )
								{
									tl += startItem.seperatorLength;
									list.removeChild( startItem );
								}
							}
							
							cleanEmptyLists( textFlow );
							
							for each ( list in lists )
							{
								if ( list )
									list.update();
							}
							
							setSelectionState( new SelectionState( textFlow, absoluteStart-tl, absoluteStart-tl ) );
						}
					}
					else
					{
						var fg1:FlowGroupElement = textFlow.findLeaf( absoluteStart ).parent;
						var fg2:FlowGroupElement = textFlow.findLeaf( absoluteStart - 1 ).parent;
						var ss:SelectionState;
						
						try {
							if ( fg1 is ListPaddingElement )
							{
								list = fg1.parent as ListElementX;
								
								if ( fg2 is ListItemElementX )
								{
									item = fg2 as ListItemElementX;
									ss = new SelectionState( textFlow, item.actualStart + item.modifiedTextLength+1, item.actualStart + item.modifiedTextLength+1 );
								}
								else
									ss = new SelectionState( textFlow, fg2.getAbsoluteStart() + fg2.textLength-1, fg2.getAbsoluteStart() + fg2.textLength-1 );
								
								setSelectionState( ss );
							}
							
							super.keyDownHandler(event);
						} catch ( e:* ) {
							//	ParagraphElements won't backspace into Lists
							//	Left fix open for the chance that other things may do the same
							
							if ( fg1 is ParagraphElement )
							{
								p = fg1 as ParagraphElement;
								if ( fg2 && fg2 is ListPaddingElement )
								{
									list = fg2.parent as ListElementX;
									
									var pTextLength:int = 0;
									
									for ( i = p.numChildren-1; i > -1; i-- )
									{
										nextElement = p.getChildAt(i);
										if ( nextElement is SpanElement )
											pTextLength += Math.max( 0, (nextElement as SpanElement).text.match( /[^\n\s\t\u2028\u2029]/ig ).length );
										else if ( nextElement is LinkElement )	//	Suffices for ExtendedLinkElement as well
										{
											for ( j = (nextElement as LinkElement).numChildren-1; j > -1; j-- )
											{
												var el:FlowElement = (nextElement as LinkElement).getChildAt(j);
												if ( el is SpanElement )
													pTextLength += Math.max( 0, (el as SpanElement).text.match( /[^\n\s\t\u2028\u2029]/ig ).length );
												else if ( el is InlineGraphicElement )
													pTextLength++;
											}
										}
										else if ( nextElement is InlineGraphicElement )
											pTextLength++;
										else if ( nextElement )
											pTextLength++;
									}
									
									for ( i = list.numChildren-1; i > -1; i-- )
									{
										if ( list.getChildAt(i) is ListItemElementX )
										{
											item = list.getChildAt(i) as ListItemElementX;
											break;
										}
									}
									
									if ( item )
										ss = new SelectionState( textFlow, item.actualStart + item.modifiedTextLength + 1, item.actualStart + item.modifiedTextLength + 1 );
									
									if ( pTextLength != 0 )
									{
										j = item.numChildren-1;
										
										for ( i = p.numChildren-1; i > -1; i-- )
											item.addChildAt( j, p.removeChildAt(i) );
									}
									
									p.parent.removeChild(p);
									
									if ( ss )
										setSelectionState( ss );
									
									textFlow.flowComposer.updateAllControllers();
									return;
								}
							}
						}
						return;
					}
					break;
				case Keyboard.DELETE:
					if ( items.length > 0 )
					{
						startItem = items[0] as ListItemElementX;
						list = startItem.parent as ListElementX;
						
						start = list.getChildIndex(startItem);
						
						//	Single point of contact
						if ( absoluteStart == absoluteEnd )
						{
							//	End of line reached
							if ( startItem.textLength == startItem.seperatorLength )
							{
								//	Remove current item
								list.removeChildAt(start);
								list.update();
								
								//	Set startItem to null for future use
								startItem = null;
								
								//	Get the item that the selection should jump to
								if ( list.numChildren > 0 )
								{
									//	If there are still list items
									if ( list.listItems.length > 0 )
									{
										tl = 0;
										if ( list.getChildAt(start) is ListItemElementX )
										{
											tl = -1;
											startItem = list.getChildAt(start) as ListItemElementX;
										}
										else
										{
											//	Go down the line trying to find a list item to be the starting item
											for ( i = start-1; i > -1; i-- )
											{
												if ( list.getChildAt(i) is ListItemElementX )
												{
													tl = -1;
													startItem = list.getChildAt(i) as ListItemElementX;
													break;
												}
											}
											
											if ( !startItem )
											{
												for ( i = start+1; i < list.numChildren; i++ )
												{
													if ( list.getChildAt(i) is ListItemElementX )
													{
														tl = 1;
														startItem = list.getChildAt(i) as ListItemElementX;
														break;
													}
												}
											}
										}
										
										if ( startItem )
										{
											//	If startItem came before - set selection to end of it
											if ( tl < 0 )
												setSelectionState( new SelectionState( textFlow, startItem.actualStart + startItem.text.length, startItem.actualStart + startItem.text.length ) );
											//	If startItem came after - set selection to beginning of it
											else if ( tl > 0 )
												setSelectionState( new SelectionState( textFlow, startItem.actualStart, startItem.actualStart ) );
											else
												trace("Not setting selection point!");
										}
										else
										{
											//	Should never happen because the list's listItems number > 0
											throw new Error("Could not find an adequate list item to reset the selection to.");
										}
									}
									else
										list.parent.removeChild(list);
								}
								else
									list.parent.removeChild(list);
							}
							//	Deleting from end of line
							else if ( absoluteStart == startItem.getAbsoluteStart() + startItem.textLength - 1 )
							{
								//	Find next item to merge with
								for ( i = start+1; i < list.numChildren; i++ )
								{
									if ( list.getChildAt(i) is ListItemElementX )
									{
										nextItem = list.getChildAt(i) as ListItemElementX;
										break;
									}
								}
								
								//	Was last item, head outside of ListElement to get next item to merge
								if ( !nextItem )
								{
									nextElement = getFirstItemAbleToMergeWithListItemElement( list.parent, list.parent.getChildIndex(list)+1 );
									
									extractChildrenToListItemElement( nextElement as FlowGroupElement, startItem );
									
									nextElement.parent.removeChild(nextElement);
								}
								//	Was not last item, merge with next item
								else
								{
									extractChildrenToListItemElement( nextItem, startItem );
									
									nextItem.parent.removeChild(nextItem);
								}
								
								list.update();
							}
							else
							{
								super.keyDownHandler(event);
								return;
							}
						}
						//	Selection
						else
						{
							endElement = textFlow.findLeaf( absoluteEnd ).getParagraph();
							start = (endElement as ParagraphElement).getChildIndex( textFlow.findLeaf( absoluteEnd ) );
							end = endElement.getAbsoluteStart();
							
							nextElement = textFlow.findLeaf( absoluteStart );
							
							if ( nextElement is SpanElement )
								(nextElement as SpanElement).text = (nextElement as SpanElement).text.substring(0, absoluteStart-nextElement.getAbsoluteStart());
							
							if ( textFlow.findLeaf( absoluteEnd ) is SpanElement )
								(textFlow.findLeaf( absoluteEnd ) as SpanElement).text = (textFlow.findLeaf( absoluteEnd ) as SpanElement).text.substring(absoluteEnd-end); 
							
							extractChildrenToListItemElement( endElement as ParagraphElement, startItem );
							
							deleteText( new SelectionState( textFlow, list.getAbsoluteStart() + list.textLength, endElement.getAbsoluteStart() ) );
							
							endElement.parent.removeChild( endElement );
						}
					}
					else
					{
						super.keyDownHandler(event);
						return;
					}
					
					cleanEmptyLists( textFlow );
					
					for each ( list in lists )
					{
						if ( list )
							list.update();
					}
					break;
				default:
					super.keyDownHandler( event );
					return;
					break;
			}
			
			setSelectionState( new SelectionState( textFlow, absoluteStart, absoluteStart, textFlow.format ) );
			textFlow.flowComposer.updateAllControllers();
		}
		
		private function extractChildrenToParagraphElement( from:FlowGroupElement, to:ParagraphElement ):void
		{
			var end:int = from is ListItemElementX ? 0 : -1;
			var addAt:int = Math.max(to.numChildren-1, 0);
			for ( var i:int = from.numChildren-1; i > end; i-- )
			{
				var child:FlowElement = from.removeChildAt(i);
				
				//	TODO: Fix the transfer of styles.
				//				//	Make sure that the child retains it's inherited styling
				//				var format:TextLayoutFormat = new TextLayoutFormat( from.computedFormat );
				//				format.apply( child.format );
				//				child.format = format;
				
				to.addChildAt( addAt, child );
			}
		}
		
		private function extractChildrenToListItemElement( from:FlowGroupElement, to:ListItemElementX ):void
		{
			var end:int = from is ListItemElementX ? 0 : -1;
			var addAt:int = Math.max(to.numChildren-1, 0);
			for ( var i:int = from.numChildren-1; i > end; i-- )
			{
				var child:FlowElement = from.removeChildAt(i);
				
				//	Make sure that the child retains it's inherited styling
				var format:TextLayoutFormat = new TextLayoutFormat( from.computedFormat );
				format.apply( new TextLayoutFormat( child.format ? child.format : null ) );
				child.format = format;
				
				to.addChildAt( addAt, child );
			}
		}
		
		private function getFirstItemAbleToMergeWithListItemElement( from:FlowGroupElement, startAt:uint = 0 ):*
		{
			for ( var i:uint = startAt; i < from.numChildren; i++ )
			{
				var child:FlowElement = from.getChildAt(i);
				
				if ( child is ListItemElementX )
					return child as ListItemElementX;
				else if ( child is ParagraphElement )
					return child as ParagraphElement;
				else if ( child is ListElementX )
					return getFirstItemAbleToMergeWithListItemElement( child as ListElementX );
				else if ( child is DivElement )
					return getFirstItemAbleToMergeWithListItemElement( child as DivElement );
			}
		}
		
		private function cleanEmptyLists( el:FlowGroupElement ):void
		{
			for ( var i:int = el.numChildren-1; i > -1; i-- )
			{
				var child:FlowElement = el.getChildAt(i);
				
				if ( child is ListElementX )
				{
					var list:ListElementX = child as ListElementX;
					if ( list.listItems.length == 0 )
						el.removeChildAt(i);
				}
				else if ( child is DivElement )
					cleanEmptyLists( child as DivElement );
			}
		}
		
		private function cleanParagraphs( element:FlowGroupElement ):void
		{
			var j:int = 0;
			var cc:FlowElement;
			var cs:SpanElement;
			for ( var i:int = 0; i < element.numChildren; i++ )
			{
				var child:FlowElement = element.getChildAt(i);
				
				//	Don't search ListElements or ListItemElements
				if ( child is DivElement )
					cleanParagraphs( child as DivElement );
				else if ( child is ParagraphElement )
				{
					var separator:SpanElement;
					if ( child is ListPaddingElement )
					{
						continue;
					}
					else if ( child is ListItemElementX )
						continue;
					else
					{
						//						var p:ParagraphElement = child as ParagraphElement;
						//						for ( j = p.numChildren-1; j > -1; j-- )
						//						{
						//							cc = p.getChildAt(j);
						//							if ( cc is SpanElement )
						//							{
						//								cs = cc as SpanElement;
						//								if ( cs.text.indexOf('\n') > -1 )
						//									p.removeChildAt(j);
						//								else
						//									trace( 'p won\'t delete:', cs.text );
						//							}
						//						}
					}
				}
			}
		}
		
		override public function pasteTextScrap(scrapToPaste:TextScrap, operationState:SelectionState = null):void
		{
			operationState = defaultOperationState(operationState);
			if (!operationState)
				return;
			
			var mark:int = operationState.anchorPosition;
			var flowElement:FlowElement = textFlow.findLeaf( mark );
			var cell:ICellContainer;
			// cycle through hiearchy to find if we are pasting into a TableElement.
			while( flowElement )
			{
				if( flowElement is TableElement )
					break;
				flowElement = flowElement.parent;
			}
			// If we have found that we are tyring to paste into a TableElement, find the corresponding cell at the position.
			if( flowElement is TableElement )
			{
				cell = ( flowElement as TableElement ).getCellAtPosition( mark );
			}
			
			// If we have our cell, fire a TablePasteOperation.
			if( cell != null )
			{
				var data:String = TextClipboard.getTextOnClipboardForFormat(ClipboardFormats.TEXT_FORMAT );
				data = data.replace( /[\r\n]/g, TableElement.LINE_BREAK_IDENTIFIER );
				// Update contents of clipboard with cleaned strings.
				var flow:TextFlow = TextConverter.importToFlow( data, TextConverter.PLAIN_TEXT_FORMAT );
				var tlf:String = TextConverter.export( flow, TextConverter.TEXT_LAYOUT_FORMAT, ConversionType.STRING_TYPE ).toString();
				TextClipboard.tlf_internal::setClipboardContents( tlf, data );
				scrapToPaste = TextClipboard.getContents();
			}
			doOperation(new PasteOperation(operationState, scrapToPaste));
		}

		public function get htmlImporter():IHTMLImporter
		{
			return _htmlImporter;
		}

	}
}