package flashx.textLayout.operations
{
	import flashx.textLayout.container.AutosizableContainerController;
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.edit.ParaEdit;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.edit.TextFlowEdit;
	import flashx.textLayout.edit.TextScrap;
	import flashx.textLayout.elements.ContainerFormattedElement;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.tlf_internal;
	
	/**
	 * PasteElementOperation is an operation that handles placing flow elements into an insertion point within the text flow. 
	 * @author toddanderson
	 */
	public class PasteElementsOperation extends FlowTextOperation
	{
		protected var _elementsToPaste:Array;
		protected var elementInsertIndex:int;
		
		/**
		 * Constructor. 
		 * @param operationState SelectionState
		 * @param elements Array
		 */
		public function PasteElementsOperation( operationState:SelectionState, elements:Array )
		{
			super( operationState );
			_elementsToPaste = elements;
		}
		
		protected function internalDoOperation():void
		{
			use namespace tlf_internal;
			var para:ParagraphElement = textFlow.findLeaf(absoluteStart).getParagraph();
			var parent:ContainerFormattedElement = para.parent as ContainerFormattedElement;
			elementInsertIndex = parent.getChildIndex(para);
			var i:int;
			var index:int = 0;
			for( i = elementInsertIndex; i < elementInsertIndex + _elementsToPaste.length; i++ )
			{
				parent.addChildAt( i, _elementsToPaste[index++] );
			}
		}
		
		override public function doOperation():Boolean
		{
			internalDoOperation();
			return true;
		}
		
		override public function undo():SelectionState
		{
			if( _elementsToPaste != null )
			{
				var i:int;
				for( i = 0; i < _elementsToPaste.length; i++ )
				{
					textFlow.removeChildAt( --elementInsertIndex );
				}
				if ( textFlow.interactionManager )
					textFlow.interactionManager.notifyInsertOrDelete( absoluteStart, 0 );
			}
			return originalSelectionState;
		}
		
		override public function redo():SelectionState
		{
			if ( _elementsToPaste != null )
				internalDoOperation();		
			
			return new SelectionState(textFlow, absoluteStart, absoluteStart, null );
		}
		
		public function get elements():Array
		{
			return _elementsToPaste;
		}
		public function set elements( value:Array ):void
		{
			_elementsToPaste = value;
		}
	}
}