package flashx.textLayout.operations
{
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	import flashx.textLayout.container.AutosizableContainerController;
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.container.IEditorDisplayContext;
	import flashx.textLayout.container.ISizableContainer;
	import flashx.textLayout.container.TableCellContainerController;
	import flashx.textLayout.container.table.ICellContainer;
	import flashx.textLayout.container.table.TableCellContainer;
	import flashx.textLayout.container.table.TableCellDisplay;
	import flashx.textLayout.container.table.TableDisplayContainer;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.edit.TextFlowEdit;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.table.ITableElementManager;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.model.table.Table;
	import flashx.textLayout.tlf_internal;
	
	/**
	 * DeleteElementsOperation is an extension to DeleteTextOperation in order to properly maintain the display list of flow composition with the context
	 * of haing autosizable container controllers and tables. 
	 * @author toddanderson
	 */
	public class DeleteElementsOperation extends FlowTextOperation
	{
		protected var _keyCode:int;
		protected var _displayContext:IEditorDisplayContext;
		protected var _deleteSelectionOperation:DeleteTextOperation;
		protected var _containerMarks:Vector.<ContainerMark>;
		protected var _controllerMarks:Vector.<ContainerControllerMark>;
		protected var _tablesToDelete:Vector.<TableElement>;
		
		protected var _operationHasDeletedCells:Boolean;
		
		/**
		 * Constructor. 
		 * @param operationState SelectionState
		 * @param keyCode The key code that invoked this operation is needed as Backspace has a different connatation to removal of elements as Delete does.
		 */
		public function DeleteElementsOperation( operationState:SelectionState, displayContext:IEditorDisplayContext, keyCode:int )
		{
			super(operationState);
			_keyCode = keyCode;
			_displayContext = displayContext;
			_containerMarks = new Vector.<ContainerMark>();
			_controllerMarks = new Vector.<ContainerControllerMark>();
			_tablesToDelete = new Vector.<TableElement>();
		}
		
		/**
		 * @private
		 * 
		 * Locates the top level group element below the TextFlow based on the leaf child. 
		 * @param leaf FlowLeafElement
		 * @return FlowElement
		 */
		protected function findTopLevelParent( leaf:FlowLeafElement ):FlowElement
		{
			var parent:FlowGroupElement = leaf.parent;
			while( parent )
			{
				if( parent.parent is TextFlow )
					break;
				parent = parent.parent;
			}
			return ( parent ) ? parent : leaf;
		}
		
		/**
		 * @private 
		 * 
		 * Determines the affected container controllers and elements based on the selection state.
		 * Elements associated with an autosizable container controller that are sandwhiched between Tables need to be stripped from the display and flow.
		 * Still performs the DeleteTextOperation to properly remove elements from the TextFlow model.
		 */
		protected function internalDoOperation():void
		{
			var leaf:FlowLeafElement;
			var startParent:FlowElement;
			var startParentIndex:int;
			var endParent:FlowElement;
			var endParentIndex:int;
			// Find first index of parenting element.
			leaf = textFlow.findLeaf( absoluteStart );
			startParent = findTopLevelParent( leaf );
			startParentIndex = textFlow.getChildIndex( startParent );
			// Find last index of parent element.
			leaf = textFlow.findLeaf( absoluteEnd );
			endParent = findTopLevelParent( leaf );
			endParentIndex = textFlow.getChildIndex( endParent );
			
			// Backspace is used to remove cells. Delete has another context.
			//	If Delete and we have a a selection of non-table and table, treat it as Backspace.
			//	Otherwise, just run regulat delete text operation.
			if( _keyCode == Keyboard.DELETE )
			{
				// IF we have a selection that includes a non-table element at anchor or active positions...
				if( !(startParent is TableElement) || !(endParent is TableElement) )
				{
					deleteElements( startParentIndex, endParentIndex );
				}
				// Else is our selection is from one table to another.
				else if( ( (startParent is TableElement) && (endParent is TableElement) ) && startParent != endParent )
				{
					deleteElements( startParentIndex, endParentIndex );
				}
				// Else run regular operation.
				else
				{
					deleteSelectedText();
				}
			}
			// If Backspace, treat as true deletion of elements.
			else
			{
				deleteElements( startParentIndex, endParentIndex );
			}
		}
		
		/**
		 * @private 
		 * 
		 * Runs DeleteTextOperation to remove elements from model.
		 */
		protected function deleteSelectedText():void
		{
			// Remove elements from model.
			if (absoluteStart < absoluteEnd)
			{
				_deleteSelectionOperation = new DeleteTextOperation(originalSelectionState);
				_deleteSelectionOperation.doOperation();
			}
		}
		
		protected function deleteElements( startParentIndex:int, endParentIndex:int ):void
		{
			try
			{
				// Flip flag to recognize that cells are deleted.
				_operationHasDeletedCells = true;
				
				// Group affected elements together as requiring operation.
				var i:int;
				var elemIndex:int;
				var elements:Vector.<FlowElementMark> = new Vector.<FlowElementMark>();
				var tableIndexes:Array = [];
				var element:FlowElement;
				for( i = startParentIndex; i < endParentIndex + 1; i++ )
				{
					element = textFlow.getChildAt( i );
					// Found index of table.
					if( element is TableElement )
					{
						tableIndexes.push( elemIndex );
					}
					// If we are finding TableElements, start pushing any affected non table elements 
					// (those contained in an autosize container) into the list of affection.
					if( tableIndexes.length > 0 )
					{
						elements.push( new FlowElementMark( element, element.getAbsoluteStart() ) );
					}
					elemIndex++;
				}
				
				var controllerIndex:int;
				var controller:ContainerController;
				var container:ISizableContainer;
				var affectedElement:FlowElementMark;
				var tableElement:TableElement;
				var anchor:int;
				var active:int;
				var anchorIndex:int;
				var activeIndex:int;
				// If we are only operating on a single table, we will not have to manage any sandwiched autosize container controllers.
				if( tableIndexes.length == 1 )
				{
					// It is determined that it would be the first in the list based on the aggregate of elements from previous loop.
					affectedElement = elements.shift();
					tableElement = affectedElement.element as TableElement;
					anchor = Math.max( absoluteStart, affectedElement.position );
					active = Math.min( absoluteEnd, affectedElement.position + tableElement.textLength );
					anchorIndex = textFlow.flowComposer.findControllerIndexAtPosition( anchor );
					activeIndex = textFlow.flowComposer.findControllerIndexAtPosition( active );
					activeIndex = Math.min( activeIndex, tableElement.elementalIndex + tableElement.getTableModel().cellAmount - 1 );
					controller = textFlow.flowComposer.getControllerAt( anchorIndex );
					operateOnTable( controller as TableCellContainerController, anchorIndex, activeIndex );
				}
				else if( tableIndexes.length > 1 )
				{
					// We need to chop out any incompassing tables and autosize container controllers.
					var affectedElements:Vector.<FlowElementMark> = elements.slice( 0, tableIndexes.pop() + 1 );
//					var len:int = tableIndexes.pop() - tableIndexes.shift();
//					var affectedElements:Vector.<FlowElementMark> = elements.slice( 0, len );
					var markedAutosizableController:AutosizableContainerController;
					for( i = 0; i < affectedElements.length; i++ )
					{
						affectedElement = affectedElements[i];
						// Find the associated controller and container for the autosizable display.
						controllerIndex = textFlow.flowComposer.findControllerIndexAtPosition( affectedElement.position );
						controller = textFlow.flowComposer.getControllerAt( controllerIndex );
						// If we have an autosizableContainerController that it is sandwhich between two tables.
						// We need to stip it out any any display objects related to it.
						if( controller is AutosizableContainerController )
						{
							// If we haven't already marked a controller for removal...
							if( controller != markedAutosizableController )
								markAutosizableController( controller as AutosizableContainerController );
							// Update reference.
							markedAutosizableController = controller as AutosizableContainerController;
						}
						else if( controller is TableCellContainerController )
						{
							// If the controller is a TableCellContainerController
							//	we know that it is related to a Table.
							// 	We'll need to operate on the Table to remove associated
							//	cell displays and controllers related to selection.
							tableElement = affectedElement.element as TableElement;
							anchor = Math.max( absoluteStart, affectedElement.position );
							active = Math.min( absoluteEnd, affectedElement.position + tableElement.textLength );
							anchorIndex = textFlow.flowComposer.findControllerIndexAtPosition( anchor );
							activeIndex = textFlow.flowComposer.findControllerIndexAtPosition( active );
							activeIndex = Math.min( activeIndex, tableElement.elementalIndex + tableElement.getTableModel().cellAmount - 1 );
							operateOnTable( controller as TableCellContainerController, anchorIndex, activeIndex );
						}
					}
				}
				
				// Now go through marked controllers and remove them from the text flow.
				var controllerMark:ContainerControllerMark;
				for( i = 0; i < _controllerMarks.length; i++ )
				{
					controllerMark = _controllerMarks[i];
					textFlow.flowComposer.removeController( controllerMark.controller );
				}
				// Now go through marked displays and remove from display context.
				var containerMark:ContainerMark;
				for( i = 0; i < _containerMarks.length; i++ )
				{
					containerMark = _containerMarks[i];
					containerMark.displayContext.removeContainer( containerMark.container );
				}
				
				// Move on as we normally would with a DeleteTextOperation.
				// Finally remove elements from model.
				deleteSelectedText();
				
				// IF whole tables are marked fro removal, kill them.
				for( i = 0; i < _tablesToDelete.length; i++ )
				{
					use namespace tlf_internal;
					tableElement =  _tablesToDelete[i];
					// If table element is still held on text flow model, remove it.
					if( textFlow.mxmlChildren.indexOf( tableElement ) > -1 )
					{
					
						TextFlowEdit.findAndRemoveFlowGroupElement( textFlow, tableElement.getAbsoluteStart(), tableElement.getAbsoluteStart() + tableElement.textLength, TableElement );	
					}
					// Else pop it from held list of deleted tables.
					else
					{
						_tablesToDelete.shift();
						--i;
					}
				}
				
				// Now update the major display.
//				_displayContext.updateDisplay();
			}
			catch( e:Error )
			{
				_displayContext.showAlert( "That feature is not supported" );
			}
		}
		
		/**
		 * @private
		 * 
		 * Operates on the AutosizableContainerController to mark the removal of display and controllers. 
		 * @param controller AutosizableContainerController
		 */
		protected function markAutosizableController( controller:AutosizableContainerController ):void
		{
			var container:ISizableContainer = controller.container as ISizableContainer;
			// Mark the controller and remove it.
			var controllerIndex:int = textFlow.flowComposer.getControllerIndex( controller );
			_containerMarks.push( new ContainerMark( container, _displayContext ) );
			_controllerMarks.push( new ContainerControllerMark( controller, controllerIndex ) );
		}
		
		/**
		 * @private
		 * 
		 * Because of the unreliability of getting a accurate end index from elments based on position
		 * we need to traverse backwards and access the correct last index of the requested cell controller. 
		 * @param index int
		 * @return int
		 */
		protected function getReliableEndOfTable( index:int ):int
		{
			var tableController:TableCellContainerController = textFlow.flowComposer.getControllerAt( index ) as TableCellContainerController;
			while( tableController == null )
			{
				tableController = textFlow.flowComposer.getControllerAt( --index ) as TableCellContainerController;
			}
			return index;
		}
		
		/**
		 * @private
		 * 
		 * Operates on a TableElement to mark containers and controllers for removal. 
		 * @param controller TableCellContainerController The affected cell controller that invoked the operation.
		 * @param anchorIndex int The starting index of the cell controller within the flow.
		 * @param activeIndex int The ending index of the cell controller within the flow.
		 */
		protected function operateOnTable( controller:TableCellContainerController, anchorIndex:int, activeIndex:int ):void
		{
			// Follow up tree from controller to get proper models and managers.
			// The overall display manager for the table.
			var manager:ITableElementManager = controller.tableManager;
			// The target TableElement in the flow.
			var tableElement:TableElement = manager.getManagedTableElement();
			// The table model.
			var table:Table = tableElement.getTableModel();
			// The display context for the table.
			var displayContext:IEditorDisplayContext = manager.getDisplayContext();
			// The master display on the editor representing the table.
			var container:TableDisplayContainer = tableElement.getTargetContainer();
			
			// Find all affected cell container controllers.
			var i:int;
			// The container controller for a cell in a table.
			var cellController:ContainerController;
			var cellDisplay:TableCellDisplay;
			var cellContainer:TableCellContainer;
			var cellCount:int;
			for( i = anchorIndex; i < activeIndex + 1; i++ )
			{
				cellController = textFlow.flowComposer.getControllerAt( i );
				cellDisplay = cellController.container as TableCellDisplay;
				cellContainer = cellDisplay.getDisplayContainer() as TableCellContainer;
				// Remove the table data model from the table model.
				table.removeTableData( cellContainer.getData() );
				// Push proper displays and controllers for removal.
				_containerMarks.push( new ContainerMark( cellContainer, displayContext ) );
				_controllerMarks.push( new ContainerControllerMark( cellController, i ) );
				// Update cell count to see if we deleted all the cells from a table.
				++cellCount;
			}
			table.cellAmount -= cellCount;
			table.updateMap();
			
			// If anchor to active encompasses the whole context of a table, push whole table container for removal.
			if( cellCount == displayContext.getContainerLength() )
			{
				_tablesToDelete.push( tableElement );
				_containerMarks.push( new ContainerMark( container, _displayContext ) );
			}
		}
		
		/**
		 * @inherit
		 */
		override public function doOperation():Boolean
		{
			internalDoOperation();
			return true;
		}
		
		/**
		 * @inherit
		 */
		override public function undo():SelectionState
		{ 
			// TODO: Undo any operations done in internalDoOoperation.
			return absoluteStart < absoluteEnd ? _deleteSelectionOperation.undo() : originalSelectionState;
		}
		
		/**
		 * Returns Flag of having operated on cells and elemetns directly.
		 * Else it has run a simple deletion of text. 
		 * @return Boolean
		 */
		public function get operationHasDeletedCells():Boolean
		{
			return _operationHasDeletedCells;
		}
	}
}
import flashx.textLayout.container.ContainerController;
import flashx.textLayout.container.IEditorDisplayContext;
import flashx.textLayout.container.ISizableContainer;
import flashx.textLayout.elements.FlowElement;
/**
 * FlowElementMark is an internal class representing a marked flow element for the deletion operation. 
 * @author toddanderson
 */
