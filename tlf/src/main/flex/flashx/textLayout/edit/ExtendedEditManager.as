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
	
	import flashx.textLayout.container.AutosizableContainerController;
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
	import flashx.textLayout.operations.ClearOperation;
	import flashx.textLayout.operations.DownArrowOperation;
	import flashx.textLayout.operations.DummyOperation;
	import flashx.textLayout.operations.EnterOperation;
	import flashx.textLayout.operations.PasteOperation;
	import flashx.textLayout.operations.TabOperation;
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
					// Retreive the default operation state. This is TLF specific
					// and is needed for specific operations.
					var operationState:SelectionState = defaultOperationState();
					if( !operationState ) return;
					
					// do the specific operation passing in the listMode argument
					doOperation( new TabOperation( operationState, this, event, _htmlImporter, _htmlExporter ) );
					
					break;
				
				case Keyboard.ENTER:
					var operationState:SelectionState = defaultOperationState();
					if( !operationState ) return;
					
					// do the specific operation passing in the listMode argument
					doOperation( new EnterOperation( operationState, this, _htmlImporter, _htmlExporter ) );
					
					break;
				case Keyboard.BACKSPACE:
					var operationState:SelectionState = defaultOperationState();
					if( !operationState ) return;
					
					// do the specific operation passing in the listMode argument
					doOperation( new BackspaceOperation( operationState, this ) );
					
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
					
					var operationState:SelectionState = defaultOperationState();
					if( !operationState ) return;
					
					/*// do the specific operation passing in the listMode argument
					if (doOperation( new DownArrowOperation( operationState, this ) )) {
						return;
					} else {
					}*/
					super.keyDownHandler( event );
					
					return;
					break;
			}
			
			//setSelectionState( new SelectionState( textFlow, absoluteStart, absoluteStart, textFlow.format ) );
			textFlow.flowComposer.updateAllControllers();
		}
		
		override public function editHandler(event:Event):void
		{
			var items:Array = SelectionHelper.getSelectedListItems( textFlow, true );
			var lists:Array = SelectionHelper.getSelectedLists( textFlow );
			
			switch (event.type)
			{
				case Event.CLEAR:
					
					var operationState:SelectionState = defaultOperationState();
					
					if (!operationState)
						return;
					
					var op:ClearOperation;
					op = new ClearOperation( operationState, this );
					doOperation(op);
					
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