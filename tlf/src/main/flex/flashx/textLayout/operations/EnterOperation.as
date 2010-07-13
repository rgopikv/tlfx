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
	public class EnterOperation extends FlowTextOperation
	{
		private var interactionManager:ExtendedEditManager;
				
		protected var _htmlImporter:IHTMLImporter;
		protected var _htmlExporter:IHTMLExporter;
								
		/**
		 * 
		 * @param operationState
		 * @param interactionManager
		 * @param importer
		 * @param exporter
		 * 
		 */
		public function EnterOperation( operationState:SelectionState, interactionManager:ExtendedEditManager, importer:IHTMLImporter, exporter:IHTMLExporter )
		{
			super( operationState );
			
			// Set the interaction manager so that we can reference it while deleting lists.
			this.interactionManager = interactionManager;
			_htmlImporter = importer;
			_htmlExporter = exporter;
		}
				
		/**
		 * doOperation is called by ExtendedEditManager.
		 * 
		 * @return 
		 * 
		 */
		public override function doOperation():Boolean	{
			
			if(isCaretSelection()) {
				interactionManager.splitParagraph();
				interactionManager.refreshSelection();
			} else {
				var operationState:SelectionState = interactionManager.defaultOperationState();
				
				if( !operationState ) {
					return true;
				}
				
				// do the specific operation passing in the listMode argument
				interactionManager.doOperation( new BackspaceOperation( operationState, interactionManager ) );
				interactionManager.splitParagraph();
				interactionManager.refreshSelection();
				
			}
			
			var nextLeaf:ListItemElementX = textFlow.findLeaf(absoluteEnd+1).parent as ListItemElementX;
			var prevLeaf:ListItemElementX = textFlow.findLeaf(absoluteEnd).parent as ListItemElementX;
			if(prevLeaf) {
				if(prevLeaf.modifiedTextLength == 0) {
					closeList(nextLeaf);
					return true;
				}
				
				if(nextLeaf) {
					var ss:SelectionState = new SelectionState(textFlow, nextLeaf.actualStart-1, nextLeaf.actualStart-1);
					interactionManager.setSelectionState(ss);
					interactionManager.refreshSelection();
				}
			} 
			
			return true;	
		}
		
		private function closeList(leaf:ListItemElementX) : void {

			var item:ListItemElementX = leaf.parent as ListItemElementX;
			
			var list:ListElementX = leaf.parent as ListElementX;
			var idx:int = list.listItems.indexOf(leaf);
			list.removeChild(leaf);
			list.removeChild(list.listItems.pop()); // use the same index since they shift
			list.update();
			
			// now jump down
			var ss:SelectionState = new SelectionState(textFlow, list.getAbsoluteStart()+list.textLength, list.getAbsoluteStart()+list.textLength);
			interactionManager.setSelectionState(ss);
			interactionManager.refreshSelection();
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
		
	}
}