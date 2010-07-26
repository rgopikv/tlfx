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
			
			 
			
			if(isClearEditor()) {
				deleteText();
				ListUtil.cleanEmptyLists( textFlow );
				
				// get the operation state
				var operationState:SelectionState = interactionManager.getSelectionState();
				return true;
			}
				
				
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
		
		private function isClearEditor() : Boolean {
			// get the operation state
			var operationState:SelectionState = interactionManager.getSelectionState();
			
			trace(textFlow.getAbsoluteStart());
			trace(operationState.absoluteStart);
			trace((textFlow.getAbsoluteStart() + textFlow.textLength)-1);
			trace(operationState.absoluteEnd);
			if(textFlow.getAbsoluteStart() == operationState.absoluteStart && (textFlow.getAbsoluteStart() + textFlow.textLength)-1 == operationState.absoluteEnd) {
				return true;
			}
			
			return false;
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

					// if this is thfirst child, we just need to pop it off
					if(fle.parent.getChildIndex(fle) == 1) {
						handleFirstListItemDeletion();						
					} else {
						selectNestingSymbol(fle);
						handleRangeDeletion();
					}
					
					return;
					
				}
			} else {
				
				// we can now deduce that we are in a non ListItemElementX. it may be possible that
				// we have entered into the ListPaddingElementX. in fact, this probably the case. so 
				// check to see if we are in a padding element.
				var padding:ListPaddingElement = (fle as ListPaddingElement);
				
				if(padding) {
					
				} else {
					handleDefaultDeletion();
				}
			}
			
			
		}
		
		private function selectNestingSymbol(fe:FlowElement) : void {
			// get the operation state
			var operationState:SelectionState = interactionManager.getSelectionState();
			
			// retrieve the separator length
			operationState.anchorPosition = fe.getAbsoluteStart() - 1;
			operationState.activePosition = fe.getAbsoluteStart() + (fe as ListItemElementX).seperatorLength - 1;
			interactionManager.setSelectionState(operationState);
			interactionManager.refreshSelection();
		}
				
		/**
		 * Deletes the first list item from a list. 
		 * 
		 */
		private function handleFirstListItemDeletion() : void {
			
			// get the operation state
			var operationState:SelectionState = interactionManager.getSelectionState();
			
			// get the current leaf
			var fle:FlowGroupElement = textFlow.findLeaf(operationState.absoluteStart).parent;
			
			// check to see if there is a previous sibling. this is needed so that we can 
			// move the children from the current item to the previous paragraph or div.
			//if(fle.parent.getPreviousSibling() != null) {
			var para:ParagraphElement = new ParagraphElement();
			
			// fle should be a ListitemElementX so we will need to remove its starting symbol
			// and the seperator space between the symbol and the text.
			fle.removeChildAt(0);
			
			// we need to get the initial length of the children because this 
			// will decrease as we call addChild below.
			var initialChildren:int = (fle.mxmlChildren) ? fle.mxmlChildren.length : 0;
			
			//var spanExists:Boolean = (fle.getChildAt(0) as SpanElement);
			
			// get the textflow and add the new paragraph to it
			var tf:TextFlow = fle.getTextFlow();
			tf.addChildAt(tf.getChildIndex(fle.parent), para);
						
			// now we loop through all of the ListItemElements children and 
			// add them to the new paragraph that we created above.
			for(var i:int=0; i< initialChildren; i++) {
				//if(i==0) continue;
				para.addChild(fle.getChildAt(0));
			}
			
			// add the paragraph to the auto sizable container
			/*var acc:AutosizableContainerController = ListUtil.findContainerControllerForElement(fle.parent);
			acc.addInitialMonitoredElement(para);*/
			
			// now we can remove the element
			//fle.parent.removeChild(fle);
			if(initialChildren == 0) {
				para.addChild(new SpanElement());
			}
						
			var list:ListElementX = (fle.parent as ListElementX);

			// remove the first list item
			fle.parent.removeChild(fle);
			
			// update the list
			list.update();
			
			// refresh the selection
			var paraAbsEnd:int = para.getAbsoluteStart() + para.textLength-1;
			operationState.activePosition = paraAbsEnd;
			operationState.anchorPosition = paraAbsEnd;
			interactionManager.setSelectionState(operationState);
			interactionManager.refreshSelection();
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
			
		//	textFlow.flowComposer.updateAllControllers();
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
					operatingState.absoluteEnd < (list.getAbsoluteStart() + list.textLength-2)) {
					
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
		 * Delete content that contains no lists 
		 * Instead of calling super.keyDownHanlder(event) we just call the correct function
		 * the function name "deletePreviousCharacter" is actually misleading. It leads the developer
		 * to believe that it will only delete the previous single character. However, in the operation
		 * we can see that it also will delete a text range if there is a selection as compared to just
		 * a caret selection.
		 */
		private function deleteText() : void {
			interactionManager.deletePreviousCharacter(interactionManager.getSelectionState());
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
					
	}
}