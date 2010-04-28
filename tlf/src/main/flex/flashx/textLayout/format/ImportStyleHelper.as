package flashx.textLayout.format
{
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.model.style.InlineStyles;
	import flashx.textLayout.utils.StyleAttributeUtil;

	/**
	 * ImportStyleHelper is a helper class for applying inline styles to an elements format. 
	 * @author toddanderson
	 */
	public class ImportStyleHelper
	{
		// TODO: Use text flow to traverse for stylesheets?
		// TODO: Store stylesheets here?
		
		protected var _pendingStyledElements:Vector.<PendingStyleElement>;
		
		/**
		 * Constrcutor.
		 */
		public function ImportStyleHelper() 
		{
			_pendingStyledElements = new Vector.<PendingStyleElement>();
		}
		
		/**
		 * @private
		 * 
		 * Determines the validitiy of the style and its relation to TLF formatting. Returns the correct value.
		 * @param property String
		 * @param value *
		 * @return StyleProperty
		 */
		protected function normalizeFormatValue( property:String, value:* ):StyleProperty
		{
			switch( property )
			{
				case "color":
					if (value.substr(0, 1) == "#")
						value = "0x" + value.substr(1, value.length-1);
					value = (value.toLowerCase().substr(0, 2) == "0x") ? parseInt(value) : NaN;
					break;
				case "mso":
					property = "fontSize";
				case "fontSize":
					var fontSizeValue:String = value.toString();
					if( fontSizeValue.indexOf( "px" ) != -1 )
					{
						fontSizeValue = fontSizeValue.replace( "px", "" );
					}
					else if( fontSizeValue.indexOf( "pt" ) != -1 )
					{
						var size:Number = Number(fontSizeValue.replace("pt","")) * 96 / 72;
						fontSizeValue = size.toString();
					}	
					value = Number(fontSizeValue);
					break;
				case "marginLeft":
					property = "paragraphStartIndent";
					break;
				case "marginRight":
					property = "paragraphEndIndent";
					break;
			}
			return new StyleProperty( property, value );
		}
		
		/**
		 * @private
		 * 
		 * Applies the style property to the format if defined on the format class.
		 * @param format ITextLAyoutFormat
		 * @param property String
		 * @param value *
		 */
		protected function setStylePropertyValue( format:ITextLayoutFormat, property:String, value:* ):void
		{
			try
			{
				var styleProperty:StyleProperty = normalizeFormatValue( property, value );
				format[styleProperty.property] = styleProperty.value;
			}
			catch( e:Error )
			{
				trace( "[" + getQualifiedClassName( this ) + "] :: Style property of type '" + property + "' can not be set on " + getQualifiedClassName( format ) + "." );
			}
		}
		
		/**
		 * @private
		 * 
		 * Applies the inline style attirbute to the flow element. 
		 * @param styleAttribute String The full inline @style attribute.
		 * @param element FlowElement
		 */
		protected function applyStylesToElement( styleAttribute:String, element:FlowElement ):void
		{
			// TODO: Do lookup on style sheets and apply styles to element.
			if( StyleAttributeUtil.isValidStyleString( styleAttribute ) )
			{
				var format:ITextLayoutFormat = ( element.format ) ? element.format : new TextLayoutFormat();
				var styles:Object = StyleAttributeUtil.parseStyles( styleAttribute );
				var property:String;
				for( property in styles )
				{
					setStylePropertyValue( format, StyleAttributeUtil.camelize(property), styles[property] );
				}
				if( element.format != format ) element.format = format;
			}
		}
		
		/**
		 * Marks element as pending style application based on inline @style attirbute from node XML. 
		 * @param node XML
		 * @param element FlowElement
		 */
		public function assignInlineStyle( node:XML, element:FlowElement ):void
		{
			var userStyles:Object = ( element.userStyles ) ? element.userStyles : {};
			userStyles.inline = new InlineStyles( node );
			element.userStyles = userStyles;
			// Push to queue for pending.
			_pendingStyledElements.push( new PendingStyleElement( node, element ) );
		}
		
		/**
		 * Cycles through pending elements that need to styles applied and updates their formats.
		 */
		public function apply():void
		{
			var styleElement:PendingStyleElement;
			while( _pendingStyledElements.length > 0 )
			{
				styleElement = _pendingStyledElements.shift();
				applyStylesToElement( styleElement.node.@style.toString(), styleElement.element );
			}
		}
	}
}

import flashx.textLayout.elements.FlowElement;
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

/**
 * PendingStyleElement is an internal model to mark elements pending style application based on inline @style attribute. 
 * @author toddanderson
 */
class PendingStyleElement
{
	public var node:XML;
	public var element:FlowElement;
	
	/**
	 * Constrctor. 
	 * @param node XML
	 * @param element FlowElement
	 */
	public function PendingStyleElement( node:XML, element:FlowElement )
	{
		this.node = node;
		this.element = element;
}
}