package flashx.textLayout.converter
{
	import flashx.textLayout.model.table.TableData;
	import flashx.textLayout.model.table.TableRow;
	import flashx.textLayout.utils.FragmentAttributeUtil;

	/**
	 * TableRowAssembler is an ITagAssembler implementation that converts a modle representation of a table row into valid HTML markup. 
	 * @author toddanderson
	 */
	public class TableRowAssembler implements ITagAssembler
	{
		protected var cellAssembler:ITagAssembler;
		
		/**
		 * Constructor.
		 * @param cellAssembler ITagAssembler The implementation that handles assembling cell data into a fragment.
		 */
		public function TableRowAssembler( cellAssembler:ITagAssembler )
		{
			this.cellAssembler = cellAssembler;
		}
		
		/**
		 * Creates a row fragment based on supplied data.
		 * @param value * The data to base a row on.
		 * @return String
		 */
		public function createFragment( value:* ):String
		{
			var fragment:XML = <tr />;
			var tr:TableRow = value as TableRow;
			FragmentAttributeUtil.assignAttributes( fragment, tr.attributes.getStrippedAttributes() );
			
			var cells:Vector.<TableData> = tr.tableData;
			var i:int;
			for( i = 0; i < cells.length; i++ )
			{
				if( cells[i] as TableData )
					fragment.appendChild( XML( cellAssembler.createFragment( cells[i] as TableData ) ) );
			}
			return fragment.toXMLString();
		}
	}
}