package flashx.textLayout.operations
{
	import flashx.textLayout.container.IEditorDisplayContext;
	import flashx.textLayout.converter.IHTMLExporter;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.edit.SelectionState;
	
	public class DeleteAndInsertTextOperation extends ExtendedInsertTextOperation
	{
		protected var _displayContext:IEditorDisplayContext;
		protected var _keyCode:int;
		
		public function DeleteAndInsertTextOperation( operationState:SelectionState, text:String,
													  htmlImporter:IHTMLImporter, htmlExporter:IHTMLExporter,
													  displayContext:IEditorDisplayContext, keyCode:int, 
													  deleteSelectionState:SelectionState=null )
		{
			_displayContext = displayContext;
			_keyCode = keyCode;
			super( operationState, text, htmlImporter, htmlExporter, deleteSelectionState );
		}
		
		override protected function initialize( deleteSelectionState:SelectionState ):void
		{
			if (deleteSelectionState == null)
				deleteSelectionState = originalSelectionState;
			
			if (deleteSelectionState.anchorPosition != deleteSelectionState.activePosition)
			{
				_deleteSelectionState = deleteSelectionState;
				delSelOp = new DeleteElementsOperation( deleteSelectionState, _displayContext, _keyCode, _htmlImporter, _htmlExporter );
			}
		}
		
		public function get deleteOperation():FlowTextOperation
		{
			return delSelOp;
		}
	}
}