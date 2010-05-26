package flashx.textLayout.elements
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.engine.TextLine;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import flashx.textLayout.compose.TextFlowLine;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.events.ModelChange;
	import flashx.textLayout.events.SelectionEvent;
	import flashx.textLayout.events.variable.VariableEditEvent;
	import flashx.textLayout.tlf_internal;

	use namespace tlf_internal;
	
	/**
	 * VarElement is a FlowLeafElement representing a variable in HTML. Very simliar to a span. 
	 * @author toddanderson
	 */
	public class VarElement extends SpanElement implements IVarElement
	{
		protected var _menuInteractiveObject:Sprite;
		protected var _contextMenu:ContextMenu;
		protected var _listenersAdded:Boolean;
		
		protected var _textFlow:TextFlow;
		
		/**
		 * Constructor.
		 */
		public function VarElement()
		{
			super();
			setTextLength(0);
		}
		
		/**
		 * @private 
		 * 
		 * Initializes the variable element with any operations. Occurs on added to display of text flow.
		 */
		protected function initialize():void
		{
			addListeners();
		}
		
		/**
		 * @priavte 
		 * 
		 * Cleans references and listeners associated with this element. Occurs on removal from display of text flow.
		 */
		protected function clean():void
		{
			removeListeners();
			_menuInteractiveObject.contextMenu = null;
			_menuInteractiveObject = null;
		}
		
		/**
		 * @private
		 * 
		 * Returns a custom context menu for use with element. 
		 * @return ContextMenu
		 */
		protected function getContextMenu():ContextMenu
		{
			var menu:ContextMenu = new ContextMenu();
			menu.hideBuiltInItems();
			
			var editItem:ContextMenuItem = new ContextMenuItem( "Edit", false, true, true );
			editItem.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, handleEditItem );
			
			menu.customItems = [editItem];
			return menu;
		}
		
		/**
		 * @private
		 * 
		 * Assigns a new context menu for this element. 
		 * @param display DisplayObjectContainer
		 */
		protected function addContextMenu( display:DisplayObjectContainer ):void
		{
			if( _contextMenu == null )
			{
				_contextMenu = getContextMenu();
			}
			_menuInteractiveObject = new Sprite();
			_menuInteractiveObject.contextMenu = _contextMenu;
			display.addChildAt( _menuInteractiveObject, 0 );
		}
		
		/**
		 * @private 
		 * 
		 * Creates event handlers for operations.
		 */
		protected function addListeners():void
		{
			_textFlow = getTextFlow();
			if( _textFlow && !_listenersAdded )
			{
				_textFlow.addEventListener(SelectionEvent.SELECTION_CHANGE, handleSelectionChange, false, 0 , true );
				_listenersAdded = true;	
			}	
		}
		
		/**
		 * @private 
		 * 
		 * Removes event handlers for operations.
		 */
		protected function removeListeners():void
		{
			if( _textFlow && _listenersAdded )
			{
				_textFlow.removeEventListener( SelectionEvent.SELECTION_CHANGE, handleSelectionChange, false );
				_textFlow = null;
				_listenersAdded = false;
			}
		}
		
		/**
		 * @private 
		 * 
		 * Notifies clients of change through text flow.
		 */
		protected function notifyOfChange():void
		{
			var tf:TextFlow = getTextFlow();
			tf.dispatchEvent( new VariableEditEvent( VariableEditEvent.EDIT_CHANGE, this ) );
		}
		
		/**
		 * @private
		 * 
		 * Updates the false background display that exposes context menu. 
		 * @param target TextLine
		 * @param blockProgression String
		 */
		protected function updateInteractiveMenu( target:TextLine, blockProgression:String ):void
		{
			var bounds:Array = this.getSpanBoundsOnLine( target, blockProgression );
			
			_menuInteractiveObject.graphics.clear();
			_menuInteractiveObject.graphics.lineStyle( 1, 0x666666 );
			_menuInteractiveObject.graphics.beginFill( 0xDDDDDD, 0.3 );
			var rect:Rectangle;
			for( var i:int = 0; i < bounds.length; i++ )
			{
				rect = bounds[i] as Rectangle;
				_menuInteractiveObject.graphics.drawRect( rect.x - 1, rect.y - 4, rect.width + 2, rect.height + 4 );
			}
		}
		
		/**
		 * @private
		 * 
		 * Event handle for edit request. 
		 * @param event ContextMenuEvent
		 */
		protected function handleEditItem(event:ContextMenuEvent):void
		{
			var tf:TextFlow = getTextFlow();
			tf.dispatchEvent( new VariableEditEvent( VariableEditEvent.EDIT_VARIABLE, this ) );
		}
		
		/**
		 * @private
		 * 
		 * Event handler fro change in selection on text flow. Checks to see if selection is included fro this element and draws selection to include the whole eleemnt instead of part of it. 
		 * @param evt SelectionEvent
		 */
		protected function handleSelectionChange( evt:SelectionEvent ):void
		{
			if( getTextFlow() == null ) return;
			
			var selStart:int = evt.selectionState.absoluteStart;
			var selEnd:int = evt.selectionState.absoluteEnd;
			var start:int = getAbsoluteStart() + 1;
			var end:int = getAbsoluteStart() + textLength;
			var selectionState:SelectionState = getTextFlow().interactionManager.getSelectionState();
			var isRightToLeft:Boolean = ( selectionState.activePosition < selectionState.anchorPosition );
			if( selStart >= start && selEnd <= end )
			{
				selectionState.anchorPosition = ( isRightToLeft ) ? end : start - 1;
				selectionState.activePosition = ( isRightToLeft ) ? start - 1 : end;
				getTextFlow().interactionManager.setSelectionState( selectionState );
			}
			else if( selStart < start && ( selEnd >= start && selEnd <= end ) )
			{
				selectionState.anchorPosition = ( isRightToLeft ) ? end : Math.min( selStart, start - 1 );
				selectionState.activePosition = ( isRightToLeft ) ? Math.min( start - 1, selStart ) : end;
				getTextFlow().interactionManager.setSelectionState( selectionState );
			} 
			else if( selStart >= start && selStart < end )
			{
				selectionState.anchorPosition = ( isRightToLeft ) ? Math.max( selEnd, end ) : start - 1;
				selectionState.activePosition = ( isRightToLeft ) ? start - 1 : Math.max( selEnd, end );
				getTextFlow().interactionManager.setSelectionState( selectionState );
			}
		}
		
		/**
		 * @inherit
		 * Override to update members.
		 */
		override tlf_internal function updateAdornments(line:TextFlowLine, blockProgression:String):int
		{
			var tLine:TextLine = line.getTextLine(true);
			addContextMenu( tLine );
			updateInteractiveMenu( tLine, blockProgression );
			
			return super.updateAdornments( line, blockProgression );
		}
		
		/**
		 * @inherit
		 * Override to perform specific operations based on changeType.
		 */
		tlf_internal override function modelChanged(changeType:String, changeStart:int, changeLen:int, needNormalize:Boolean = true, bumpGeneration:Boolean = true):void
		{
			super.modelChanged( changeType, changeStart, changeLen, needNormalize, bumpGeneration );
			switch( changeType )
			{
				case ModelChange.ELEMENT_ADDED:
					initialize();
					break;
				case ModelChange.ELEMENT_REMOVAL:
					clean();
					break;
			}
		}
		
		/**
		 * @inherit
		 * Override to initialize this element upon delayed update.
		 */
		tlf_internal override function appendElementsForDelayedUpdate(tf:TextFlow):void
		{ 
			super.appendElementsForDelayedUpdate( tf );
			initialize();
		}
		
		/**
		 * Accessor/Modifier for textual content associated with this element. 
		 * @return String
		 */
		public function get textContent():String
		{
			return text;
		}
		public function set textContent( value:String ):void
		{
			this.replaceText( 0, textLength, value );
			var tf:TextFlow = getTextFlow();
			tf.dispatchEvent( new VariableEditEvent( VariableEditEvent.EDIT_CHANGE, this ) );
		}
	}
}