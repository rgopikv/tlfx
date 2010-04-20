package flashx.textLayout.format
{
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.model.style.InlineStyles;
	import flashx.textLayout.utils.StyleAttributeUtil;

	public class ExportStyleHelper
	{
		// TODO: Run diffs on stylesheets.
		
		public function ExportStyleHelper() {}
		
		protected function normalizeProperty( property:String, value:* ):StyleProperty
		{
			switch( property )
			{
				case "color":
					value = "#" + value.toString( 16 );
					break;
				case "fontSize":
					value = value + "px";
					break;
			}	
			return new StyleProperty( property, value )
		}
		
		protected function getComputedParentFormat( element:FlowElement ):ITextLayoutFormat
		{
			var format:ITextLayoutFormat;
			var parent:FlowElement;
			var parentList:Array;
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
		
		protected function getDifferingStyles( childFormat:ITextLayoutFormat, parentFormat:ITextLayoutFormat ):Array /* StyleProperty[] */
		{
			var styles:Array = []; /* StyleProperty[] */
			var property:String;
			var propertyList:XMLList = describeType( childFormat )..accessor;
			var i:int;
			for( i = 0; i < propertyList.length(); i++ )
			{
				if( propertyList[i].@access == "writeonly" ) continue;
				property = propertyList[i].@name;
				if( childFormat[property] != undefined )
				{
					try
					{
						if( childFormat[property] != parentFormat[property] )
						{
							styles.push( normalizeProperty( property, childFormat[property] ) );			
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
		
		protected function applySelectorAttributes( node:XML, element:FlowElement ):void
		{
			var inlineStyle:InlineStyles = ( element.userStyles ) ? element.userStyles.inline as InlineStyles : null;
			if( inlineStyle )
			{
				inlineStyle.serialize( node );
			}
		}
		
		public function applyStyleAttributesFromElement( node:XML, element:FlowElement ):Boolean
		{
			// TODO: Strip styles based on stylesheet assignment.
			var childFormat:ITextLayoutFormat = element.format;
			var parentFormat:ITextLayoutFormat = getComputedParentFormat( element );
			var differingStyles:Array = getDifferingStyles( childFormat, parentFormat );
			
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

class StyleProperty
{
	public var property:String;
	public var value:*;
	
	public function StyleProperty( property:String, value:* )
	{
		this.property = property;
		this.value = value;
	}
}