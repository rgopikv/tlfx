package flashx.textLayout.model.table
{
	import flash.events.Event;
	
	import flashx.textLayout.converter.TableMapper;
	import flashx.textLayout.elements.table.TableRowElement;
	import flashx.textLayout.model.attribute.TableAttribute;

	[Event(name="resize", type="flash.events.Event")]
	/**
	 * Table represents the data associated with a Table. 
	 * @author toddanderson
	 */
	public class Table extends TableBaseElement
	{
		public var rows:Vector.<TableRow>;
		public var columns:Vector.<TableColumn>;
		public var cellAmount:int;
		
		protected var _width:Number;
		protected var _height:Number;
		
		/**
		 * Constructor. 
		 * @param rows Vector.<TableRow> The list of rows.
		 */
		public function Table() { super() }
		
		/**
		 * @inherit
		 */
		override protected function setDefaultAttributes():void
		{
			attributes = TableAttribute.getDefaultAttributes();
		}
		
		/**
		 * Returns the cellspacing attribute value. 
		 * @return int
		 */
		public function get cellspacing():int
		{
			if( attributes == null ) return TableAttribute.DEFAULTS[TableAttribute.CELLSPACING];
			return attributes[TableAttribute.CELLSPACING];
		}
		
		/**
		 * Returns the cellpadding attribute value. 
		 * @return int
		 */
		public function get cellpadding():int
		{
			if( attributes == null ) return TableAttribute.DEFAULTS[TableAttribute.CELLPADDING];
			return attributes[TableAttribute.CELLPADDING];
		}
		
		/**
		 * Returns the specified width for the table. 
		 * @return Number
		 */
		public function get width():Number
		{
			return _width;
		}
		public function set width( value:Number ):void
		{
			if( value == _width ) return;
			
			_width = value;
			dispatchEvent( new Event( Event.RESIZE ) );
		}
		
		/**
		 * Returns the specified height for the table. 
		 * @return String
		 */
		public function get height():Number
		{
			return _height;
		}
		public function set height( value:Number ):void
		{
			if( value == height ) return;
			
			_height = value;
			dispatchEvent( new Event( Event.RESIZE ) );
		}
	}
}