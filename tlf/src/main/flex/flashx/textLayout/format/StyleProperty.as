package flashx.textLayout.format
{
	import flashx.textLayout.formats.Direction;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextAlign;
	import flashx.textLayout.utils.ColorValueUtil;
	import flashx.textLayout.utils.DimensionTokenUtil;
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
		 * Determines the comparible value properties of two StyleProperty instances. 
		 * @param formatProperty StyleProperty
		 * @param explicitProperty StyleProperty
		 * @return Boolean
		 */
		public static function isEqual( cssProperty:StyleProperty, explicitProperty:StyleProperty ):Boolean
		{
			// First catch, if they equal each other than move on.
			if( cssProperty.value.toString() == explicitProperty.value.toString() ) return true;
			// Next we check if differing format values are comparible.
			var convertedProperty:StyleProperty = StyleProperty.normalizeForFormat( explicitProperty.property, explicitProperty.value );
			convertedProperty = StyleProperty.normalizePropertyForCSS( convertedProperty.property, convertedProperty.value );
			return ( cssProperty.property == convertedProperty.property && cssProperty.value == convertedProperty.value );
		}
		
		/**
		 * Creates a new StyleProperty that relates to TLF formatting based on property and value. 
		 * @param property
		 * @param value
		 * @return StyleProperty
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
					value = DimensionTokenUtil.normalize( value );
					break;
				case "marginLeft":
					property = "paragraphStartIndent";
					break;
				case "marginRight":
					property = "paragraphEndIndent";
					break;
				case "textIndent":
					value = DimensionTokenUtil.normalize( value );
					break;
				case "letterSpacing":
					property = "trackingRight";
					value = ( value == "normal" || value == "inherit" ) ? 0 : DimensionTokenUtil.normalize( value );
					break;
				case "lineHeight":
					//	[KK]	Return null, as lineHeight causes lines to wrap in on themselves
					return null;
					//	[KK]	This shouldn't be reached until we've had more time to work on implementing a more successful way of dealing with lineHeight
					value = DimensionTokenUtil.normalize( value );
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
					value = DimensionTokenUtil.exportAsPoint( value );
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
				case "trackingRight":
					property = "letterSpacing";
					break;
				case "paragraphSpaceAfter":
				case "paragraphSpaceBefore":
					return null;
					break;
			}	
			return new StyleProperty( StyleAttributeUtil.dasherize(property), value )
		}
	}
}