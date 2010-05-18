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
	import flashx.textLayout.elements.ListElement;
	import flashx.textLayout.elements.ListItemElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.operations.CutOperation;
	import flashx.textLayout.operations.ExtendedCopyOperation;
	import flashx.textLayout.operations.PasteOperation;
	import flashx.textLayout.tlf_internal;
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
		
		override public function textInputHandler(event:TextEvent):void
		{
			var startElement:FlowLeafElement = textFlow.findLeaf( absoluteStart );
			var endElement:FlowLeafElement = textFlow.findLeaf( absoluteEnd );
			var item:ListItemElement = startElement.getParentByType( ListItemElement ) as ListItemElement;
			var endItem:ListItemElement = endElement.getParentByType( ListItemElement ) as ListItemElement;
			
			if ( item )
			{
				var relStart:int = absoluteStart - item.span.getAbsoluteStart()
				if ( isRangeSelection() )
				{
					if ( endItem && endItem != item )	//	Multiline
					{
						
					}
					else
					{
						
					}
				}
				else
				{
					
				}
			}
			else
				super.textInputHandler(event);
		}
		
		override public function keyDownHandler(event:KeyboardEvent):void
		{
			var startElement:FlowLeafElement = textFlow.findLeaf( absoluteStart );
			var endElement	:FlowLeafElement = textFlow.findLeaf( absoluteEnd );
			
			var i:int = 0;
			
			var item:ListItemElement = startElement.getParentByType( ListItemElement ) as ListItemElement;
			var endItem:ListItemElement = endElement.getParentByType( ListItemElement ) as ListItemElement;
			var list:ListElement;
			var selectedItems:Array = ListHelper.getSelectedListItemElements( textFlow );
			
			var index:int = item ? item.parent.getChildIndex( item ) : -1;
			var endIndex:int = endItem ? endItem.parent.getChildIndex( endItem ) : -1;
			
			var relStart1:int;
			var relEnd1:int;
			
			switch ( event.keyCode )
			{
				case Keyboard.TAB:
					if ( item )
					{
						var indent:int = int( item.paragraphStartIndent );
						
						//	TODO: implement
					}
					else
						super.keyDownHandler(event);
					break;
				case Keyboard.ENTER:
					if ( item )
					{
						list = item.parent as ListElement;
						
						var newItem:ListItemElement = new ListItemElement();
						newItem.mode = list.mode;
						
						relStart1 = absoluteStart - item.span.getAbsoluteStart() - item.seperatorLength;
						if ( !endItem )
						{
							relEnd1 = absoluteEnd - item.span.getAbsoluteStart() - item.seperatorLength;
						}
						else
						{
							relEnd1 = absoluteEnd - endItem.span.getAbsoluteStart() - endItem.seperatorLength;
						}
						
						var addNew:Boolean = true;
						
						if ( !isRangeSelection() )	//	single line
							newItem.text = item.text.substring( relEnd1, item.text.length );
						else
						{
							if ( endItem && endItem != item )
								endItem.text = endItem.text.substring( relEnd1, endItem.text.length );
							else if ( endItem && endItem == item )
								newItem.text = endItem.text.substring( relEnd1, endItem.text.length );
							
							for ( i = endIndex-1; i > index; i-- )
							{
								if ( list.getChildAt(i) )
								{
									addNew = false;
									list.removeChildAt(i);
								}
							}
						}
						
						item.text = item.text.substring(0, relStart1);
						
						if ( addNew )
						{
							list.addChildAt(index+1, newItem);
							setSelectionState( new SelectionState( textFlow, newItem.span.getAbsoluteStart() + newItem.span.textLength-1, newItem.span.getAbsoluteStart() + newItem.span.textLength-1 ) );
						}
						else
							setSelectionState( new SelectionState( textFlow, endItem ? endItem.span.getAbsoluteStart() + endItem.seperatorLength : item.span.getAbsoluteStart() + item.span.text.length-1, endItem ? endItem.span.getAbsoluteStart() + endItem.seperatorLength : item.span.getAbsoluteStart() + item.span.text.length-1 ) );
						updateAllControllers();
					}
					else
						super.keyDownHandler(event);
					break;
				case Keyboard.BACKSPACE:
					if ( item )
					{
						list = item.parent as ListElement;
						
						if ( isRangeSelection() )
						{
							if ( endItem == item )
								deleteText( getSelectionState() );
							else
							{
								if ( endIndex == -1 )
									endIndex = list.numChildren-1;
								
								relStart1 = absoluteStart - item.span.getAbsoluteStart() - item.seperatorLength;
								if ( endItem )
								{
									relEnd1 = absoluteEnd - endItem.span.getAbsoluteStart() - endItem.seperatorLength;
									endItem.text = endItem.text.substring(relEnd1, endItem.text.length);
								}
								
								for ( i = endIndex-1; i > index; i-- )
								{
									if ( list.getChildAt(i) )
										list.removeChildAt(i);
								}
								
								item.text = item.text.substring(0, relStart1);
								
								updateAllControllers();
								
								//	TODO: Fix, it's setting the selection state too early
								setSelectionState( new SelectionState( textFlow, item.span.getAbsoluteStart() + item.text.length-1, item.span.getAbsoluteStart() + item.text.length-1 ) );
								
								updateAllControllers();
							}
						}
						else
							deletePreviousCharacter( getSelectionState() );
					}
					else
						super.keyDownHandler(event);
					break;
				case Keyboard.DELETE:
					if ( item )
					{
						list = item.parent as ListElement;
						
						if ( isRangeSelection() )
						{
							if ( endItem == item )
								deleteText( getSelectionState() );
							else
							{
								if ( endIndex == -1 )
									endIndex = list.numChildren-1;
								
								relStart1 = absoluteStart - item.span.getAbsoluteStart() - item.seperatorLength;
								if ( endItem )
								{
									relEnd1 = absoluteEnd - endItem.span.getAbsoluteStart() - endItem.seperatorLength;
									endItem.text = endItem.text.substring(relEnd1, endItem.text.length);
								}
								
								for ( i = endIndex-1; i > index; i-- )
								{
									if ( list.getChildAt(i) )
										list.removeChildAt(i);
								}
								
								item.text = item.text.substring(0, relStart1);
								
								updateAllControllers();
								
								//	TODO: Fix, it's setting the selection state too early
								setSelectionState( new SelectionState( textFlow, item.span.getAbsoluteStart() + item.text.length-1, item.span.getAbsoluteStart() + item.text.length-1 ) );
								
								updateAllControllers();
							}
						}
						else
							deleteNextCharacter( getSelectionState() );
					}
					else
						super.keyDownHandler(event);
					break;
				default:
//					//	Space or
//					//	Numbers or
//					//	characters
//					//	Keypad or
//					//	keypad punctuation & special chars or
//					//	regular punctuation & special chars
//					if ( event.keyCode == 32 ||
//						(event.keyCode > 47 && event.keyCode < 58) ||
//						(event.keyCode > 64 && event.keyCode < 91) ||
//						(event.keyCode > 95 && event.keyCode < 108) ||
//						(event.keyCode > 108 && event.keyCode < 112) ||
//						(event.keyCode > 185 && event.keyCode < 192) ||
//						(event.keyCode > 218 && event.keyCode < 223))
					if ( !event.ctrlKey )
					{
						if ( item )
						{
							list = item.parent as ListElement;
							if ( isRangeSelection() )
							{
								if ( endItem && endItem != item )	//	Multiline list selection
								{
									if ( endIndex == -1 )
										endIndex = list.numChildren-1;
									
									relStart1 = absoluteStart - item.span.getAbsoluteStart() - item.seperatorLength;
									if ( endItem )
									{
										relEnd1 = absoluteEnd - endItem.span.getAbsoluteStart() - endItem.seperatorLength;
										var endText:String = endItem.text.substring(relEnd1, endItem.text.length);
									}
									
									for ( i = endIndex; i > index; i-- )
									{
										if ( list.getChildAt(i) )
											list.removeChildAt(i);
									}
									
									//	Auto inserts text being entered... need to find out where that is happening
									item.text = item.text.substring(0, relStart1) + endText;
									
									updateAllControllers();
									
									//	TODO: Fix, it's setting the selection state too early
									setSelectionState( new SelectionState( textFlow, item.span.getAbsoluteStart() + item.text.length-1, item.span.getAbsoluteStart() + item.text.length-1 ) );
									
									updateAllControllers();
									return;
								}
							}
						}
					}
					
					super.keyDownHandler( event );
					break;
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
	}
}