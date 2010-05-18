package flashx.textLayout.format
{
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.ExtendedLinkElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.table.TableDataElement;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.elements.table.TableHeadingElement;
	import flashx.textLayout.elements.table.TableRowElement;
	import flashx.textLayout.formats.Direction;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextAlign;
	import flashx.textLayout.model.style.InlineStyles;
	import flashx.textLayout.utils.StyleAttributeUtil;

	/**
	 * ExportStyleHelper is a helper class to export inline styles associated with FlowElements 
	 * @author toddanderson
	 */
	public class ExportStyleHelper implements IExportStyleHelper
	{
		// TODO: Run diffs on stylesheets.
		
		/**
		 * Constrcutor.
		 */
		public function ExportStyleHelper() {}
		
		/**
		 * Returns the next possible parent from hiearchical list of possible parents in order to access computed format. 
		 * @param element FlowElement
		 * @param parentList Array An Array of Class type reprsenting the heiarchical strcutrue of parenting elements.
		 * @return FlowElement
		 */
		protected function getParentElementForComputedFormat( element:FlowElement, parentList:Array /* Class[] */ ):FlowElement
		{
			var parent:FlowElement;
			while( parent == null && parentList.length > 0 )
			{
				parent = element.getParentByType( parentList.shift() as Class );
			}
			return parent;
		}
		
		/**
		 * @private
		 * 
		 * Returns the computed format of the parented FlowElement 
		 * @param element FlowElement
		 * @return ITextLayoutFormat
		 */
		protected function getComputedParentFormat( element:FlowElement ):ITextLayoutFormat
		{
			var format:ITextLayoutFormat;
			var parent:FlowElement;
			var parentList:Array;
			// Cycle through the type of element and determine parent format based on that type.
			var type:Class = Class( getDefinitionByName( getQualifiedClassName( element ) ) );
			switch( type )
			{
				case SpanElement:
					parentList = [LinkElement, ParagraphElement, DivElement, TextFlow];
					break;
				case LinkElement:
				case ExtendedLinkElement:
					parentList = [ParagraphElement, DivElement, TextFlow];
					break;
				case ParagraphElement:
					parentList = [TableDataElement, DivElement, TextFlow];
					break;
				case DivElement:
					parentList = [DivElement, TextFlow];
					break;
				case TableHeadingElement:
				case TableDataElement:
					parentList = [TableRowElement];
					break;
				case TableRowElement:
					parentList = [TableElement];
					break;
				case TableElement:
					parentList = [TextFlow];
					break;
			}
			
			// If we have deciphered a heiarchical parent list based on the element type, try to find parent computed format.
			if( parentList )
			{
				// Get the next possible parent for computed format.
				parent = getParentElementForComputedFormat( element, parentList );
				// If a parent has been found, assign format to computed format of parent.
				if( parent )
				{
					format = parent.computedFormat;
				}
			}
			return format;
		}
		
		/**
		 * @private
		 * 
		 * Returns an array of differing styles between child and parent if they are defined. 
		 * @param childFormat ITextLAyoutFormat
		 * @param parentFormat ITextLayoutFormat
		 * @param element FlowElement Optional flow element to determine validity of styles.
		 * @return Array An array of StyleProperty
		 */
		protected function getDifferingStyles( childFormat:ITextLayoutFormat, parentFormat:ITextLayoutFormat, element:FlowElement = null ):Array /* StyleProperty[] */
		{
			var styles:Array = []; /* StyleProperty[] */
			var property:String;
			var propertyList:XMLList = describeType( childFormat )..accessor;
			var styleProperty:StyleProperty;
			var childPropertyValue:*;
			var parentPropertyValue:*;
			var i:int;
			for( i = 0; i < propertyList.length(); i++ )
			{
				if( propertyList[i].@access == "writeonly" ) continue;
				property = propertyList[i].@name;
				if( childFormat[property] != undefined )
				{
					try
					{
						childPropertyValue = childFormat[property];
						parentPropertyValue = parentFormat[property];
						// Special case for links. If they have been decorated as none, then they
						//	could possibly equal the property value of parent
						//	Therefore apply no text-decoration style, however default is 'underline'.
						if( element is LinkElement && property == "textDecoration" )
						{
							if( childPropertyValue == "none" &&
								childPropertyValue == parentPropertyValue )
							{
								parentPropertyValue = undefined;
							}
						}
						if( childPropertyValue != parentPropertyValue )
						{
							styleProperty = StyleProperty.normalizePropertyForCSS( property, childPropertyValue, childFormat );
							styles.push( styleProperty );			
						}
					}
					catch( e:Error )
					{
						// chances are that the property is not held on parent.
						// That is because we are comparing a FlowValueHolder to a computed format for parent.
					}
				}
			}
			return styles;
		}
		
		/**
		 * @private
		 * 
		 * Serializes inline styles onto XML related to element. 
		 * @param node XML
		 * @param element FlowElement
		 */
		protected function applySelectorAttributes( node:XML, element:FlowElement ):Boolean
		{
			var inlineStyle:InlineStyles = ( element.userStyles ) ? element.userStyles.inline as InlineStyles : null;
			if( inlineStyle )
			{
				inlineStyle.serialize( node );
				return inlineStyle.styleId != null || inlineStyle.styleClass != null;
			}
			return false;
		}
		
		/**
		 * Applies inline style attribute to element. Returns flag of inline styles applied to the xml node.
		 * @param node XML
		 * @param element FlowElement
		 * @return Boolean
		 */
		public function applyStyleAttributesFromElement( node:XML, element:FlowElement ):Boolean
		{
			if ( element )
			{
				// TODO: Strip styles based on stylesheet assignment.
				var childFormat:ITextLayoutFormat = element.format;
				var parentFormat:ITextLayoutFormat = getComputedParentFormat( element );
				return applyStyleAttributesFromDifferingStyles( node, parentFormat, childFormat, element );
			}
			return false;
		} 
		
		/**
		 * Constrcuts @style attribute based on differing styles between parent and child formatting. 
		 * @param node XML
		 * @param parentFormat ITextLayoutFormat
		 * @param elementFormat ITextLayoutFormat
		 * @param element FlowElement
		 * @return Boolean
		 */
		public function applyStyleAttributesFromDifferingStyles( node:XML, parentFormat:ITextLayoutFormat, elementFormat:ITextLayoutFormat, element:FlowElement = null ):Boolean
		{
			var differingStyles:Array = getDifferingStyles( elementFormat, parentFormat, element );
			
			delete node.@style;
			if( differingStyles.length > 0 )
			{
				var i:int;
				var attribute:StyleProperty;
				var property:String;
				var value:String;
				var style:String = "";
				for( i = 0; i < differingStyles.length; i++ )
				{
					attribute = differingStyles[i] as StyleProperty;
					property = StyleAttributeUtil.dasherize( attribute.property );
					value = attribute.value;
					style += property + StyleAttributeUtil.STYLE_PROPERTY_DELIMITER + value + StyleAttributeUtil.STYLE_DELIMITER;
				}
			}
			// Apply @style if key/value pairs are available.
			if( StyleAttributeUtil.isValidStyleString( style ) ) 
				node.@style = style;
			// Apply other attributes that relate to style like id and class.
			var requiresInlineStyleAttributes:Boolean;
			if( element )
			{
				requiresInlineStyleAttributes = applySelectorAttributes( node, element );	
			}
			return ( differingStyles.length > 0 ) || requiresInlineStyleAttributes;	
		}
	}
}