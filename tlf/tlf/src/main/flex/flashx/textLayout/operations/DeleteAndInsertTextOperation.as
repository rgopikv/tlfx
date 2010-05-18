package flashx.textLayout.operations
{
	import flashx.textLayout.container.IEditorDisplayContext;
	import flashx.textLayout.edit.SelectionState;
	
	public class DeleteAndInsertTextOperation extends InsertTextOperation
	{
		protected var _displayContext:IEditorDisplayContext;
		protected var _keyCode:int;
		
		public function DeleteAndInsertTextOperation( operationState:SelectionState, text:String, displayContext:IEditorDisplayContext, keyCode:int, deleteSelectionState:SelectionState=null )
		{
			_displayContext = displayContext;
			_keyCode = keyCode;
			super( operationState, text, deleteSelectionState );
		}
		
		override protected function initialize( deleteSelectionState:SelectionState ):void
		{
			if (deleteSelectionState == null)
				deleteSelectionState = originalSelectionState;
			
			if (deleteSelectionState.anchorPosition != deleteSelectionState.activePosition)
			{
				_deleteSelectionState = deleteSelectionState;
				delSelOp = new DeleteElementsOperation( deleteSelectionState, _displayContext, _keyCode );
			}
		}
		
		public function get deleteOperation():FlowTextOperation
		{
			return delSelOp;
		}
	}
}