package flashx.textLayout.model.table
{
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.attribute.TableHeadingAttribute;

	/**
	 * TableData is abase model fot table heading elements including <th> 
	 * @author toddanderson
	 */
	public class TableHeading extends TableData
	{
		/**
		 * Constructor. 
		 * @param parentingTable Table
		 */
		public function TableHeading(parentingTable:Table)
		{
			super(parentingTable);
		}
		
		/**
		 * @inherit
		 */
		override protected function getDefaultAttributes():IAttribute
		{
			return new TableHeadingAttribute();
		}
	}
}