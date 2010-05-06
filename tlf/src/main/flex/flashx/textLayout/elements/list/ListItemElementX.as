package flashx.textLayout.elements.list
{
	import flash.display.Sprite;
	import flash.text.FontStyle;
	import flash.text.engine.FontPosture;
	import flash.text.engine.FontWeight;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.xml.XMLNode;
	
	import flashx.textLayout.accessibility.TextAccImpl;
	import flashx.textLayout.conversion.HtmlExporter;
	import flashx.textLayout.elements.ExtendedLinkElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.InlineGraphicElement;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.format.ExportStyleHelper;
	import flashx.textLayout.formats.TextDecoration;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.StyleAttributeUtil;
	
	use namespace tlf_internal;
	
	public class ListItemElementX extends ParagraphElement
	{
		public static const UNORDERED	:String	=	'unordered';
		public static const ORDERED		:String	=	'ordered';
		
		private var _mode:String;
		private var _number:uint;
		
		private var _bulletSpan:SpanElement;
		private var _bulletFormat:TextLayoutFormat;
		
		public function ListItemElementX()
		{
			super();
			
			paddingBottom = paddingTop = paragraphSpaceAfter = paragraphSpaceBefore = 0;
			
			_number = 1;
			_mode = UNORDERED;
			_bulletSpan = new SpanElement();
			addChild( _bulletSpan );
			
			_bulletFormat = new TextLayoutFormat();
			
			_bulletFormat.fontSize = 12;
			_bulletFormat.color = 0;
			_bulletFormat.fontWeight = FontWeight.NORMAL;
			_bulletFormat.textDecoration = TextDecoration.NONE;
			_bulletFormat.fontStyle = FontPosture.NORMAL;
			_bulletFormat.lineThrough = false;
			_bulletFormat.paddingBottom = _bulletFormat.paddingTop = _bulletFormat.paragraphSpaceAfter = _bulletFormat.paragraphSpaceBefore = 0;
			
			_bulletSpan.format = _bulletFormat;
			
			update(false);
		}
		
		
		
		public function update( updateParent:Boolean = true ):void
		{
			if ( updateParent && this.parent && this.parent is ListElementX )
				( this.parent as ListElementX ).update();
			_bulletSpan.format = _bulletFormat;
			_bulletSpan.text = getSeparator();
			
			if ( getTextFlow() )
				getTextFlow().flowComposer.updateAllControllers();
		}
		
		public override function addChild(child:FlowElement):FlowElement
		{
			super.addChild(child);
			
			//	Add a SpanElement afterwords if the new element is not a SpanElement
			if ( !(child is SpanElement) )
				super.addChild( new SpanElement() );
			return child;
		}
		
		public override function addChildAt(index:uint, child:FlowElement):FlowElement
		{
			super.addChildAt(index+1, child);
			
			//	If the new element is not a SpanElement
			if ( !(child is SpanElement) )
			{
				var hasSpan:Boolean = false;
				for ( var i:int = index+2; i < numChildren; i++ )
				{
					if ( getChildAt(i) is SpanElement )
					{
						hasSpan = true;
						break;
					}
				}
				
				//	If no SpanElement after new element, add a new SpanElement directly after it
				if ( !hasSpan )
				{
					super.addChildAt(index+2, new SpanElement());
				}
			}
			return child;
		}
		
		tlf_internal override function ensureTerminatorAfterReplace(oldLastLeaf:FlowLeafElement):void
		{
			//	Nothing here in order to ensure that no extra spaces are added between lines
		}
		
		public function export():XML
		{
			var xml:XML = <li/>;
			var styleExporter:ExportStyleHelper = new ExportStyleHelper();
			
			for ( var i:int = 1; i < numChildren; i++ )
			{
				var child:FlowElement = getChildAt(i);
				var childXML:XML;
				
				switch ( Class( getDefinitionByName( getQualifiedClassName( child ) ) ) )
				{
					case SpanElement:
						var span:SpanElement = child as SpanElement;
						childXML = <span>{span.text}</span>;
						styleExporter.applyStyleAttributesFromElement( childXML, span );
						if ( span.id.length > 0 )
							childXML.@id = span.id;
						break;
					case InlineGraphicElement:
						var img:InlineGraphicElement = child as InlineGraphicElement;
						if ( img.source.hasOwnProperty( 'export' ) )	//	EditableImageElement or VariableElement
							childXML = img.source.export();	//	May not be an <img/> tag
						else
						{
							childXML = <img/>;
							childXML.@src = img.source.toString();
							if ( img.id.length > 0 )
								childXML.@id = childXML.@alt = img.id;
						}
						break;
					case ExtendedLinkElement:
					case LinkElement:
						var link:LinkElement = child as LinkElement;
						childXML = <a/>;
						childXML.@href = link.href;
						childXML.@target = link.target;
						if ( link.id.length > 0 )
							childXML.@id = link.id;
						break;
					default:
						trace('Could not export:', child, 'from:', this);
						break;
				}
				
				if ( childXML )
					xml.appendChild( childXML );
			}
			
			return xml.toXMLString() != '<li/>' ? xml : null;
		}
		
//		public function toString():String
//		{
//			return '[ListItemElementX number: ' + number + ' | text: ' + text + ' | mode: ' + mode + ' | indent: ' + indent + ']';
//		}
		
		protected function getSeparator():String
		{
			if ( mode == UNORDERED )
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
			else
			{
				return number.toString() + '. ';
			}
		}
		
		
		
		public override function set paragraphStartIndent(paragraphStartIndentValue:*):void
		{
			super.paragraphStartIndent = paragraphStartIndentValue;
			update( false );
		}
		
		public function set mode( value:String ):void
		{
			_mode = value;
			//	Prevent bad set
			if ( value != UNORDERED && value != ORDERED )
				_mode = UNORDERED;
			
			update(false);
		}
		public function get mode():String
		{
			return _mode;
		}
		
		public function set number( value:uint ):void
		{
			_number = value;
		}
		public function get number():uint
		{
			return _number;
		}
		
		public function set text( value:String ):void
		{
			var i:int = numChildren;
			while (--i > 0)
				removeChildAt(i);
			
			var span:SpanElement = new SpanElement();
			span.text = value;
			addChild( span );
			
			update(false);
		}
		public function get text():String
		{
			var str:String = '';
			var i:int = 0;
			while (++i < numChildren)
			{
				if ( getChildAt(i) is SpanElement )
					str += ( getChildAt(i) as SpanElement ).text;
				else if ( getChildAt(i) is LinkElement )
					str += ( ( getChildAt(i) as LinkElement ).getChildAt(0) as SpanElement ).text;
			}
			return str;
		}
		
		public function get actualStart():uint
		{
			if ( numChildren > 1 )
				return getChildAt(1).getAbsoluteStart();
			return getChildAt(0).getAbsoluteStart() + getChildAt(0).textLength;
		}
		
		public function get modifiedTextLength():uint
		{
			return textLength - getChildAt(0).textLength;
		}
		
		public function set indent( value:uint ):void
		{
			paragraphStartIndent = value;
		}
		public function get indent():uint
		{
			return Math.max( uint( paragraphStartIndent ), 0 );
		}
	}
}