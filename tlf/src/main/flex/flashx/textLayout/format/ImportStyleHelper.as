package flashx.textLayout.format
{
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.model.style.InlineStyles;
	import flashx.textLayout.utils.StyleAttributeUtil;

	public class ImportStyleHelper
	{
		// TODO: Use text flow to traverse for stylesheets?
		// TODO: Store stylesheets here?
		
		public function ImportStyleHelper() {}
		
		protected function normalizeFormatValue( property:String, value:* ):*
		{
			switch( property )
			{
				case "color":
					value = Number( value.toString().split("#").join("0x") );
					break;
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
			}
			return value;
		}
		
		protected function setStylePropertyValue( format:ITextLayoutFormat, property:String, value:* ):void
		{
			//format.fontSize  * 72 / 96
			try
			{
				format[property] = normalizeFormatValue( property, value );
			}
			catch( e:Error )
			{
				trace( "[" + getQualifiedClassName( this ) + "] :: Style property of type '" + property + "' can not be set on " + getQualifiedClassName( format ) + "." );
			}
		}
		
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
					setStylePropertyValue( format, StyleAttributeUtil.camelize(property), StyleAttributeUtil.stripWhitespaces(styles[property]) );
				}
				if( element.format != format ) element.format = format;
			}
		}
		
		public function assignInlineStyle( node:XML, element:FlowElement ):void
		{
			var userStyles:Object = ( element.userStyles ) ? element.userStyles : {};
			userStyles.inline = new InlineStyles( node );
			element.userStyles = userStyles;
			
			applyStylesToElement( node.@style.toString(), element );
		}
	}
}