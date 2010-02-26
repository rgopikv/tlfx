package flashx.textLayout.edit
{
	import flash.events.KeyboardEvent;
	import flash.events.TextEvent;
	import flash.ui.Keyboard;
	
	import flashx.textLayout.edit.helpers.ListItemElementEnterHelper;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.ListElement;
	import flashx.textLayout.elements.ListItemElement;
	import flashx.undo.IUndoManager;
	
	public class ExtendedEditManager extends EditManager
	{
		public function ExtendedEditManager(undoManager:IUndoManager=null)
		{
			super(undoManager);
		}
		
		override public function textInputHandler(event:TextEvent) : void
		{
			//
		}
		
		override public function keyDownHandler(event:KeyboardEvent) : void
		{
			var startElement:FlowLeafElement = this.textFlow.findLeaf( this.absoluteStart );
			var endElement:FlowLeafElement = this.textFlow.findLeaf( this.absoluteEnd );
			
			switch ( event.keyCode )
			{
				case Keyboard.TAB:
					this.insertText( '\t' );
					break;
				case Keyboard.ENTER:
					if ( this.hasSelection() )
					{
						if ( startElement is ListItemElement )
						{
							ListItemElementEnterHelper.processReturnKey( this, startElement as ListItemElement );
						}
						else
						{
							this.insertText( '\n' );
						}
					}
					break;
				case Keyboard.BACKSPACE:
					if ( this.hasSelection() )
					{
						var previousElement:FlowLeafElement = this.textFlow.findLeaf( startElement.getElementRelativeStart( this.textFlow ) - 1 );
						
						if ( (startElement is ListItemElement) || (endElement is ListItemElement) )
						{
							ListItemElementEnterHelper.processDeleteKey( this, startElement, endElement );
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
							var offset:int = startItem.mode == ListElement.BULLETED ? 3 : 4;
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
									
									list.update();
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
									
									list.update();
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
		
//		private static function getClass(obj:Object):Class
//		{
//			return Class(getDefinitionByName(getQualifiedClassName(obj)));
//		}
	}
}