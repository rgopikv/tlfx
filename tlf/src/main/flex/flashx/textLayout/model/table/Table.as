package flashx.textLayout.model.table
{
	import flash.events.Event;
	
	import flashx.textLayout.converter.TableMapper;
	import flashx.textLayout.format.IStyle;
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
		
		protected var _tableMapper:TableMapper;
		protected var _precomposedRows:Vector.<TableRow>;
		
		protected var _width:Number;
		protected var _height:Number;
		
		/**
		 * Constructor. 
		 * @param rows Vector.<TableRow> The list of rows.
		 * @param style IStyle The IStyle implementation associated with the Table.
		 */
//		public function Table( rows:Vector.<TableRow>, columns:Vector.<TableColumn>, style:IStyle = null )
//		{
//			super();
//			this.rows = rows;
//			this.columns = columns;
//			this.styles = style;
//		}
		public function Table( precomposedRows:Vector.<TableRow>, style:IStyle = null )
		{
			super();
			_precomposedRows = precomposedRows;
			// Map out the table to fill out composed rows and columns.
			_tableMapper = new TableMapper( this );
			updateMap();
			this.styles = style;
			
		}
		
		/**
		 * Inserts TableData into a TableRow at an index. 
		 * @param item TableData
		 * @param rowIndex int
		 * @param itemIndex int
		 */
		public function addTableData( item:TableData, rowIndex:int, itemIndex:int ):void
		{
			var row:TableRow;
			if( _precomposedRows.length > rowIndex )
			{
				row = _precomposedRows[rowIndex];
				row.tableData.splice( itemIndex, 0, item );
			}
		}
		
		/**
		 * Removes a TableData item from the precomposed rows. 
		 * @param item TableData
		 */
		public function removeTableData( item:TableData ):void
		{
			var row:TableRow;
			var tableData:Vector.<TableData>;
			var itemIndex:int;
			var i:int;
			for( i = 0; i < _precomposedRows.length; i++ )
			{
				row = _precomposedRows[i];
				tableData = row.tableData;
				itemIndex = tableData.indexOf( item );
				if( itemIndex > -1 )
				{
					// run through.
					tableData.splice( itemIndex, 1 );
					if( tableData.length == 0 )
					{
						_precomposedRows.splice( _precomposedRows.indexOf( row ), 1 );
					}
					break;
				}
			}
		}
		
		/**
		 * Adds a row to the end of the flat list of rows. 
		 * @param row TableRow
		 */
		public function addRow( row:TableRow ):void
		{
			_precomposedRows.push( row );
		}
		
		/**
		 * Adds a TableRow to the flat list of rows at a specific index. 
		 * @param row TableRow
		 * @param index int
		 */
		public function addRowAt( row:TableRow, index:int ):void
		{
			_precomposedRows.splice( index, 0, row );
		}
		
		/**
		 * Removes a row from the flat list of rows. 
		 * @param row TableRow
		 */
		public function removeRow( row:TableRow ):void
		{
			var index:int = _precomposedRows.indexOf( row );
			if( index > -1 ) removeRowAt( index );
		}
		
		/**
		 * Removes a row from the flat list of rows at the specified index. 
		 * @param index int
		 */
		public function removeRowAt( index:int ):void
		{
			_precomposedRows.splice( index, 1 );
		}
		
		/**
		 * Runs an update on the map of the table into structures rows and columns.
		 */
		public function updateMap():void
		{	
			_tableMapper.map( _precomposedRows );
		}
		
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