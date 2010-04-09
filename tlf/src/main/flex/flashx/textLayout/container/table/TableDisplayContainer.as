package flashx.textLayout.container.table
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	import flashx.textLayout.container.ISizableContainer;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.model.table.Table;
	
	[Event(name="resize", type="flash.events.Event")]
	/**
	 * TableDisplayContainer is the highlevel display container for the visual displays of a table.
	 * This sits at the highest level of the display list on the editor alongside AutosizableControllerContainers and mainly serves as
	 * a model wrapper for the table to report back size change. 
	 * @author toddanderson
	 */
	public class TableDisplayContainer extends Sprite implements ISizableContainer
	{
		protected var _table:Table;
		protected var _tableElement:TableElement;
		
		/**
		 * Constructir. 
		 * @param tableElement TableElement
		 */
		public function TableDisplayContainer( tableElement:TableElement )
		{
			_tableElement = tableElement;
		}
		
		/**
		 * @private
		 * 
		 * Event handler for resize of table model. 
		 * @param evt Event
		 */
		protected function handleTableResize( evt:Event ):void
		{
			dispatchEvent( evt.clone() );
		}
		
		/**
		 * Initializes the display manager to handle resize events from the model.
		 */
		public function initialize():void
		{
			_table = _tableElement.getTableModel();
			_table.addEventListener( Event.RESIZE, handleTableResize, false, 0, true );
		}
		
		/**
		 * Updates the elemental index within the flow that the table element should work from when composing container. 
		 * @param index int
		 */
		public function setStartControllerIndex( index:int ):void
		{
			_tableElement.elementalIndex = index;
		}
		
		/**
		 * Returns the managed tables cell amount which directly correlated to the container controllers held on this display. 
		 * @return int
		 */
		public function getControllerLength():int
		{
			return ( _table ) ? _table.cellAmount : 0;
		}
		
		/**
		 * Returns the height specified on the model. 
		 * @return Number
		 */
		public function get actualHeight():Number
		{
			return ( _table ) ? _table.height : 0;
		}
		/**
		 * Returns the width specified on the model. 
		 * @return 
		 * 
		 */
		public function get actualWidth():Number
		{
			return ( _table ) ? _table.width : 0;
		}
	}
}