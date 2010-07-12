package flashx.textLayout.edit
{
	import flash.desktop.ClipboardFormats;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TextEvent;
	import flash.net.getClassByAlias;
	import flash.ui.Keyboard;
	import flash.utils.getQualifiedClassName;
	import flash.utils.setTimeout;
	
	import flashx.textLayout.container.table.ICellContainer;
	import flashx.textLayout.conversion.ConversionType;
	import flashx.textLayout.conversion.TextConverter;
	import flashx.textLayout.converter.IHTMLExporter;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.edit.helpers.SelectionHelper;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.InlineGraphicElement;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.ListItemElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.list.ListElementX;
	import flashx.textLayout.elements.list.ListItemElementX;
	import flashx.textLayout.elements.list.ListPaddingElement;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.operations.BackspaceOperation;
	import flashx.textLayout.operations.DummyOperation;
	import flashx.textLayout.operations.PasteOperation;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.ListUtil;
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
		
		override public function textInputHandler(event:TextEvent):void
		{
			var prevElement:FlowLeafElement = textFlow.findLeaf(absoluteStart-1);
			var startElement:FlowLeafElement = textFlow.findLeaf(absoluteStart);
			var startGroupElement:FlowGroupElement = startElement.parent;
			
			if ( startGroupElement is ListItemElementX )
			{
				var item:ListItemElementX = startGroupElement as ListItemElementX;
				if ( item.modifiedTextLength == 0 && event.text != '\n' && event.text != '\r' )
				{
					var s:SpanElement = new SpanElement();
					s.text = event.text;
					item.addChildAt(0,s);
					item.correctChildren();
					performDummyOperation(getSelectionState());
					
					setSelectionState( new SelectionState( textFlow, s.getAbsoluteStart()+1, s.getAbsoluteStart()+1 ) );
					updateAllControllers();
					return;
				}
				else if ( (absoluteStart-item.getAbsoluteStart()) <= item.seperatorLength )
				{
					if ( item.getChildAt(1) && item.getChildAt(1) is SpanElement && event.text != '\n' && event.text != '\r' )
					{
						(item.getChildAt(1) as SpanElement).text = event.text + (item.getChildAt(1) as SpanElement).text;
						
						setSelectionState( new SelectionState( textFlow, absoluteStart+1, absoluteStart+1 ) );
						
						textFlow.flowComposer.updateAllControllers();
					}
				}
				else
					super.textInputHandler(event);
			}
			else if ( prevElement is SpanElement && (prevElement as SpanElement).text == "¡™£¢∞§¶•ªº" )
			{
				(prevElement as SpanElement).text = "";
				textFlow.flowComposer.updateAllControllers();
				
				setSelectionState( new SelectionState( textFlow, prevElement.getAbsoluteStart(), prevElement.getAbsoluteStart() ) );
				refreshSelection();
				
				var evt:KeyboardEvent = new KeyboardEvent( KeyboardEvent.KEY_DOWN );
				evt.keyCode = Keyboard.DELETE;
				super.keyDownHandler( evt );
				return;
			}
			else
				super.textInputHandler(event);
		}
		
		override public function keyDownHandler(event:KeyboardEvent):void
		{
			var items:Array = SelectionHelper.getSelectedListItems( textFlow, true );
			var lists:Array = SelectionHelper.getSelectedLists( textFlow );
			
			var startItem:ListItemElementX;
			var endItem:ListItemElementX;
			
			var startElement:FlowElement;
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
			
			var deleteFrom:int;
			var deleteTo:int;
			
			var i:int;
			var j:int;
			
			var tl:int;
			
			var node:XML;
			
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
						
						var origSelectionState:SelectionState = getSelectionState();
						
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
							
							//	[FORMATING]
							//	[KK]	Apply inline styling from ListElementX to ParagraphElement
							node = _htmlExporter.getSimpleMarkupModelForElement(list);
							if ( node )
								_htmlImporter.importStyleHelper.assignInlineStyle( node, p );
							else
								trace('Error assigning inline styling #1');
							
							//	[KK]	Hack to appropriate all of ListElementX's formatting
							p.format = list.computedFormat ? TextLayoutFormat(list.computedFormat) : list.format ? TextLayoutFormat(list.format) : new TextLayoutFormat();
							if ( startItem == first )
								list.parent.addChildAt( list.parent.getChildIndex(list), p );
							else if ( startItem == last )
								list.parent.addChildAt( list.parent.getChildIndex(list)+1, p );
							else
							{
								start = list.getChildIndex(startItem);
								
								endList = new ListElementX();
								list.parent.addChildAt( list.parent.getChildIndex(list)+1, endList );
								
								//	[KK]	Still set from export above
								if ( node )
									_htmlImporter.importStyleHelper.assignInlineStyle( node, endList );
								else
									trace('Error assigning inline styling #2');
								
								//	[FORMATING]
								//	[KK]	Hack to appropriate all of ListElementX's formatting
								endList.format = list.computedFormat ? TextLayoutFormat(list.computedFormat) : list.format ? TextLayoutFormat(list.format) : new TextLayoutFormat();
								
								list.parent.addChildAt( list.parent.getChildIndex(list)+1, p );
								
								for ( i = list.numChildren-1; i > start; i-- )
								{
									if ( list.getChildAt(i) is ListItemElementX )
										endList.addChildAt( 0, list.removeChildAt(i) );
								}
								
								endList.update();
							}
							
							list.removeChild(startItem);
							
//							//	[KK]	¡¡¡ REMOVED because it causes an error !!! Do not put back in. The editor will not resize.
//							textFlow.flowComposer.updateAllControllers();
							
							// update the list
							list.update();
							
							// add a new paragraph directly below the list.  This is 
							// necessary, see BUG 1701
							var newPara:ParagraphElement = new ParagraphElement();
							var newSpan:SpanElement = new SpanElement();
							newSpan.text = "¡™£¢∞§¶•ªº";
							newPara.addChild(newSpan);
							var listIdx:int = textFlow.getChildIndex(list);
							textFlow.addChildAt(++listIdx, newPara);
							
							//	Set selection state to beginning in order to prevent a TLF bug which caused nothing after the (now) split list(s) to be selectable
							
							setSelectionState( new SelectionState( textFlow, 0, 0 ) );
							
							//	update after every set selection in order to force a refresh for the same TLF bug
							
							setSelectionState( new SelectionState( textFlow, p.getAbsoluteStart(), p.getAbsoluteStart() ) );
							
							textFlow.flowComposer.updateAllControllers();
							
							performDummyOperation(getSelectionState());
							
							//	[FORMATING]
							//	[KK]	Apply styling
							_htmlImporter.importStyleHelper.apply();
							
							event.keyCode = Keyboard.DELETE;
							super.keyDownHandler(event);
							
							event.preventDefault();
							event.stopImmediatePropagation();
							
							return;
						}
						
						
						//	Single list
						if ( list == endList )
						{
							deleteText( new SelectionState( textFlow, absoluteStart, absoluteEnd ) );
							
							textFlow.flowComposer.updateAllControllers();
							
							//	AbsoluteStart is cursor position, subtract from that the startItem's actual start (start of text)
							//	Then add on the length of the seperator span (usually 3 or 4, depending on mode)
							newItem = startItem.splitAtPosition( absoluteStart-startItem.actualStart+startItem.seperatorLength ) as ListItemElementX;
							newItem.mode = startItem.mode;
							newItem.indent = startItem.indent;
							
							//	Multiline
							if ( startItem != endItem )
							{
								//	[FORMATING]
								//	[KK]	Hack to appropriate all of ListItemElementX's formatting
								newItem.format = startItem.computedFormat ? TextLayoutFormat(startItem.computedFormat) : startItem.format ? TextLayoutFormat(startItem.format) : new TextLayoutFormat();
								
								node = _htmlExporter.getSimpleMarkupModelForElement( startItem );
							}
								//	Single line
							else
							{
								endElement = null;
								i = startItem.numChildren;
								while (--i > -1)
								{
									if ( startItem.getChildAt(i) is SpanElement )
									{
										endElement = startItem.getChildAt(i);
										break;
									}
								}
								
								//	[FORMATING]
								//	[KK]	Hack to appropriate all of ListItemElementX's formatting
								if ( endElement )
									newItem.format = endElement.computedFormat ? TextLayoutFormat(endElement.computedFormat) : endElement.format ? TextLayoutFormat(endElement.format) : new TextLayoutFormat();
								else
									newItem.format = startItem.computedFormat ? TextLayoutFormat(startItem.computedFormat) : startItem.format ? TextLayoutFormat(startItem.format) : new TextLayoutFormat();
								
								node = _htmlExporter.getSimpleMarkupModelForElement( endElement ? endElement : startItem );
							}
							
							if ( node )
								_htmlImporter.importStyleHelper.assignInlineStyle( node, newItem );
							else
								trace('Error assigning inline styling #3');
							
							newItem.correctChildren();
							
							textFlow.flowComposer.updateAllControllers();
							
							list.update();
							
							// if there is text in front of the cursor when someone clicks enter, then the new line
							// should include the text but also move the cursor to the end.
							// Else we need to back up one space to place the cursor at the beginning of the line
							if(newItem.modifiedTextLength > 0) {
								setSelectionState( new SelectionState( textFlow, newItem.actualStart, newItem.actualStart) );
							} else {
								setSelectionState( new SelectionState( textFlow, newItem.actualStart-1, newItem.actualStart-1 ) );
							}
//							refreshSelection();
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
							
							textFlow.flowComposer.updateAllControllers();
							
							//	Children to shift from endList to list
							var children:Vector.<ListItemElementX> = new Vector.<ListItemElementX>();
							
							for ( i = endList.numChildren-2; i > 0; i-- )
								children.push( endList.removeChildAt(i) as ListItemElementX );
							
							//	New child from hitting enter
							newItem = new ListItemElementX();
							newItem.mode = startItem.mode;
							newItem.indent = startItem.indent;
							
							//	[FORMATING]
							//	[KK]	Hack to appropriate all of ListItemElementX's formatting
							newItem.format = startItem.computedFormat ? TextLayoutFormat(startItem.computedFormat) : startItem.format ? TextLayoutFormat(startItem.format) : new TextLayoutFormat();
							
							node = _htmlExporter.getSimpleMarkupModelForElement( startItem );
							if ( node )
								_htmlImporter.importStyleHelper.assignInlineStyle( node, newItem );
							else
								trace('Error assigning inline styling #4');
							
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
							
//							notifyInsertOrDelete( list.getAbsoluteStart(), list.textLength );
							
							var selPoint:uint = Math.min( newItem.actualStart+newItem.text.length-1, textFlow.textLength-1 );
							setSelectionState( new SelectionState( textFlow, selPoint, selPoint ) );
						}
						
						textFlow.flowComposer.updateAllControllers();
						
						performDummyOperation( getSelectionState() );
						event.preventDefault();
						return;
					}
					else
					{
						super.keyDownHandler(event);
						
						performDummyOperation( getSelectionState() );
						
						textFlow.flowComposer.updateAllControllers();
						
						return;
					}
					break;
				case Keyboard.BACKSPACE:
					
					// Retreive the default operation state. This is TLF specific
					// and is needed for specific operations.
					var operationState:SelectionState = defaultOperationState();
					if( !operationState ) return;
					
					// do the specific operation passing in the listMode argument
					doOperation( new BackspaceOperation( operationState, this, _htmlImporter, _htmlExporter ) );
					
					break;
				
				case Keyboard.DELETE:
					if ( items.length > 0 )
					{
						startItem = items[0] as ListItemElementX;
						list = startItem.parent as ListElementX;
						
						//	Get end item for special case
						for ( i = list.numChildren-1; i > -1; i-- )
						{
							if ( list.getChildAt(i) is ListItemElementX )
							{
								endItem = list.getChildAt(i) as ListItemElementX;
								break;
							}
						}
						
						var itemStart:uint = startItem.actualStart;
						var listStart:uint = list.getAbsoluteStart();
						var itemEnd:uint = endItem.getAbsoluteStart() + endItem.textLength - 1;
						var listEnd:uint = listStart + list.textLength;
						
						//	[KK]	Special case, deleting one whole list (and only that list)
						if ( absoluteStart <= itemStart && absoluteStart >= listStart &&
							absoluteEnd >= itemEnd && absoluteEnd <= listEnd)
						{
							list.parent.removeChild(list);
							
							//	[KK]	Repeated code (for this one special case)
							cleanEmptyLists( textFlow );
							
							for each ( list in lists )
							{
								if ( list )
									list.update();
							}
							
							break;
						}
						
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
							startItem = textFlow.findLeaf( absoluteStart ).parent as ListItemElementX;
							endItem = textFlow.findLeaf( absoluteEnd ).parent as ListItemElementX;
							
							start = absoluteStart;
							end = absoluteEnd;
							
							//	From list item to whatever
							if ( startItem )
							{
								list = startItem.parent as ListElementX;
								
								//	Trim start item
								deleteFrom = Math.min( startItem.numChildren-1, Math.max(1, startItem.findChildIndexAtPosition( start-startItem.getAbsoluteStart() ) ) );
								
								for ( i = startItem.numChildren-1; i >= deleteFrom; i-- )
								{
									if ( i != deleteFrom )
										startItem.removeChildAt(i);
									else
									{
										if ( startItem.getChildAt(i) is SpanElement )
										{
											j = absoluteStart-startItem.getChildAt(i).getAbsoluteStart();
											
											if ( j <= 0 )
												startItem.removeChildAt(i);
											else
											{
												end -= (startItem.getChildAt(i) as SpanElement).text.length - j;
												(startItem.getChildAt(i) as SpanElement).text = (startItem.getChildAt(i) as SpanElement).text.substring(0, j);
											}
										}
										else
											startItem.removeChildAt(i);	//	TODO: Fix, does not account for LinkElement
									}
								}
								
								//	To list item
								if ( endItem )
								{
									j = endItem.getChildIndex( textFlow.findLeaf(end) );
									i = endItem.numChildren-1;
									
									//	Cannot be more than # of children in list, cannot be less than position 1
									deleteFrom = Math.min( i, Math.max(1, j ) );
									
									//	Merge items
									for ( i = deleteFrom; i < endItem.numChildren; i++ )
									{
										//	Clone item
										endElement = endItem.getChildAt(i).deepCopy();
										
										//	Special case for first item
										//		if span, trim text to match selection state
										if ( i == deleteFrom )
										{
											//	TODO: Fix, does not account for LinkElement
											if ( endElement is SpanElement )
											{
												//	Relative start of selection (must be > -1)
												//								Get from original item's absoluteStart as the clone isn't on the textFlow
												j = Math.max(0, end - endItem.getChildAt(i).getAbsoluteStart()-1);	//	-1 because the calculation is going forward one too many
												
												(endElement as SpanElement).text = (endElement as SpanElement).text.substring(j);
											}
										}
										
										startItem.addChild( endElement );
									}
									
									//	[KK]	Without merge, a space will show between the two joined items upon save/export
									//	Merge all applicable children
									for ( i = startItem.numChildren-1; i > 1  ; i-- )
									{
										j = i-1;
										
										startElement = startItem.getChildAt(i);
										endElement = startItem.getChildAt(j);
										
										//	Must be same class
										if ( getQualifiedClassName(startElement) == getQualifiedClassName(endElement) )
										{
											//	Must have same formatting
											if ( TextLayoutFormat.isEqual( startElement.format, endElement.format ) )
											{
												//	Must be able to merge... e.g. cannot be two images
												if ( endElement is SpanElement )
												{
													(endElement as SpanElement).text = (endElement as SpanElement).text + (startElement as SpanElement).text; 
													startItem.removeChildAt(i);
												}
												else if ( endElement is LinkElement )
												{
													var startLink:LinkElement = startElement as LinkElement;
													var endLink:LinkElement = endElement as LinkElement;
													while ( startLink.numChildren > 0 )
													{
														endLink.addChild( startLink.removeChildAt(0) );
													}
													startItem.removeChildAt(i);
												}
											}
										}
									}
									
									deleteFrom = startItem.parent.getChildIndex( startItem );
									deleteTo = endItem.parent.getChildIndex( endItem );
									
									endList = endItem.parent as ListElementX;
									
									//	Single list
									if ( list == endList )
									{
										for ( i = deleteTo; i > deleteFrom; i-- )
										{
											list.removeChildAt(i);
										}
									}
									//	Multiple lists
									else
									{
										//	Delete between lists
										deleteText( new SelectionState( textFlow, list.getAbsoluteStart() + list.textLength, endList.getAbsoluteStart()-1 ) );
										
										//	Delete selected items from starting list (except for starting item)
										for ( i = list.numChildren-1; i > deleteFrom; i-- )
										{
											list.removeChildAt(i);
										}
										
										//	Delete selected items from ending list (including ending item)
										for ( i = deleteTo; i > -1; i-- )
										{
											endList.removeChildAt(i);
										}
										
										//	Merge lists
										for ( i = 0; i < endList.numChildren; i++ )
										{
											if ( endList.getChildAt(i) is ListItemElementX )
											{
												list.addChild( endList.removeChildAt(i) );
												i--;
											}
										}
										
										//	Delete end list
										endList.parent.removeChild( endList );
									}
								}
								//	To whatever
								else
								{
									//	Delete from end of list to end point
									deleteText( new SelectionState(textFlow, list.getAbsoluteStart()+list.textLength, end) );
									
									//	Remove items from list that are above / equal to start item position +1
									for ( i = list.numChildren-1; i > list.getChildIndex(startItem); i-- )
									{
										if ( list.getChildAt(i) is ListItemElementX )
											list.removeChildAt(i);
									}
								}
							}
							//	From whatever to list item, special case (must remove list item and manually join)
							else if ( endItem )
							{
								list = endItem.parent as ListElementX;
								
								end -= list.getAbsoluteStart()-start;
								//	Delete from start to start of list
								deleteText( new SelectionState(textFlow, start, list.getAbsoluteStart()) );
								
								//	Delete items from list
								//	If ending item, concatenate it
								for ( i = list.getChildIndex(endItem); i > -1; i-- )
								{
									if ( i == list.getChildIndex(endItem) )
									{
										deleteFrom = Math.max( 0, endItem.getChildIndex( textFlow.findLeaf(end) ) );
										
										//	Trim end item
										for ( j = deleteFrom; j > 0; j-- )
										{
											endElement = endItem.getChildAt(j);
											
											//	Special case for first item
											//		if span, trim text to match selection state
											if ( j == deleteFrom )
											{
												//	TODO: Fix, does not account for LinkElement
												if ( endElement is SpanElement )
												{
													//	Relative start of selection (must be > -1)
													//								Get from original item's absoluteStart as the clone isn't on the textFlow
													deleteTo = Math.max(0, end - endElement.getAbsoluteStart());
													
													(endElement as SpanElement).text = (endElement as SpanElement).text.substring(deleteTo+1);	//	+1 because the calculation is off by one for some reason
												}
											}
											else
												endItem.removeChildAt(j);
										}
									}
									else if ( list.getChildAt(i) is ListItemElementX )
										list.removeChildAt(i);
								}
							}
							else
							{
								super.keyDownHandler(event);
								return;
							}
						}
					}
					else
					{
						super.keyDownHandler(event);
						return;
					}
					
					ListUtil.cleanEmptyLists( textFlow );
					
					for each ( list in lists )
					{
						if ( list )
							list.update();
					}
					break;
				default:
					//trace(textFlow.findLeaf(textFlow.getAbsoluteStart()));
					super.keyDownHandler( event );
					return;
					break;
			}
			
			setSelectionState( new SelectionState( textFlow, absoluteStart, absoluteStart, textFlow.format ) );
			textFlow.flowComposer.updateAllControllers();
		}
		
		override public function editHandler(event:Event):void
		{
			var items:Array = SelectionHelper.getSelectedListItems( textFlow, true );
			var lists:Array = SelectionHelper.getSelectedLists( textFlow );
			
			switch (event.type)
			{
				case Event.CLEAR:
					//	[KK]	Special case for list clear
					if ( items.length > 0 )
					{
						var startItem:ListItemElementX = items[0] as ListItemElementX;
						var startList:ListElementX = startItem.parent as ListElementX;
						
						var endItem:ListItemElementX;
						
						//	Get end item for special case
						for ( var i:int = startList.numChildren-1; i > -1; i-- )
						{
							if ( startList.getChildAt(i) is ListItemElementX )
							{
								endItem = startList.getChildAt(i) as ListItemElementX;
								break;
							}
						}
						
						var itemStart:uint = startItem.actualStart;
						var listStart:uint = startList.getAbsoluteStart();
						var itemEnd:uint = endItem.getAbsoluteStart() + endItem.textLength - 1;
						var listEnd:uint = listStart + startList.textLength;
						
						//	[KK]	Special case, deleting one whole list (and only that list)
						if ( absoluteStart <= itemStart && absoluteStart >= listStart &&
							absoluteEnd >= itemEnd && absoluteEnd <= listEnd)
						{
							startList.parent.removeChild(startList);
							
							//	[KK]	Repeated code (for this one special case)
							cleanEmptyLists( textFlow );
							
							for each ( startList in lists )
							{
								if ( startList )
									startList.update();
							}
						}
						else
						{
							super.editHandler(event);
							break;
						}
						
						setSelectionState( new SelectionState( textFlow, absoluteStart, absoluteStart ) );
						textFlow.flowComposer.updateAllControllers();
					}
					else
						super.editHandler(event);
					break;
				default:
					super.editHandler(event);
					break;
			}
		}
		
		/**
		 * Perform a dummy operation in order to force the entire textFlow and all of it's container controllers (including AutosizeableContainerControllers) to update properly.
		 * 
		 * @param operationState
		 * 
		 * [KK]
		 */		
		public function performDummyOperation(operationState:SelectionState = null):void
		{
			operationState = defaultOperationState(operationState);
			if (!operationState)
				return;
			
			var op:DummyOperation;
			op = new DummyOperation( operationState );
			doOperation(op);
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
				
				try {
					to.addChildAt( addAt, child );
				} catch ( e:* ) {
					trace(e, "child:", child, "target:", to);
				}
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