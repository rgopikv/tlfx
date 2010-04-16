package flashx.textLayout.edit
{
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
	import flashx.textLayout.edit.helpers.ListItemElementEnterHelper;
	import flashx.textLayout.elements.BreakElement;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.ListElement;
	import flashx.textLayout.elements.ListItemElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
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
		
		override public function textInputHandler(event:TextEvent) : void
		{
			var startElement:FlowLeafElement = this.textFlow.findLeaf( this.absoluteStart );
			
			if ( startElement is ListItemElement )
			{
				//	Nothing
			}
			else
			{
				super.textInputHandler( event );
			}
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
		
		override public function keyDownHandler(event:KeyboardEvent) : void
		{
			var startElement:FlowLeafElement = this.textFlow.findLeaf( this.absoluteStart );
			var endElement:FlowLeafElement = this.textFlow.findLeaf( this.absoluteEnd );
			
			switch ( event.keyCode )
			{
				case Keyboard.TAB:

					var item:ListItemElement = startElement.getParentByType( ListItemElement ) as ListItemElement;
					if ( item )
					{
//						var list:ListElement = item.parent as ListElement;
//						var mode:String = item.mode;
						var indent:int = int( item.paragraphStartIndent );
//						
//						var itemCopy:ListItemElement;
						
						//	Apply tabbing
						if ( event.shiftKey )
						{
							indent = Math.max( indent - 24, 0 );
//							
//							if ( list.getParentByType( ListItemElement ) )
//							{
//								var parentItem:ListItemElement = list.getParentByType( ListItemElement ) as ListItemElement;
//								
//								var textCopy:String = item.text;
//								
//								parentItem.removeChild( list );
//								
//								parentItem.mode = mode;
//								parentItem.paragraphStartIndent = indent;
//								parentItem.text = textCopy;
//							}
//							else
//								item.paragraphStartIndent = indent;
						}
						else
						{
							indent = Math.min( indent + 24, 240 );
//							
//							//	Clone item
//							itemCopy = new ListItemElement();
//							itemCopy.mode = mode;
//							itemCopy.paragraphStartIndent = indent;
//							itemCopy.text = item.text;
//							
//							//	Replace current item with new list
//							var newList:ListElement = new ListElement();
//							newList.mode = mode;
//							newList.addChild( itemCopy );
//							
//							item.text = '';
//							
//							item.addChild( newList );
						}
						
						item.paragraphStartIndent = indent;
					}
					else
					{
						this.insertText( '\t' );
					}
					break;
				case Keyboard.ENTER:
//					trace('enter pressed');
					if ( this.hasSelection() )
					{
//						trace('startElement:', startElement);
						if ( startElement.getParentByType(ListItemElement) )// startElement.parent.parent is ListItemElement )
						{
							ListItemElementEnterHelper.processReturnKey( this, startElement.getParentByType( ListItemElement ) as ListItemElement );
						}
						else
						{
							// [TA] :: 03/16/10 -> entering a line character would not properly perform a Split paragraph operation.
//							super.keyDownHandler( event );
							
							if ( startElement is FlowGroupElement )
							{
								( startElement as FlowGroupElement ).addChildAt( startElement.parent.getChildIndex(startElement)+1, new BreakElement() );
							}
							else
							{
								if ( startElement is SpanElement )
								{
									var span1:SpanElement = startElement as SpanElement;
									var span2:SpanElement = new SpanElement();
									
									var index:int = span1.getParagraph().getChildIndex( span1 );
									
									var span1Start:int = this.absoluteStart - span1.getElementRelativeStart( this.textFlow );
									var span2Text:String = span1.text.substring( span1Start, span1.textLength );
									span1.text = span1.text.substring( 0, span1Start );
									
									span2.text = span2Text;
									
									span1.getParagraph().addChildAt( index+1, new BreakElement() );
									span1.getParagraph().addChildAt( index+2, span2 );
									
									this.selectRange( this.absoluteStart+1, this.absoluteStart+1 );
								}
								else
								{
									trace('not a span element!');
								}
							}
						}
					}
					break;
				case Keyboard.BACKSPACE:
					if ( this.hasSelection() )
					{
						var previousElement:FlowLeafElement = this.textFlow.findLeaf( startElement.getElementRelativeStart( this.textFlow ) - 1 );
						
						if ( startElement.getParentByType( ListItemElement ) )// (startElement.parent is ListItemElement) || (endElement.parent is ListItemElement) )
						{
							ListItemElementEnterHelper.processDeleteKey( textFlow );
						}
						else if ( previousElement is ListItemElement )
						{
							var previousItem:ListItemElement = previousElement as ListItemElement;
							var selectionState:SelectionState = new SelectionState( this.textFlow, this.absoluteStart, this.absoluteEnd, this.textFlow.format );
							
							if ( this.isRangeSelection() )
							{
								this.deleteText( selectionState );
								this.selectRange( this.absoluteStart-2, this.absoluteStart-2 );
							}
							else
							{
								previousItem.text = previousItem.text.substr( 0, previousItem.text.length-2 );//rawText.substr( 0, previousItem.rawText.length-2 );
								var selectionPos:int = previousItem.getElementRelativeStart( this.textFlow ) + previousItem.text.length - 2;
								this.selectRange( selectionPos, selectionPos );
							}
							this.textFlow.flowComposer.updateAllControllers();
						}
						else
						{
							super.keyDownHandler( event );
						}
					}
					break;
				case Keyboard.DELETE: //del
					super.keyDownHandler( event );
					event.preventDefault();
				break;
				default:
					var char:String = String.fromCharCode( event.charCode );
					var regEx:RegExp = /\w/;
					if ( regEx.test( char ) )
					{
						if ( startElement.getParentByType( ListItemElement ) )
						{
							event.stopImmediatePropagation();
							event.preventDefault();
							
							//	Insert text being entered into position it's being entered
							var startItem:ListItemElement = startElement.getParentByType( ListItemElement ) as ListItemElement;
							var list:ListElement = startItem.parent as ListElement;
							var offset:int = startItem.mode == ListElement.UNORDERED ? 3 : 4;
							var relativeStart:int = this.absoluteStart - startItem.getElementRelativeStart( this.textFlow ) - offset;
							var rawText:String = startItem.text;//rawText;
							var beginning:String = rawText.substring(0, relativeStart-1);
							var end:String;
							
							var deleteState:SelectionState;
							var startPos:int = list.getChildIndex( startItem);
							var i:int;
							
							if ( this.isRangeSelection() )
							{
								var endItem:ListItemElement;
								if ( endElement is ListItemElement )
								{
									endItem = endElement as ListItemElement;
									
									deleteState = new SelectionState( this.textFlow, endItem.getElementRelativeStart( this.textFlow ) + endItem.text.length, this.absoluteEnd, this.textFlow.format );
									this.deleteText( deleteState );
									
									var relativeEnd:int = this.absoluteEnd - endItem.getElementRelativeStart( this.textFlow ) - offset;
									var endText:String = endItem.text;//rawText;
									endItem.text = endText.substr( relativeEnd, endText.length );
									
									var endPos:int = list.getChildIndex( endItem );
									
									for ( i = endPos - 1; i > startPos; i-- )
									{
										list.removeChildAt(i);
									}
									
//									list.update();
								}
								else
								{
									endItem = list.getChildAt( list.numChildren - 1 ) as ListItemElement;
									var startDelete:int = endItem.getElementRelativeStart( this.textFlow ) + endItem.text.length;
									
									deleteState = new SelectionState( this.textFlow, startDelete, this.absoluteEnd, this.textFlow.format );
									this.deleteText( deleteState );
									
									for ( i = list.numChildren - 1; i > startPos; i-- )
									{
										list.removeChildAt(i);
									}
									
//									list.update();
								}
								
								end = '';
							}
							else
							{
								end = rawText.substring(relativeStart-1, rawText.length);
							}
							
							startItem.text = beginning + char + end;
							
							this.textFlow.flowComposer.updateAllControllers();
							this.selectRange( this.absoluteStart+1, this.absoluteStart+1 );
						}
						else
						{
							super.keyDownHandler( event );
						}
					}
					else
					{
						super.keyDownHandler( event );
					}
					break;
			}
			
			this.textFlow.flowComposer.updateAllControllers();
		}
		
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