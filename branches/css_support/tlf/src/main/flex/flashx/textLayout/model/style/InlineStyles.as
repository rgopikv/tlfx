package flashx.textLayout.model.style
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
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
	public class InlineStyles extends EventDispatcher
	{
		public var node:XML;
		public var styleId:String;
		public var styleClass:String;
		protected var _appliedStyle:*; 			/* Style applied from stylesheet */
		protected var _explicitStyle:Object; 	/* Generic object fo key/value pairs for style properties. */
		
		public static const APPLIED_STYLE_CHANGE:String = "appliedStyleChange";
		public static const EXPLICIT_STYLE_CHANGE:String = "explicitStyleChange";
		
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
			node = tag;
			
			var id:String = tag.@id;
			if( id.length > 0 ) styleId = id;
			
			var clazz:String = tag["@class"];
			if( clazz.length > 0 ) styleClass = clazz; 
			
			var style:String = tag.@style;
			if( style.length > 0 ) explicitStyle = StyleAttributeUtil.parseStyles( style );
		}
		
		public function get appliedStyle():*
		{
			return _appliedStyle;
		}
		public function set appliedStyle( value:* ):void
		{
			_appliedStyle = value;
			dispatchEvent( new Event( InlineStyles.APPLIED_STYLE_CHANGE ) );
		}
		
		public function get explicitStyle():Object
		{
			return _explicitStyle;
		}
		public function set explicitStyle( value:Object ):void
		{
			_explicitStyle = value;
			dispatchEvent( new Event( InlineStyles.EXPLICIT_STYLE_CHANGE ) );
		}
	}
}