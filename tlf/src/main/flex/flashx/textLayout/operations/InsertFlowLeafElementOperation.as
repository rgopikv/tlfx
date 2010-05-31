package flashx.textLayout.operations
{
	import flashx.textLayout.edit.ElementRange;
	import flashx.textLayout.edit.ParaEdit;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.SubParagraphGroupElement;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.tlf_internal;

	use namespace tlf_internal;
	public class InsertFlowLeafElementOperation extends FlowTextOperation
	{
		protected var delSelOp:DeleteTextOperation;
		protected var selPos:int = 0;
		protected var _text:String;
		protected var _elementClass:String;
		protected var _createdElement:FlowLeafElement;
		
		public function InsertFlowLeafElementOperation( operationState:SelectionState, text:String, elementClass:String )
		{
			super(operationState);
			
			if (absoluteStart != absoluteEnd)
				delSelOp = new DeleteTextOperation(operationState);
			
			_text = text;
			_elementClass = elementClass;
		}
		
		/** @private */
		public override function doOperation():Boolean
		{
			var pointFormat:ITextLayoutFormat;
			
			selPos = absoluteStart;
			if (delSelOp) 
			{
				var leafEl:FlowLeafElement = textFlow.findLeaf(absoluteStart);
				var deleteFormat:ITextLayoutFormat = new TextLayoutFormat(textFlow.findLeaf(absoluteStart).format);
				if (delSelOp.doOperation())
					pointFormat = deleteFormat;
			}
			else
				pointFormat = originalSelectionState.pointFormat;
			
			// lean left logic included
			var range:ElementRange = ElementRange.createElementRange(textFlow,selPos, selPos);		
			var leafNode:FlowElement = range.firstLeaf;
			var leafNodeParent:FlowGroupElement = leafNode.parent;
			while (leafNodeParent is SubParagraphGroupElement)
			{
				var subParInsertionPoint:int = selPos - leafNodeParent.getAbsoluteStart();
				if (((subParInsertionPoint == 0) && (!(leafNodeParent as SubParagraphGroupElement).acceptTextBefore())) ||
					((subParInsertionPoint == leafNodeParent.textLength) && (!(leafNodeParent as SubParagraphGroupElement).acceptTextAfter())))
				{
					leafNodeParent = leafNodeParent.parent;
				} else {
					break;
				}
			}
			
			_createdElement = ParaEdit.createElement( leafNodeParent, selPos - leafNodeParent.getAbsoluteStart(), _elementClass, pointFormat);
			if( _createdElement is SpanElement )
			{
				( _createdElement as SpanElement ).replaceText( 0, 0, _text );
			}
			
			if (textFlow.interactionManager)
				textFlow.interactionManager.notifyInsertOrDelete(absoluteStart, 1);
			
			return true;
		}
		
		/** @private */
		public override function undo():SelectionState
		{
			var leafNode:FlowElement = textFlow.findLeaf(selPos);
			var leafNodeParent:FlowGroupElement = leafNode.parent;
			var elementIdx:int = leafNode.parent.getChildIndex(leafNode);
			leafNodeParent.replaceChildren(elementIdx, elementIdx + 1, null);			
			
			_createdElement = null;
			
			if (textFlow.interactionManager)
				textFlow.interactionManager.notifyInsertOrDelete(absoluteStart, -1);
			
			return delSelOp ? delSelOp.undo() : originalSelectionState; 
		}
		
		/**
		 * Re-executes the operation after it has been undone.
		 * 
		 * <p>This function is called by the edit manager, when necessary.</p>
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0 
		 */
		public override function redo():SelectionState
		{ 
			doOperation();
			return new SelectionState(textFlow,selPos+1,selPos+1,null);
		}
	}
}