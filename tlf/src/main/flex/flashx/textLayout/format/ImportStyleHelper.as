package flashx.textLayout.format
{
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.IManagedInlineGraphicSource;
	import flashx.textLayout.elements.InlineGraphicElement;
	import flashx.textLayout.elements.list.ListItemBaseElement;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.model.style.InlineStyles;
	import flashx.textLayout.utils.ColorValueUtil;
	import flashx.textLayout.utils.StyleAttributeUtil;

	/**
	 * ImportStyleHelper is a helper class for applying inline styles to an elements format. 
	 * @author toddanderson
	 */
	public class ImportStyleHelper implements IImportStyleHelper
	{
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
		 * Applies the style property to the format if defined on the format class.
		 * @param format ITextLAyoutFormat
		 * @param property String
		 * @param value *
		 */
		protected function setStylePropertyValue( format:ITextLayoutFormat, property:String, value:* ):void
		{
			try
			{
				var styleProperty:StyleProperty = StyleProperty.normalizeForFormat( property, value );
				format[styleProperty.property] = styleProperty.value;
			}
			catch( e:Error )
			{
				//trace( "[" + getQualifiedClassName( this ) + "] :: Style property of type '" + property + "' can not be set on " + getQualifiedClassName( format ) + "." );
			}
		}
		
		/**
		 * @private
		 * 
		 * Checks to see if the element is managing other elements, as is the case with InlineGraphicElement source being an IManagedInlineGraphicSource with variables.
		 * If the element is managing another element, pass along the InlineStyles. 
		 * @param element FlowElement
		 */
		protected function applyManagedStyles( element:FlowElement ):void
		{
			var type:Class = Class( getDefinitionByName( getQualifiedClassName( element ) ) );
			switch( type )
			{
				case InlineGraphicElement:
					if( ( element as InlineGraphicElement ).source is IManagedInlineGraphicSource )
					{
						var src:IManagedInlineGraphicSource = ( ( element as InlineGraphicElement ).source as IManagedInlineGraphicSource );
					}
					break;
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
			var format:ITextLayoutFormat = getFormatFromStyleAttribute( styleAttribute, element.format );
			if( element.format != format ) element.format = format;
			if( element is InlineGraphicElement )
			{
				var graphicElement:InlineGraphicElement = ( element as InlineGraphicElement );
				if( graphicElement.source is IManagedInlineGraphicSource )
				{
					( graphicElement.source as IManagedInlineGraphicSource ).applyCascadingFormat();
				}
			}
		}
		
		/**
		 * Returns a populated ITextLayoutFormat instance with style formatting based on @style attribute. 
		 * @param styleAttribute String The contents of the @style attribute.
		 * @param heldFormat ITextLayoutFormat The optional previously applied format. 
		 * @return ITextLayoutFormat
		 */
		public function getFormatFromStyleAttribute( styleAttribute:String, heldFormat:ITextLayoutFormat = null ):ITextLayoutFormat
		{
			if( StyleAttributeUtil.isValidStyleString( styleAttribute ) )
			{
				var format:ITextLayoutFormat = ( heldFormat ) ? heldFormat : new TextLayoutFormat();
				var styles:Object = StyleAttributeUtil.parseStyles( styleAttribute );
				var property:String;
				for( property in styles )
				{
					setStylePropertyValue( format, StyleAttributeUtil.stripWhitespaces( StyleAttributeUtil.camelize(property) ), StyleAttributeUtil.stripWhitespaces( styles[property] ) );
				}
				return format;
			}
			return heldFormat;
		}
		
		/**
		 * Marks element as pending style application based on inline @style attirbute from node XML. 
		 * @param node XML
		 * @param element FlowElement
		 */
		public function assignInlineStyle( node:XML, element:FlowElement ):void
		{
			var userStyles:Object = ( element.userStyles ) ? element.userStyles : {};
			var explicitStyle:Object = StyleAttributeUtil.parseStyles( node.@style );
			// Create new.
			if( userStyles.inline == null )
			{
				userStyles.inline = new InlineStyles( node );
			}
			// Assign node value.
			else
			{
				userStyles.inline.node = node;
			}
			// supply explicitStyle
			if( element is ListItemBaseElement )
			{
				var parentNode:XML = node.parent();
				if( parentNode != null )
				{
					var parentStyle:Object = StyleAttributeUtil.parseStyles( parentNode.@style );
					explicitStyle = StyleAttributeUtil.mergeStyles( explicitStyle, parentStyle );
				}
			}
			userStyles.inline.explicitStyle = explicitStyle;
			// Assign user styles.
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
		
		public function clean():void
		{
			// nada.
		}
	}
}

import flashx.textLayout.elements.FlowElement;

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