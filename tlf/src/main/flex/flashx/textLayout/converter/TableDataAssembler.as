package flashx.textLayout.converter
{
	import flashx.textLayout.elements.table.TableDataElement;
	import flashx.textLayout.elements.table.TableHeadingElement;
	import flashx.textLayout.model.attribute.TableHeadingAttribute;
	import flashx.textLayout.model.table.ITableBaseDecorationContext;
	import flashx.textLayout.model.table.Table;
	import flashx.textLayout.utils.FragmentAttributeUtil;
	import flashx.textLayout.utils.StyleAttributeUtil;

	/**
	 * TableDataAssembler is an ITagAssembler implementation that converts a model representation of a cell into valid HTML markup. 
	 * @author toddanderson
	 */
	public class TableDataAssembler implements ITagAssembler
	{
		protected var imageProxy:String = "";
		protected var htmlExporter:IHTMLExporter;
		
		/**
		 * Constructor.
		 */		
		public function TableDataAssembler( htmlExporter:IHTMLExporter, imageProxy:String = "" ) 
		{
			this.imageProxy = imageProxy;
			this.htmlExporter = htmlExporter;
		}
		
		/**
		 * @private
		 * 
		 * Replaces properly parsed <img /> tag for TLF back into well formatted <img /> tag for html. 
		 * @param fragment XML
		 */
		protected function replaceImageSourceAttribute( fragment:XML ):void
		{
			var imgList:XMLList = fragment..img;
			var node:XML;
			var source:String;
			var i:int;
			for( i = 0; i < imgList.length(); i++ )
			{
				node = imgList[i] as XML;
				source = node.@source;
				if( source.length > 0 )
				{
					delete node.@source;
					node.@src = source.replace( imageProxy, "" );
				}
			}
		}
		
		/**
		 * Creates a valid <td /> based on supplied data assumed as a TableData instance. 
		 * @param value * A TableData instance.
		 * @return String
		 */
		public function createFragment(value:*):String
		{
			var td:TableDataElement = value as TableDataElement;
			var tdContext:ITableBaseDecorationContext = td.getContext();
			var fragment:XML = ( td is TableHeadingElement ) ? <th /> : <td />;
			htmlExporter.exportElementsToFragment( fragment, td.mxmlChildren );
			replaceImageSourceAttribute( fragment );
			FragmentAttributeUtil.removeAttributesFromFragment( fragment, tdContext.attributes.getStrippedAttributes() );
			htmlExporter.exportStyleHelper.applyStyleAttributesFromElement( fragment, td );
			return fragment.toXMLString();
		}
	}
}