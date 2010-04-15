package flashx.textLayout.elements.table
{
	import flashx.textLayout.model.attribute.TableHeadingAttribute;

	public class TableHeadingElement extends TableDataElement
	{
		public function TableHeadingElement()
		{
			super();
		}
		
		/**
		 * @inherit
		 */
		override protected function setDefaultAttributes():void
		{
			attributes = TableHeadingAttribute.getDefaultAttributes();
		}
	}
}