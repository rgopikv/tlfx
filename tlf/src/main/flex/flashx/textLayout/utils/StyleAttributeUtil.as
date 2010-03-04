package flashx.textLayout.utils
{
	import flashx.textLayout.elements.FlowElement;

	public class StyleAttributeUtil
	{
		public static const DASH:String = "-";
		public static const STYLE_DELIMITER:String = ";";
		public static const STYLE_PROPERTY_DELIMITER:String = ":";
		
		static protected function isValidStyleString( value:String ):Boolean
		{
			return value != null && value != "" && value != "undefined";
		}
		
		static protected function isValidStyleNumber( value:Number ):Boolean
		{
			return !isNaN(value);
		}
		
		static protected function isValidFontSize( value:Number ):Boolean
		{
			return !isNaN(value) && value != 0;
		}
			
		/**
		 * Turns any dashed properties to camelCaps. 
		 * @param value String
		 * @return String
		 */
		public static function camelize( value:String ):String
		{
			var i:int;
			var char:String;
			while( value.indexOf( StyleAttributeUtil.DASH ) > -1 )
			{
				i = value.indexOf( StyleAttributeUtil.DASH );
				char = value.charAt(i+1);
				value = value.replace( StyleAttributeUtil.DASH + char, char.toUpperCase() );
			}
			return value;
		}
		
		public static function dasherize( value:String ):String
		{
			var match:* = value.match( /[A-Z]/ig );
			return value;
		}
		
		/**
		 * Assigns styles from FlowElement as individual attributes on tag. 
		 * @param tag XML
		 * @param element FlowElement
		 */
		public static function assignStylesFromElement( tag:XML, element:FlowElement ):void
		{
			var styles:Array = [];
			if( isValidStyleString( element.fontFamily ) )
				styles.push( "font-family:" + element.fontFamily );
			if( isValidStyleString( element.fontWeight ) )
				styles.push( "font-weight:" + element.fontWeight );
			if( isValidStyleString( element.fontStyle ) )
				styles.push( "font-style:" + element.fontStyle );
			if( isValidStyleString( element.textDecoration ) )
				styles.push( "text-decoration:" + element.textDecoration );
			if( isValidStyleNumber( element.color ) )
				styles.push( "color:#" + element.color.toString( 16 ) );
			if( isValidFontSize( element.fontSize ) )
				styles.push( "font-size:" + element.fontSize + "px" );
			if( isValidStyleString( element.textAlign ) )
				styles.push( "text-align:" + element.textAlign );
			
			if( styles.length > 0 )
			{
				var i:int;
				var keyValues:Array;
				var attribute:String;
				var value:String;
				for( i = 0; i < styles.length; i++ )
				{
					keyValues = styles[i].split( StyleAttributeUtil.STYLE_PROPERTY_DELIMITER );
					attribute = StyleAttributeUtil.camelize( keyValues[0] );
					value = keyValues[1].toString();
					tag["@" + attribute] = value;
				}
			}
		}
		
		/**
		 * Strips out any style property attributes and pushes then to a @style attribute. 
		 * @param tag XML
		 */
		static public function assignAttributesAsStyle( tag:XML ):void
		{
			var fontFamily:String = tag.@fontFamily;
			var fontWeight:String = tag.@fontWeight;
			var fontStyle:String = tag.@fontStyle;
			var textDecoration:String = tag.@textDecoration;
			var color:String = tag.@color;
			var fontSize:Number = Number( String( tag.@fontSize ).replace( "px", "" ) );
			var textAlign:String = tag.@textAlign;
			
			var styles:Array = [];
			if( isValidStyleString( fontFamily ) )
				styles.push( "font-family:" + fontFamily );
			if( isValidStyleString( fontWeight ) )
				styles.push( "font-weight:" + fontWeight );
			if( isValidStyleString( fontStyle ) )
				styles.push( "font-style:" + fontStyle );
			if( isValidStyleString( textDecoration ) )
				styles.push( "text-decoration:" + textDecoration );
			if( isValidStyleString( color ) )
				styles.push( "color:" + color );
			if( isValidFontSize( fontSize ) )
				styles.push( "font-size:" + fontSize + "px" );
			if( isValidStyleString( textAlign ) )
				styles.push( "text-align:" + textAlign );
			
			if( styles.length > 0 )
			{
				var style:String = styles.join(StyleAttributeUtil.STYLE_DELIMITER);
				if( isValidStyleString( tag.@style ) )
				{
					style = tag.@style + StyleAttributeUtil.STYLE_DELIMITER + style;
				}
				tag.@style = style;
			}
			
			delete tag.@fontFamily;
			delete tag.@fontWeight;
			delete tag.@fontStyle;
			delete tag.@textDecoration;
			delete tag.@color;
			delete tag.@fontSize;
			delete tag.@textAlign;
		}
	}
}