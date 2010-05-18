package flashx.textLayout.model.attribute
{
	import flashx.textLayout.formats.TextLayoutFormat;
	
	/**
	 * TableDataAttribute is a class representation of the atributes for a TableData object. 
	 * @author toddanderson
	 */
	dynamic public class TableDataAttribute extends Attribute
	{
		public static var DEFAULTS:Object;
		
		public static const VALIGN:String = "valign";
		public static const ALIGN:String = "align";
		public static const ROWSPAN:String = "rowspan";
		public static const COLSPAN:String = "colspan";
		public static const WIDTH:String = "width"; // % or number
		public static const HEIGHT:String = "height"; // % or number
		//ALIGN VALUES
		public static const LEFT:String = "left";
		public static const CENTER:String = "center";
		public static const RIGHT:String = "right";
		public static const JUSTIFY:String = "justify";
		// VALIGN VALUES
		public static const TOP:String = "top";
		public static const MIDDLE:String = "middle";
		public static const BOTTOM:String = "bottom";
		
		public static const DEFAULT_DIMENSION:String = "NaN";
		public static const DEPRECATED_TO_STYLE:Array = [TableDataAttribute.WIDTH, TableDataAttribute.HEIGHT];
		
		/**
		 * Returns a default filled in attribute object for a Table Data object.
		 * @return TableDataAttribute
		 */
		public static function getDefaultAttributes():TableDataAttribute
		{
			var attributes:Object = {};
			attributes[TableDataAttribute.VALIGN] = TableDataAttribute.MIDDLE;
			attributes[TableDataAttribute.ALIGN] = TableDataAttribute.LEFT;
			attributes[TableDataAttribute.ROWSPAN] = 1;
			attributes[TableDataAttribute.COLSPAN] = 1;
			attributes[TableDataAttribute.WIDTH] = TableDataAttribute.DEFAULT_DIMENSION;
			attributes[TableDataAttribute.HEIGHT] = TableDataAttribute.DEFAULT_DIMENSION;
			TableDataAttribute.DEFAULTS = attributes;
			return new TableDataAttribute( Attribute.clone( attributes ) );
		}
		
		/**
		 * Constructor. 
		 * @param attributes Object Optional initial attributes.
		 */
		public function TableDataAttribute( attributes:Object = null )
		{
			this.attributes = attributes || {};
		}
		
		/**
		 * @inherit
		 */
		override public function applyAttributesToFormat( format:TextLayoutFormat ):void
		{
			format.textAlign = attributes[TableDataAttribute.ALIGN];
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
				if( attributes[attribute] != TableDataAttribute.DEFAULTS[attribute] )
					stripped[attribute] = attributes[attribute];
			}
			return stripped;
		}
	}
}