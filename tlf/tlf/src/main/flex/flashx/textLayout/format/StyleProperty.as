package flashx.textLayout.format
{
	import flashx.textLayout.formats.Direction;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextAlign;
	import flashx.textLayout.utils.ColorValueUtil;
	import flashx.textLayout.utils.StyleAttributeUtil;

	public class StyleProperty
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
		
		/**
		 * Creates a new StyleProperty that relates to TLF formatting based on property and value. 
		 * @param property
		 * @param value
		 * @return 
		 * 
		 */
		public static function normalizeForFormat( property:String, value:* ):StyleProperty
		{
			property = StyleAttributeUtil.camelize( property );
			value = StyleAttributeUtil.stripWhitespaces( value );
			switch( property )
			{
				case "backgroundColor":
				case "color":
					value = ColorValueUtil.normalizeForLayoutFormat( value );
					break;
				case "fontFamily":
					value = escape( value );
					value = value.replace( /%27/g, "" ); 
					value = value.replace( /%22/g, "" );
					value = unescape( value );
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
				case "textIndent":
					value = value.replace( "px", "" );
					break;
			}
			return new StyleProperty( property, value );
		}
		
		/**
		 * Determines CSS related style and values based on properties and formatting. 
		 * @param property String
		 * @param value *
		 * @param format ITextLayoutFormat
		 * @return StyleProperty
		 */
		static public function normalizePropertyForCSS( property:String, value:*, format:ITextLayoutFormat = null ):StyleProperty
		{
			switch( property )
			{
				case "backgroundColor":
				case "color":
					value = ColorValueUtil.normalizeForCSS( value );
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
			return new StyleProperty( StyleAttributeUtil.dasherize(property), value )
		}
	}
}