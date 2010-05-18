package flashx.textLayout.model.attribute
{
	import flashx.textLayout.formats.TextLayoutFormat;

	public class TableRowAttribute extends Attribute
	{
		public static var DEFAULTS:Object;
		
		public static const ALIGN:String = "align"; // left, center, right, justify
		public static const VALIGN:String = "valing"; // top, middle, bottom
		
		//ALIGN VALUES
		public static const LEFT:String = "left";
		public static const CENTER:String = "center";
		public static const RIGHT:String = "right";
		public static const JUSTIFY:String = "justify";
		// VALIGN VALUES
		public static const TOP:String = "top";
		public static const MIDDLE:String = "middle";
		public static const BOTTOM:String = "bottom";
		
		/**
		 * Returns a default filled in attribute object for a Table Data object.
		 * @return TableDataAttribute
		 */
		public static function getDefaultAttributes():TableRowAttribute
		{
			var attributes:Object = {};
			attributes[TableRowAttribute.VALIGN] = TableRowAttribute.MIDDLE;
			attributes[TableRowAttribute.ALIGN] = TableRowAttribute.LEFT;
			TableRowAttribute.DEFAULTS = attributes;
			return new TableRowAttribute( Attribute.clone( attributes ) );
		}
		
		/**
		 * Constructor. 
		 * @param attributes Object Optional initial attributes.
		 */
		public function TableRowAttribute( attributes:Object = null )
		{
			this.attributes = attributes || {};
		}
		
		/**
		 * @inherit
		 */
		override public function applyAttributesToFormat( format:TextLayoutFormat ):void
		{
			format.textAlign = attributes[TableRowAttribute.ALIGN];
		}
		
		/**
		 * @inherit
		 */
		override public function getStrippedAttributes():Object
		{
			var stripped:Object = {};
			var attribute:String;
			for( attribute in attributes )
			{
				if( attributes[attribute] != TableRowAttribute.DEFAULTS[attribute] )
					stripped[attribute] = attributes[attribute];
			}
			return stripped;
		}
	}
}