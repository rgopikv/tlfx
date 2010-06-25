package flashx.textLayout.utils
{
	import flashx.textLayout.model.style.BackgroundShorthand;

	public class BackgroundShorthandUtil
	{
		
		protected static function isColorUnit( value:* ):Boolean
		{
			return !isNaN(ColorValueUtil.normalizeForLayoutFormat( value ));
		}
		
		protected static function indexOfColorUnit( units:Array ):int
		{
			var i:int;
			for( i = 0; i < units.length; i++ )
			{
				if( isColorUnit( units[i] ) )
					return i;
			}
			return -1;
		}
		
		public static function deserializeShortHand( value:* ):BackgroundShorthand
		{
			if( !value ) return null;
			
			var color:*;
			
			var units:Array = value.toString().split( " " );
			var cIndex:int = BackgroundShorthandUtil.indexOfColorUnit( units );
			if( cIndex >= 0 )
			{
				color = ColorValueUtil.normalizeForLayoutFormat( units[cIndex] );
				units.splice( cIndex, 1 );
			}
			
			return new BackgroundShorthand( color );
		}
	}
}