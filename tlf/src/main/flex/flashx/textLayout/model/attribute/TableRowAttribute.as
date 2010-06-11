package flashx.textLayout.model.attribute
{
	import flashx.textLayout.formats.TextLayoutFormat;

	public class TableRowAttribute extends Attribute
	{
		public static const ALIGN:String = "align"; // left, center, right, justify
		public static const VALIGN:String = "valign"; // top, middle, bottom
		
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
		override protected function getDefault():Object
		{
			var attributes:Object = {};
			attributes[TableRowAttribute.VALIGN] = TableRowAttribute.MIDDLE;
			attributes[TableRowAttribute.ALIGN] = TableRowAttribute.LEFT;
			return attributes;
		}
		
		/**
		 * Constructor. 
		 * @param attributes Object Optional initial attributes.
		 */
		public function TableRowAttribute()
		{
			super();
		}
		
		override public function getFormattableAttributes():IAttribute
		{
			if( !isUndefined( TableRowAttribute.ALIGN ) )
			{
				if( _formattableAttribute == null )
					_formattableAttribute = new Attribute();
				
				_formattableAttribute["textAlign"] = this[TableRowAttribute.ALIGN];
			}
			return _formattableAttribute;
		}
	}
}