package flashx.textLayout.elements
{
	import flash.text.engine.FontWeight;
	
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;

	public class HeaderElement extends ParagraphElement
	{
		public static const H1:String = 'h1';
		public static const H2:String = 'h2';
		public static const H3:String = 'h3';
		public static const H4:String = 'h4';
		public static const H5:String = 'h5';
		public static const H6:String = 'h6';
		
		protected var _type:String;
		
		protected var _span:SpanElement;
		
		public function HeaderElement( $type:String = H3 )
		{
			super();
			
			type = $type;
			
			//	[KK]	These two styles can be overridden by the user, so merely set them as the default
			fontSize = getPointSize(type);
			fontWeight = FontWeight.BOLD;
		}
		
		
		//	[KK]	These two overrides should prevent other text / elements from merging with header elements
		override tlf_internal function canReleaseContentElement():Boolean
		{
			return false;
		}
		
		override tlf_internal function mergeToPreviousIfPossible():Boolean
		{
			return false;
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
		
		public function set text( value:String ):void
		{
			if ( !_span )
				_span = new SpanElement();
			
			try {
				removeChild( _span );
			} catch (e:*) {
				//	Could not remove, because it didn't contain the child
			}
			
			addChild( _span );
			
			_span.text = value;
		}
		public function get text():String
		{
			if ( !_span )
				return '';
			return _span.text;
		}
	}
}