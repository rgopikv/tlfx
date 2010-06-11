package flashx.textLayout.elements.table
{
	import flash.display.DisplayObjectContainer;
	import flash.events.IEventDispatcher;
	
	import flashx.textLayout.container.IEditorDisplayContext;
	import flashx.textLayout.container.table.ICellContainer;
	import flashx.textLayout.container.table.TableDisplayContainer;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.model.table.Table;

	/**
	 * ITableManager is a manager for a TableElement and its construction and life cycle of a visual table within the text flow. 
	 * @author toddanderson
	 */
	public interface ITableElementManager extends IEventDispatcher
	{
		/**
		 * Starts the management process with necessary targets. 
		 * @param element TableElement
		 * @param targetContainer DisplayObjectContainer
		 */
		function create( element:TableElement, targetContainer:TableDisplayContainer ):void;
		
		/**
		 * Composes the table for initial layout.
		 */
		function compose():void;
		
		/**
		 * Returns the corresponding cell container related to the FlowElement. 
		 * @param element FlowElement
		 * @return ICellContainer
		 */
		function findCellFromElement( element:FlowElement ):ICellContainer;
		
		/**
		 * Returns the managed table element reference. 
		 * @return TableElement
		 */
		function getManagedTableElement():TableElement;
		
		/**
		 * Returns the display context for a managed table. 
		 * @return IEditorDisplayContext
		 */
		function getDisplayContext():IEditorDisplayContext;
		
		/**
		 * Runs a refresh command on the table element manager.
		 */
		function refresh():void;
		
		/**
		 * Performs any cleanup for garbage collection.
		 */
		function dispose():void;
	}
}