package flashx.textLayout.utils
{
	public class BoxModelStyleUtil
	{
		public static const THIN:String = "thin";
		public static const MEDIUM:String = "medium";
		public static const THICK:String = "thick";
		
		static public function normalizeBorderUnit( value:Object ):Number
		{
			if( value is String )
			{
				if( value.indexOf( "px" ) != -1 )
				{
					value = value.replace( "px", "" );
				}
				else if( value.indexOf( "pt" ) != -1 )
				{
					value = Number(value.replace("pt","")) * 96 / 72;
				}	
				else
				{
					switch( value )
					{
						case BoxModelStyleUtil.THIN:
							value = 1;
							break;
						case BoxModelStyleUtil.MEDIUM:
							value = 3;
							break;
						case BoxModelStyleUtil.THICK:
							value = 5;
							break;
					}
				}
			}
			return Number(value);
		}
		
		static public function convertBorderUnits( units:Array ):Array
		{
			var i:int = units.length;
			while( --i > -1 )
			{
				units[i] = BoxModelStyleUtil.normalizeBorderUnit( units[i] );
			}
			return units;
		}
		
		static public function convertColorUnits( units:Array ):Array
		{
			var i:int = units.length;
			while( --i > -1 )
			{
				units[i] = ColorValueUtil.normalizeForLayoutFormat( units[i] );
			}
			return units;
		}
	}
}