package flashx.textLayout.operations
{
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.edit.TextFlowEdit;
	import flashx.textLayout.edit.TextScrap;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.tlf_internal;
	
	public class DeleteElementIntoDivOperation extends FlowTextOperation
	{
		protected var _element:ParagraphElement;
		protected var _divElement:DivElement;
		
		protected var _elementIndexStart:int;
		protected var _elementIndexEnd:int;
		protected var _insertIndexStart:int;
		protected var _insertIndexEnd:int;
		
		protected var _undoInsertRangeStart:int;
		protected var _undoInsertRangeEnd:int;
		protected var _undoDeleteRangeStart:int;
		protected var _undoDeleteRangeEnd:int;
		
		use namespace tlf_internal;
		public function DeleteElementIntoDivOperation( operationState:SelectionState, element:ParagraphElement, divElement:DivElement )
		{
			super(operationState);
			_element = element;
			_divElement = divElement;
			
			// If these values com in null, we want to perform an empty operation.
			// If we let the backspacing from an element into a div without this, TLF has abug were it starts deleting forward on elements in current position of div.
			if( _element && _divElement )
			{
				_elementIndexStart = _element.getAbsoluteStart();
				_elementIndexEnd = _elementIndexStart + _element.textLength;
				_insertIndexStart = _divElement.getAbsoluteStart() + _divElement.textLength - 1;
				_insertIndexEnd = _insertIndexStart;
			}
		}
		
		override public function doOperation():Boolean
		{
			if( _element == null && _divElement == null ) return false;
			
			var elementStart:int = _elementIndexStart;
			var elementEnd:int = _elementIndexEnd;
			var insertStart:int = _insertIndexStart;
			var insertEnd:int = _insertIndexEnd;
			
			var sibling:FlowElement = textFlow.findLeaf( insertStart );
			var hasParagraphTerminator:Boolean;
			if( sibling is SpanElement )
			{
				var span:SpanElement = sibling as SpanElement;
				hasParagraphTerminator = span.hasParagraphTerminator;
				if( hasParagraphTerminator ) 
				{
					insertStart--;
					elementEnd--;
					_element.getLastLeaf().removeParaTerminator();
				}
			}
			// Affix a permanent format from cascade to ensure that the removed and inserted element looks as it did before.
			_element.format = _element.computedFormat;
			
			var scrap:TextScrap = TextFlowEdit.createTextScrap( textFlow, elementStart, elementEnd );
			TextFlowEdit.replaceRange( textFlow, elementStart, elementEnd, null );
			TextFlowEdit.replaceRange( textFlow, insertStart, insertStart + 1, scrap );
			// Add empty p back with terminator.
			if( hasParagraphTerminator ) _divElement.addChild( new ParagraphElement() );
			
			if (textFlow.interactionManager)
			{
				textFlow.interactionManager.notifyInsertOrDelete( insertStart, _divElement.textLength );
				textFlow.interactionManager.setSelectionState( new SelectionState( textFlow, insertStart, insertStart ) );
			}
			
			_undoInsertRangeStart = elementStart;
			_undoInsertRangeEnd = elementEnd;
			_undoDeleteRangeStart = insertStart;
			_undoDeleteRangeEnd = insertStart + _element.textLength;
			return true;
		}
		
		/** @private */
		public override function undo():SelectionState
		{
//			var scrap:TextScrap = TextFlowEdit.createTextScrap( textFlow, _undoDeleteRangeStart, _undoDeleteRangeEnd );
//			TextFlowEdit.replaceRange( textFlow, _undoDeleteRangeStart, _undoDeleteRangeEnd, null );
//			TextFlowEdit.replaceRange( textFlow, _divElement.textLength, _divElement.textLength, scrap );
//			
//			if (textFlow.interactionManager)
//			{
//				textFlow.interactionManager.notifyInsertOrDelete( _undoDeleteRangeStart, _undoInsertRangeEnd );
//			}
//			return new SelectionState( textFlow, _divElement.textLength, _divElement.textLength );
			return originalSelectionState;
		}
		
		// [TA] 07-27-2010 :: See comment on FlowOperation.
		override public function get affectsFlowStructure():Boolean
		{
			return true;
		}
		// [END TA]
	}
}