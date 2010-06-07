package flashx.textLayout.elements
{
	import flash.text.engine.FontWeight;
	
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;

	public class HeaderElement extends ParagraphElement
	{
		public static const H1:String = 'h1';
		public static const H2:String = 'h2';
		public static const H3:String = 'h3';
		public static const H4:String = 'h4';
		public static const H5:String = 'h5';
		public static const H6:String = 'h6';
		
		protected var _type:String;
		
		public function HeaderElement( $type:String = H3 )
		{
			super();
			
			type = $type;
		}
		
		
		
		protected function getPointSize( type:String ):uint
		{
			switch ( type )
			{
				case H1:
					return 24;
				case H2:
					return 18;
				case H3:
					return 14;
				case H4:
					return 12;
				case H5:
					return 10;
				case H6:
					return 8;
				default:
					return 14;
			}
			return 14;
		}
		
		
		
		public function set type( value:String ):void
		{
			if ( value !== H1 && value !== H2 &&
				value !== H3 && value !== H4 &&
				value != H5 && value !== H6 )
				return;
			
			_type = value;
			
			var $format:TextLayoutFormat = new TextLayoutFormat( format );
			$format.fontSize = getPointSize( _type ) * 96/72;
			$format.fontWeight = FontWeight.BOLD;
			format = $format;
		}
		
		public function get type():String
		{
			return _type;
		}
	}
}