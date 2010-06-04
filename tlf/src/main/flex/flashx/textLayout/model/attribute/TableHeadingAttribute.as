package flashx.textLayout.model.attribute
{
	import flashx.textLayout.formats.TextLayoutFormat;

	/**
	 * TableHeadingAttribute serves as possible attribues on a Table Header. 
	 * @author toddanderson
	 */
	dynamic public class TableHeadingAttribute extends Attribute
	{
		public static const VALIGN:String = "valign";
		public static const ALIGN:String = "align";
		public static const ROWSPAN:String = "rowspan";
		public static const COLSPAN:String = "colspan";
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
		 * Returns default TableHeadingAttribute objetc 
		 * @return TableHeadingAttribute
		 */
		override protected function getDefault():Object
		{
			var attributes:Object = {};
			attributes[TableHeadingAttribute.VALIGN] = TableHeadingAttribute.MIDDLE;
			attributes[TableHeadingAttribute.ALIGN] = TableHeadingAttribute.CENTER;
			attributes[TableHeadingAttribute.ROWSPAN] = 1;
			attributes[TableHeadingAttribute.COLSPAN] = 1;
			attributes[TableDataAttribute.WIDTH] = TableDataAttribute.DEFAULT_DIMENSION;
			attributes[TableDataAttribute.HEIGHT] = TableDataAttribute.DEFAULT_DIMENSION;
			return attributes;
		}
		
		/**
		 * Constructor. 
		 * @param attributes Optional default attributes prop/val pairs.
		 */
		public function TableHeadingAttribute()
		{
			super();
		}
	}
}