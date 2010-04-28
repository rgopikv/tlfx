package flashx.textLayout.converter
{
	import flashx.textLayout.elements.table.TableDataElement;
	import flashx.textLayout.elements.table.TableRowElement;
	import flashx.textLayout.format.ExportStyleHelper;
	import flashx.textLayout.utils.FragmentAttributeUtil;

	/**
	 * TableRowAssembler is an ITagAssembler implementation that converts a modle representation of a table row into valid HTML markup. 
	 * @author toddanderson
	 */
	public class TableRowAssembler implements ITagAssembler
	{
		protected var htmlExporter:IHTMLExporter;
		protected var cellAssembler:ITagAssembler;
		
		/**
		 * Constructor.
		 * @param cellAssembler ITagAssembler The implementation that handles assembling cell data into a fragment.
		 */
		public function TableRowAssembler( cellAssembler:ITagAssembler, htmlExporter:IHTMLExporter )
		{
			this.cellAssembler = cellAssembler;
			this.htmlExporter = htmlExporter;
		}
		
		/**
		 * Creates a row fragment based on supplied data.
		 * @param value * The data to base a row on.
		 * @return String
		 */
		public function createFragment( value:* ):String
		{
			var fragment:XML = <tr />;
			var tr:TableRowElement = value as TableRowElement;
			FragmentAttributeUtil.assignAttributes( fragment, tr.attributes.getStrippedAttributes() );
			
			var cells:Vector.<TableDataElement> = tr.children();
			var i:int;
			for( i = 0; i < cells.length; i++ )
			{
				if( cells[i] as TableDataElement )
					fragment.appendChild( XML( cellAssembler.createFragment( cells[i] as TableDataElement ) ) );
			}
			htmlExporter.exportStyleHelper.applyStyleAttributesFromElement( fragment, tr );
			return fragment.toXMLString();
		}
	}
}