package flashx.textLayout.utils
{
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.table.TableBaseElement;
	import flashx.textLayout.model.style.ITableStyle;
	import flashx.textLayout.model.style.InlineStyles;
	import flashx.textLayout.model.style.TableStyle;
	import flashx.textLayout.model.table.ITableBaseDecorationContext;

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
		
		static public function getExplicitStyle( element:FlowElement ):Object
		{
			if( element.userStyles )
			{
				if( element.userStyles.inline as InlineStyles )
				{
					return ( element.userStyles.inline as InlineStyles ).explicitStyle;
				}
			}
			return null;
		}
		
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
					styleObj[StyleAttributeUtil.stripWhitespaces(StyleAttributeUtil.dasherize(keyValue[0]))] = StyleAttributeUtil.stripWhitespaces( keyValue[1] );
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
		 * Creates or appends styles from a box model style for table-base elements into a @style attribute for the node fragment. 
		 * @param fragment XML
		 * @param element TableBaseElement
		 */
		public static function assembleTableBaseStyles( fragment:XML, element:TableBaseElement ):void
		{
			var context:ITableBaseDecorationContext = element.getContext();
			var style:ITableStyle = context.style;
			var exportableStyle:Object = style.getExportableStyle();
			
			var styleDefinition:String = "";
			var property:String;
			for( property in exportableStyle )
			{
				styleDefinition += StyleAttributeUtil.assembleStyleProperty( property, exportableStyle[property] );
			}
			// If no styles, move on.
			if( !StyleAttributeUtil.isValidStyleString( styleDefinition ) ) return;
			
			// If @style currently existant, append.
			if( StyleAttributeUtil.isValidStyleString( fragment.@style ) )
			{
				fragment.@style += styleDefinition;
			}
			// Else add new @style attribute.
			else
			{
				fragment.@style = styleDefinition;
			}
		}
		
		/**
		 * Concatenates the inline syle values from node to masterNode. 
		 * @param node XML
		 * @param masterNode XML
		 */
		static public function concatInlineStyle( node:XML, masterNode:XML ):void
		{
			var nodeStyleAttribute:String = node.@style.toString();
			var masterStyleAttribute:String = masterNode.@style.toString();
			// If we don't have style attributes to concat, forget it.
			if( !StyleAttributeUtil.isValidStyleString( nodeStyleAttribute ) )
			{
				return;
			}
			// Generate generic key/value objects.
			var nodeStyles:Object = StyleAttributeUtil.parseStyles( nodeStyleAttribute );
			var masterStyles:Object = StyleAttributeUtil.parseStyles( masterStyleAttribute );
			// Loop through properties on node and assign to master if not previously defined.
			var property:String;
			for( property in nodeStyles )
			{
				if( !masterStyles[property] )
					masterStyles[property] = nodeStyles[property];
			}
			// Delete the style attribute form master for clean insertion.
			delete masterNode.@style;
			// Loop through key/value and assemble inline @style attribute.
			var style:String = "";
			for( property in masterStyles )
			{
				style += property + StyleAttributeUtil.STYLE_PROPERTY_DELIMITER + masterStyles[property] + StyleAttributeUtil.STYLE_DELIMITER;
			}
			masterNode.@style = style;
		}
	}
}