class FlowElementMark
{
	public var element:FlowElement;
	public var position:int;
	/**
	 * Constructor. 
	 * @param element FlowElement The marked FlowElement.
	 * @param position int The position with the TextFlow that the element resides.
	 */
	public function FlowElementMark( element:FlowElement, position:int )
	{
		this.element = element;
		this.position = position;
	}
}

/**
 * ContainerMark is a mark for a display container related to a controller that is removed from this operation.
 * A list of ContainerMarks is held in order to perfom an undo. 
 * @author toddanderson
 */
class ContainerMark
{
	public var container:ISizableContainer;
	public var displayContext:IEditorDisplayContext;
	public var displayIndex:int;
	public function ContainerMark( container:ISizableContainer, displayContext:IEditorDisplayContext )
	{
		this.container = container;
		this.displayContext = displayContext;
		this.displayIndex = displayContext.getContainerIndex( container );
	}
}

/**
 * ContainerControllerMark is a mark of deleted container controller from this operation.
 * A list of ContainerControllerMarks is held in order to perfom an undo. 
 * @author toddanderson
 */
class ContainerControllerMark
{
	public var controller:ContainerController;
	public var flowIndex:int;
	/**
	 * Constructor. 
	 * @param controller ContainerController The ContainerController instance that is being removed.
	 * @param flowIndex int The index within the flow composer at which it resided.
	 */
	public function ContainerControllerMark( controller:ContainerController, flowIndex:int )
	{
		this.controller = controller;
		this.flowIndex = flowIndex;
	}
}