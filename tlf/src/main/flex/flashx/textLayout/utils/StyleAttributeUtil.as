package flashx.textLayout.utils
{
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowValueHolder;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.tlf_internal;

	/**
	 * StyleAttributeUtil is a utility class to work with style attribute on HTML fragments. 
	 * @author toddanderson
	 * 
	 */
	public class StyleAttributeUtil
	{
		public static const DASH:String = "-";
		public static const STYLE_DELIMITER:String = ";";
		public static const STYLE_PROPERTY_DELIMITER:String = ":";
		
		/**
		 * Determines the validity of a style property value. 
		 * @param value String
		 * @return Boolean
		 */
		static public function isValidStyleString( value:String ):Boolean
		{
			return value != null && value != "" && value != "undefined" && value.length > 0;
		}
		
		/**
		 * Determines the validity of a style proerty value as a Number. 
		 * @param value String
		 * @return Boolean
		 */
		static public function isValidStyleNumber( value:String ):Boolean
		{
			return value.length > 0 && !isNaN(Number(value));
		}
		
		/**
		 * Determines the validity of a style property as a valid font size. 
		 * @param value String
		 * @return Boolean
		 */
		static public function isValidFontSize( value:String ):Boolean
		{
			return StyleAttributeUtil.isValidStyleNumber(value) && Number(value) != 0;
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
		
		/**
		 * Turns camelCap into dashed properties. 
		 * @param value String
		 * @return String
		 */
		public static function dasherize( value:String ):String
		{
			var match:Array = value.match( /[A-Z]/g );
			var parts:Array = [];
			var index:int = 0;
			while( match.length > 0 )
			{
				var end:int = value.indexOf(match.shift(), index);
				parts.push( value.substring( index, end ) );
				index = end;
			}
			parts.push( value.substring( index, value.length ) );
			if( parts.length > 0 ) value = parts.join(StyleAttributeUtil.DASH);
			value = value.toLowerCase();
			return value;
		}
		
		/**
		 * Strips pre and post white spaces from value. 
		 * @param value String
		 * @return String
		 */
		static public function stripWhitespaces( value:String ):String
		{
			var char:String = value.charAt(0);
			while( char == " " )
			{
				value = value.substr( 1, value.length );
				char = value.charAt( 0 );
			}
			char = value.charAt(value.length - 1);
			while( char == " " )
			{
				value = value.substr( 0, value.length - 1 );
				char = value.charAt(value.length - 1);
			}
			return value;
		}
		
		/**
		 * Parses a style property into a generic key-value object. 
		 * @param style String
		 * @return Object
		 */
		public static function parseStyles( style:String ):Object
		{
			var styleObj:Object = {};
			var styles:Array = style.split(StyleAttributeUtil.STYLE_DELIMITER);
			var i:int;
			var keyValue:Array;
			for( i = 0; i < styles.length; i++ )
			{
				if( styles[i].indexOf(StyleAttributeUtil.STYLE_PROPERTY_DELIMITER) != -1 )
				{
					keyValue = styles[i].split( ":" );
					styleObj[keyValue[0]] = keyValue[1];
				}
			}
			return styleObj;
		}
		
		/**
		 * Does a quick and easy assembly of a style property with proper character formats. 
		 * @param name String
		 * @param value *
		 * @return String
		 */
		public static function assembleStyleProperty( name:String, value:* ):String
		{
			return StyleAttributeUtil.dasherize(name) + StyleAttributeUtil.STYLE_PROPERTY_DELIMITER + value + StyleAttributeUtil.STYLE_DELIMITER;
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
			var fontSize:String = String( tag.@fontSize ).replace( "px", "" );
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