package flashx.textLayout.operations
{
	import flashx.textLayout.edit.ElementRange;
	import flashx.textLayout.edit.ParaEdit;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.IManagedInlineGraphicSource;
	import flashx.textLayout.elements.InlineGraphicElement;
	import flashx.textLayout.elements.SubParagraphGroupElement;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;
	public class InsertEditableInlineGraphicOperation extends InsertInlineGraphicOperation
	{
		public function InsertEditableInlineGraphicOperation(operationState:SelectionState, source:Object, width:Object, height:Object, options:Object=null)
		{
			super(operationState, source, width, height, options);
		}
		
		public override function doOperation():Boolean
		{
			/* Straight paste */
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
			
			/* To get to applying managed inline graphic element if applicable. */
			var imgElem:InlineGraphicElement = ParaEdit.createImage(leafNodeParent, selPos - leafNodeParent.getAbsoluteStart(), _source, imageWidth, imageHeight, options, pointFormat);
			if( source is IManagedInlineGraphicSource )
			{
				( source as IManagedInlineGraphicSource ).inlineGraphicElement = imgElem;
			}
			
			if (textFlow.interactionManager)
				textFlow.interactionManager.notifyInsertOrDelete(absoluteStart, 1);
			
			return true;
		}
	}
}