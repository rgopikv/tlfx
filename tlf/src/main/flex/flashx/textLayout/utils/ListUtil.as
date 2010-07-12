package flashx.textLayout.utils
{
	import flashx.textLayout.edit.EditManager;
	import flashx.textLayout.edit.ExtendedEditManager;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.list.ListElementX;
	import flashx.textLayout.operations.DummyOperation;
	import flashx.textLayout.tlf_internal;

	use namespace tlf_internal;
	
	/**
	 * 
	 * @author dominickaccattato
	 * 
	 */
	public class ListUtil
	{
		/**
		 * 
		 * 
		 */
		public function ListUtil()
		{
		}
		
		/**
		 * 
		 * @param el
		 * 
		 */
		public static function cleanEmptyLists( el:FlowGroupElement ):void
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
		
		/**
		 * Perform a dummy operation in order to force the entire textFlow and all of it's container controllers (including AutosizeableContainerControllers) to update properly.
		 * 
		 * @param operationState
		 * 
		 * [KK]
		 */		
		public static function performDummyOperation(editManager:EditManager, operationState:SelectionState = null):void
		{
			operationState = editManager.defaultOperationState(operationState);
			if (!operationState)
				return;
			
			var op:DummyOperation;
			op = new DummyOperation( operationState );
			editManager.doOperation(op);
		}
	}
}