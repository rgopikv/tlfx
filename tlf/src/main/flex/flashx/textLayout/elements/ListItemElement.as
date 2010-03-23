package flashx.textLayout.elements
{
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;
	
	public class ListItemElement extends DivElement implements IListElement
	{
		private var _baseText:String;
		private var _mode:String;
		
		private var _num:uint;
		
		private var _first:Boolean;
		private var _last:Boolean;
		
		public var previousItem:ListItemElement;
		
		public var span:SpanElement;
		public var p:ParagraphElement;
		
		public function get list():ListElement
		{
			return parent as ListElement;
		}
		
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
		}
		
		public function init():void
		{
			p = new ParagraphElement();
			span = new SpanElement();
			p.addChild( span );
			super.addChild( p );
		}
		
		
		
		override public function addChild(child:FlowElement):FlowElement
		{
			if ( child is FlowLeafElement )
				return p.addChild( child );
			else
			{
				var toReturn:FlowElement = super.addChild( child );
				p = new ParagraphElement();
				span = new SpanElement();
				p.addChild( span );
				super.addChild( p );
				return toReturn;
			}
		}
		
		
		
		private function getSeparator():String
		{									
			switch (_mode)
			{
				case ListElement.UNORDERED:
					return getSeperatorForIndent();
					
				case ListElement.ORDERED:
					return _num.toString() + '. ';
					
				default:
					return '';
			}	
		}
		
		private function getSeperatorForIndent():String 
		{			
			if (paragraphStartIndent == 0 || paragraphStartIndent == undefined)
			{
				return '\u25CF ';
			}
			
			var mod:int = (paragraphStartIndent / 24);
			
			if (mod < 2)
			{
				return '\u25CB ';
			}
			
			return '\u25A0 ';
		}
		
		public override function set paragraphStartIndent(paragraphStartIndentValue:*):void
		{
			super.paragraphStartIndent = paragraphStartIndentValue;
			
			this.text = rawText;
		}
		
		override tlf_internal function canReleaseContentElement() : Boolean
		{
			return false;
		}
		
		override tlf_internal function canOwnFlowElement(elem:FlowElement) : Boolean
		{
			return elem is FlowLeafElement || elem is ParagraphElement || elem is ListElement;
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