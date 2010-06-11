package flashx.textLayout.utils
{
	import flashx.textLayout.model.style.ListStyleEnum;

	public class ListStyleConversionUtil
	{
		public static const DISC:String = "\u25CF";
		public static const CIRCLE:String = "\u25CB";
		public static const SQUARE:String = "\u25A0";
		
		private static const _NUMBERALS:Array = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];
		private static const _NUMBERS:Array = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
		private static const _ALPHAS:Array = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "x", "y", "z"];
		
		// Courtesy of http://etc.joshspoon.com/2008/12/17/how-to-convert-roman-numerals-and-arabic-numbers-in-actionscript-3/
		static private function romanize( value:int ):String
		{
			var numerals:Array = ListStyleConversionUtil._NUMBERALS;
			var numbers:Array = ListStyleConversionUtil._NUMBERS;
			var romanValue:String = "";
			var i:int;
			for( i = 0; i < numbers.length; i++ )
			{
				while( value >= numbers[i] )
				{
					romanValue += numerals[i];
					value -= numbers[i];
				}
			}
			return romanValue;
		}
		
		static private function alphaize( value:uint ):String
		{
			value = Math.max( value, 0 );
			var alphas:Array = ListStyleConversionUtil._ALPHAS;
			var alphaValue:String = "";
			if( value <= alphas.length )
				alphaValue = alphas[value - 1];
			// TODO: double back for higher than 52 numbers.
			return alphaValue;
		}
		
		static private function stylizeUnordered( type:String, index:int ):String
		{
			var style:String = ListStyleConversionUtil.DISC;
			switch( type )
			{
				case ListStyleEnum.UNORDERED_CIRCLE:
					style = ListStyleConversionUtil.CIRCLE;
					break;
				case ListStyleEnum.UNORDERED_SQUARE:
					style = ListStyleConversionUtil.SQUARE;
					break;
				case ListStyleEnum.UNORDERED_NONE:
					style = "";
					break;
				case ListStyleEnum.UNORDERED_DISC:
					style = ListStyleConversionUtil.DISC;
					break;
				default:
					style = ListStyleConversionUtil.convertAny( type, index );
					break;
			}
			return style;
		}
		
		static public function convertUnordered( type:String, modifier:Number, index:int ):String
		{
			if( type ) return stylizeUnordered( type, index );
				
			if( isNaN( modifier ) || modifier <= 0 ) return ListStyleConversionUtil.DISC;
			else if( modifier % 2 == 1 ) return ListStyleConversionUtil.CIRCLE;
			else if( modifier % 2 == 0 ) return ListStyleConversionUtil.SQUARE;
			return ListStyleConversionUtil.SQUARE;
		}
		
		static public function convertOrdered( type:String, value:uint ):String
		{
			var convertedValue:String = value.toString();
			switch( type )
			{
				case ListStyleEnum.ORDERED_LOWER_ROMAN:
					convertedValue = ListStyleConversionUtil.romanize( value ).toLowerCase();
					break;
				case ListStyleEnum.ORDERED_UPPER_ROMAN:
					convertedValue = ListStyleConversionUtil.romanize( value ).toUpperCase();
					break;
				case ListStyleEnum.ORDERED_LOWER_ALPHA:
					convertedValue = ListStyleConversionUtil.alphaize( value ).toLowerCase();
					break;
				case ListStyleEnum.ORDERED_UPPER_ALPHA:
					convertedValue = ListStyleConversionUtil.alphaize( value ).toUpperCase();
					break;
				case ListStyleEnum.ORDERED_NONE:
				case ListStyleEnum.UNORDERED_NONE:
					convertedValue = "";
					break;
				case ListStyleEnum.ORDERED_DECIMAL:
					convertedValue = value.toString();
					break;
				default:
					convertedValue = ListStyleConversionUtil.convertAny( type, value );
					break;
			}
			convertedValue = convertedValue + ( ( convertedValue.length > 0 ) ? "." : "" );
			return convertedValue;
		}
		
		static public function convertAny( styleType:String, value:* = null ):String
		{
			var convertedType:String = "";
			switch( styleType )
			{
				case ListStyleEnum.ORDERED_LOWER_ROMAN:
				case ListStyleEnum.ORDERED_UPPER_ROMAN:
				case ListStyleEnum.ORDERED_LOWER_ALPHA:
				case ListStyleEnum.ORDERED_UPPER_ALPHA:
				case ListStyleEnum.ORDERED_NONE:
				case ListStyleEnum.UNORDERED_NONE:
				case ListStyleEnum.ORDERED_DECIMAL:
					convertedType = ListStyleConversionUtil.convertOrdered( styleType, value );
					break;
				case ListStyleEnum.UNORDERED_CIRCLE:
					convertedType = ListStyleConversionUtil.CIRCLE;
					break;
				case ListStyleEnum.UNORDERED_DISC:
					convertedType = ListStyleConversionUtil.DISC;
					break;
				case ListStyleEnum.UNORDERED_SQUARE:
					convertedType = ListStyleConversionUtil.SQUARE;
					break;
			}
			return convertedType;
		}
	}
}