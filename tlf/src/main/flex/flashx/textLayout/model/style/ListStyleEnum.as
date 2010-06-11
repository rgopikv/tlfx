package flashx.textLayout.model.style
{
	public class ListStyleEnum
	{
		public static const UNORDERED_DISC:String = "disc";
		public static const UNORDERED_CIRCLE:String = "circle";
		public static const UNORDERED_SQUARE:String = "square";
		public static const UNORDERED_NONE:String = "none";
		
		public static const ORDERED_DECIMAL:String = "decimal";
		public static const ORDERED_LOWER_ROMAN:String = "lower-roman";
		public static const ORDERED_UPPER_ROMAN:String = "upper-roman";
		public static const ORDERED_LOWER_ALPHA:String = "lower-alpha";
		public static const ORDERED_UPPER_ALPHA:String = "upper-alpha";
		public static const ORDERED_NONE:String = "none";
		
		public static const POSITION_INSIDE:String = "inside";
		public static const POSITION_OUTSIDE:String = "outside";
		
		private static var _unorderedTypes:Array;
		private static var _orderedTypes:Array;
		private static var _positions:Array;
		
		public static function getUnorderedTypes():Array
		{
			if( ListStyleEnum._unorderedTypes == null )
			{
				ListStyleEnum._unorderedTypes = [ListStyleEnum.UNORDERED_DISC,
													ListStyleEnum.UNORDERED_CIRCLE,
													ListStyleEnum.UNORDERED_SQUARE,
													ListStyleEnum.UNORDERED_NONE];
			}
			return ListStyleEnum._unorderedTypes;
		}
		
		public static function getOrderedTypes():Array
		{
			if( ListStyleEnum._orderedTypes == null )
			{
				ListStyleEnum._orderedTypes = [ListStyleEnum.ORDERED_DECIMAL,
												ListStyleEnum.ORDERED_LOWER_ALPHA,
												ListStyleEnum.ORDERED_LOWER_ROMAN,
												ListStyleEnum.ORDERED_UPPER_ALPHA,
												ListStyleEnum.ORDERED_UPPER_ROMAN,
												ListStyleEnum.ORDERED_NONE];
			}
			return ListStyleEnum._orderedTypes;
		}
		
		public static function getAllTypes():Array
		{
			return ListStyleEnum.getOrderedTypes().concat( ListStyleEnum.getUnorderedTypes() );
		}
		
		public static function getPositions():Array
		{
			if( ListStyleEnum._positions == null )
			{
				ListStyleEnum._positions = [ListStyleEnum.POSITION_INSIDE, ListStyleEnum.POSITION_OUTSIDE];
			}
			return ListStyleEnum._positions;
		}
	}
}