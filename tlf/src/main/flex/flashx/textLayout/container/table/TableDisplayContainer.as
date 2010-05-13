package flashx.textLayout.container.table
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.container.ISizableContainer;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.model.style.TableStyle;
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
		
		protected var _background:Shape;
		protected var _border:Shape;
		protected var _cellHolder:Sprite;
		
		/**
		 * Constructir. 
		 * @param tableElement TableElement
		 */
		public function TableDisplayContainer( tableElement:TableElement )
		{
			_tableElement = tableElement;
			createChildren();
		}
		
		protected function createChildren():void
		{
			_background = new Shape();
			_border = new Shape();
			_cellHolder = new Sprite();
			
			addChild( _background );
			addChild( _border );
			addChild( _cellHolder );
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
		 * Returns the elemental index within the flow that the references table element should work from when composing container. 
		 * @return int
		 */
		public function getStartControllerIndex():int
		{
			return _tableElement.elementalIndex;
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
		 * Cleans for removal.
		 */
		public function dispose():void
		{
			_table.removeEventListener( Event.RESIZE, handleTableResize, false );
		}
		
		/**
		 * Returns defined instance of background display. 
		 * @return Shape
		 */
		public function get backgroundDisplay():Shape
		{
			return _background;
		}
		
		/**
		 * Returns defined instance of border display. 
		 * @return Shape
		 */
		public function get borderDisplay():Shape
		{
			return _border;
		}
		
		/**
		 * Returns defined instance of cell holder display. 
		 * @return DisplayObjectContainer
		 */
		public function get cellHolder():DisplayObjectContainer
		{
			return _cellHolder;
		}
		
		/**
		 * Accessor/Modifier for x offset of cell holder display. 
		 * @return Number
		 */
		public function get cellOffsetX():Number
		{
			return _cellHolder.x;
		}
		public function set cellOffsetX( value:Number ):void
		{
			_cellHolder.x = value;
		}
		
		/**
		 * Accessor/Modifier for y offset of cell holder display. 
		 * @return Number
		 */
		public function get cellOffsetY():Number
		{
			return _cellHolder.y;
		}
		public function set cellOffsetY( value:Number ):void
		{
			_cellHolder.y = value;
		}
		
		/**
		 * Returns the height specified on the model. 
		 * @return Number
		 */
		public function get actualHeight():Number
		{
			var amount:Number = 0;
			if( _table )
			{
				amount = _table.getComputedHeight();
			}
			return amount;
		}
		/**
		 * Returns the width specified on the model. 
		 * @return 
		 * 
		 */
		public function get actualWidth():Number
		{
			var amount:Number = 0;
			if( _table )
			{
				amount = _table.getComputedWidth();
			}
			return amount;
		}
	}
}