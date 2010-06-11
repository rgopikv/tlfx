package flashx.textLayout.utils
{
	public class DimensionTokenUtil
	{
		static public function normalize( token:String ):Number
		{
			if( token.indexOf( "px" ) != -1 )
			{
				token = token.replace( "px", "" );
			}
			else if( token.indexOf( "pt" ) != -1 )
			{
				var size:Number = Number(token.replace("pt","")) * 96 / 72;
				token = size.toString();
			}	
			else if( token.indexOf( "%" ) != -1 )
			{
				return Number.NaN;
			}
			return Number( token );
		}
		
		static public function export( value:* ):*
		{
			var charMatch:Array = value.toString().match( /[^0-9]/ );
			// If just a straight number, default to px as that is the most liekely unit token used within the Flash movie.
			if( !charMatch || charMatch.length == 0 )
				return value.toString() + "px";
			
			return value;
		}
	}
}