package flashx.textLayout.edit
{
	import flash.desktop.ClipboardFormats;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TextEvent;
	import flash.ui.Keyboard;
	
	import flashx.textLayout.container.table.ICellContainer;
	import flashx.textLayout.conversion.ConversionType;
	import flashx.textLayout.conversion.TextConverter;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.edit.helpers.ListItemElementEnterHelper;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.ListElement;
	import flashx.textLayout.elements.ListItemElement;
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
		
		override public function keyDownHandler(event:KeyboardEvent) : void
		{
//			trace('key down handler');
			
			var startElement:FlowLeafElement = this.textFlow.findLeaf( this.absoluteStart );
			var endElement:FlowLeafElement = this.textFlow.findLeaf( this.absoluteEnd );
			
			switch ( event.keyCode )
			{
				case Keyboard.TAB:
					this.insertText( '\t' );
					break;
				case Keyboard.ENTER:
//					trace('enter pressed');
					if ( this.hasSelection() )
					{
//						trace('startElement:', startElement);
						if ( startElement.parent is ListItemElement )
						{
							ListItemElementEnterHelper.processReturnKey( this, startElement.parent as ListItemElement );
						}
						else
						{
							// [TA] :: 03/16/10 -> entering a line character would not properly perform a Split paragraph operation.
							//this.insertText( '\n' );
							super.keyDownHandler( event );
						}
					}
					break;
				case Keyboard.BACKSPACE:
					if ( this.hasSelection() )
					{
						var previousElement:FlowLeafElement = this.textFlow.findLeaf( startElement.getElementRelativeStart( this.textFlow ) - 1 );
						
						if ( (startElement.parent is ListItemElement) || (endElement.parent is ListItemElement) )
						{
							ListItemElementEnterHelper.processDeleteKey( textFlow );
							this.textFlow.flowComposer.updateAllControllers();
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
								previousItem.text = previousItem.rawText.substr( 0, previousItem.rawText.length-2 );
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
				default:
					var char:String = String.fromCharCode( event.charCode );
					var regEx:RegExp = /\w/;
					if ( regEx.test( char ) )
					{
						if ( startElement is ListItemElement )
						{
							event.stopImmediatePropagation();
							event.preventDefault();
							
							//	Insert text being entered into position it's being entered
							var startItem:ListItemElement = startElement as ListItemElement;
							var list:ListElement = startItem.parent as ListElement;
							var offset:int = startItem.mode == ListElement.UNORDERED ? 3 : 4;
							var relativeStart:int = this.absoluteStart - startItem.getElementRelativeStart( this.textFlow ) - offset;
							var rawText:String = startItem.rawText;
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
									var endText:String = endItem.rawText;
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
		}
		
		/**
		 * Override to intercept paste operations applied to cells. Currently strings from the Clipboard that contain carraige returns break the flow and cause RTEs. 
		 * @param event Event
		 */
		override public function editHandler(event:Event):void
		{
			// Access to String pasted form clipboard. Just for reference.
			var data:String = TextClipboard.getTextOnClipboardForFormat(ClipboardFormats.TEXT_FORMAT );
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