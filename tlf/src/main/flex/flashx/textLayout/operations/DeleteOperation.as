package flashx.textLayout.operations
{
	import flash.events.KeyboardEvent;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.container.AutosizableContainerController;
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.converter.IHTMLExporter;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.edit.EditManager;
	import flashx.textLayout.edit.ExtendedEditManager;
	import flashx.textLayout.edit.ParaEdit;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.edit.helpers.SelectionHelper;
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
	 * The TabOperation is a subclass that tabs text.
	 * 
	 * @author dominickaccattato
	 * 
	 */
	public class DeleteOperation extends FlowTextOperation
	{
		private var interactionManager:ExtendedEditManager;
				
		protected var selectedLists:Array = new Array();
		
		private static var NORMAL:int = 1;
		private static var END_OF_LIST_ITEM:int = 2;
		private static var END_OF_LIST:int = 3;
		
		private var deletionState:int = DeleteOperation.NORMAL;
		
		/**
		 * 
		 * @param operationState
		 * @param interactionManager
		 * @param importer
		 * @param exporter
		 * 
		 */
		public function DeleteOperation( operationState:SelectionState, interactionManager:ExtendedEditManager )
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
			
			if(isCaretSelection()) {
				
				var state:int = getDeletionState();
				
				switch(state) {
					case DeleteOperation.NORMAL:
						interactionManager.deleteNextCharacter();
						break;
					
					case DeleteOperation.END_OF_LIST_ITEM:
						var selectionState:SelectionState = interactionManager.getSelectionState();
						var tf:TextFlow = interactionManager.textFlow;
						var leaf:FlowElement = tf.findLeaf(selectionState.absoluteStart);

						var listItem:ListItemElementX = tf.findLeaf(selectionState.absoluteStart).parent as ListItemElementX;
						
						var ss:SelectionState = new SelectionState(tf, absoluteStart, absoluteStart + (listItem as ListItemElementX).seperatorLength+1)
						interactionManager.setSelectionState(ss);
						interactionManager.refreshSelection();
						
						// issue a backspace operation to delete the symbol
						interactionManager.doOperation( new BackspaceOperation( ss, interactionManager ) );

						break;
					
					case DeleteOperation.END_OF_LIST:
						var selectionState:SelectionState = interactionManager.getSelectionState();
						var tf:TextFlow = interactionManager.textFlow;
						interactionManager.setSelectionState(new SelectionState(tf, selectionState.absoluteStart+1, selectionState.absoluteStart+1));
						interactionManager.refreshSelection();
						break;
					
				}
				
			} else {
				var operationState:SelectionState = interactionManager.defaultOperationState();
				if( !operationState ) return true;
				
				// do the specific operation passing in the listMode argument
				interactionManager.doOperation( new BackspaceOperation( operationState, interactionManager ) );
			}

			return true;	
		}
		
		private function getDeletionState() : int {
			var selectionState:SelectionState = interactionManager.getSelectionState();
			
			// are we at the end of a list? If so, we need to 
			// move the cursor to the line below it
			var tf:TextFlow = interactionManager.textFlow;
			var leaf:FlowElement = tf.findLeaf(selectionState.absoluteStart);
			
			var list:ListElementX = leaf.parent.parent as ListElementX;
			var listItem:ListItemElementX = leaf.parent as ListItemElementX;
			
			if(list && absoluteStart == list.getAbsoluteStart() + list.textLength-1) {
				return DeleteOperation.END_OF_LIST;
			}
			
			if(listItem && absoluteStart == listItem.getAbsoluteStart() + listItem.textLength-1) {
				return DeleteOperation.END_OF_LIST_ITEM;
			}
			
			return DeleteOperation.NORMAL;
			
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
		
		// [TA] 07-27-2010 :: See comment on FlowOperation.
		override public function get affectsFlowStructure():Boolean
		{
			return !isCaretSelection();
		}
		// [END TA]
	}
}