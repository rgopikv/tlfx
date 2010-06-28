package flashx.textLayout.converter
{
	import flashx.textLayout.elements.table.TableDataElement;
	import flashx.textLayout.elements.table.TableHeadingElement;
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.attribute.TableHeadingAttribute;
	import flashx.textLayout.model.style.ITableStyle;
	import flashx.textLayout.model.table.ITableBaseDecorationContext;
	import flashx.textLayout.model.table.Table;
	import flashx.textLayout.model.table.TableData;
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
		
		protected function affixDimensionsToStyleForElement( element:TableDataElement, fragment:XML, width:Number, height:Number ):void
		{	
			var explicitStyles:Object = StyleAttributeUtil.getExplicitStyle( element );
			if( explicitStyles && explicitStyles.hasOwnProperty( "width" ) ) delete explicitStyles["width"];
			if( explicitStyles && explicitStyles.hasOwnProperty( "height" ) ) delete explicitStyles["height"];
			StyleAttributeUtil.assignDimensionsToTableBaseStyles( fragment, width, height );
		}
		
		/**
		 * Creates a valid <td /> based on supplied data assumed as a TableData instance. 
		 * @param value * A TableData instance.
		 * @return String
		 */
		public function createFragment(value:*):String
		{
			var td:TableDataElement = value as TableDataElement;
			var dataModel:TableData = td.getTableDataModel();
			var tdContext:ITableBaseDecorationContext = td.getContext();
			var attributes:IAttribute = tdContext.getDefinedAttributes();
			
			var fragment:XML = ( td is TableHeadingElement ) ? <th /> : <td />;
			// Export along with styles.
			htmlExporter.exportElementsToFragment( fragment, td.mxmlChildren );
			// Surgery on HTML compliant @src attribute from Flash @source
			replaceImageSourceAttribute( fragment );
			// Assign defined attributes.
			FragmentAttributeUtil.assignAttributes( fragment, attributes );
			StyleAttributeUtil.assembleTableBaseStyles( fragment, td );
			affixDimensionsToStyleForElement( td, fragment, dataModel.width, dataModel.height );
			// Stylize td or th element tag.
			htmlExporter.exportStyleHelper.applyStyleAttributesFromElement( fragment, td );
			
			return fragment.toXMLString();
		}
	}
}