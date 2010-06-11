package flashx.textLayout.utils
{
	public class ColorValueUtil
	{
		static public function normalizeForLayoutFormat( value:String ):Number
		{
			var nums:Array = [];
			if ( value.charAt(0) != '#' )
				nums = value.toString().match( /[^a-gA-GrR\(#]?\d{1,3}/g );
			
			if( nums.length > 0 )
			{
				var hexString:String = '#';
				for ( var i:int = 0; i < nums.length; i++ )
				{
					var str:String = nums[i].replace(/[,|\(]/g, '');
					var color:String = uint(str).toString(16);
					while ( color.length < 2 )
						color = color + '0';
					hexString += color;
				}
				while ( hexString.length < 7 )
					hexString = hexString + '0';
				
				value = hexString;
			}
			
			value = ColorValueUtil.validateColor( value.toString() );
			if (value.substr(0, 1) == "#")
				value = "0x" + value.substr(1, value.length-1);
			
			return (value.toLowerCase().substr(0, 2) == "0x") ? parseInt(value) : Number.NaN;
		}
		
		static public function normalizeForCSS( value:Number ):String
		{
			var rgb:String = value.toString( 16 );
			while (rgb.length < 6) 
				rgb = "0" + rgb;
			return ( "#" + rgb );
		}
		
		static public function validateColor( value:String ):String
		{
			value = value.replace( /AliceBlue/ig, '#F0F8FF' );
			value = value.replace( /AntiqueWhite/ig, '#FAEBD7' );
			value = value.replace( /Aqua/ig, '#00FFFF' );
			value = value.replace( /Aquamarine/ig, '#7FFFD4' );
			value = value.replace( /Azure/ig, '#F0FFFF' );
			value = value.replace( /Beige/ig, '#F5F5DC' );
			value = value.replace( /Bisque/ig, '#FFE4C4' );
			value = value.replace( /Black/ig, '#000000' );
			value = value.replace( /BlanchedAlmond/ig, '#FFEBCD' );
			value = value.replace( /Blue/ig, '#0000FF' );
			value = value.replace( /BlueViolet /ig, '#8A2BE2' );
			value = value.replace( /Brown/ig, '#A52A2A' );
			value = value.replace( /BurlyWood/ig, '#DEB887' );
			value = value.replace( /CadetBlue/ig, '#5F9EA0' );
			value = value.replace( /Chartreuse/ig, '#7FFF00' );
			value = value.replace( /Chocolate/ig, '#D2691E' );
			value = value.replace( /Coral/ig, '#FF7F50' )
			value = value.replace( /CornflowerBlue/ig, '#6495ED' );
			value = value.replace( /Cornsilk/ig, '#FFF8DC' );
			value = value.replace( /Crimson/ig, '#DC143C' );
			value = value.replace( /Cyan/ig, '#00FFFF' );
			value = value.replace( /DarkBlue/ig, '#00008B' );
			value = value.replace( /DarkCyan/ig, '#008B8B' );
			value = value.replace( /DarkGoldenRod/ig, '#B8860B' );
			value = value.replace( /DarkGray/ig, '#A9A9A9' );
			value = value.replace( /DarkGreen/ig, '#006400' );
			value = value.replace( /DarkKhaki/ig, '#BDB76B' );
			value = value.replace( /DarkMagenta/ig, '#8B008B' );
			value = value.replace( /DarkOliveGreen/ig, '#556B2F' );
			value = value.replace( /DarkOrange/ig, '#FF8C00' );
			value = value.replace( /DarkOrchid/ig, '#9932CC' );
			value = value.replace( /DarkRed/ig, '#8B0000' );
			value = value.replace( /DarkSalmon/ig, '#E9967A' );
			value = value.replace( /DarkSeaGreen/ig, '#8FBC8F' );
			value = value.replace( /DarkSlateBlue/ig, '#483D8B' );
			value = value.replace( /DarkSlateGray/ig, '#2F4F4F' );
			value = value.replace( /DarkTurquoise/ig, '#00CED1' );
			value = value.replace( /DarkViolet/ig, '#9400D3' );
			value = value.replace( /DeepPink/ig, '#FF1493' );
			value = value.replace( /DeepSkyBlue/ig, '#00BFFF' );
			value = value.replace( /DimGray/ig, '#696969' );
			value = value.replace( /DodgerBlue/ig, '#1E90FF' );
			value = value.replace( /FireBrick/ig, '#B22222' );
			value = value.replace( /FloralWhite/ig, '#FFFAF0' );
			value = value.replace( /ForestGreen/ig, '#228B22' );
			value = value.replace( /Fuchsia/ig, '#FF00FF' );
			value = value.replace( /Gainsboro/ig, '#DCDCDC' );
			value = value.replace( /GhostWhite/ig, '#F8F8FF' );
			value = value.replace( /Gold/ig, '#FFD700' );
			value = value.replace( /GoldenRod/ig, '#DAA520' );
			value = value.replace( /Gray/ig, '#808080' );
			value = value.replace( /Green/ig, '#008000' );
			value = value.replace( /GreenYellow/ig, '#ADFF2F' );
			value = value.replace( /HoneyDew/ig, '#F0FFF0' );
			value = value.replace( /HotPink/ig, '#FF69B4' );
			value = value.replace( /IndianRed/ig, '#CD5C5C' );
			value = value.replace( /Indigo/ig, '#4B0082' );
			value = value.replace( /Ivory/ig, '#FFFFF0' );
			value = value.replace( /Khaki/ig, '#F0E68C' );
			value = value.replace( /Lavender/ig, '#E6E6FA' );
			value = value.replace( /LavenderBlush/ig, '#FFF0F5' );
			value = value.replace( /LawnGreen/ig, '#7CFC00' );
			value = value.replace( /LemonChiffon/ig, '#FFFACD' );
			value = value.replace( /LightBlue/ig, '#ADD8E6' );
			value = value.replace( /LightCoral/ig, '#F08080' );
			value = value.replace( /LightCyan/ig, '#E0FFFF' );
			value = value.replace( /LightGoldenRodYellow/ig, '#FAFAD2' );
			value = value.replace( /LightGrey/ig, '#D3D3D3' );
			value = value.replace( /LightGreen/ig, '#90EE90' );
			value = value.replace( /LightPink/ig, '#FFB6C1' );
			value = value.replace( /LightSalmon/ig, '#FFA07A' );
			value = value.replace( /LightSeaGreen/ig, '#20B2AA' );
			value = value.replace( /LightSkyBlue/ig, '#87CEFA' );
			value = value.replace( /LightSlateGray/ig, '#778899' );
			value = value.replace( /LightSteelBlue/ig, '#B0C4DE' );
			value = value.replace( /LightYellow/ig, '#FFFFE0' );
			value = value.replace( /Lime/ig, '#00FF00' );
			value = value.replace( /LimeGreen/ig, '#32CD32' );
			value = value.replace( /Linen/ig, '#FAF0E6' );
			value = value.replace( /Magenta/ig, '#FF00FF' );
			value = value.replace( /Maroon/ig, '#800000' );
			value = value.replace( /MediumAquaMarine/ig, '#66CDAA' );
			value = value.replace( /MediumBlue/ig, '#0000CD' );
			value = value.replace( /MediumOrchid/ig, '#BA55D3' );
			value = value.replace( /MediumPurple/ig, '#9370D8' );
			value = value.replace( /MediumSeaGreen/ig, '#3CB371' );
			value = value.replace( /MediumSlateBlue/ig, '#7B68EE' );
			value = value.replace( /MediumSpringGreen/ig, '#00FA9A' );
			value = value.replace( /MediumTurquoise/ig, '#48D1CC' );
			value = value.replace( /MediumVioletRed/ig, '#C71585' );
			value = value.replace( /MidnightBlue/ig, '#191970' );
			value = value.replace( /MintCream/ig, '#F5FFFA' );
			value = value.replace( /MistyRose/ig, '#FFE4E1' );
			value = value.replace( /Moccasin/ig, '#FFE4B5' );
			value = value.replace( /NavajoWhite/ig, '#FFDEAD' );
			value = value.replace( /Navy/ig, '#000080' );
			value = value.replace( /OldLace/ig, '#FDF5E6' );
			value = value.replace( /Olive/ig, '#808000' );
			value = value.replace( /OliveDrab/ig, '#6B8E23' );
			value = value.replace( /Orange/ig, '#FFA500' );
			value = value.replace( /OrangeRed/ig, '#FF4500' );
			value = value.replace( /Orchid/ig, '#DA70D6' );
			value = value.replace( /PaleGoldenRod/ig, '#EEE8AA' );
			value = value.replace( /PaleGreen/ig, '#98FB98' );
			value = value.replace( /PaleTurquoise/ig, '#AFEEEE' );
			value = value.replace( /PaleVioletRed/ig, '#D87093' );
			value = value.replace( /PapayaWhip/ig, '#FFEFD5' );
			value = value.replace( /PeachPuff/ig, '#FFDAB9' );
			value = value.replace( /Peru/ig, '#CD853F' );
			value = value.replace( /Pink/ig, '#FFC0CB' );
			value = value.replace( /Plum/ig, '#DDA0DD' );
			value = value.replace( /PowderBlue/ig, '#B0E0E6' );
			value = value.replace( /Purple/ig, '#800080' );
			value = value.replace( /Red/ig, '#FF0000' );
			value = value.replace( /RosyBrown/ig, '#BC8F8F' );
			value = value.replace( /RoyalBlue/ig, '#4169E1' );
			value = value.replace( /SaddleBrown/ig, '#8B4513' );
			value = value.replace( /Salmon/ig, '#FA8072' );
			value = value.replace( /SandyBrown/ig, '#F4A460' );
			value = value.replace( /SeaGreen/ig, '#2E8B57' );
			value = value.replace( /SeaShell/ig, '#FFF5EE' );
			value = value.replace( /Sienna/ig, '#A0522D' );
			value = value.replace( /Silver/ig, '#C0C0C0' );
			value = value.replace( /SkyBlue/ig, '#87CEEB' );
			value = value.replace( /SlateBlue/ig, '#6A5ACD' );
			value = value.replace( /SlateGray/ig, '#708090' );
			value = value.replace( /Snow/ig, '#FFFAFA' );
			value = value.replace( /SpringGreen/ig, '#00FF7F' );
			value = value.replace( /SteelBlue/ig, '#4682B4' );
			value = value.replace( /Tan/ig, '#D2B48C' );
			value = value.replace( /Teal/ig, '#008080' );
			value = value.replace( /Thistle/ig, '#D8BFD8' );
			value = value.replace( /Tomato/ig, '#FF6347' );
			value = value.replace( /Turquoise/ig, '#40E0D0' );
			value = value.replace( /Violet/ig, '#EE82EE' );
			value = value.replace( /Wheat/ig, '#F5DEB3' );
			value = value.replace( /White/ig, '#FFFFFF' );
			value = value.replace( /WhiteSmoke/ig, '#F5F5F5' );
			value = value.replace( /Yellow/ig, '#FFFF00' );
			value = value.replace( /YellowGreen/ig, '#9ACD32' );
			return value;
		}
	}
}