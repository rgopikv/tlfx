package flashx.textLayout.format
{
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.ExtendedLinkElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.GreetingElement;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.VarElement;
	import flashx.textLayout.elements.list.ListElementX;
	import flashx.textLayout.elements.list.ListItemElementX;
	import flashx.textLayout.elements.table.TableDataElement;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.elements.table.TableHeadingElement;
	import flashx.textLayout.elements.table.TableRowElement;
	import flashx.textLayout.formats.Direction;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextAlign;
	import flashx.textLayout.model.style.InlineStyles;
	import flashx.textLayout.utils.FragmentAttributeUtil;
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
		
		protected function getInlineStyleOfElement( element:FlowElement ):InlineStyles
		{
			if( element )
			{
				if( element.userStyles && ( element.userStyles.inline is InlineStyles ) )
				{
					return element.userStyles.inline as InlineStyles;
				}
			}
			return null;
		}
		/**
		 * Returns the explicit styles set on the element id available. 
		 * @param element FlowElement
		 * @return Object
		 */
		protected function getExplicitStyleOfElement( element:FlowElement ):Object
		{
			var inline:InlineStyles = getInlineStyleOfElement( element );
			if( inline )
			{
				return inline.explicitStyle;
			}
			return null;
		}
		
		protected function mergeDifferingAndExplicitStyles( styles:Object, explicitStyles:Object ):Array /* StyleProperty[] */
		{
			var styleList:Array = []; /* StyleProperty[] */
			// Fill out styles with no-conflictingly styles from explicit.
			var property:String;
			for( property in explicitStyles )
			{
				if( !styles.hasOwnProperty( property ) )
					styles[property] = explicitStyles[property];
			}
			// Fill out style list with StyleProperty instances.
			var styleProperty:StyleProperty;
			for( property in styles )
			{
				styleProperty = new StyleProperty( property, styles[property] );
				styleList.push( styleProperty );
			}
			return styleList;
		}
		
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
				case VarElement:
				case GreetingElement:
					parentList = [LinkElement, ParagraphElement, DivElement, TextFlow];
					break;
				case LinkElement:
				case ExtendedLinkElement:
					parentList = [ParagraphElement, DivElement, TextFlow];
					break;
				case ParagraphElement:
					parentList = [TableDataElement, DivElement, TextFlow];
					break;
				case ListItemElementX:
					parentList = [ListElementX, TextFlow];
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
		protected function getDifferingStyles( childFormat:ITextLayoutFormat, parentFormat:ITextLayoutFormat, element:FlowElement = null ):Object
		{
			var styles:Object = {};
			var property:String;
			var propertyList:XMLList = describeType( childFormat )..accessor;
			var explicitStyle:Object = getExplicitStyleOfElement( element );
			var styleProperty:StyleProperty;
			var childPropertyValue:*;
			var parentPropertyValue:*;
			var explicitProperty:String
			var explicitValue:*;
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
						
						// Differing between child and parent, assumed a custom style.
//						if( childPropertyValue != parentPropertyValue )
//						{
						// Actually, Check if differing between explicit style and defined child style. That should be enough.
							styleProperty = StyleProperty.normalizePropertyForCSS( property, childPropertyValue, childFormat );
							
							if( explicitStyle && explicitStyle[StyleAttributeUtil.dasherize( styleProperty.property )] != null )
							{
								// Run a check that if new style is actually equal to the declard explicit style on import.
								// For instance, if explicitly set as rgb(255,0,0) and we have #ff0000, than keep the original explicit value.
								explicitProperty = StyleAttributeUtil.dasherize( styleProperty.property );
								explicitValue = explicitStyle[explicitProperty];
								if( StyleProperty.isEqual( styleProperty, new StyleProperty( explicitProperty, explicitValue ) ) )
									styleProperty.value = explicitValue;
							} 
							styles[styleProperty.property] = styleProperty.value;
//						}
//						// If not differing, check to see if our explicit style differs
//						else
//						{
//							
//						}
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
		 * Applies inline style attribute to element. Returns flag of inline styles applied to the xml node.
		 * @param node XML
		 * @param element FlowElement
		 * @param format ITextLayoutFormat The format to base the element styles on.
		 * @return Boolean
		 */
		public function applyStyleAttributesFromElement( node:XML, element:FlowElement, format:ITextLayoutFormat = null ):Boolean
		{
			if ( element )
			{
				var inline:InlineStyles = getInlineStyleOfElement( element );
				// serialize attributes.
				if( inline ) inline.serialize( node );
				var childFormat:ITextLayoutFormat = ( format ) ? format : element.format;
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
			var differingStyles:Object = getDifferingStyles( elementFormat, parentFormat, element );
			var explicitStyles:Object = getExplicitStyleOfElement( element );
			var applicableStyles:Array = mergeDifferingAndExplicitStyles( differingStyles, explicitStyles );
			// If we have some applicable styles that differ, strip style node and reassemble.
			// The applicable styles should be a list of StyleProperty instances rom a merge of differing child/parent styles and those explicitly set on import.
			if( applicableStyles.length > 0 )
			{
				var i:int;
				var attribute:StyleProperty;
				var property:String;
				var value:String;
				var style:String = "";
				delete node.@style;
				for( i = 0; i < applicableStyles.length; i++ )
				{
					attribute = applicableStyles[i] as StyleProperty;
					property = attribute.property;
					value = attribute.value;
					style += StyleAttributeUtil.assembleStyleProperty( property, value );
				}
			}
			// Apply @style if key/value pairs are available.
			if( StyleAttributeUtil.isValidStyleString( style ) ) 
			{
				node.@style = style;
			}
			var hasAttributes:Boolean = FragmentAttributeUtil.hasAttributes( node );
			return ( applicableStyles.length > 0 ) || hasAttributes;	
		}
	}
}