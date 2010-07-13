package flashx.textLayout.operations
{
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.container.AutosizableContainerController;
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.converter.IHTMLExporter;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.edit.ExtendedEditManager;
	import flashx.textLayout.edit.ParaEdit;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.edit.helpers.SelectionHelper;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.list.ListElementX;
	import flashx.textLayout.elements.list.ListItemElementX;
	import flashx.textLayout.elements.list.ListPaddingElement;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.ListUtil;
	
	use namespace tlf_internal;
	
	/**
	 * The BackspaceOperation is a subclass that removes a select range of text.
	 * 
	 * @author dominickaccattato
	 * 
	 */
	public class BackspaceOperation extends FlowTextOperation
	{
		private var interactionManager:ExtendedEditManager;
				
		protected var selectedLists:Array = new Array();
								
		/**
		 * 
		 * @param operationState
		 * @param interactionManager
		 * @param importer
		 * @param exporter
		 * 
		 */
		public function BackspaceOperation( operationState:SelectionState, interactionManager:ExtendedEditManager )
		{
			super( operationState );
			
			// Set the interaction manager so that we can reference it while deleting lists.
			this.interactionManager = interactionManager;
		}
				
		/**
		 * doOperation is called by ExtendedEditManager.
		 * 
		 * @return 
		 * 
		 */
		public override function doOperation():Boolean	{
						
			// We determine whether there are selected list items in
			// the selected range.  If there are we handle the deletion using
			// tlfx list deletion logic.  If there is no list content in the 
			// selected range we proceed with tlf default logic.
			if ( hasListSelected() ) {
				handleListDeletion();
			} else {
				handleDefaultDeletion();
			}
			
			return true;	
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */
		public override function undo():SelectionState
		{
			/*
			if( _listModeChange )
			{
			undoListModeChange();
			}
			else if( _listModeCreateOnTextFlow )
			{
			removeListFromTextFlow( _listCreatedOnTextFlow );
			}*/
			return originalSelectionState; 
		}
				
		/**
		 * 
		 * 
		 */
		private function handleListDeletion() : Boolean {
			// We will eventually need to get the absolute positions from the 
			// start and end ListItemElements.
			
			if ( isCaretSelection() ) {
				deleteListByCaret();
			} else {
				deleteListByRange();
			}
			
			return true;
		}
		
		/**
		 * Delete content that contains no lists 
		 * Instead of calling super.keyDownHanlder(event) we just call the correct function
		 * the function name "deletePreviousCharacter" is actually misleading. It leads the developer
		 * to believe that it will only delete the previous single character. However, in the operation
		 * we can see that it also will delete a text range if there is a selection as compared to just
		 * a caret selection.
		 */
		private function handleDefaultDeletion() : void {
			interactionManager.deletePreviousCharacter(interactionManager.getSelectionState());
		}
						
		/**
		 * Delete the list by its caret selection.
		 * // rule 1: if the absoluteStart is <= startItem.actualStart then we can assume that we are
			// at the beginning of the item and should delete the entire item and move up to the previous 
			// item if one exists. If one doesn't exist, we should remove the list and move to the previous
			// paragraph and select it's last leaf FlowElement.
		 *  
		 * @return Returns the state of the operation. 
		 * 
		 */
		private function deleteListByRange() : Boolean {
			
			var selectedListItems:Array = SelectionHelper.getSelectedListItems( textFlow, true );
			// We use the helper class SelectionHelper to get the selected list items.
			// remember that we have access to the textFlow from the operationState that
			// was passed to the super class in our construction.
			// Using the same SelectionHelper we can also get a list of the Lists.
			var selectedLists:Array = SelectionHelper.getSelectedLists( textFlow );
			var startItem:ListItemElementX = selectedListItems[0] as ListItemElementX;
			var endItem:ListItemElementX = selectedListItems[selectedListItems.length-1] as ListItemElementX;
				var listStart:ListElementX = startItem.parent as ListElementX;
				var listEnd:ListElementX = endItem.parent as ListElementX;
	
				// First we retreive the start and end leaf elements. These SpanElements will 
			// help retreive their parent FlowGroupElements. 
			var flowLeafStart:FlowLeafElement = textFlow.findLeaf(absoluteStart);
			var flowLeafEnd:FlowLeafElement = textFlow.findLeaf(absoluteEnd);
			
			// Retreive the parent FlowGroupElement objects. These will help in 
			// determining if we are deleting from within a list or outside of a list.
			var flowGroupStart:FlowGroupElement = flowLeafStart.parent;
			var flowGroupEnd:FlowGroupElement = flowLeafEnd.parent;
			
			// correct the selection before we do any type of operations on the range of
			// selected text.
			//correctSelection();
			var ss:SelectionState = interactionManager.getSelectionState();
			var tmpItem:ListItemElementX;
			var originalActualStart:int = ss.absoluteStart;
			if(flowGroupStart is ListItemElementX) {
				tmpItem = flowGroupStart as ListItemElementX;
				originalActualStart = tmpItem.actualStart;
				
				if(ss.absoluteStart < tmpItem.actualStart) {
					deleteRange();
					interactionManager.setSelectionState(new SelectionState(textFlow, originalActualStart, originalActualStart));
					interactionManager.refreshSelection();
				} else {
					deleteRange();
				}
			}
			else 
			{
				deleteRange();
			}
			
			if(flowLeafStart.text == "") {
				ListUtil.cleanEmptyLists( textFlow );
				textFlow.flowComposer.updateAllControllers();
				return true;
			} 
			
			// is this a multi-deletion
			/*if(listStart == listEnd) {
				return true;
			}*/
			/*if(flow*/
			
			// are we starting the deletion inside of a list?
			if(flowGroupStart is ListItemElementX) {
				
				if(flowGroupEnd is FlowGroupElement) {
					// if listStart != listEnd then we know that we are doing a multi-list delete
					if(listStart != listEnd) {
						// we need to first check to see if the flow group is a ListItemElementX because
						// ListItemElementX extends ParagraphElement
						if(flowGroupEnd is ListItemElementX) {
							// join lists by first adding the first child of the flowGroupEnd
							var listItemEnd:ListItemElementX = ListItemElementX(listStart.listItems[listStart.listItems.length-1]);
							listItemEnd.addChild(flowGroupEnd.getChildAt(0));
							listEnd.removeChild(flowGroupEnd);
							// now add the remaining items from listEnd
							var initialChildrenLen:int = listEnd.listItems.length;
							
							// loop through the rest of the end lists children and add them
							// to the start lists children. Always make sure that when using
							// lists that you do not use the traditional getChildAt. Instead
							// you need to use the special array called "listItems".
							for(var i:int=0; i<=initialChildrenLen-1; i++) {
								listStart.addChild(listEnd.listItems[0]);
							}
							
							ListUtil.cleanEmptyLists( textFlow );
						}
						
					} else {
						var listItemEnd:ListItemElementX = ListItemElementX(listStart.listItems[listStart.listItems.length-1]);
						
						// since the ListItemElementX overrides addChild, we need to get the children before hand.  
						// This is because it actually shifts the children off of the previous flow element resulting
						// in the loop counter getting smaller and not finishing the rest of the children.
						var initialChildrenLen:int = flowGroupEnd.numChildren;
						
						// if we are deleting from within the same list, we just delete using the default tlf behavior]
						// FIXME: may not need this after we correct the selection.. let me try that first.
						/*if(flowGroupStart == flowGroupEnd) {
							if(flowGroupStart.textLength == 0) {
								flowGroupStart.parent.removeChild(flowGroupStart);
								ListUtil.cleanEmptyLists( textFlow );
								return;
							}
						}*/
						
						
						/*if(listStart.getChildIndex(flowGroupStart) == -1) {
							interactionManager.setSelectionState(new SelectionState(textFlow, tmpItem.actualStart, tmpItem.actualStart));
							interactionManager.refreshSelection();
						}*/
						
						// if each entire list item is selected, the we should not append any children.
						// instead we just need to delete and move the cursor up to the end of the previoius element
						if(listStart.getChildIndex(flowGroupStart) == -1) {
							var tmpFlowGroupEnd:ListItemElementX = flowGroupEnd as ListItemElementX;
							if(tmpFlowGroupEnd.text == "") {
								listStart.removeChild(tmpFlowGroupEnd);
								interactionManager.setSelectionState(new SelectionState(textFlow, this.absoluteStart-1, this.absoluteStart-1));
								interactionManager.refreshSelection();
							}
							ListUtil.cleanEmptyLists( textFlow );
														
							// need to create one item
							if(textFlow.numChildren < 1) {
								//var div:DivElement = new DivElement();
								//ParaEdit.createElement(new ParagraphElement(), 0, "ParagraphElement", interactionManager.
								var para:ParagraphElement = new ParagraphElement();
								var span:SpanElement = new SpanElement();
								span.text = "";
								para.addChild(span);
								
								//div.addChild(para);
								textFlow.addChild(para);
								textFlow.flowComposer.updateAllControllers();
								interactionManager.setSelectionState(new SelectionState(textFlow, absoluteStart, absoluteStart));
								interactionManager.refreshSelection();
								
								var container:AutosizableContainerController = ListUtil.findDefaultContainerController(para);
								container.addMonitoredElement(para);
							}
							
							//textFlow.flowComposer.updateAllControllers();
							return true;
						}
						
						/*
						if(listStart.getChildIndex(flowGroupStart) == -1) {
						var tmpFlowGroupEnd:ParagraphElement = flowGroupEnd as ParagraphElement;
						if(tmpFlowGroupEnd.textLength == 0) {
						listStart.removeChild(tmpFlowGroupEnd);
						interactionManager.setSelectionState(new SelectionState(textFlow, this.absoluteStart-1, this.absoluteStart-1));
						interactionManager.refreshSelection();
						}
						ListUtil.cleanEmptyLists( textFlow );
						textFlow.flowComposer.updateAllControllers();
						return true;
						}
						*/
						
						var fe:ListItemElementX;
						for(var i:int=0; i<initialChildrenLen; i++) {
							fe = listItemEnd.addChild(flowGroupEnd.getChildAt(0)) as ListItemElementX;
						}

					}				
				} 
				
				textFlow.flowComposer.updateAllControllers();
				
				ListUtil.cleanEmptyLists( textFlow );
				
				/*if(textFlow.numChildren < */
				
				listStart.update();
			}
			
			return true;
		}
					
		protected function findContainerControllerForElement( element:FlowElement ):AutosizableContainerController
		{
			var tf:TextFlow = element.getTextFlow();
			var i:int;
			var cc:ContainerController;
			var acc:AutosizableContainerController;
			for ( i = 0; i < tf.flowComposer.numControllers; i++ )
			{
				cc = tf.flowComposer.getControllerAt(i);
				if ( cc is AutosizableContainerController )
				{
					acc = cc as AutosizableContainerController;
					if ( acc.containsMonitoredElement( element ) )
						return acc;
				}
			}
			return null;
		}
		
		/**
		 * 
		 * 
		 */
		private function deleteRange() : void {
			var deleteFrom:int = Math.max(0, absoluteStart);
			var deleteTo:int = Math.min(absoluteEnd, textFlow.textLength-1);
			
			try {
				interactionManager.deleteText( new SelectionState( textFlow, deleteFrom, deleteTo ) );//absoluteStart, i ) );
			} catch ( e:* ) {
				trace( '[KK] {' + getQualifiedClassName(this) + '} :: Could not delete from position ' + deleteFrom + ' to position ' + deleteTo + ' on ' + textFlow + ' because:\n\t' + e);
				textFlow.flowComposer.updateAllControllers();
			}
		}
		
		/**
		 * @private
		 * 
		 * Adds the list to be monitored by the specified autosizable container controller for resizing of layout. 
		 * @param element FlowElement
		 * @param containerController AutosizableContainerController
		 */
		protected function addElementToAutosizableContainerController( element:FlowElement, containerController:AutosizableContainerController ):void
		{
			// Monitor element in autosizable container controller associated with sibling.
			if( containerController ) containerController.addMonitoredElement( element );
		}
				
		/**
		 * Delete the list by its caret selection.
		 *  
		 * @return Returns the state of the operation. 
		 * 
		 */
		private function deleteListByCaret() : Boolean {
			
			// First we retreive the start and end leaf elements. These SpanElements will 
			// help retreive their parent FlowGroupElements. 
			var flowLeafStart:FlowLeafElement = textFlow.findLeaf(absoluteStart);
			var flowLeafEnd:FlowLeafElement = textFlow.findLeaf(absoluteEnd);
			
			// Retreive the parent FlowGroupElement objects. These will help in 
			// determining if we are deleting from within a list or outside of a list.
			var flowGroupStart:ListItemElementX = flowLeafStart.parent as ListItemElementX;
			var flowGroupEnd:FlowGroupElement = flowLeafEnd.parent;
			
			var tmp:int = flowGroupStart.getAbsoluteStart() + flowGroupStart.seperatorLength;
			
			if(absoluteStart > flowGroupStart.actualStart) {
				handleDefaultDeletion();
			} else {
				trace("check this out");
				//handleDeleteSymbol();
				
				// check to see the item contains content.  This can happen if the cursor is at the front of 
				// the item but there is text afterwards. We add 1 to the seperatorLenth to account for the space.
				if(flowGroupStart.textLength - (flowGroupStart.seperatorLength+1) > 0) {
					
					// we need to move the rest of its contents to a previous bullet or a previous paragraphElement
					var remainingElements:Array = flowGroupStart.mxmlChildren.slice(1);
					var selectionState:SelectionState = new SelectionState(textFlow, flowGroupStart.getAbsoluteStart()-1, flowGroupStart.getAbsoluteStart()-1);			
					interactionManager.setSelectionState(selectionState);
					interactionManager.refreshSelection();
					
					// get the previous leaf which we will end up using to
					// append the remaining items
					var leaf:FlowLeafElement = getPreviousElement(flowGroupStart);
					
					// last we remove the item
					flowGroupStart.parent.removeChild(flowGroupStart);
					
					for(var i:int=0; i<remainingElements.length; i++) {
						leaf.parent.addChild(remainingElements[i]);
					}
					
				} else {
					var selectionState:SelectionState = new SelectionState(textFlow, flowGroupStart.getAbsoluteStart()-1, flowGroupStart.getAbsoluteStart()-1);			
					interactionManager.setSelectionState(selectionState);
					flowGroupStart.parent.removeChild(flowGroupStart);
				}
				
				ListUtil.cleanEmptyLists(textFlow);
			}
			
			// delete selected range
			/*deleteRange();
			
			var selectedListItems:Array = SelectionHelper.getSelectedListItems( textFlow, true );
			// We use the helper class SelectionHelper to get the selected list items.
			// remember that we have access to the textFlow from the operationState that
			// was passed to the super class in our construction.
			// Using the same SelectionHelper we can also get a list of the Lists.
			var selectedLists:Array = SelectionHelper.getSelectedLists( textFlow );
			var startItem:ListItemElementX = selectedListItems[0] as ListItemElementX;
			var list:ListElementX = startItem.parent as ListElementX;
			var start:int = list.getChildIndex( startItem );
			
			// FIXME: what does this stand for??? I believe it is Text Length
			var tl:int;
			
			var item:ListItemElementX;
			var prevItem:ListItemElementX;
			
			// If the absoluteStart is less than or equal to startItem.actualStart then we can
			// deduce that we have the caret at the start of a list item.
			if ( absoluteStart <= startItem.actualStart )
			{
				// First we need to check to see if we can join to an existing list previous in
				// the text flow. We do this by checking to see if the previous element in
				// a ListElementX.
				if( canJoinList(list) ) {
					joinLists(list);					
				}
				
				//	Add new list after current list
				var newList:ListElementX = new ListElementX();
				list.parent.addChildAt( list.parent.getChildIndex(list)+1, newList );
				
				//	Switch all children AFTER the start child to the new list
				for (var i:int = list.numChildren-1; i > start; i-- )
				{
					if ( list.getChildAt(i) is ListItemElementX )
						newList.addChildAt(0, list.removeChildAt(i));
				}
				
				newList.update();
				
				//	Add new paragraph right after current list
				var p:ParagraphElement = new ParagraphElement();
				list.parent.addChildAt( list.parent.getChildIndex(list)+1, p );
				
				//	Transfer children
				extractChildrenToParagraphElement( startItem, p );
				
				//	Remove original child
				startItem.parent.removeChild(startItem);
				
				// as percautionary we delete any empty lists
				ListUtil.cleanEmptyLists( textFlow );
			}
				//	If the startItem does not have any text, we need to ... FIXME
			else if ( startItem.text.length == 0 )
			{
				if ( start-1 < 0 )
				{
					var i:int = 0;
					while ( i++ < list.numChildren )
					{
						if ( list.getChildAt(i) is ListItemElementX )
						{
							prevItem = list.getChildAt(i) as ListItemElementX;
							break;
						}
					}
					interactionManager.setSelectionState( new SelectionState( textFlow, prevItem.actualStart, prevItem.actualStart ));
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
					
					interactionManager.setSelectionState( new SelectionState( textFlow, prevItem.actualStart + tl, prevItem.actualStart + tl ) );
				}
			}
			else
			{
				// Just handle the backspace normally.
				handleDefaultDeletion();
				return true;
			}*/
			
			return true;
		}
		
		/**
		 * 
		 * @param element
		 * @return 
		 * 
		 */
		private function getPreviousElement(element:ListItemElementX) : FlowLeafElement {
			var relativePosition:int = element.getAbsoluteStart() - element.seperatorLength - 1;
			return textFlow.findLeaf(relativePosition);
		}
		
		private function joinLists(currentList:ListElementX) : Boolean {
			var prevElement:FlowElement = currentList.parent.getChildAt( currentList.parent.getChildIndex(currentList)-1 );					
			var previousList:ListElementX = prevElement as ListElementX;
			var item:ListItemElementX;
			
			var listInsertIdx:int;
			
			// Loop through the previous list to find it's 
			// end index.  
			// FIXME: why can't we just get numChildren - 1????
			for (var i:int = previousList.numChildren-1; i > -1; i-- )
			{
				if ( previousList.getChildAt(i) is ListItemElementX )
				{
					listInsertIdx = i+1;
					break;
				}
			}
			
			//	Merge current list to the previous list
			for (var j:int = currentList.numChildren-1; j > -1; j-- )
			{
				if ( currentList.getChildAt(j) is ListItemElementX )
					previousList.addChildAt( listInsertIdx ? listInsertIdx : previousList.numChildren, currentList.removeChildAt(j) as ListItemElementX );
			}
			
			// remove the current list as we are now merged and do not
			// need it anymore.
			currentList.parent.removeChild( currentList );
			
			// FIXME: should move the selection stuff out of this function
			item = previousList.getChildAt(listInsertIdx-1) as ListItemElementX;
			interactionManager.setSelectionState( new SelectionState( textFlow, item.actualStart + item.modifiedTextLength, item.actualStart + item.modifiedTextLength ) );
			interactionManager.textFlow.flowComposer.updateAllControllers();
			return true;
		}
		
		
		/**
		 * Determines if lists can join sibling lists.
		 *  
		 * @param list
		 * @return 
		 * 
		 */
		private function canJoinList(list:ListElementX) : Boolean {
			var prevElement:FlowElement = list.parent.getChildAt( list.parent.getChildIndex(list)-1 );
			return (prevElement != null && prevElement is ListElementX);
		}
		
		/**
		 * Helper function that returns whether there is a selection being deleted
		 * or just a caret delete. If absoluteStart is equal to absoluteEnd we can assume that there is no selection and
		 * we should delete according to the following rules. 
		 * 
		 * @return 
		 * 
		 */
		private function isCaretSelection() : Boolean {
			return (absoluteStart == absoluteEnd);
		}
		
		/**
		 * A helper function that determines if a list is in the selected range. 
		 * @return 
		 * 
		 */
		private function hasListSelected() : Boolean {
			var selectedListItems:Array = SelectionHelper.getSelectedListItems( textFlow, true );
			
			// if their are list items in the selected range we return true
			if(selectedListItems.length > 0) {
				return true;
			}
			
			// by default we return false indicating that we are not in a list
			return false;			
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
				
				try {
					to.addChildAt( addAt, child );
				} catch ( e:* ) {
					trace(e, "child:", child, "target:", to);
				}
			}
		}
		
	}
}