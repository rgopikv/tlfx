package flashx.textLayout.model.attribute
{
	import flashx.textLayout.formats.TextLayoutFormat;

	public class TableAttribute extends Attribute
	{
		public static const BORDER:String = "border"; // number
		public static const CELLPADDING:String = "cellpadding"; // number
		public static const CELLSPACING:String = "cellspacing"; // number
		public static const WIDTH:String = "width"; // % or number
		public static const HEIGHT:String = "height"; // % or number
		public static const RULES:String = "rules"; // none, groups, rows, cols, all
		public static const ALIGN:String = "align";
		public static const VALIGN:String = "valign";
		
		public static const RULES_NONE:String = "none";
		public static const RULES_GROUPS:String = "groups";
		public static const RULES_ROWS:String = "rows";
		public static const RULES_ALL:String = "all";
		
		//ALIGN VALUES
		public static const LEFT:String = "left";
		public static const CENTER:String = "center";
		public static const RIGHT:String = "right";
		public static const JUSTIFY:String = "justify";
		// VALIGN VALUES
		public static const TOP:String = "top";
		public static const MIDDLE:String = "middle";
		public static const BOTTOM:String = "bottom";
		
		public static const DEFAULT_WIDTH:String = "NaN";
		public static const DEFAULT_HEIGHT:String = "NaN";
		
		public static const DEFAULT_BORDER:int = -1;
		
		/**
		 * Returns a default filled in attribute object for a Table Data object.
		 * @return TableDataAttribute
		 */
		override protected function getDefault():Object
		{
			var attributes:Object = {};
			attributes[TableAttribute.BORDER] = TableAttribute.DEFAULT_BORDER;
			attributes[TableAttribute.CELLPADDING] = 1;
			attributes[TableAttribute.CELLSPACING] = 2;
			attributes[TableAttribute.WIDTH] = TableAttribute.DEFAULT_WIDTH;
			attributes[TableAttribute.HEIGHT] = TableAttribute.DEFAULT_HEIGHT;
			attributes[TableAttribute.RULES] = TableAttribute.RULES_NONE;
			attributes[TableAttribute.VALIGN] = TableAttribute.TOP;
			attributes[TableAttribute.ALIGN] = TableAttribute.LEFT;
			return attributes;
		}
		
		/**
		 * Constructor. 
		 * @param attributes Object Optional initial attributes.
		 */
		public function TableAttribute()
		{
			super();
		}
	}
}