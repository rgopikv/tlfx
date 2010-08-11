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
	import flashx.textLayout.elements.ListElement;
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
			
			// are we in a list. if so, go to current logic below
			
			// if we aren't in a list, what are we currently in.
			// are we in a Div, Para, Table
			
			// if its a table do nothing
			
			/*var prevElement:FlowElement = (textFlow.findLeaf(Math.max(0, absoluteStart-1)).parent) as ListPaddingElement;
			
			if(prevElement is ListPaddingElement) {
			
			var operationState:SelectionState = interactionManager.getSelectionState();
			
			//interactionManager.selectRange(absoluteStart-2, absoluteEnd+2);
			interactionManager.setSelectionState(new SelectionState(textFlow, prevElement.getAbsoluteStart()-1, absoluteEnd));
			interactionManager.refreshSelection();
			
			prevElement = textFlow.findLeaf(interactionManager.absoluteStart).parent;
			//return true;
			}*/
			
			// We determine whether there are selected list items in
			// the selected range.  If there are we handle the deletion using
			// tlfx list deletion logic.  If there is no list content in the 
			// selected range we proceed with tlf default logic.
			//if ( hasListSelected() /*|| prevElement*/) {
			//	handleListDeletion();
			//} else {
			//handleDefaultDeletion();
			//}
			
			if(isCaretSelection()) {
				handleCaretDeletion();
				// are we working on a ListItemElemenX
				//handleDefaultDeletion(); 
			} else {
				handleRangeDeletion();
			}
			
			ListUtil.cleanEmptyLists( textFlow );
			
			return true;	
		}
		
		private function handleCaretDeletion() : void {
			
			// get the operation state
			var operationState:SelectionState = interactionManager.getSelectionState();
			
			// get the current leaf
			var fle:FlowGroupElement = textFlow.findLeaf(operationState.absoluteStart).parent;
			
			// check to see if this is a ListItemX
			if(fle is ListItemElementX) {
				
				// if activepositin is greater than the list item
				// then we can use default deletion
				if(operationState.activePosition > (fle as ListItemElementX).actualStart) {
					deleteText();
				} else {
					
					// remove the current item. however if there is remaining elements
					// we need to join them to the previous child.  if we are at the first
					// item of a list then this would mean appending them to the previous paragraph 
					// if one exists.  If one does not exist, we need to create one and append it to 
					// the newly created element.
					
					// we can handle deleting the separator using the handleRangeDeletion function
					
					// retrieve the separator length
					operationState.anchorPosition = fle.getAbsoluteStart() - 1;
					operationState.activePosition = fle.getAbsoluteStart() + (fle as ListItemElementX).seperatorLength-1;
					interactionManager.setSelectionState(operationState);
					
					// if this is the first child, we just need to pop it off. however there is the use case 
					// where two lists join if they are above and below.
					if(fle.parent.getChildIndex(fle) == 0) {
						
						if(fle.parent is ListElementX) {
							var currentList:ListElementX = fle.parent as ListElementX;
							
							if(canJoinList(currentList)) {
								joinLists(currentList);
								return;
							}
						}
					//	if(fle.parent.getPreviousSibling() != null) {
							var para:ParagraphElement = new ParagraphElement();
							fle.removeChildAt(0);
							var initialChildren:int = (fle.mxmlChildren) ? fle.mxmlChildren.length : 0;
							
							var spanExists:Boolean = (fle.getChildAt(0) as SpanElement);
							
							var tf:TextFlow = fle.getTextFlow();
							tf.addChildAt(tf.getChildIndex(fle.parent), para);
							
							var paraAbsEnd:int = para.getAbsoluteStart() + para.textLength-1;
							
							for(var i:int=0; i< initialChildren; i++) {
								//if(i==0) continue;
								para.addChild(fle.getChildAt(0));
							}
							
							fle.parent.removeChild(fle);
							if(initialChildren == 0) {
								para.addChild(new SpanElement());
								tf.flowComposer.updateAllControllers();
								trace("**abs: " + para.getAbsoluteStart());
								trace("**: " + para.textLength);
								paraAbsEnd = para.getAbsoluteStart() + para.textLength-1;
							}
							
							operationState.activePosition = paraAbsEnd;
							operationState.anchorPosition = paraAbsEnd;
							
							//operationState.activePosition = operationState.anchorPosition;
							interactionManager.setSelectionState(operationState);
							interactionManager.refreshSelection();
					//	}
						
						return;
					}
					
					// now we can handle the range deletion like so
					handleRangeDeletion();
					
					//paraAbsEnd = para.getAbsoluteStart() + para.textLength-1;
					operationState.activePosition = operationState.anchorPosition;
					interactionManager.setSelectionState(operationState);
					interactionManager.refreshSelection();
				}
			} else {
				
				// we can now deduce that we are in a non ListItemElementX. it may be possible that
				// we have entered into the ListPaddingElementX. in fact, this probably the case. so 
				// check to see if we are in a padding element.
				
				var flePreviousSibling:ListElementX = fle.getPreviousSibling() as ListElementX;
				
				if(!flePreviousSibling) {
					if(fle.parent is DivElement) {
						flePreviousSibling = fle.parent.getPreviousSibling() as ListElementX;
					}
				}
			//	var tmp:* = fle.getPreviousSibling();
				//var areWeAtEnd:Boolean = fle.getAbsoluteStart()
				trace("operationState.absoluteStart: " + operationState.absoluteStart);
				trace("fle.getAbsoluteStart(): " + fle.getAbsoluteStart());
				
				//*******************'
				// *******************
				// This may be due to the fact that it's in a div
				// if that's the case then it will be null
				// we need to look at it's parent
				if(flePreviousSibling && operationState.absoluteStart <= fle.getAbsoluteStart()) {
					// if the previous sibling is a list, just set it to the absolute end
					operationState.absoluteStart = flePreviousSibling.getAbsoluteStart() + flePreviousSibling.textLength - 1;
					operationState.absoluteEnd = flePreviousSibling.getAbsoluteStart() + flePreviousSibling.textLength - 1;
					interactionManager.setSelectionState(operationState);
					interactionManager.refreshSelection();
					
					//flePreviousSibling.update();
				} else {
					//					var newPos:int = flePreviousSibling.getAbsoluteStart() + flePreviousSibling.textLength;
					//					operationState.activePosition = newPos;
					//					interactionManager.refreshSelection();
					//					//handleRangeDeletion();
					//				} else {
					this.deleteText();	
					//				}
				}
			}
		}
		
		private function handleRangeDeletion() : void {
			
			var selectedLists:Array = SelectionHelper.getSelectedLists( textFlow );
			var startList:ListElementX = selectedLists[0] as ListElementX;
			
			// if there are lists selected we need to get access to the top
			// level list
			if(startList) {
				if(isOperatingWithinSingleList(startList)) {
					// we delete the text by default in a range deletion
					deleteText();			
				} else {
					// loop through and add remaining children to the last item
					// find the leaf at the current absolute position.
					if(startList) {
						joinElements();
					}
				}
			}
			
			
			if(selectedLists.length > 0) {
				for(var i:String in selectedLists) {
					
					var list:ListElementX = selectedLists[i] as ListElementX;
					
					if(list) {
						trace("updating list: " + i);
						list.update();
					}
				}
			} else {
				deleteText();
			}
			
			//textFlow.flowComposer.updateAllControllers();
		}
		
		/**
		 * 
		 * @param element
		 * 
		 */
		private function joinElements() : void {
			// we delete the text by default in a range deletion
			deleteText();
			
			// get selection operation
			var operationState:SelectionState = interactionManager.getSelectionState();
			
			// we need to subtract 2 from the numChildren to account for 
			// the ListPaddingElement added to the end of the List
			var fe1:FlowGroupElement = textFlow.findLeaf(operationState.absoluteStart).parent;
			var fe2:FlowGroupElement = textFlow.findLeaf(operationState.absoluteEnd+1).parent;
			
			// loop through all of the remaining children and join them to 
			// the existing flow group element. we need to get the initial
			// amount of children since the addChild is overriden and slices
			// the children.
			var initialChildren:int = fe2.numChildren;
			
			for(var i:int=0; i < initialChildren; i++) {
				fe1.addChild(fe2.getChildAt(0));
			}
			
			// remove the dangling paragraph
			fe2.parent.removeChild(fe2);
		}
		
		/**
		 * Helper function that determines if we are deleting within a single list. 
		 * If we are deleting within a single list, we do not need to loop through
		 * and add remaining children to the last list item.  
		 * 
		 * @param list
		 * @return 
		 * 
		 */
		private function isOperatingWithinSingleList(list:ListElementX) : Boolean{
			if(list) {
				
				// get the selection state
				var operatingState:SelectionState = interactionManager.getSelectionState();
				
				// we now know that we have the top level list
				// we need to find out if we are deleting within the list.
				// If we are deleting within the list, we do not need to add
				// remaining span elements to the last item.
				trace(list.getAbsoluteStart());
				trace((list.getAbsoluteStart() + list.textLength));
				trace("absStart: " + operatingState.absoluteStart);
				trace("absend: " + operatingState.absoluteEnd );
				if(operatingState.absoluteStart > list.getAbsoluteStart()  && 
					
					// we subtract 2 to account for the padding element and the 0 based index
					operatingState.absoluteEnd < (list.getAbsoluteStart() + list.textLength)) {
					
					// we now know that we are operating within one list
					return true;
				}
			}
			
			return false;
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
		private function deleteText() : void {
			interactionManager.deletePreviousCharacter(originalSelectionState);
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
			
			var operationState:SelectionState = interactionManager.getSelectionState();
			
			// if we are moving into a padding element we need to use our select range function
			var currentElement:FlowGroupElement = textFlow.findLeaf(absoluteStart).parent;
			var previousSibling:FlowGroupElement = currentElement.getPreviousSibling() as FlowGroupElement;
			
			// get the actual parent
			if(!previousSibling) {
				// we must be in a div, so we need tto get the actual parent
				if(currentElement.parent) {
					previousSibling = currentElement.parent.getPreviousSibling() as FlowGroupElement;
					if(!previousSibling) {
						trace("no previous sibling");
						//return;
					}
				}
			}
			
			
			if(absoluteStart <= currentElement.getAbsoluteStart()) {
				if(previousSibling is ListElementX) {
					// since the previousSibling is a ListElementX we know that
					// there is a ListItemElementX above so we get a reference to that
					// we need to subtract by 2 to account for the padding
					var lastListItem:ListItemElementX = previousSibling.getChildAt(previousSibling.numChildren-2) as ListItemElementX;
					
					if(lastListItem) {
						operationState.activePosition = lastListItem.getAbsoluteStart() + lastListItem.textLength - 1;
						interactionManager.setSelectionState(operationState)
						interactionManager.refreshSelection();
						// now we can use our handlerange deletion function
						handleRangeDeletion();
						return;
					}
				}
			} else {
				//interactionManager.deletePreviousCharacter(interactionManager.getSelectionState());
			}
			
			//var operationState:SelectionState = interactionManager.getSelectionState();
			deleteText();
			//var deleteOperation:DeleteTextOperation = new DeleteTextOperation(operationState, operationState, true);
			//var success:Boolean = deleteOperation.doOperation();
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
			var operationState:SelectionState = interactionManager.getSelectionState();
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
			var flowLeafStart:FlowLeafElement = textFlow.findLeaf(operationState.absoluteStart);
			var flowLeafEnd:FlowLeafElement = textFlow.findLeaf(operationState.absoluteEnd);
			
			// Retreive the parent FlowGroupElement objects. These will help in 
			// determining if we are deleting from within a list or outside of a list.
			var flowGroupStart:FlowGroupElement = flowLeafStart.parent;
			var flowGroupEnd:FlowGroupElement = flowLeafEnd.parent;
			
			var listItemEnd:ListItemElementX;
			
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
			
			// are we starting the deletion inside of a list?
			if(flowGroupStart is ListItemElementX) {
				var initialChildrenLen:int;
				
				if(flowGroupEnd is FlowGroupElement) {
					// if listStart != listEnd then we know that we are doing a multi-list delete
					if(listStart != listEnd) {
						// we need to first check to see if the flow group is a ListItemElementX because
						// ListItemElementX extends ParagraphElement
						if(flowGroupEnd is ListItemElementX) {
							// join lists by first adding the first child of the flowGroupEnd
							listItemEnd = ListItemElementX(listStart.listItems[listStart.listItems.length-1]);
							listItemEnd.addChild(flowGroupEnd.getChildAt(0));
							listEnd.removeChild(flowGroupEnd);
							// now add the remaining items from listEnd
							initialChildrenLen = listEnd.listItems.length;
							
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
						listItemEnd = ListItemElementX(listStart.listItems[listStart.listItems.length-1]);
						
						// since the ListItemElementX overrides addChild, we need to get the children before hand.  
						// This is because it actually shifts the children off of the previous flow element resulting
						// in the loop counter getting smaller and not finishing the rest of the children.
						initialChildrenLen = flowGroupEnd.numChildren;
						
						// if each entire list item is selected, the we should not append any children.
						// instead we just need to delete and move the cursor up to the end of the previoius element
						if(listStart.getChildIndex(flowGroupStart) == -1) {
							var tmpFlowGroupEnd:ListItemElementX = flowGroupEnd as ListItemElementX;
							if(tmpFlowGroupEnd.text == "") {
								listStart.removeChild(tmpFlowGroupEnd);
								interactionManager.setSelectionState(new SelectionState(textFlow, operationState.absoluteStart-1, operationState.absoluteStart-1));
								interactionManager.refreshSelection();
							}
							ListUtil.cleanEmptyLists( textFlow );
							
							// need to create one item
							if(textFlow.numChildren < 1) {
								var para:ParagraphElement = new ParagraphElement();
								var span:SpanElement = new SpanElement();
								span.text = "";
								para.addChild(span);
								
								textFlow.addChild(para);
								textFlow.flowComposer.updateAllControllers();
								interactionManager.setSelectionState(new SelectionState(textFlow, operationState.absoluteStart, operationState.absoluteStart));
								interactionManager.refreshSelection();
								
							}
							
							return true;
						}
						
						var fe:ListItemElementX;
						
						if(flowGroupStart != flowGroupEnd) {
							for(var j:int=0; j<initialChildrenLen; j++) {
								fe = listItemEnd.addChild(flowGroupEnd.getChildAt(0)) as ListItemElementX;
							}
						}
						
					}				
				} 
				
				textFlow.flowComposer.updateAllControllers();
				
				ListUtil.cleanEmptyLists( textFlow );
				
				listStart.update();
			}
			
			return true;
		}
		
		/**
		 * 
		 * 
		 */
		private function deleteRange() : void {
			var operationState:SelectionState = interactionManager.getSelectionState();
			var deleteFrom:int = Math.max(0, operationState.absoluteStart);
			var deleteTo:int = Math.min(operationState.absoluteEnd, textFlow.textLength-1);
			
			try {
				interactionManager.deleteText( new SelectionState( textFlow, deleteFrom, deleteTo ) );//absoluteStart, i ) );
			} catch ( e:* ) {
				trace( '[KK] {' + getQualifiedClassName(this) + '} :: Could not delete from position ' + deleteFrom + ' to position ' + deleteTo + ' on ' + textFlow + ' because:\n\t' + e);
				textFlow.flowComposer.updateAllControllers();
			}
		}
		
		protected function findContainerControllerForElement( element:FlowElement ):AutosizableContainerController
		{
			/*var tf:TextFlow = element.getTextFlow();
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
			}*/
			return null;
		}
		
		/**
		 * Delete the list by its caret selection.
		 *  
		 * @return Returns the state of the operation. 
		 * 
		 */
		private function deleteListByCaret() : Boolean {
			
			var operationState:SelectionState = interactionManager.getSelectionState();
			var selectedLists:Array = SelectionHelper.getSelectedLists( textFlow );
			var list:ListElementX = selectedLists[0] as ListElementX;
			
			//if(
			
			// First we retreive the start and end leaf elements. These SpanElements will 
			// help retreive their parent FlowGroupElements. 
			var flowLeafStart:FlowLeafElement = textFlow.findLeaf(operationState.absoluteStart);
			var flowLeafEnd:FlowLeafElement = textFlow.findLeaf(operationState.absoluteEnd);
			
			// Retreive the parent FlowGroupElement objects. These will help in 
			// determining if we are deleting from within a list or outside of a list.
			var flowGroupStart:ListItemElementX = flowLeafStart.parent as ListItemElementX;
			var flowGroupEnd:FlowGroupElement = flowLeafEnd.parent;
			
			/*var tmp:int = flowGroupStart.getAbsoluteStart() + flowGroupStart.seperatorLength;*/
			
			if(operationState.absoluteStart > flowGroupStart.actualStart) {
				handleDefaultDeletion();
			} else {
				trace("check this out");
				//handleDeleteSymbol();
				
				var selectionState:SelectionState;
				
				// check to see the item contains content.  This can happen if the cursor is at the front of 
				// the item but there is text afterwards. We add 1 to the seperatorLenth to account for the space.
				if(flowGroupStart.textLength - (flowGroupStart.seperatorLength+1) > 0) {
					
					// we need to move the rest of its contents to a previous bullet or a previous paragraphElement
					var remainingElements:Array = flowGroupStart.mxmlChildren.slice(1);
					selectionState = new SelectionState(textFlow, flowGroupStart.getAbsoluteStart()-1, flowGroupStart.getAbsoluteStart()-1);			
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
					selectionState = new SelectionState(textFlow, flowGroupStart.getAbsoluteStart()-1, flowGroupStart.getAbsoluteStart()-1);			
					interactionManager.setSelectionState(selectionState);
					flowGroupStart.parent.removeChild(flowGroupStart);
				}
				
			}
			
			ListUtil.cleanEmptyLists( textFlow );
			
			list.update();
			
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
			
			// update previuos list
			previousList.update();
			
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
			var operationState:SelectionState = interactionManager.getSelectionState();
			return (operationState.absoluteStart == operationState.absoluteEnd);
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