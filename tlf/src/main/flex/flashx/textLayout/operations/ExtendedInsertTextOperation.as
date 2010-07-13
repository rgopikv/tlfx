package flashx.textLayout.operations
{
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.converter.IHTMLExporter;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.edit.ElementRange;
	import flashx.textLayout.edit.ParaEdit;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.InlineGraphicElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TCYElement;
	import flashx.textLayout.elements.VarElement;
	import flashx.textLayout.elements.list.ListItemElementX;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.model.style.InlineStyles;
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;
	public class ExtendedInsertTextOperation extends InsertTextOperation
	{
		protected var _htmlImporter:IHTMLImporter;
		protected var _htmlExporter:IHTMLExporter;
		
		public function ExtendedInsertTextOperation(operationState:SelectionState, text:String, htmlImporter:IHTMLImporter, htmlExporter:IHTMLExporter, deleteSelectionState:SelectionState=null)
		{
			_htmlImporter = htmlImporter;
			_htmlExporter = htmlExporter;
			super(operationState, text, deleteSelectionState);
		}
		
		// [TA] 05-27-2010 :: Check to see if element is a non-writable element so as to progress to next sibling when editing.
		protected function isWritableElement( element:FlowLeafElement ):Boolean
		{
			return !(element is VarElement);
		}
		// [END TA]
		
		// [TA] 05-27-2010 :: Tranfer formatting from element to leaf, as is the case if previous sibling of leaf is a non-writable element.
		protected function updateLeafUserStyles( leaf:FlowElement, node:XML ):void
		{
			var inlineStyles:InlineStyles;
			if( leaf.userStyles != null )
			{
				inlineStyles = leaf.userStyles.inline;
				if( inlineStyles )
				{
					inlineStyles.deserialize( node );
				}
				else
				{
					inlineStyles = new InlineStyles( node );
				}
			}
			else
			{
				leaf.userStyles = {};
			}
			leaf.userStyles.inline = inlineStyles;
		}
		// [END TA]
		
		// [TA] 05-27-2010 :: Checks if formatting was handed over to next sibling from nonwritable leaf which is the case when normalizeRange is called.
		protected function leafFormattingMatches( leaf:FlowLeafElement, nonwritableLeaf:FlowLeafElement ):Boolean
		{
			if( leaf.userStyles && nonwritableLeaf.userStyles )
			{
				var leafInline:InlineStyles = leaf.userStyles.inline;
				var nonwritableInline:InlineStyles = nonwritableLeaf.userStyles.inline;
				if( leafInline && nonwritableInline )
				{
					return leafInline.node == nonwritableInline.node;
				}
				return false; 
			}
			return false;	
		}
		// [END TA]
		
		// [TA] Cheap copy to do what we need since this isn't marked as protected in super class.
		private function doExtendedInternal():void
		{
			var leafEl:FlowLeafElement = textFlow.findLeaf(absoluteStart);
			var tcyEl:TCYElement = null;
			
			if(leafEl is InlineGraphicElement && leafEl.parent is TCYElement)
			{
				tcyEl = leafEl.parent as TCYElement;
			}
			
			if (delSelOp != null) {	
				var deleteFormat:ITextLayoutFormat = new TextLayoutFormat(textFlow.findLeaf(absoluteStart).format);
				if (delSelOp.doOperation())		// figure out what to do here
				{
					//do not change characterFormat if user specified one already
					if ((characterFormat == null) && (absoluteStart < absoluteEnd))
					{
						_characterFormat = deleteFormat;
					} 
					else 
					{
						if (leafEl.textLength == 0) 
						{
							var pos:int = leafEl.parent.getChildIndex(leafEl);
							leafEl.parent.replaceChildren(pos, pos + 1, null);
						}
					}
					
					if(tcyEl && tcyEl.numChildren == 0)
					{
						leafEl = new SpanElement();
						tcyEl.replaceChildren(0,0,leafEl);
					}
				} 
			} 
			var range:ElementRange;
			var useExistingLeaf:Boolean = false;
			// favor using leaf we have if it's valid (i.e., it has a paragraph in its parent chain and it is still inside a TextFlow)
			if (absoluteStart >= absoluteEnd || leafEl.getParagraph() == null || leafEl.getTextFlow() == null)
			{
				range = ElementRange.createElementRange(textFlow,absoluteStart, absoluteStart);
			}
			else
			{
				range = new ElementRange();
				range.firstParagraph = leafEl.getParagraph();
				range.firstLeaf = leafEl;
				useExistingLeaf = true;
			}
			var paraSelBegIdx:int = absoluteStart-range.firstParagraph.getAbsoluteStart();
			
			// [TA] 05-27-2010 :: Check for non writable elements, such as VarElement.
			//						If found for insertion of text, push to next sibling if available.
			var leaf:FlowLeafElement = range.firstLeaf;
			if( !isWritableElement( leaf ) ) leaf = leaf.getNextLeaf();
			if( leaf == null )
			{
				leaf = ParaEdit.createElement( range.firstParagraph, paraSelBegIdx, getQualifiedClassName( SpanElement ), _characterFormat );
			}
			if( !isWritableElement( leaf.getPreviousLeaf() ) )
			{
				var nonWritableElement:FlowLeafElement = leaf.getPreviousLeaf();
				if( leafFormattingMatches( leaf, nonWritableElement ) )
				{
					var leafInline:InlineStyles = leaf.userStyles.inline as InlineStyles;
					leafInline.deserialize( null );
					var simpleLeafMarkup:XML = _htmlExporter.getSimpleMarkupModelForElement( leaf );
					updateLeafUserStyles( leaf, simpleLeafMarkup );
				}
			}
			// [END TA]
			
			// force insert to use the leaf given if we have a good one
			ParaEdit.insertText(range.firstParagraph, leaf, paraSelBegIdx, _text, useExistingLeaf);
			if (textFlow.interactionManager)
				textFlow.interactionManager.notifyInsertOrDelete(absoluteStart, _text.length);
			
			if (_characterFormat && !TextLayoutFormat.isEqual(_characterFormat, range.firstLeaf.format) && !(range.firstParagraph is ListItemElementX))
				ParaEdit.applyTextStyleChange(textFlow,absoluteStart,absoluteStart+_text.length,_characterFormat,null);
		}
		
		/** @private */
		public override function doOperation():Boolean
		{
			doExtendedInternal();
			if (originalSelectionState.selectionManagerOperationState && textFlow.interactionManager)
			{
				var state:SelectionState = textFlow.interactionManager.getSelectionState();
				if (state.pointFormat)
				{
					state.pointFormat = null;
					textFlow.interactionManager.setSelectionState(state);
				}
			}
			return true;
		}
	}
}