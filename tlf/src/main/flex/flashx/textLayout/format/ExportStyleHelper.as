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
	import flashx.textLayout.formats.Direction;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextAlign;
	import flashx.textLayout.model.style.InlineStyles;
	import flashx.textLayout.utils.StyleAttributeUtil;

	/**
	 * ExportStyleHelper is a helper class to export inline styles associated with FlowElements 
	 * @author toddanderson
	 */
	public class ExportStyleHelper
	{
		// TODO: Run diffs on stylesheets.
		
		/**
		 * Constrcutor.
		 */
		public function ExportStyleHelper() {}
		
		/**
		 * @private
		 * 
		 * Determines CSS related style and values based on properties and formatting. 
		 * @param property String
		 * @param value *
		 * @param format ITextLayoutFormat
		 * @return StyleProperty
		 */
		protected function normalizeProperty( property:String, value:*, format:ITextLayoutFormat = null ):StyleProperty
		{
			switch( property )
			{
				case "color":
					var rgb:String = value.toString( 16 );
					while (rgb.length < 6) 
						rgb = "0" + rgb;
					value = "#" + rgb;
					break;
				case "fontSize":
					value = value + "px";
					break;
				case "textAlign":
					if( value == TextAlign.START )
					{
						value = ( format.direction == Direction.LTR) ? TextAlign.LEFT : TextAlign.RIGHT;
					}
					else if( value == TextAlign.END )
					{
						value = ( format.direction == Direction.LTR) ? TextAlign.RIGHT : TextAlign.LEFT;
					}
					break;
				case "paragraphStartIndent":
					if( format.direction == Direction.RTL )
					{
						property = "marginRight";
					}
					else
					{
						property = "marginLeft";
					}
					break;
				case "paragraphEndIndent":
					if( format.direction == Direction.RTL )
					{
						property = "marginLeft";
					}
					else
					{
						property = "marginRight";
					}
					break;
			}	
			return new StyleProperty( property, value )
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
					while( parent == null && parentList.length > 0 )
					{
						parent = element.getParentByType( parentList.shift() as Class );
					}
					break;
				case LinkElement:
				case ExtendedLinkElement:
					parentList = [ParagraphElement, DivElement, TextFlow];
					while( parent == null && parentList.length > 0 )
					{
						parent = element.getParentByType( parentList.shift() as Class );
					}
					break;
				case ParagraphElement:
					parentList = [DivElement, TextFlow];
					while( parent == null && parentList.length > 0 )
					{
						parent = element.getParentByType( parentList.shift() as Class );
					}
					break;
				case DivElement:
					parentList = [DivElement, TextFlow];
					while( parent == null && parentList.length > 0 )
					{
						parent = element.getParentByType( parentList.shift() as Class );
					}
					break;
			}
			
			if( parent ) format = parent.computedFormat;
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
							styleProperty = normalizeProperty( property, childPropertyValue, childFormat );
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
		protected function applySelectorAttributes( node:XML, element:FlowElement ):void
		{
			var inlineStyle:InlineStyles = ( element.userStyles ) ? element.userStyles.inline as InlineStyles : null;
			if( inlineStyle )
			{
				inlineStyle.serialize( node );
			}
		}
		
		/**
		 * Applies inline style attribute to element. Returns flag of inline styles applied to the xml node.
		 * @param node XML
		 * @param element FlowElement
		 * @return Boolean
		 */
		public function applyStyleAttributesFromElement( node:XML, element:FlowElement ):Boolean
		{
			// TODO: Strip styles based on stylesheet assignment.
			var childFormat:ITextLayoutFormat = element.format;
			var parentFormat:ITextLayoutFormat = getComputedParentFormat( element );
			var differingStyles:Array = getDifferingStyles( childFormat, parentFormat, element );
			
			if( differingStyles.length > 0 )
			{
				var i:int;
				var attribute:StyleProperty;
				var property:String;
				var value:String;
				var style:String;
				for( i = 0; i < differingStyles.length; i++ )
				{
					attribute = differingStyles[i] as StyleProperty;
					property = StyleAttributeUtil.dasherize( attribute.property );
					value = attribute.value;
					style = property + StyleAttributeUtil.STYLE_PROPERTY_DELIMITER + value;
					if( StyleAttributeUtil.isValidStyleString( node.@style ) )
					{
						style = node.@style + StyleAttributeUtil.STYLE_DELIMITER + style;
					}
					node.@style = style;
				}
			}
			applySelectorAttributes( node, element );
			return differingStyles.length > 0;
		}
	}
}

/**
 * StyleProperty is an internal class model to represent a style on key/value pair. 
 * @author toddanderson
 */
class StyleProperty
{
	public var property:String;
	public var value:*;
	
	/**
	 * Constructor. 
	 * @param property String
	 * @param value *
	 */
	public function StyleProperty( property:String, value:* )
	{
		this.property = property;
		this.value = value;
	}
}