package flashx.textLayout.operations
{
	import flashx.textLayout.container.AutosizableContainerController;
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.edit.ParaEdit;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.edit.TextFlowEdit;
	import flashx.textLayout.edit.TextScrap;
	import flashx.textLayout.elements.BreakElement;
	import flashx.textLayout.elements.ContainerFormattedElement;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.list.ListElementX;
	import flashx.textLayout.elements.table.TableDataElement;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.events.ModelChange;
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;
	/**
	 * PasteElementOperation is an operation that handles placing flow elements into an insertion point within the text flow. 
	 * @author toddanderson
	 */
	public class PasteElementsOperation extends FlowTextOperation
	{
		protected var _elementsToPaste:Array;
		protected var _elementInsertIndex:int;
		protected var _isPartOfComposite:Boolean;
		
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
		
		protected function isInsertLeafAnEmptyBreakElement( leaf:FlowElement ):Boolean
		{
			if( leaf is BreakElement )
			{
				var text:String = ( leaf as BreakElement ).text;
				text = text.replace( /[\u2029\u2028\n\r]/g, "" );
				return text.length == 0;
			}
			return false;
		}
		
		protected function pastedContentRequiresSplit():Boolean
		{
			var i:int;
			var length:int = elements.length;
			var element:FlowElement;
			for( i = 0; i < length; i++ )
			{
				element = elements[i] as FlowElement;
				if( element is TableElement || element is ListElementX ) return true;
			}
			return false;
		}
		
		protected function getInsertTokenForPasteIntoTextFlow( leaf:FlowElement, paragraph:ParagraphElement, splitIndex:int ):InsertToken
		{
			var targetGroup:FlowGroupElement = textFlow;
			var insertIndex:int = textFlow.getChildIndex( paragraph ) + 1;
			var globalSplitIndex:int = absoluteEnd - paragraph.getAbsoluteStart();
			// If we are splitting after the first character of a target paragraph...
			if( splitIndex > 0 )
			{
				if( isInsertLeafAnEmptyBreakElement( leaf ) )
				{
					paragraph.removeChild( leaf );
				}
				if( globalSplitIndex < (paragraph.textLength - 1) )
				{
					paragraph.splitAtPosition( splitIndex );
				}
			}
			// Else we are pasting before it.
			else if( paragraph.getAbsoluteStart() == 0 )
			{
				insertIndex = 0;
			}
			return new InsertToken( insertIndex, targetGroup );
		}
		
		protected function getInsertTokenForPasteIntoDiv( div:DivElement, leaf:FlowElement, paragraph:ParagraphElement, splitIndex:int ):InsertToken
		{
			var targetGroup:FlowGroupElement = div;
			var insertIndex:int = div.getChildIndex( paragraph ) + 1;
			var len:int = leaf.getText().length;
			var globalSplitIndex:int = absoluteEnd - paragraph.getAbsoluteStart();
			if( splitIndex > 0 )
			{
				if( isInsertLeafAnEmptyBreakElement( leaf ) )
				{
					paragraph.removeChild( leaf );
				}
				if( globalSplitIndex < (paragraph.textLength - 1) )
				{
					targetGroup = div.parent;
					insertIndex = targetGroup.getChildIndex( div ) + 1;
					div.splitAtPosition( absoluteEnd - div.getAbsoluteStart() );
				}
				else if( pastedContentRequiresSplit() )
				{
					targetGroup = div.parent;
					insertIndex = targetGroup.getChildIndex( div ) + 1;
					div.splitAtPosition( absoluteEnd - div.getAbsoluteStart() );
				}
			}
			else if( paragraph.getAbsoluteStart() == 0 ) 
			{
				targetGroup = div.parent;
				insertIndex = 0;
			}
			return new InsertToken( insertIndex, targetGroup );
		}
		
		protected function getInsertTokenForPasteIntoGroup( group:FlowGroupElement, leaf:FlowElement, paragraph:ParagraphElement, splitIndex:int ):InsertToken
		{
			var targetGroup:FlowGroupElement = group;
			var insertIndex:int = group.getChildIndex( paragraph ) + 1;
			var globalSplitIndex:int = absoluteEnd - paragraph.getAbsoluteStart();
			if( splitIndex > 0 )
			{
				if( isInsertLeafAnEmptyBreakElement( leaf ) )
				{
					paragraph.removeChild( leaf );
				}
				if( splitIndex < (paragraph.textLength - 1) )
				{
					TextFlowEdit.splitElement( group, absoluteEnd - group.getAbsoluteStart(), true );
				}
			}
			else if( paragraph.getAbsoluteStart() == 0 ) 
			{
				insertIndex = 0;
			}
			return new InsertToken( insertIndex, targetGroup );
		}
		
		protected function internalDoOperation():void
		{
			// Update selection state if part of merge
			if( _isPartOfComposite )
			{
				originalSelectionState = textFlow.interactionManager.getSelectionState();
				absoluteStart = originalSelectionState.absoluteStart;
				absoluteEnd = originalSelectionState.absoluteEnd;
			}
			
			// Find leaf.
			var leaf:FlowLeafElement = textFlow.findLeaf( absoluteStart );
			// Find Paragraph at position in flow.
			var para:ParagraphElement = textFlow.findAbsoluteParagraph( absoluteStart );
			// Find the global character position.
			var paraSplitIndex:int = absoluteEnd - para.getAbsoluteStart();
			// Find the elemental index of para in parent.
			var flowElIndex:int = para.parent.getChildIndex(para);
			// Find the parent of the target para.
			var topGroup:FlowGroupElement = para.parent;
			// Determine if we are pasting into a table.
			var isPastingIntoTable:Boolean = topGroup is TableDataElement;
			
			if( !isPastingIntoTable && !(topGroup is TextFlow) )
			{
				// Find the top group element based on parent structure.
				//	This is used to detemrin how to split at the position and insert elements in a target element.
				while( topGroup && !(topGroup is TextFlow) && !(topGroup is TableDataElement) )
				{
					if( topGroup.parent is TextFlow ) break;
					topGroup = topGroup.parent;
				}
			}
			
			// Default to paste at end of flow.
			var insertToken:InsertToken = new InsertToken( textFlow.numChildren, textFlow );
			// Pasting content into a table takes on a different context, if we arent' doing that, find the insert position and target group element to paste into.
			if( !isPastingIntoTable )
			{
				// If Paragraph is direct child of TextFlow...
				if( topGroup is TextFlow )
				{
					insertToken = getInsertTokenForPasteIntoTextFlow( leaf, para, paraSplitIndex );
				}
				// If Paragraph is in a DivElement that is not a ListElement...
				else if ( topGroup is DivElement && !(topGroup is ListElementX) )
				{
					insertToken = getInsertTokenForPasteIntoDiv( topGroup as DivElement, leaf, para, paraSplitIndex );
				}
				// Default...
				else
				{
					insertToken = getInsertTokenForPasteIntoGroup( topGroup, leaf, para, paraSplitIndex );
				}
			}
			// Switch target to table data element for operation.
			else
			{
				var cellChildIndex:int;
				var cellElement:TableDataElement;
				if( topGroup is TableDataElement ) 
				{
					cellElement = topGroup as TableDataElement;
					cellChildIndex = cellElement.getChildIndex( para ) + 1;
					ParaEdit.splitParagraph( para, absoluteEnd - para.getAbsoluteStart() );
				}
				else
				{
					cellElement = topGroup.parent as TableDataElement;
					cellChildIndex = cellElement.getChildIndex( topGroup ) + 1;
					TextFlowEdit.splitElement( topGroup, absoluteEnd - topGroup.getAbsoluteStart(), true );	
				}
				insertElementsIntoCell( topGroup as TableDataElement, para, _elementsToPaste );
				insertToken = new InsertToken( cellChildIndex, cellElement );
			}
			// Add the elements to the target group.
			var insertIndex:int = insertToken.index;
			var targetGroup:FlowGroupElement = insertToken.target;
			var i:int;
			var length:int;
			var elem:FlowElement;
			for( i = 0; i < _elementsToPaste.length; i++ )
			{
				elem = _elementsToPaste[i];
				targetGroup.addChildAt( insertIndex, elem );
				length += elem.textLength;
				insertIndex++;
			}
			
			// Check if we emptied out where we split/started.
//			var insertElement:FlowElement = targetGroup.getChildAt( insertIndex - 1 );
//			if( insertElement.textLength == 0 )
//			{
//				targetGroup.removeChild( insertElement );
//			}
//			else if( insertElement is FlowGroupElement && insertElement.textLength == 1 )
//			{
//				// Empty spans, ones that are handed a paragraph terminator have the *awesome* design of havin textlength = 1.
//				leaf = ( insertElement as FlowGroupElement ).findLeaf( absoluteStart ) as FlowLeafElement;
//				if( leaf is SpanElement )
//				{
//					if( leaf.textLength == 1 && ( leaf as SpanElement ).hasParagraphTerminator )
//					{
//						targetGroup.removeChild( insertElement );
//					}
//				}
//			}
			
			// Notify and update selection.
			textFlow.interactionManager.notifyInsertOrDelete( absoluteEnd, length );
			textFlow.interactionManager.setSelectionState( new SelectionState( textFlow, absoluteStart + length, absoluteStart + length ) );
		}
		
		protected function insertElementsIntoCell( element:TableDataElement, beforePara:ParagraphElement, elements:Array ):void
		{
			var i:int;
			var endIndex:int = element.mxmlChildren.length;
			for( i = 0; i < element.mxmlChildren.length; i++ )
			{
				if( element.mxmlChildren[i] == beforePara )
					break;
			}
			var content:Array = element.mxmlChildren;
			var head:Array = content.slice( 0, i );
			head = head.concat( elements );
			var tail:Array = content.slice( i, endIndex );
			var newChildren:Array = head.concat( tail );
			for( i = 0; i < newChildren.length; i++ )
			{
				element.addChild( newChildren[i] as FlowElement );
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
					textFlow.removeChildAt( --_elementInsertIndex );
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
		
		tlf_internal override function merge(operation:FlowOperation):FlowOperation
		{
			if (this.endGeneration != operation.beginGeneration)
				return null;
			
			if ((operation is SplitParagraphOperation))
			{
				_isPartOfComposite = true;
				return new CompositeOperation([operation,this]);
			}
			return null;
		}
		
		public function get elements():Array
		{
			return _elementsToPaste;
		}
		public function set elements( value:Array ):void
		{
			_elementsToPaste = value;
		}
		
		public function get insertIndex():int
		{
			return _elementInsertIndex;
		}
		
		// [TA] 07-27-2010 :: See comment on FlowOperation.
		override public function get affectsFlowStructure():Boolean
		{
			return true;
		}
		// [END TA]
	}
}

import flashx.textLayout.elements.FlowGroupElement;
class InsertToken
{
	public var index:int;
	public var target:FlowGroupElement;
	
	public function InsertToken( index:int, target:FlowGroupElement )
	{
		this.index = index;
		this.target = target;
	}
}