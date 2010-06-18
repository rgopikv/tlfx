package flashx.textLayout.operations
{
	import flashx.textLayout.edit.SelectionState;
	
	public class DummyOperation extends FlowTextOperation
	{
		public function DummyOperation(operationState:SelectionState)
		{
			super(operationState);
		}
		
		/** @private */
		public override function doOperation():Boolean
		{
			return true;	
		}
		
		/** @private */
		public override function undo():SelectionState
		{
			return new SelectionState( textFlow, absoluteStart, absoluteEnd );
		}
		
		/** @private */
		public override function redo():SelectionState
		{
			return new SelectionState( textFlow, absoluteStart, absoluteEnd );
		}
	}
}
