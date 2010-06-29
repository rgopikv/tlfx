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
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.table.TableDataElement;
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
		
		protected function internalDoOperation():void
		{
			// Update selection state if part of merge
			if( _isPartOfComposite )
			{
				originalSelectionState = textFlow.interactionManager.getSelectionState();
				absoluteStart = originalSelectionState.absoluteStart;
				absoluteEnd = originalSelectionState.absoluteEnd;
			}
			
			var i:int;
			var index:int = 0;
			var length:int;
//			var tfStart:int = textFlow.getAbsoluteStart();
//			if( absoluteStart == tfStart )
//			{
//				var elem:FlowElement;
//				for( i = 0; i < _elementsToPaste.length; i++ )
//				{
//					elem = _elementsToPaste[i];
//					textFlow.addChildAt( i, elem );
//					length += elem.textLength;
//				}
//				textFlow.interactionManager.notifyInsertOrDelete( 0, length );
//				textFlow.interactionManager.setSelectionState( new SelectionState( textFlow, length, length ) );
//				return;
//			}
			
			var leaf:FlowLeafElement = textFlow.findLeaf( absoluteEnd );
			var para:ParagraphElement = leaf.getParagraph();
			var parent:ContainerFormattedElement = para.parent as ContainerFormattedElement;
			_elementInsertIndex = textFlow.getChildIndex( ( parent is TextFlow ) ? para : parent ) + 1;
			// If the partent of the target is a Textflow. Just pop it and begin.
			if( parent is TextFlow )
			{
				( parent as TextFlow ).removeChild( para );
				_elementsToPaste.push( para );
				_elementInsertIndex -= 1;
			}
			// Else sever the div and add the lower children as needed to be re-adsed to the flow.
			else if( parent is DivElement )
			{
				var groupElement:FlowElement = hotSwapFlowGroup( ( parent as FlowGroupElement ), para );
				// If we have split the div.
				if( groupElement )
				{
					_elementsToPaste.push( groupElement );
				}
				// Else we had the cursor at the end of a div and want to add content afterword.
				//	Remove the paragraph at cursor in order to not add an extra line on insertion.
				else
				{
					( parent as DivElement ).removeChild( para );
				}
			}
			else if( parent is TableDataElement )
			{
				insertElementsIntoCell( parent as TableDataElement, leaf.getParagraph(), _elementsToPaste );
				return;
			}
			length = _elementInsertIndex + _elementsToPaste.length;
			index = 0;
			var element:FlowElement;
			var insertPosition:Number;
			var insertLength:int;
			// Update the text flow with required elements in past operation.
			for( i = _elementInsertIndex; i < length; i++ )
			{
				element = _elementsToPaste[index++];
				textFlow.addChildAt( i, element );
				element.modelChanged( ModelChange.ELEMENT_ADDED, element.getAbsoluteStart(), element.textLength );
				
				if( isNaN( insertPosition ) ) insertPosition = element.getAbsoluteStart();
				insertLength += element.textLength;
			}
			
			if( _elementsToPaste.length == 0 ) return;
			
			if( textFlow.interactionManager )
			{
				textFlow.interactionManager.notifyInsertOrDelete( insertPosition, insertLength );
				textFlow.interactionManager.setSelectionState( new SelectionState( textFlow, insertPosition, insertPosition ) );
			}
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
		
		/**
		 * @private
		 * 
		 * Slices and dices content fromt FlowGroupElement to get a copy of the element with children tacked on.
		 * @param groupElement FlowGroupElement
		 * @param para ParagraphElement
		 * @return FlowElement
		 */
		protected function hotSwapFlowGroup( groupElement:FlowGroupElement, para:ParagraphElement ):FlowElement
		{
			if( absoluteStart == groupElement.getAbsoluteStart() + groupElement.textLength - 1 ) return null;
			
			var index:int = 0;
			var length:int;
			index = groupElement.getChildIndex( para );
			length = groupElement.numChildren;
			var content:Array = groupElement.mxmlChildren;
			groupElement.mxmlChildren = content.slice( 0, index );
			var newGroupChildren:Array = content.slice( index, length );
			var newGroup:FlowGroupElement = ( groupElement.shallowCopy() as FlowGroupElement );
			for( var i:int = 0; i < newGroupChildren.length; i++ )
			{
				newGroup.addChild( ( newGroupChildren[i] as FlowElement ) );
			}
			return newGroup;
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
	}
}