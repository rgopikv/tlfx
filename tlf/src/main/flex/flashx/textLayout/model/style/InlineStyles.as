package flashx.textLayout.model.style
{
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.utils.StyleAttributeUtil;

	/**
	 * InlineStyles is a basic model for holding attibutes related to a FlowElement as they pertain to id and class of style. 
	 * An InlineStyles object is handed to a FlowElement through its userStyles property.
	 * @author toddanderson
	 */
	public class InlineStyles
	{
		public var node:XML;
		public var styleId:String;
		public var styleClass:String;
		public var appliedStyle:*; 			/* Style applied from stylesheet */
		public var explicitStyle:Object; 	/* Generic object fo key/value pairs for style properties. */
		
		/**
		 * Constructor. 
		 * @param elementTag XML The tag to parse.
		 */
		public function InlineStyles( elementTag:XML = null )
		{
			// Deserialize style atts from tag if available.
			if( elementTag )
				deserialize( elementTag );
		}
		
		/**
		 * Serializes held properties to a tag. 
		 * @param tag XML
		 */
		public function serialize( tag:XML ):void
		{	
			if( styleId != null )
				tag.@id = styleId;
			
			if( styleClass != null )
				tag["@class"] = styleClass;
		}
		
		/**
		 * Deserializes tag attributes to properties. 
		 * @param tag XML
		 */
		public function deserialize( tag:XML ):void
		{
			id = null;
			styleClass = null;
			node = tag;
			
			var id:String = ( tag ) ? tag.@id : null;
			if( id && id.length > 0 ) styleId = id;
			
			var clazz:String = ( tag ) ? tag["@class"] : null;
			if( clazz && clazz.length > 0 ) styleClass = clazz; 
			
			var style:String = ( tag ) ? tag.@style : null;
			if( style && style.length > 0 ) explicitStyle = StyleAttributeUtil.parseStyles( style );
		}
	}
}