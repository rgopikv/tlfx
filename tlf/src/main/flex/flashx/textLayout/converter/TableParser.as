package flashx.textLayout.converter
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import flashx.textLayout.events.TagParserCleanCompleteEvent;
	import flashx.textLayout.events.TagParserCleanProgressEvent;
	import flashx.textLayout.format.IStyle;
	import flashx.textLayout.format.TableStyle;
	import flashx.textLayout.model.attribute.TableDataAttribute;
	import flashx.textLayout.model.table.Table;
	import flashx.textLayout.model.table.TableColumn;
	import flashx.textLayout.model.table.TableData;
	import flashx.textLayout.model.table.TableHeading;
	import flashx.textLayout.model.table.TableRow;

	[Event(name="cleanComplete", type="flashx.textLayout.events.TagParserCleanCompleteEvent")]
	/**
	 * TableParser is an ITagParser implementation that parses valid html into a model representation of a Table. 
	 * @author toddanderson
	 */
	public class TableParser extends EventDispatcher implements ITagParser
	{
		protected var _cleaner:ITagCleaner;
		public static const TAG_TD:String = "td";
		public static const TAG_TH:String = "th";
		
		/**
		 * Constructor.
		 */
		public function TableParser( imageProxy:String = "" ) 
		{
			_cleaner = new TableCleaner( imageProxy );
			_cleaner.addEventListener( TagParserCleanCompleteEvent.CLEAN_COMPLETE, handleCleanComplete, false, 0, true );
			_cleaner.addEventListener( TagParserCleanProgressEvent.CLEAN_PROGRESS, handleCleanProgress, false, 0, true );
		}
		
		/**
		 * @private
		 * 
		 * Parses style attribute. 
		 * @param tableNode XML
		 * @return IStyle
		 */
		protected function getStyle( tableNode:XML ):IStyle
		{
			// TODO. Check for attibute style and instantiate the TabStyle with it.
			var style:IStyle = new TableStyle();
			style.deserializeAttribute( tableNode.attribute("style") );
			( style as TableStyle ).border = int( tableNode.attribute("border") );
			return style;
		}
		
		/**
		 * @private
		 * 
		 * Maps the table out into a 2-d row/column strcuture in order to properly fill the cell slots. 
		 * @param rows Vector.<TableRow> The unstructured parsed rows of the table.
		 * @param tableRows Vector.<TableRows> The empty list to populate a structured row/column based list of rows.
		 */
		protected function mapTable( rows:Vector.<TableRow>, tableRows:Vector.<TableRow> ):void
		{
			var i:int;
			var j:int;
			var rowData:Vector.<TableData>;
			var tableData:TableData;
			var attributes:*;
			
			var rowMap:Array = [];
			// Cycle through data and register column and rows for each data.
			for( i; i < rows.length; i++ )
			{
				rowData = rows[i].tableData;
				for( j = 0; j < rowData.length; j++ )
				{
					tableData = ( rowData[j] as TableData );
					attributes = tableData.attributes as Object;
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
				rowData = new Vector.<TableData>();
				for( j = 0; j < rowColumns.length; j++ )
				{
					rowData.push( rowColumns[j] as TableData );
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
		protected function registerRowColumnSlot( tableData:TableData, rowMap:Array, fromCol:int, colLength:int, fromRow:int, rowLength:int ):void
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
			var nextData:TableData;
			var prevData:TableData;
			for( i = 0; i < list.length; i++ )
			{
				var row:TableRow = list[i] as TableRow;
				nextRow = ( i == list.length - 1 ) ? null : list[i+1] as TableRow;
				row.previousRow = prevRow;
				row.nextRow = nextRow;
				prevRow = row;
				
				j = 0;
				for( j; j < row.tableData.length; j++ )
				{
					var data:TableData = row.tableData[j];
					// May be null as cells can occupy row and col spans. If so, move on to real data.
					if( data == null ) continue;
					nextData = ( j == row.tableData.length - 1 ) ? null : row.tableData[j+1] as TableData;
					data.previousTableData = prevData;
					data.nextTableData = nextData;
					prevData = data;
				}
				prevData = null;
				nextData = null;
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
			var tableData:TableData = row.tableData[index] as TableData;
			if( columns.length - 1 < index )
			{
				columns[index] = new TableColumn( new Vector.<TableData>() );
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
		 * @private 
		 * 
		 * Parses attributes on node into generic key/value Object.
		 * @param node XML
		 * @return Object
		 */
		protected function parseAttributes( node:XML ):Object
		{
			var attribute:XML;
			var attributes:Object = {};
			for each( attribute in node.attributes() )
			{
				var propertyName:String = attribute.name().localName;
				var propertyValue:String = attribute.toString();
				attributes[propertyName] = ( isNaN( Number(propertyValue) ) ) ? propertyValue : Number(propertyValue);
			}
			return attributes;
		}
		
		/**
		 * @private
		 * 
		 * Parses each Table Data in a given Table Row. 
		 * @param td XML The markup representing a table cell.
		 * @param parentingAttributes Object The parenting attibutes of the Row.
		 * @return TableData
		 */
		protected function parseTableData( td:XML, parentingAttributes:Object ):TableData
		{
			var cell:TableData = new TableData( td );
			cell.attributes.modifyAttributes( parentingAttributes );
			cell.attributes.modifyAttributes( parseAttributes( td ) );
			return cell;
		}
		
		/**
		 * @privtae
		 * 
		 * Parses and returns a TableHeading. 
		 * @param th XML The markup represeting a table heading.
		 * @param parentingAttributes Object The parenting attibutes of the Row.
		 * @return TableData
		 */
		protected function parseTableHeading( th:XML, parentingAttributes:Object ):TableData
		{
			var cell:TableData = new TableHeading( th );
			cell.attributes.modifyAttributes( parentingAttributes );
			cell.attributes.modifyAttributes( parseAttributes( th ) );
			return cell;
		}
		
		/**
		 * @private
		 * 
		 * Parses each row in the Table. 
		 * @param tr XML XML fragment related to a single Table Row.
		 * @return Array An array of Table Data information.
		 */
		protected function parseTableRow( tr:XML ):TableRow
		{
			var attributes:Object = parseAttributes( tr );
			var tdArray:Vector.<TableData> = new Vector.<TableData>();
			var i:int = 0;
		
			var children:XMLList = tr.children();
			var child:XML;
			var tableData:TableData;
			for( i = 0; i < children.length(); i++ )
			{
				child = children[i] as XML;
				if( child.name() == TableParser.TAG_TD )
				{
					tableData = parseTableData( child, attributes );
				}
				else if( child.name() == TableParser.TAG_TH )
				{
					tableData = parseTableHeading( child, attributes );
				}	
					
				if( tableData ) tdArray.push( tableData );
				tableData = null;
			}
			
			var row:TableRow = new TableRow( tdArray );
			row.attributes.modifyAttributes( attributes );
			return row;
		}
		
		/**
		 * @private
		 * 
		 * Parses the table (whether created generically or using thead, tfoot and tbody) into a constructed top-down sequence of rows. 
		 * @param xml XML
		 * @return Vector.<TableRow>
		 */
		protected function parseTableIntoSequenceRows( xml:XML ):Vector.<TableRow>
		{
			var rows:Vector.<TableRow> = new Vector.<TableRow>();
			
			// straight up list of normal constructed table.
			var trList:XMLList = xml.tr;
			var thList:XMLList = xml.th;
			
			// list of optional sections of table.
			var thead:XMLList = xml.thead;
			var tfoot:XMLList = xml.tfoot;
			var tbody:XMLList = xml.tbody;
			
			// First go through optional thead. tbody, tfoot construction.
			rows = rows.concat( parseHead( thead ) );
			
			// Then move on to normal construction.
			// first go through headers -> they are considered as rows.
			var i:int = 0;
			if( thList.length() > 0 )
			{
				// wrap the header in a row and push to stack.
				rows.push( parseTableRow( wrapHeadersInRow( thList ) ) );
			}
			
			// Then start on body.
			rows = rows.concat( parseBody( tbody ) );
			// then go through rows.
			for( i = 0; i < trList.length(); i++ )
			{
				rows.push( parseTableRow( trList[i] ) );
			}
			
			// Finish up with footer.
			rows = rows.concat( parseFoot( tfoot ) );
			
			return rows;
		}
		
		/**
		 * @private
		 * 
		 * Parses a list of <thead /> tags into a list of TableRow. 
		 * @param head XMLList A List of <thead />
		 * @return Vector.<TableRow>
		 */
		protected function parseHead( head:XMLList ):Vector.<TableRow>
		{
			var list:Vector.<TableRow> = new Vector.<TableRow>();
			var th:XMLList;
			var row:TableRow;
			var i:int;
			for( i = 0; i < head.length(); i++ )
			{
				th = XML( head[i] )..th;
				row = parseTableRow( wrapHeadersInRow( th ) );
				row.isHeader = true;
				list.push( row );
			}
			return list;
		}
		
		/**
		 * @private
		 * 
		 * Parses a list of <tbody /> tags into a list of TableRow. 
		 * @param body XMLList A List of <tbody />
		 * @return Vector.<TableRow>
		 */
		protected function parseBody( body:XMLList ):Vector.<TableRow>
		{
			var list:Vector.<TableRow> = new Vector.<TableRow>();
			var tr:XMLList;
			var row:TableRow;
			var i:int;
			var j:int;
			for( i = 0; i < body.length(); i++ )
			{
				tr = XML( body[i] ).tr;
				for( j = 0; j < tr.length(); j++ )
				{
					row = parseTableRow( tr[j] );
					row.isBody = true;
					list.push( row );
				}
			}
			return list;
		}
		
		/**
		 * @private
		 * 
		 * Parses a list of <tfoot /> tags into TableRow list. 
		 * @param foot XMLList A list of <tfoot />
		 * @return Vector.<TableRow>
		 */
		protected function parseFoot( foot:XMLList ):Vector.<TableRow>
		{
			var list:Vector.<TableRow> = new Vector.<TableRow>();
			var tr:XMLList;
			var row:TableRow;
			var i:int;
			var j:int;
			for( i = 0; i < foot.length(); i++ )
			{
				tr = XML( foot[i] ).tr;
				for( j = 0; j < tr.length(); j++ )
				{
					row = parseTableRow( tr[j] );
					row.isFooter = true;
					list.push( row );
				}
			}
			return list;
		}
		
		/**
		 * @private
		 * 
		 * Wraps <th /> tags in <tr /> in order to parse into TableRow. 
		 * @param headers XMLList List of <th />
		 * @return XML
		 */
		protected function wrapHeadersInRow( headers:XMLList ):XML
		{
			var rowFragment:XML = <tr />;
			var i:int;
			for( i = 0; i < headers.length(); i++ )
			{
				rowFragment.appendChild( headers[i] as XML );	
			}
			return rowFragment;
		}
		
		/**
		 * @private
		 * 
		 * Event handle for progress of clean. 
		 * @param evt TagParserCleanProgressEvent
		 */
		protected function handleCleanProgress( evt:TagParserCleanProgressEvent ):void
		{
			dispatchEvent( evt.clone() );
		}
		
		/**
		 * @private
		 * 
		 * Event handler for complete of clean. 
		 * @param evt TagParserCleanCompleteEvent
		 */
		protected function handleCleanComplete( evt:TagParserCleanCompleteEvent ):void
		{
			dispatchEvent( evt.clone() );
		}
		
		/**
		 * Cleans fragment into nice table, also used for loading images. 
		 * @param fragment String
		 */
		public function clean( fragment:String ):void
		{
			_cleaner.clean( fragment );
		}
		
		/**
		 * Parses HTML <table> element. 
		 * @param fragment String
		 */
		public function parse( fragment:String ):*
		{
			var table:Table;
			try
			{
				XML.ignoreComments = true;
				XML.ignoreWhitespace = true;
				XML.prettyPrinting = false;
				XML.prettyIndent = 0;
				var xml:XML = XML( fragment );
				
				// Establish vector of rows and columns.
				var trArray:Vector.<TableRow> = new Vector.<TableRow>();
				var tcArray:Vector.<TableColumn> = new Vector.<TableColumn>();
				
				// parse into row array.
				var rows:Vector.<TableRow> = parseTableIntoSequenceRows( xml );
				// Map table into row and column slots.
				// Pass the row vector to be filled.
				mapTable( rows, trArray );
				// use row array to create row iterator.
				invalidateRowIteration( trArray );
				// use row array to create column iterator.
				invalidateColumnIteration( tcArray, trArray );
				
				// instantiate a new Table instance.
				table = new Table( trArray, tcArray, getStyle( xml ) );
				table.attributes.modifyAttributes( parseAttributes( xml ) );
			}
			catch( e:Error )
			{
				// Possibly a TypeError.
				trace( e );
			}
			return table;
		}
		
		/**
		 * Performs any necessary clean up instructions.
		 */
		public function dismantle():void
		{
			_cleaner.removeEventListener( TagParserCleanCompleteEvent.CLEAN_COMPLETE, handleCleanComplete, false );
			_cleaner.removeEventListener( TagParserCleanProgressEvent.CLEAN_PROGRESS, handleCleanProgress, false );
			_cleaner.dismantle();
		}
	}
}