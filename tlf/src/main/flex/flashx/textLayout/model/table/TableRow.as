package flashx.textLayout.model.table
{
	import flashx.textLayout.elements.table.TableDataElement;
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.attribute.TableRowAttribute;
	import flashx.textLayout.model.style.ITableStyle;
	import flashx.textLayout.model.style.TableStyle;

	/**
	 * TableRow is a representation of a row of TableData (cells) in a Table. 
	 * @author toddanderson
	 */
	public class TableRow extends TableModelBase
	{
		public var tableData:Vector.<TableDataElement>;
		public var nextRow:TableRow;
		public var previousRow:TableRow;
		
		public var width:Number;
		public var height:Number;
		
		// Flags for row pertaining to <thead />, <tfoot /> and <tbody />
		public var isHeader:Boolean;
		public var isFooter:Boolean;
		public var isBody:Boolean;
		
		/**
		 * Constuctor. 
		 * @param tableData Vector.<TableData> The list of TableData (cells) related to this row.
		 */
		public function TableRow( tableData:Vector.<TableDataElement> )
		{
			super();
			this.tableData = tableData;
		}
		
		/**
		 * @inherit
		 */
		override protected function getDefaultAttributes():IAttribute
		{
			return new TableRowAttribute();
		}
		
		/**
		 * Returns the default styles related to this table model instance. 
		 * @return ITableStyle
		 */
		override protected function getDefaultStyle():ITableStyle
		{
			return new TableStyle();
		}
	}
}