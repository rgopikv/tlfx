package flashx.textLayout.utils
{
	import flash.utils.Dictionary;

	public class DimensionTokenUtil
	{
		public static const TOKEN_PT:String = "pt";
		public static const TOKEN_PX:String = "px";
		public static const TOKEN_IN:String = "in";
		public static const TOKEN_CM:String = "cm";
		public static const TOKEN_MM:String = "mm";
		public static const TOKEN_PC:String = "pc";
		public static const TOKEN_PERCENT:String = "%";
		public static const TOKEN_EM:String = "em";
		public static var ABSOLUTE_FONT_MAP:Dictionary;
		
		static private function getAbsoluteFontMap():Dictionary
		{
			if( DimensionTokenUtil.ABSOLUTE_FONT_MAP == null )
			{
				// Based on 12pt, 16px standard web browser font size.
				var map:Dictionary = new Dictionary( true );
				map["xx-small"] = 9;
				map["x-small"] = 10;
				map["small"] = 13;
				map["smaller"] = 13;
				map["medium"] = 16;
				map["large"] = 18;
				map["larger"] = 18;
				map["x-large"] = 24;
				map["xx-large"] = 32;
				DimensionTokenUtil.ABSOLUTE_FONT_MAP = map;
			}
			return DimensionTokenUtil.ABSOLUTE_FONT_MAP;
		}
		
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
		
		static public function convertEmToPixel( value:* ):Number
		{
			var number:Number = Number( value );
			if ( isNaN( number ) )
				return Number.NaN;
			
			return number < 1 ? 16 : number * 16;
		}
		
		static public function convertPercentToPixel( value:* ):Number
		{
			var number:Number = Number( value );
			if ( isNaN( number ) )
				return Number.NaN;
			
			return number < 1 ? 16 : number / 100 * 16;
		}
		
		static public function convertAbsoluteSizeToPixel( value:* ):Number
		{
			var map:Dictionary = DimensionTokenUtil.getAbsoluteFontMap();
			if( map.hasOwnProperty( value ) )
			{
				// Values stored in map relate to pixel sizes.
				return map[value];
			}
			return 16;
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
//					return Number.NaN;
					return DimensionTokenUtil.convertPercentToPixel( Number( token ) );
					break;
				case DimensionTokenUtil.TOKEN_EM:
					return DimensionTokenUtil.convertEmToPixel( Number( token ) );
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
					return ( token.length == 0 ) ? convertAbsoluteSizeToPixel( unit ) : Number( token );
					break;
					
			}
			return Number( token );
		}
		
		private static function isNonTokenedNumberValue( value:* ):Boolean
		{
			var charMatch:Array = value.toString().match( /[^0-9\.]/ );
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