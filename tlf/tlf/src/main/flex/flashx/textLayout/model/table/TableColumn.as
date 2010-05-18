package flashx.textLayout.model.table
{
	import flashx.textLayout.elements.table.TableDataElement;

	/**
	 * TableColumn represents a column of cells within a Table model. 
	 * @author toddanderson
	 */
	public class TableColumn extends TableBaseElement
	{
		public var tableData:Vector.<TableDataElement>;
		public var nextColumn:TableColumn;
		public var previousColumn:TableColumn;
		
		public var width:Number;
		public var height:Number;
		
		/**
		 * Constructor. 
		 * @param tableData Vector.<TableData>
		 */
		public function TableColumn( tableData:Vector.<TableDataElement> = null )
		{
			super();
			this.tableData = tableData || new Vector.<TableDataElement>();
		}
	}
}