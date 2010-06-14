package flashx.textLayout.utils
{
	public class DimensionTokenUtil
	{
		public static const TOKEN_PT:String = "pt";
		public static const TOKEN_PX:String = "px";
		public static const TOKEN_PERCENT:String = "%";
		
		static public function convertToPoint( value:* ):Number
		{
			var number:Number = Number( value );
			if( isNaN( number ) ) return Number.NaN;
			
			return number * 72 / 96;
		}
		
		static public function convertToPixel( value:* ):Number
		{
			var number:Number = Number( value );
			if( isNaN( number ) ) return Number.NaN;
			
			return number * 96 / 72;
		}
		
		static public function normalize( token:String ):Number
		{
			if( token.indexOf( DimensionTokenUtil.TOKEN_PX ) != -1 )
			{
				token = token.replace( DimensionTokenUtil.TOKEN_PX, "" );
			}
			else if( token.indexOf( DimensionTokenUtil.TOKEN_PT ) != -1 )
			{
				var size:Number = DimensionTokenUtil.convertToPixel( Number(token.replace(DimensionTokenUtil.TOKEN_PT,"")) );
				token = size.toString();
			}	
			else if( token.indexOf( DimensionTokenUtil.TOKEN_PERCENT ) != -1 )
			{
				return Number.NaN;
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
			return ( isNonTokenedNumberValue( value ) ) ? convertToPoint( value ) + DimensionTokenUtil.TOKEN_PT : value;
		}
	}
}