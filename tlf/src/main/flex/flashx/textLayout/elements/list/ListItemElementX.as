package flashx.textLayout.elements.list
{
	import flash.events.Event;
	import flash.text.engine.FontPosture;
	import flash.text.engine.FontWeight;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.elements.ExtendedLinkElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.InlineGraphicElement;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.SubParagraphGroupElement;
	import flashx.textLayout.events.UpdateEvent;
	import flashx.textLayout.format.ExportStyleHelper;
	import flashx.textLayout.formats.TextDecoration;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;
	
	public class ListItemElementX extends ParagraphElement
	{
		public static const UNORDERED	:String	=	'unordered';
		public static const ORDERED		:String	=	'ordered';
		
		private var _mode:String;
		private var _number:uint;
		
		private var _source:XML;
		
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
			
			update();
		}
		
		
		
		public function update():void
		{
			_bulletSpan.format = _bulletFormat;
			_bulletSpan.text = getSeparator();
		}
		
		public function correctChildren():void
		{
			try {
				try {
					removeChild( _bulletSpan );
				} catch ( e:* ) {
					trace(e);
				}
				iaddChildAt(0, _bulletSpan);
			} catch ( e:* ) {
				trace(e);
			}
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
			//	Nothing, to prevent extra line breaks
		}
		
		/** @private */
		tlf_internal override function normalizeRange(normalizeStart:uint,normalizeEnd:uint):void
		{
			var idx:int = findChildIndexAtPosition(normalizeStart);
			if (idx != -1 && idx < numChildren)
			{
				var child:FlowElement = getChildAt(idx);
				normalizeStart = normalizeStart-child.parentRelativeStart;
				
				CONFIG::debug { assert(normalizeStart >= 0, "bad normalizeStart in normalizeRange"); }
				for (;;)
				{
					// watch out for changes in the length of the child
					var origChildEnd:int = child.parentRelativeStart+child.textLength;
					child.normalizeRange(normalizeStart,normalizeEnd-child.parentRelativeStart);
					var newChildEnd:int = child.parentRelativeStart+child.textLength;
					normalizeEnd += newChildEnd-origChildEnd;	// adjust
					
					// no zero length children
					if (child.textLength == 0 && !child.bindableElement)
						replaceChildren(idx,idx+1);
					else if (child.mergeToPreviousIfPossible())
					{
//						var prevElement:FlowElement = this.getChildAt(idx-1);
//						// possibly optimize the start to the length of prevelement before the merge
//						prevElement.normalizeRange(0,prevElement.textLength);
					}
					else
						idx++;
					
					if (idx == numChildren)
					{
						// check if last child is an empty SubPargraphBlock and remove it
						if (idx != 0)
						{
							var lastChild:FlowElement = this.getChildAt(idx-1);
							if (lastChild is SubParagraphGroupElement && lastChild.textLength == 1 && !lastChild.bindableElement)
								replaceChildren(idx-1,idx);
						}
						break;
					}
					
					// next child
					child = getChildAt(idx);
					
					if (child.parentRelativeStart > normalizeEnd)
						break;
					
					normalizeStart = 0;		// for the next child	
				}
			}
			
			// empty paragraphs not allowed after normalize
			if (numChildren == 0 || textLength == 0)
			{
				var s:SpanElement = new SpanElement();
				replaceChildren(0,0,s);
				s.normalizeRange(0,s.textLength);
			}
		}
		
		public function export():XML
		{
			var xml:XML = <li/>;
			var styleExporter:ExportStyleHelper = new ExportStyleHelper();
			
			//	Remove the paragraphStartIndent for applying styles
			var origIndent:int = indent;
			indent = 0;
			
			styleExporter.applyStyleAttributesFromElement( xml, this );
			
			//	Apply the indent once more
			indent = origIndent;
			
			for ( var i:int = 1; i < numChildren; i++ )
			{
				var child:FlowElement = getChildAt(i);
				var childXML:XML;
				
				switch ( Class( getDefinitionByName( getQualifiedClassName( child ) ) ) )
				{
					case SpanElement:
						var span:SpanElement = child as SpanElement;
						childXML = <span>{span.text}</span>;
						var hasStyles:Boolean = styleExporter.applyStyleAttributesFromElement( childXML, span );
						if ( span.id && span.id.length > 0 )
							childXML.@id = span.id;
						
						if ( !hasStyles && (!span.id || !(span.id && span.id.length > 0)) )
							childXML = new XML(span.text);
						break;
					case InlineGraphicElement:
						var img:InlineGraphicElement = child as InlineGraphicElement;
						if ( img.source && img.source.hasOwnProperty( 'export' ) )	//	EditableImageElement or VariableElement
							childXML = img.source.export();	//	May not be an <img/> tag
						else
						{
							childXML = <img/>;
							childXML.@src = img.source.toString();
							if ( img.id && img.id.length > 0 )
								childXML.@id = childXML.@alt = img.id;
						}
						styleExporter.applyStyleAttributesFromElement( childXML, img );
						break;
					case ExtendedLinkElement:
					case LinkElement:
						var link:LinkElement = child as LinkElement;
						childXML = <a/>;
						childXML.@href = link.href;
						childXML.@target = link.target;
						if ( link.id && link.id.length > 0 )
							childXML.@id = link.id;
						styleExporter.applyStyleAttributesFromElement( childXML, link );
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
		
		protected function iaddChildAt(index:uint, child:FlowElement):FlowElement
		{
			return super.addChildAt(index, child);
		}
		
		
		
		public override function set paragraphStartIndent(paragraphStartIndentValue:*):void
		{
			super.paragraphStartIndent = paragraphStartIndentValue;
			update();
		}
		
		public function set mode( value:String ):void
		{
			_mode = value;
			//	Prevent bad set
			if ( value != UNORDERED && value != ORDERED )
				_mode = UNORDERED;
			
			update();
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
			var indexes:Vector.<int> = new Vector.<int>();
			var children:Vector.<FlowElement> = new Vector.<FlowElement>();
			while (--i > 0)
			{
				if ( getChildAt(i) is InlineGraphicElement || getChildAt(i) is ExtendedLinkElement || getChildAt(i) is LinkElement )
				{
					indexes.push( i );
					children.push( getChildAt(i) );
				}
				else
				{
					var childSpan:SpanElement = getChildAt(i) as SpanElement;
					var childSpanFormat:TextLayoutFormat = new TextLayoutFormat();
					childSpanFormat.apply(childSpan.computedFormat);
					if ( !(TextLayoutFormat.isEqual( computedFormat, childSpanFormat )) )
					{
						indexes.push( i );
						children.push( getChildAt(i) );
					}
				}
				removeChildAt(i);
			}
			
			indexes.reverse();
			children.reverse();
			
			var span:SpanElement = new SpanElement();
			span.text = value;
			addChild( span );
			
			for ( i = 0; i < indexes.length; i++ )
			{
				var index:int = indexes[i];
				var child:FlowElement = children[i];
				
				if ( index > numChildren-1 )
					addChild(child);
				else
					addChildAt(index, child);
			}
			
			update();
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
		
		public function get seperatorLength():uint
		{
			return getChildAt(0).textLength;
		}
		
		public function get modifiedTextLength():uint
		{
			return textLength - getChildAt(0).textLength;
		}
		
		public function set indent( value:uint ):void
		{
			paragraphStartIndent = Math.max(0, Math.min(240, value));
		}
		public function get indent():uint
		{
			return Math.max( uint( paragraphStartIndent ), 0 );
		}
		
		public function set source( value:XML ):void
		{
			_source = value;
		}
	}
}