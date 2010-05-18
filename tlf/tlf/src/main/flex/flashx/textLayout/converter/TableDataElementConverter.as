package flashx.textLayout.converter
{
	import flashx.textLayout.utils.StyleAttributeUtil;
	
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.InlineGraphicElement;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;

	/**
	 * The TableDataConverter converts a list of FlowElements into a formatted valid <td /> tag.
	 * @author toddanderson
	 */
	public class TableDataElementConverter
	{
		// TODO: Set inline styles.
		/**
		 * @private
		 * 
		 * Recursively goes through groups and elemnts to tagify a single fragment from element. 
		 * @param element FlowElement
		 * @return XML
		 */
		static protected function tagifyElement( element:FlowElement ):XML
		{
			var tag:XML;
			if( element is FlowGroupElement )
			{
				// Find Group type and set appropriate flag.
				// Create Paragraph.
				if( element is ParagraphElement )
				{
					tag = <p style="margin:0in;margin-bottom:.0001pt" />;
				}
				// Create Div.
				else if( element is DivElement )
				{
					tag = <div />;
				}
				// Create Link.
				else if( element is LinkElement )
				{
					var link:LinkElement = element as LinkElement;
					tag = <a href={link.href} />;
				}
				
				// Cycle through children and recursively add elements to parent tag.
				var children:Array = ( element as FlowGroupElement ).mxmlChildren;
				if( children != null )
				{
					var i:int;
					for( i = 0; i < children.length; i++ )
					{
						tag.appendChild( tagifyElement( children[i] as FlowElement ) );
					}
				}
				else
				{
					trace( element );
				}
			}
			// Create Span.
			else if( element is SpanElement )
			{
				tag = <span>{(element as SpanElement).text}</span>;
			}
			// Create Image.
			else if( element is InlineGraphicElement )
			{
				var el:InlineGraphicElement = element as InlineGraphicElement;
				tag = <img source={el.source} width={el.width} height={el.height} />;
			}
			StyleAttributeUtil.assignStylesFromElement( tag, element );
			return tag;
		}
		
		static protected function isValidStyleString( value:String ):Boolean
		{
			return value != null && value != "" && value != "undefined";
		}
		
		static protected function isValidStyleNumber( value:Number ):Boolean
		{
			return !isNaN(value);
		}
		
		/**
		 * Creates fragment based on supplied data. 
		 * @param value * The data to convert into a fragment.
		 * @return String
		 */
		static public function createFragmentFromElements( openingNode:XML, elements:Array /* FlowElement */ ):String
		{
			var fragment:XML = openingNode;
			var i:int;
			var element:FlowElement;
			for( i = 0; i < elements.length; i++ )
			{
				element = elements[i] as FlowElement;
				fragment.appendChild( TableDataElementConverter.tagifyElement( element ) );
			}
			return fragment.toXMLString();
		}
	}
}