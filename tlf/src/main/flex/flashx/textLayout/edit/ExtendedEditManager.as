package flashx.textLayout.edit
{
	import flash.desktop.ClipboardFormats;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
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
	import flashx.textLayout.elements.table.TableDataElement;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.events.SelectionEvent;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.operations.BackspaceOperation;
	import flashx.textLayout.operations.ClearOperation;
	import flashx.textLayout.operations.DeleteElementsOperation;
	import flashx.textLayout.operations.DeleteOperation;
	import flashx.textLayout.operations.DownArrowOperation;
	import flashx.textLayout.operations.DummyOperation;
	import flashx.textLayout.operations.EnterOperation;
	import flashx.textLayout.operations.ExtendedApplyFormatOperation;
	import flashx.textLayout.operations.FlowTextOperation;
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
			var operationState:SelectionState = defaultOperationState();
			
			var ss:SelectionState;
			if( !operationState ) return;
			
			
			if(event.keyCode > 31 
				&& event.keyCode != Keyboard.DELETE) {
				
				// if any of these keys are selected and there is a range of text
				if(absoluteStart != absoluteEnd
					&& !event.ctrlKey
					&& !event.altKey
					&& !event.shiftKey
					&& event.charCode != 0) {
					
					// we need to make sure that if the entire contents are selected, that characters 
					// do not try to delete text.  without this guard, the table is not deleted properly
					trace("absoluteStart: " + absoluteStart);
					trace("absoluteEnd: " + absoluteEnd);
					trace("textFlow.getAbsoluteStart(): " + textFlow.getAbsoluteStart());
					trace("tFlow.textLength-1: " + (textFlow.textLength-1));
//					if(absoluteStart == textFlow.getAbsoluteStart() && absoluteEnd == textFlow.textLength-1) {
//						doOperation( new BackspaceOperation( operationState, this ) )
//					} 	
					
					if(absoluteStart != absoluteEnd) {
						doOperation( new BackspaceOperation( operationState, this ) )
					}
				}
			}
			
			var p:ParagraphElement;
			var span:SpanElement;
			
			switch ( event.keyCode )
			{
				case Keyboard.TAB:
					doOperation( new TabOperation( operationState, this, event, _htmlImporter, _htmlExporter ) );
					return;
					break;
				
				case Keyboard.ENTER:
					//	[KK]	Changed to getSelectionState() from operationState
					doOperation( new EnterOperation( operationState, this, _htmlImporter, _htmlExporter ) );
					return;
					break;
				
				case Keyboard.BACKSPACE:
					doOperation( new BackspaceOperation( operationState, this ) );
					return;
					break;
				
				case Keyboard.DELETE:
					doOperation( new DeleteOperation( operationState, this ) );
					return;
					break;
				
				default:
					super.keyDownHandler( event );
					break;
			}
			
			//textFlow.flowComposer.updateAllControllers();
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
		
		// Overriding t o ensure proper styling of list items.
		override public function applyLeafFormat(characterFormat:ITextLayoutFormat, operationState:SelectionState=null):void
		{
			operationState = defaultOperationState(operationState);
			if (!operationState)
				return;
			
			// apply to the current selection else remember new format for next char typed
			doOperation(new ExtendedApplyFormatOperation(operationState, characterFormat, null, null));
		}
		
		override public function deleteNextCharacter(operationState:SelectionState=null):void
		{
			operationState = defaultOperationState(operationState);
			if (!operationState)
				return;
			
			if( operationState.absoluteEnd == operationState.absoluteStart )
			{
				// Check to see if we are trying to performa a delete from outside a table and will move the cursor into the table.
				//	This is not allowed.
				var paragraph:ParagraphElement = textFlow.findLeaf( operationState.anchorPosition ).getParagraph();
				var sibling:ParagraphElement = paragraph.getNextParagraph();
				if( sibling && paragraph.parent != sibling.parent )
				{
					var tableIsCurrent:Boolean = SelectionHelper.isCursorInElement( textFlow, operationState.absoluteStart, TableElement );
					var tableIsNext:Boolean = SelectionHelper.isCursorInElement( textFlow, operationState.absoluteStart + 1, TableElement );
					if( !tableIsCurrent && tableIsNext ) return;
				}
			}
			// If we are not trying to do a delte from outside a table into a table with one character, then do super.
			super.deleteNextCharacter( operationState );
		}
		
		override public function deletePreviousCharacter(operationState:SelectionState=null):void
		{
			operationState = defaultOperationState( operationState );
			if( !operationState ) return;
			
			if( operationState.absoluteEnd == operationState.absoluteStart )
			{
				// Check to see if we are trying to a perform a backspace from inside a table and will move the cursor outside the table.
				//	This is not allowed.
				var paragraph:ParagraphElement = textFlow.findLeaf( operationState.anchorPosition ).getParagraph();
				var previousSibling:ParagraphElement = paragraph.getPreviousParagraph();
				if( previousSibling && paragraph.parent != previousSibling.parent )
				{
					var tableIsCurrent:Boolean = SelectionHelper.isCursorInElement( textFlow, operationState.absoluteStart, TableElement );
					var tableIsPrevious:Boolean = SelectionHelper.isCursorInElement( textFlow, Math.max(operationState.anchorPosition - 1, 0), TableElement );
					if( tableIsCurrent && !tableIsPrevious ) return;
				}
			}
			// If we are not backspacing from inside a table to outside of a table with one character, then do super.
			super.deletePreviousCharacter( operationState );
		}
		
		public function get htmlImporter():IHTMLImporter
		{
			return _htmlImporter;
		}
		
	}
}