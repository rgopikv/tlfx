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
		
		/**
		 * Dimensions are preserved for exporting sake and related to the area of which the cell holds content.
		 * These properties are changed on update to related cell containers. 
		 */
		public var width:Number;
		public var height:Number;
		
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
	}
}