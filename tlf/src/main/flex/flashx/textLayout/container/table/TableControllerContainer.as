package flashx.textLayout.container.table
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	import flashx.textLayout.container.ISizableContainer;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.model.table.Table;
	
	[Event(name="resize", type="flash.events.Event")]
	public class TableControllerContainer extends Sprite implements ISizableContainer
	{
		protected var _table:Table;
		protected var _tableElement:TableElement;
		
		public function TableControllerContainer( tableElement:TableElement )
		{
			_tableElement = tableElement;
		}
		
		protected function handleTableResize( evt:Event ):void
		{
			dispatchEvent( evt.clone() );
		}
		
		public function initialize():void
		{
			_table = _tableElement.getTableModel();
			_table.addEventListener( Event.RESIZE, handleTableResize, false, 0, true );
		}
		
		public function get actualHeight():Number
		{
			return ( _table ) ? _table.height : 0;
		}
		
		public function get actualWidth():Number
		{
			return ( _table ) ? _table.width : 0;
		}
	}
}