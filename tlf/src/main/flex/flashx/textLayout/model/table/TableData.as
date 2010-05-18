package flashx.textLayout.model.table
{
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.attribute.TableDataAttribute;
	import flashx.textLayout.model.style.ITableStyle;
	import flashx.textLayout.model.style.TableStyle;

	/**
	 * TableData is abase model fot table data elements including <td> and <th> 
	 * @author toddanderson
	 */
	public class TableData extends TableModelBase
	{
		protected var _parentingTable:Table;
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
			return TableDataAttribute.getDefaultAttributes();
		}
		
		/**
		 * @inherit
		 */
		override protected function getDefaultStyle():ITableStyle
		{
			return new TableStyle();
		}
		
		public function getContextImplementation():ITableDataDecorationContext
		{
			return ( context as ITableDataDecorationContext );
		}
	}
}