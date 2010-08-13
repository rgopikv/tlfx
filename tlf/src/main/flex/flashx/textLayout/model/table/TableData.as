package flashx.textLayout.model.table
{
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.attribute.TableDataAttribute;
	import flashx.textLayout.model.style.ITableStyle;
	import flashx.textLayout.model.style.TableDataStyle;
	import flashx.textLayout.model.style.TableStyle;

	/**
	 * TableData is abase model fot table data elements including <td> and <th> 
	 * @author toddanderson
	 */
	public class TableData extends TableModelBase
	{
		protected var _parentingTable:Table;
		
		protected var _width:Number;
		protected var _height:Number;
		protected var _explicitWidth:Number;
		private var _explicitHeight:Number;
		
		/**
		 *Constructor.
		 */
		public function TableData( parentingTable:Table )
		{
			context = new TableDataDecorationContext( parentingTable, this, getDefaultAttributes(), getDefaultStyle() );
			_parentingTable = parentingTable;
		}
		
		/**
		 * @inherit
		 */
		override protected function getDefaultAttributes():IAttribute
		{
			return new TableDataAttribute();
		}
		
		/**
		 * @inherit
		 */
		override protected function getDefaultStyle():ITableStyle
		{
			return new TableDataStyle();
		}
		
		public function getContextImplementation():ITableDataDecorationContext
		{
			return ( context as ITableDataDecorationContext );
		}

		/**
		 * Dimensions are preserved for exporting sake and related to the area of which the cell holds content.
		 * These properties are changed on update to related cell containers. 
		 */
		public function get width():Number
		{
			return _width;
		}
		public function set width(value:Number):void
		{
			_width = value;
		}
		public function get height():Number
		{
			return _height;
		}
		public function set height( value:Number ):void
		{
			_height = value;
		}

		public function get explicitWidth():Number
		{
			return _explicitWidth;
		}
		public function set explicitWidth(value:Number):void
		{
			_explicitWidth = value;
		}

		public function get explicitHeight():Number
		{
			return _explicitHeight;
		}
		public function set explicitHeight(value:Number):void
		{
			_explicitHeight = value;
		}
	}
}