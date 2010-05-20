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
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.edit.helpers.ListHelper;
	import flashx.textLayout.edit.helpers.ListItemElementEnterHelper;
	import flashx.textLayout.edit.helpers.SelectionHelper;
	import flashx.textLayout.elements.BreakElement;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.ListElement;
	import flashx.textLayout.elements.ListItemElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.list.ListElementX;
	import flashx.textLayout.elements.list.ListItemElementX;
	import flashx.textLayout.elements.list.ListPaddingElement;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.operations.PasteOperation;
	import flashx.textLayout.tlf_internal;
	import flashx.undo.IUndoManager;
	
	use namespace tlf_internal;
	
	public class ExtendedEditManager extends EditManager
	{
		protected var _htmlImporter:IHTMLImporter;
		
		public function ExtendedEditManager(undoManager:IUndoManager=null)
		{
			super(undoManager);
		}
		
		// TODO: Hack to ensure won't throw error on delete including table cells.
		protected function getTableCellControllersInRange():Array
		{
			var selectionState:SelectionState = this.getSelectionState();
			var anchor:int = selectionState.anchorPosition;
			var active:int = selectionState.activePosition;
			var anchorIndex:int = ( anchor > active ) ? active : anchor;
			var activeIndex:int = ( anchor > active ) ? anchor : active;
			var start:int = textFlow.flowComposer.findControllerIndexAtPosition( anchorIndex );
			var end:int = textFlow.flowComposer.findControllerIndexAtPosition( activeIndex );
			// Allow for delete in single cell for table.
			if( start == end ) return [];
			var controllers:Array = [];
			for( var i:int = start; i < end + 1; i++ )
			{
				if( textFlow.flowComposer.getControllerAt( i ) is TableCellContainerController )
				{
					controllers.push( textFlow.flowComposer.getControllerAt( i ) );
				}
			}
			return controllers;
		}
		
		override public function keyDownHandler(event:KeyboardEvent):void
		{
			var items:Array = SelectionHelper.getSelectedListItems( textFlow, true );
			var lists:Array = SelectionHelper.getSelectedLists( textFlow );
			
			var startItem:ListItemElementX;
			var endItem:ListItemElementX;
			
			var list:ListElementX;
			var endList:ListElementX;
			
			var start:int;
			var end:int;
			
			var i:int;
			
			switch ( event.keyCode )
			{
				case Keyboard.TAB:
					if ( items.length > 0 )
					{
						for each ( startItem in items )
						{
							if ( event.shiftKey )
								startItem.indent = Math.max(0, startItem.indent-24);
							else
								startItem.indent = Math.min(240, startItem.indent+24);
						}
						
						for each ( list in lists )
							list.update();
					}
					else
						super.keyDownHandler(event);
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
								var item:ListItemElementX = items[i];
								
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
							
							setSelectionState( new SelectionState( textFlow, newItem.actualStart+newItem.text.length-1, newItem.actualStart+newItem.text.length-1 ) );
						}
					}
					else
						super.keyDownHandler(event);
					break;
				case Keyboard.BACKSPACE:
					super.keyDownHandler(event);
					break;
				case Keyboard.DELETE:
					super.keyDownHandler(event);
					break;
				default:
					super.keyDownHandler( event );
					break;
			}
			
			setSelectionState( new SelectionState( textFlow, absoluteStart, absoluteStart, textFlow.format ) );
			textFlow.flowComposer.updateAllControllers();
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
		
		private function preserveParagraphAppearance( element:FlowGroupElement ):void
		{
			var j:int = 0;
			var cc:FlowElement;
			var cs:SpanElement;
			for ( var i:int = 0; i < element.numChildren; i++ )
			{
				var child:FlowElement = element.getChildAt(i);
				
				//	Don't search ListElements or ListItemElements
				if ( child is DivElement )
					preserveParagraphAppearance( child as DivElement );
				else if ( child is ParagraphElement )
				{
					var separator:SpanElement;
					if ( child is ListPaddingElement )
					{
						continue;
//						var lpe:ListPaddingElement = child as ListPaddingElement;
//						separator = new SpanElement();
//						use namespace tlf_internal;
//						separator.text = SpanElement.tlf_internal::kParagraphTerminator;
//						lpe.addChild(separator);
					}
					else if ( child is ListItemElementX )
						continue;
					else
					{
//						var p:ParagraphElement = child as ParagraphElement;
//						separator = new SpanElement();
//						use namespace tlf_internal;
//						separator.text = SpanElement.tlf_internal::kParagraphTerminator;
//						p.addChild(separator);
					}
				}
			}
		}
		
