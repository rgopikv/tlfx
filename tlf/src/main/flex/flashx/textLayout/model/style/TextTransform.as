package flashx.textLayout.model.style
{
	import flashx.textLayout.elements.FlowLeafElement;

	public class TextTransform
	{
		protected var _mode:String;
		protected var _leaf:FlowLeafElement;
		protected var _originalText:String;
		
		public static const UPPERCASE:String = "uppercase";
		public static const LOWERCASE:String = "lowercase";
		public static const CAPITALIZE:String = "capitalize";
		public static const NONE:String = "none";
		public static const INHERIT:String = "inherit";
		
		public function TextTransform( mode:String, leaf:FlowLeafElement ) 
		{
			_mode = mode;
			_leaf = leaf;
		}
		
		protected function getInheritedTextTransform():TextTransform
		{
			
			return null;
		}
		
		public function transform( mode:String = null ):String
		{
			var tranformMode:String = ( mode ) ? mode : _mode;
			var transformed:String;
			switch( tranformMode )
			{
				case TextTransform.UPPERCASE:
					_originalText = _leaf.text;
					transformed = _leaf.text.toUpperCase();
					break;
				case TextTransform.LOWERCASE:
					_originalText = _leaf.text;
					transformed = _leaf.text.toLowerCase();
					break;
				case TextTransform.CAPITALIZE:
					_originalText = _leaf.text;
					break;
				case TextTransform.INHERIT:
					_originalText = _leaf.text;
					var textTransform:TextTransform = getInheritedTextTransform();
					transformed = textTransform.transform( textTransform.mode );
					break;
				case TextTransform.NONE:
				default:
					transformed = ( _originalText ) ? _originalText : _leaf.text;
			}
			return transformed;
		}
		
		public function untransform():String
		{
			if( _originalText == null ) return _leaf.text;
			return _originalText;
		}
		
		public function get mode():String
		{
			return _mode;
		}
	}
}