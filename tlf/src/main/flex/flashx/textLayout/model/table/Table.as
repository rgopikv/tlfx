package flashx.textLayout.model.table
{
	import flash.events.Event;
	
	import flashx.textLayout.converter.TableMapper;
	import flashx.textLayout.elements.table.TableRowElement;
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.attribute.TableAttribute;
	import flashx.textLayout.model.style.ITableStyle;
	import flashx.textLayout.model.style.TableStyle;

	[Event(name="resize", type="flash.events.Event")]
	/**
	 * Table represents the data associated with a Table. 
	 * @author toddanderson
	 */
	public class Table extends TableModelBase
	{
		public var rows:Vector.<TableRow>;
		public var columns:Vector.<TableColumn>;
		public var cellAmount:int;
		
		protected var _width:Number;
		protected var _height:Number;
		protected var _maximumWidth:Number;
		
		/**
		 * Constructor. 
		 * @param rows Vector.<TableRow> The list of rows.
		 */
		public function Table() 
		{ 
			context = new TableDecorationContext( this, getDefaultAttributes(), getDefaultStyle() );
		}
		
		/**
		 * @inherit
		 */
		override protected function getDefaultAttributes():IAttribute
		{
			return new TableAttribute();
		}
		
		/**
		 * @inherit
		 */
		override protected function getDefaultStyle():ITableStyle
		{
			return new TableStyle();
		}
		
		public function getContextImplementation():ITableDecorationContext
		{
			return ( context as ITableDecorationContext );
		}
		
		/**
		 * Returns the cellspacing attribute value. 
		 * @return int
		 */
		public function get cellspacing():int
		{
			return ( context as ITableDecorationContext ).determineCellSpacing();
		}
		
		/**
		 * Returns the cellpadding attribute value. 
		 * @return int
		 */
		public function get cellpadding():int
		{
			return ( context as ITableDecorationContext ).determineCellPadding();
		}
		
		/**
		 * Returns the overall computed height of the table for display based on context and held properties. 
		 * @return Number
		 */
		public function getComputedHeight():Number
		{
			return _height + getContextImplementation().getComputedHeightOfBorders() + ( cellspacing * 2 );
		}
		/**
		 * Returns the overall computed width of the table for display based on context and held properties. 
		 * @return Number
		 */
		public function getComputedWidth():Number
		{
			return _width + getContextImplementation().getComputedWidthOfBorders() + ( cellspacing * 2 );
		}
		
		public function getNonEditableHorizontalSpace():Number
		{
			return ( getContextImplementation().getComputedWidthOfBorders() + ( cellspacing * 2 ) ) + ( ( columns.length - 1 ) * cellspacing );
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
			if( value == _height ) return;
			
			_height = value;
			dispatchEvent( new Event( Event.RESIZE ) );
		}
		
		public function get maximumWidth():Number
		{
			return _maximumWidth;
		}
		public function set maximumWidth( value:Number ):void
		{
			if( value == _maximumWidth ) return;
			
			_maximumWidth = value;
			if( _width > _maximumWidth ) width = _maximumWidth;
		}
		
		public function get maximumColumnWidth():Number
		{
			if( isNaN( _maximumWidth ) ) return 1000000;
			
			return _maximumWidth / columns.length;
		}
	}
}