//		override public function keyDownHandler(event:KeyboardEvent) : void
//		{
//			var startElement:FlowLeafElement = this.textFlow.findLeaf( this.absoluteStart );
//			var endElement:FlowLeafElement = this.textFlow.findLeaf( this.absoluteEnd );
//			
//			var i:int;
//			
//			switch ( event.keyCode )
//			{
//				case Keyboard.TAB:
//
//					var item:ListItemElement = startElement.getParentByType( ListItemElement ) as ListItemElement;
//					if ( item )
//					{
//						var selectedItems:Array = ListHelper.getSelectedListItemElements( this.textFlow );
//						
//						var tabList:ListElement = item.parent as ListElement;
//						var mode:String = item.mode;
//						var indent:int = int( item.paragraphStartIndent );
//						
//						var parentListIndex:int;
//						
//						var selectedItem:ListItemElement;
//						var itemParent:ListElement;
//						
//						//	Apply tabbing
//						if ( event.shiftKey )
//						{
//							indent = Math.max( indent - 24, 0 );
//							
//							for ( i = 0; i < selectedItems.length; i++ )
//							{
//								//	A	<----
//								//	->	B	|
//								//		->	C
//								
//								selectedItem = selectedItems[i] as ListItemElement;
//								itemParent = selectedItem.parent as ListElement;
//								var itemParent2:FlowGroupElement = itemParent.parent;
//								var itemParent3:FlowGroupElement = itemParent2.parent;
//								
//								if ( itemParent2 is ListElement )
//								{
//									//	Nested
//									if ( itemParent3 )
//									{
//										if ( itemParent3 is ListElement )
//										{
//											//	Nested twice or more
//											parentListIndex = ( itemParent3 as ListElement ).getChildIndex( itemParent2 );
//											itemParent2.removeChild( itemParent );
//											itemParent3.addChildAt( parentListIndex+1, itemParent );
//											itemParent.paragraphStartIndent = indent;
//										}
//										else
//										{
//											//	Nested only once
//											parentListIndex = ( itemParent2 as ListElement ).parent.getChildIndex( itemParent2 );
//											itemParent2.removeChild( itemParent );
//											( itemParent2 as ListElement ).parent.addChildAt( parentListIndex+1, itemParent );
//											itemParent.paragraphStartIndent = indent;
//										}
//									}
//									else
//									{
//										//	Nested only once
//										parentListIndex = ( itemParent2 as ListElement ).parent.getChildIndex( itemParent2 );
//										itemParent2.removeChild( itemParent );
//										( itemParent2 as ListElement ).parent.addChildAt( parentListIndex+1, itemParent );
//										itemParent.paragraphStartIndent = indent;
//									}
//								}
//								else
//								{
//									//	Not nested
//								}
//							}
//						}
//						else
//						{
//							indent = Math.min( indent + 24, 240 );
//							
//							var prevList:ListElement;
//							var newList:ListElement;
//							
//							for ( i = 0; i < selectedItems.length; i++ )
//							{
//								selectedItem = selectedItems[i] as ListItemElement;
//								itemParent = selectedItem.parent as ListElement;
//								
//								//	Figure out if current parent is the same as last parent
//								
//								var clonedItem:ListItemElement = new ListItemElement();
//								clonedItem.mode = selectedItem.mode;
//								clonedItem.text = selectedItem.text;
//								clonedItem.paragraphStartIndent = indent;
//								
//								if ( prevList != itemParent )
//								{
//									newList = new ListElement();
//									newList.mode = itemParent.mode;
//									newList.paragraphStartIndent = indent;
//									
//									var selectedItemIndex:int = itemParent.getChildIndex( selectedItem );
//									if ( selectedItemIndex < itemParent.numChildren/2 )
//										itemParent.addChildAt( selectedItemIndex, newList );
//									else
//										itemParent.addChildAt( selectedItemIndex+1, newList );
//									
//									itemParent.removeChild( selectedItem );
//								}
//								
//								newList.addChild( clonedItem );
//							}
//						}
//						
//						//item.paragraphStartIndent = indent;
//					}
//					else
//					{
//						this.insertText( '\t' );
//					}
//					break;
//				case Keyboard.ENTER:
////					trace('enter pressed');
//					if ( this.hasSelection() )
//					{
////						trace('startElement:', startElement);
//						if ( startElement.getParentByType(ListItemElement) )// startElement.parent.parent is ListItemElement )
//						{
//							ListItemElementEnterHelper.processReturnKey( this, startElement.getParentByType( ListItemElement ) as ListItemElement );
//						}
//						else
//						{
//							// [TA] :: 03/16/10 -> entering a line character would not properly perform a Split paragraph operation.
//							super.keyDownHandler( event );
//						}
//					}
//					break;
//				case Keyboard.BACKSPACE:
//					if ( this.hasSelection() )
//					{
//						var previousElement:FlowLeafElement = this.textFlow.findLeaf( startElement.getElementRelativeStart( this.textFlow ) - 1 );
//						
//						if ( startElement.getParentByType( ListItemElement ) )// (startElement.parent is ListItemElement) || (endElement.parent is ListItemElement) )
//						{
//							ListItemElementEnterHelper.processDeleteKey( textFlow );
//						}
//						else if ( previousElement is ListItemElement )
//						{
//							var previousItem:ListItemElement = previousElement as ListItemElement;
//							var selectionState:SelectionState = new SelectionState( this.textFlow, this.absoluteStart, this.absoluteEnd, this.textFlow.format );
//							
//							if ( this.isRangeSelection() )
//							{
//								this.deleteText( selectionState );
//								this.selectRange( this.absoluteStart-2, this.absoluteStart-2 );
//							}
//							else
//							{
//								previousItem.text = previousItem.text.substr( 0, previousItem.text.length-2 );//rawText.substr( 0, previousItem.rawText.length-2 );
//								var selectionPos:int = previousItem.getElementRelativeStart( this.textFlow ) + previousItem.text.length - 2;
//								this.selectRange( selectionPos, selectionPos );
//							}
//							this.textFlow.flowComposer.updateAllControllers();
//						}
//						else
//						{
//							super.keyDownHandler( event );
//						}
//					}
//					break;
//				case Keyboard.DELETE: //del
//					super.keyDownHandler( event );
//					event.preventDefault();
//				break;
//				default:
//					var char:String = String.fromCharCode( event.charCode );
//					var regEx:RegExp = /\w/;
//					if ( regEx.test( char ) )
//					{
//						if ( startElement.getParentByType( ListItemElement ) )
//						{
//							event.stopImmediatePropagation();
//							event.preventDefault();
//							
//							//	Insert text being entered into position it's being entered
//							var startItem:ListItemElement = startElement.getParentByType( ListItemElement ) as ListItemElement;
//							var list:ListElement = startItem.parent as ListElement;
//							var offset:int = startItem.mode == ListElement.UNORDERED ? 3 : 4;
//							var relativeStart:int = this.absoluteStart - startItem.getElementRelativeStart( this.textFlow ) - offset;
//							var rawText:String = startItem.text;//rawText;
//							var beginning:String = rawText.substring(0, relativeStart-1);
//							var end:String;
//							
//							var deleteState:SelectionState;
//							var startPos:int = list.getChildIndex( startItem);
//							
//							if ( this.isRangeSelection() )
//							{
//								var endItem:ListItemElement;
//								if ( endElement is ListItemElement )
//								{
//									endItem = endElement as ListItemElement;
//									
//									deleteState = new SelectionState( this.textFlow, endItem.getElementRelativeStart( this.textFlow ) + endItem.text.length, this.absoluteEnd, this.textFlow.format );
//									this.deleteText( deleteState );
//									
//									var relativeEnd:int = this.absoluteEnd - endItem.getElementRelativeStart( this.textFlow ) - offset;
//									var endText:String = endItem.text;//rawText;
//									endItem.text = endText.substr( relativeEnd, endText.length );
//									
//									var endPos:int = list.getChildIndex( endItem );
//									
//									for ( i = endPos - 1; i > startPos; i-- )
//									{
//										list.removeChildAt(i);
//									}
//									
////									list.update();
//								}
//								else
//								{
//									endItem = list.getChildAt( list.numChildren - 1 ) as ListItemElement;
//									var startDelete:int = endItem.getElementRelativeStart( this.textFlow ) + endItem.text.length;
//									
//									deleteState = new SelectionState( this.textFlow, startDelete, this.absoluteEnd, this.textFlow.format );
//									this.deleteText( deleteState );
//									
//									for ( i = list.numChildren - 1; i > startPos; i-- )
//									{
//										list.removeChildAt(i);
//									}
//									
////									list.update();
//								}
//								
//								end = '';
//							}
//							else
//							{
//								end = rawText.substring(relativeStart-1, rawText.length);
//							}
//							
//							startItem.text = beginning + char + end;
//							
//							this.textFlow.flowComposer.updateAllControllers();
//							this.selectRange( this.absoluteStart+1, this.absoluteStart+1 );
//						}
//						else
//						{
//							super.keyDownHandler( event );
//						}
//					}
//					else
//					{
//						super.keyDownHandler( event );
//					}
//					break;
//			}
//			
//			this.textFlow.flowComposer.updateAllControllers();
//		}
		
		/**
		 * Override to intercept paste operations applied to cells. Currently strings from the Clipboard that contain carraige returns break the flow and cause RTEs. 
		 * @param event Event
		 */
		override public function editHandler(event:Event):void
		{
			// Access to String pasted form clipboard. Just for reference.
//			var data:String = TextClipboard.getTextOnClipboardForFormat(ClipboardFormats.TEXT_FORMAT );
			super.editHandler( event );
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
	}
}