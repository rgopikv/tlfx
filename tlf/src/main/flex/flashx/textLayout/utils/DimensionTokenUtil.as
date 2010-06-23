package flashx.textLayout.utils
{
	public class DimensionTokenUtil
	{
		public static const TOKEN_PT:String = "pt";
		public static const TOKEN_PX:String = "px";
		public static const TOKEN_IN:String = "in";
		public static const TOKEN_CM:String = "cm";
		public static const TOKEN_MM:String = "mm";
		public static const TOKEN_PC:String = "pc";
		public static const TOKEN_PERCENT:String = "%";
		
		static public function convertPixelToPoint( value:* ):Number
		{
			var number:Number = Number( value );
			if( isNaN( number ) ) return Number.NaN;
			
			return number * 72 / 96;
		}
		
		static public function convertPointToPixel( value:* ):Number
		{
			var number:Number = Number( value );
			if( isNaN( number ) ) return Number.NaN;
			
			return number * 96 / 72;
		}
		
		static public function convertInToPixel( value:* ):Number
		{
			var number:Number = Number( value );
			if( isNaN( number ) ) return Number.NaN;
			
			return number * 25.4 / 0.28;
		}
		
		static public function convertPcToPixel( value:* ):Number
		{
			var number:Number = Number( value );
			if( isNaN( number ) ) return Number.NaN;
			
			return number * (4 / 3) * 12;
		}
		
		static public function convertCmToPixel( value:* ):Number
		{
			var number:Number = Number( value );
			if( isNaN( number ) ) return Number.NaN;
			
			return number * 1 / 0.028;
		}
		
		static public function convertMmToPixel( value:* ):Number
		{
			var number:Number = Number( value );
			if( isNaN( number ) ) return Number.NaN;
			
			return number * 1 / 0.28;
		}
		
		static public function normalize( token:String ):Number
		{
			// Find token.
			var charMatch:Array = token.match( /[^0-9\.]/ );
			var unit:String = ( charMatch && charMatch.length > 0 ) ? token.substring( token.indexOf( charMatch[0] ), token.length ) : "";
			if( unit.length > 0 ) token = token.replace( unit, "" );
			
			switch( unit )
			{
				case DimensionTokenUtil.TOKEN_PT:
					return DimensionTokenUtil.convertPointToPixel( Number( token ) );
					break;
				case DimensionTokenUtil.TOKEN_PERCENT:
					return Number.NaN;
					break;
				case DimensionTokenUtil.TOKEN_IN:
					return DimensionTokenUtil.convertInToPixel( Number( token ) );
					break;
				case DimensionTokenUtil.TOKEN_PC:
					return DimensionTokenUtil.convertPcToPixel( Number( token ) );
					break;
				case DimensionTokenUtil.TOKEN_CM:
					return DimensionTokenUtil.convertCmToPixel( Number( token ) );
					break;
				case DimensionTokenUtil.TOKEN_MM:
					return DimensionTokenUtil.convertMmToPixel( Number( token ) );
					break;
				case DimensionTokenUtil.TOKEN_PX:
				default:
					return Number( token );
					break;
					
			}
			return Number( token );
		}
		
		private static function isNonTokenedNumberValue( value:* ):Boolean
		{
			var charMatch:Array = value.toString().match( /[^0-9.]/ );
			return ( !charMatch || charMatch.length == 0 );
		}
		
		static public function exportAsPixel( value:* ):*
		{
			// If just a straight number, default to px as that is the most likely unit token used within the Flash movie.
			// Else may have already come in as formatted.
			return ( isNonTokenedNumberValue( value ) ) ? value.toString() + DimensionTokenUtil.TOKEN_PX : value
		}
		
		static public function exportAsPoint( value:* ):*
		{
			// If just a straight number, default to px as that is the most likely unit token used within the Flash movie.
			// Else may have already come in as formatted.
			return ( isNonTokenedNumberValue( value ) ) ? convertPixelToPoint( value ) + DimensionTokenUtil.TOKEN_PT : value;
		}
	}
}