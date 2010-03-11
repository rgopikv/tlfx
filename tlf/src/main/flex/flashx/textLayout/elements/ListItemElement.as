package flashx.textLayout.elements
{
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;
	
	public class ListItemElement extends ParagraphElement
	{
		private var _baseText:String;
		private var _mode:String;
		
		private var _num:uint;
		
		private var _first:Boolean;
		private var _last:Boolean;
		
		public var span:SpanElement;
		
		public function ListItemElement()
		{
			super();
			
			init();
			
			tlf_internal::setTextLength(1);
			
			_mode = ListElement.UNORDERED;
			_baseText = '';
			_num = 0;
			_first = false;
			_last = false;
			
			
			
//			span = new SpanElement();
//			
//			this.addChild( span );
		}
		
		public function init():void
		{
			span = new SpanElement();
			super.addChild( span );
		}
		
//		override tlf_internal function c
		
		private function getSeparator():String
		{					
			switch (_mode)
			{
				case ListElement.UNORDERED:
					return '\u2022 ';
					
				case ListElement.ORDERED:
					if ( isNaN( _num ) )
						return '\u2022 ';
					else
						return _num.toString() + '. ';
					
				default:
					return '';
			}	
		}
		
		override tlf_internal function canReleaseContentElement() : Boolean
		{
			return false;
		}
		
		override tlf_internal function canOwnFlowElement(elem:FlowElement) : Boolean
		{
			return elem is ParagraphElement || elem is SpanElement;
		}
		
		public function set mode( value:String ):void
		{
			if ( value != ListElement.UNORDERED && 
				 value != ListElement.ORDERED && 
				 value != ListElement.NONE)
				return;
						
			if (!first && !last)
			{
				_mode = value;
				this.text = rawText;
			}
		}
		public function get mode():String
		{
			return _mode;
		}
		
		public function set number( value:uint ):void
		{
			_num = value;
			this.text = rawText;
		}
		public function get number():uint
		{
			return _num;
		}
		
		public function set first( value:Boolean ):void
		{
			_first = value;
			if ( first )
				this.text = rawText;
		}
		public function get first():Boolean
		{
			return _first;
		}
		
		public function set last( value:Boolean ):void
		{
			_last = value;
			if ( last )
				this.text = rawText;
		}
		public function get last():Boolean
		{
			return _last;
		}
		
		public function set text(textValue:String) : void
		{
			_baseText = textValue;
			//var start:String = first ? '\n' : '';
			//var end:String = last ? '\n' : '';
			
			//start = getSeparator();
			
			//var textToPass:String = start + textValue + end;

			span.text = getSeparator() + textValue;
		}
		public function get text() : String
		{
			return span.text;
		}
		
		public function get rawText() : String
		{
			return _baseText;
		}
		
		override protected function get abstract() : Boolean
		{
			return false;
		}
	}
}