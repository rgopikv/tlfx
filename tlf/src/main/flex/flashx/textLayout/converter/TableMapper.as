package flashx.textLayout.converter
{
	import flashx.textLayout.elements.table.TableDataElement;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.elements.table.TableRowElement;
	import flashx.textLayout.model.table.ITableBaseDecorationContext;
	import flashx.textLayout.model.table.ITableDecorationContext;
	import flashx.textLayout.model.table.Table;
	import flashx.textLayout.model.table.TableColumn;
	import flashx.textLayout.model.table.TableRow;

	/**
	 * TableMapper is a quasi utility class to properly map put rows and columns of a Table model. 
	 * @author toddanderson
	 */
	public class TableMapper
	{
		protected var _tableElement:TableElement;
		
		/**
		 * Constructor. 
		 * @param table Table The model to map rows and columns to.
		 */
		public function TableMapper( tableElement:TableElement )
		{
			_tableElement = tableElement;
		}
		
		/**
		 * @private
		 * 
		 * Maps the table out into a 2-d row/column strcuture in order to properly fill the cell slots. 
		 * @param rows Vector.<TableRow> The unstructured parsed rows of the table.
		 * @param tableRows Vector.<TableRows> The empty list to populate a structured row/column based list of rows.
		 */
		protected function mapTable( rows:Vector.<TableRowElement>, tableRows:Vector.<TableRow> ):void
		{
			var i:int;
			var j:int;
			var rowData:Vector.<TableDataElement>;
			var tableData:TableDataElement;
			var tableDataContext:ITableBaseDecorationContext;
			var attributes:*;
			
			var rowMap:Array = [];
			// Cycle through data and register column and rows for each data.
			for( i = 0; i < rows.length; i++ )
			{
				rowData = rows[i].children();
				if( rowData == null ) continue;
				
				for( j = 0; j < rowData.length; j++ )
				{
					tableData = ( rowData[j] as TableDataElement );
					tableDataContext = tableData.getContext();
					attributes = tableDataContext.attributes as Object;
					// Update slot hash.
					var colindex:int = j;
					var colspanLength:int = attributes.colspan;
					var rowindex:int = i;
					var rowspanLength:int = attributes.rowspan;
					registerRowColumnSlot( tableData, rowMap, colindex, colspanLength, rowindex, rowspanLength );
				}
			}
			// With map set in place, parse map and asemble table rows.
			i = 0;
			var rowColumns:Array;
			for( i = 0; i < rowMap.length; i++ )
			{
				rowColumns = rowMap[i];
				j = 0;
				rowData = new Vector.<TableDataElement>();
				for( j = 0; j < rowColumns.length; j++ )
				{
					rowData.push( rowColumns[j] as TableDataElement );
				}
				tableRows.push( new TableRow( rowData ) );
			}
		}
		
		/**
		 * @private
		 * 
		 * Determines the place of the TableData within a table based on rowspan and colspan of data with the table as a whole. 
		 * @param tableData TableData
		 * @param rowMap Array The 2d map to modify.
		 * @param fromCol int
		 * @param colLength int
		 * @param fromRow int
		 * @param rowLength int
		 */
		protected function registerRowColumnSlot( tableData:TableDataElement, rowMap:Array, fromCol:int, colLength:int, fromRow:int, rowLength:int ):void
		{
			var x:int = fromCol;
			var y:int = fromRow;
			// if slot is filled move over horizontally. mainly to catch rowspan change.
			if( rowMap.length - 1 < y )
			{
				rowMap[y] = [];
			}
			// If a cell is registered which may occus due to row and col span, bump up column position until we find an empty slot.
			while( rowMap[y][x] )
			{
				x++;
			}
			
			var colIndex:int = x;
			var rowIndex:int = y;
			// fill in map.
			var i:int;
			var j:int;
			for( i = x; i < x + colLength; i++ )
			{
				j = fromRow;
				for( j; j < y + rowLength; j++ )
				{
					if( rowMap.length - 1 < j ) rowMap[j] = [];
					// Only register once. IF colspan or rowspan is set, push null for display.
					if( colIndex == i && rowIndex == j )
					{
						rowMap[j][i] = tableData;
					}
					else
					{
						rowMap[j][i] = true;
					}
				}	
			}
		}
		
		/**
		 * @private
		 * 
		 * Establishes iteration of elements that make up rows and data elements. 
		 * @param list Vector.<TableRow>
		 */
		protected function invalidateRowIteration( list:Vector.<TableRow> ):void
		{
			var i:int = 0;
			var j:int = 0;
			var nextRow:TableRow;
			var prevRow:TableRow;
			for( i = 0; i < list.length; i++ )
			{
				var row:TableRow = list[i] as TableRow;
				nextRow = ( i == list.length - 1 ) ? null : list[i+1] as TableRow;
				row.previousRow = prevRow;
				row.nextRow = nextRow;
				prevRow = row;
			}
		}
		
		/**
		 * @private
		 * 
		 * Establishes iteration of elements that make up a table column of data elements. 
		 * @param columns Vector.<TableColumn>
		 * @param rows Vector.<TableRow>
		 */
		protected function invalidateColumnIteration( columns:Vector.<TableColumn>, rows:Vector.<TableRow> ):void
		{
			// First recursively go through each row and add the item along the length at index for a column
			var i:int;
			for( i = 0; i < rows.length; i++ )
			{
				recursivelyInsertIntoColumns( columns, rows[i] as TableRow );
			}
			
			// Iterate through and add next and previous to the target TableColumn.
			var column:TableColumn;
			var nextColumn:TableColumn;
			var previousColumn:TableColumn;
			for( i = 0; i < columns.length; i++ )
			{
				column = columns[i] as TableColumn;
				nextColumn = ( i == columns.length - 1 ) ? null : columns[i+1];
				previousColumn = ( i == 0 ) ? null : columns[i-1];
				column.nextColumn = nextColumn;
				column.previousColumn = previousColumn;
				nextColumn = null;
				previousColumn = null;
			}
		}
		
		/**
		 * @private
		 * 
		 * Recursive function to add an item from a row to a column. 
		 * @param columns Vector.<TableColumn>
		 * @param row TableRow The TableRow to recursively go through adding each TableData item to a specified column.
		 * @param index int The index at which the cursor is at in the TableRow.
		 */
		protected function recursivelyInsertIntoColumns( columns:Vector.<TableColumn>, row:TableRow, index:int = 0 ):void
		{
			var tableData:TableDataElement = row.tableData[index] as TableDataElement;
			if( columns.length - 1 < index )
			{
				columns[index] = new TableColumn( new Vector.<TableDataElement>() );
			}
			var column:TableColumn = columns[index];
			column.tableData.push( tableData );
			// If we haven't reached the end of the column, do it again.
			if( ++index < row.tableData.length )
			{
				recursivelyInsertIntoColumns( columns, row, index );
			}
		}
		
		/**
		 * Composes proper row and columns based on flat list of row data. 
		 * @param precomposedRows Vector.<TableRow>
		 */
		public function map( rows:Vector.<TableRowElement> ):void
		{	
			var table:Table = _tableElement.getTableModel();
			
			// Establish vector of rows and columns.
			var trArray:Vector.<TableRow> = new Vector.<TableRow>();
			var tcArray:Vector.<TableColumn> = new Vector.<TableColumn>();
			
			// Map table into row and column slots.
			// Pass the row vector to be filled.
			mapTable( rows, trArray );
			// use row array to create row iterator.
			invalidateRowIteration( trArray );
			// use row array to create column iterator.
			invalidateColumnIteration( tcArray, trArray );
			
			// Set mapped rows and columns on the Table reference.
			table.rows = trArray;
			table.columns = tcArray;
		}
	}
}