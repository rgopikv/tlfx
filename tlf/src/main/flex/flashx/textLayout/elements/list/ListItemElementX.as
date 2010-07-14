package flashx.textLayout.elements.list
{
	import flash.events.Event;
	import flash.text.engine.FontPosture;
	import flash.text.engine.FontWeight;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.converter.IHTMLExporter;
	import flashx.textLayout.elements.ExtendedLinkElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.InlineGraphicElement;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.SubParagraphGroupElement;
	import flashx.textLayout.elements.VarElement;
	import flashx.textLayout.events.ModelChange;
	import flashx.textLayout.events.UpdateEvent;
	import flashx.textLayout.events.list.ListElementEvent;
	import flashx.textLayout.format.ExportStyleHelper;
	import flashx.textLayout.format.IExportStyleHelper;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextAlign;
	import flashx.textLayout.formats.TextDecoration;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.model.style.IListStyle;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.ListStyleConversionUtil;
	
	use namespace tlf_internal;
	
	public class ListItemElementX extends ListItemBaseElement
	{
		protected var _computedStyle:IListStyle;
		
		private var _number:uint;
		private var _source:XML;
		
		private var _bulletSpan:SpanElement;
		private var _bulletFormat:TextLayoutFormat;
		
		public function ListItemElementX()
		{
			super();
			
			paddingBottom = paddingTop = paragraphSpaceAfter = paragraphSpaceBefore = 0;
			
			_number = 1;
			createBullet();
			
			update();
		}
		
		// [TA] 06-30-2010 :: Offloaded creating of bullet to own method, as it may be requested by multiple methods at different times. Lazy create on request.
		protected function createBullet():void
		{
			if( _bulletSpan != null ) return;
			
			_bulletSpan = new SpanElement();
			addChild( _bulletSpan );
		}
		// [END TA]
		
//		tlf_internal override function ensureTerminatorAfterReplace(oldLastLeaf:FlowLeafElement):void
//		{
//			//	Nothing
//		}
		
		public function updateBulletFormat():void
		{
			// [TA] 07-13-2010 :: Removed appropriating computed format for the bullet. Should cascade down to element since it resides on the flow.
			var bFormat:TextLayoutFormat = new TextLayoutFormat();
			// [END TA]
			bFormat.paragraphSpaceAfter = bFormat.paragraphSpaceBefore = bFormat.paragraphStartIndent = 0;
			if( !TextLayoutFormat.isEqual( bFormat, _bulletFormat ) )
			{
				_bulletFormat = bFormat;
				if( _bulletSpan == null ) 
				{
					createBullet();
				}
				_bulletSpan.format = _bulletFormat;
				update();
			}
		}
		
		public function update():void
		{
			_computedStyle = _style.getComputedStyle();
			_bulletSpan.text = getSeparator();
			
			correctChildren();
			//	[KK]	May be unnecessary
//			ensureLegitimateChildren();
		}
		
		override protected function updateDisplayForListStyle():void
		{
			update();
		}
		
		public function correctChildren():void
		{
			try {
				try {
					removeChild( _bulletSpan );
				} catch ( e:* ) {
					//	Fail silently
				}
				iaddChildAt(0, _bulletSpan);
			} catch ( e:* ) {
				//	Fail silently
			}
		}
		
		protected function ensureLegitimateChildren():void
		{
			var span:SpanElement;
			var link:LinkElement;
			
			for ( var i:int = numChildren-1; i > -1; i-- )
			{
				var child:FlowElement = getChildAt(i);
				
				if ( child is SpanElement )
				{
					span = child as SpanElement;
					if ( span.text.match( /[\n\r\u2028\u2029]/g ).length > 0 )
					{
						if ( span.text.match( /\w/g ).length > 0 )
							span.text.replace( /[\n\r\u2028\u2029]/g, '' );
						else
						{
							//	Break element?
							trace( '[KK] {' + getQualifiedClassName(this) + '} :: Found a break element? Child #' + i + '. Removing.' );
							removeChildAt(i);
						}
					}
				}
				else if ( child is LinkElement || child is ExtendedLinkElement )
				{
					link = child as LinkElement;
					for ( var j:int = link.numChildren-1; j > -1; j-- )
					{
						child = link.getChildAt(j);
						
						if ( child is SpanElement )
						{
							span = child as SpanElement;
							if ( span.text.match( /[\n\r\u2028\u2029]/g ).length > 0 )
							{
								if ( span.text.match( /\w/g ).length > 0 )
									span.text.replace( /[\n\r\u2028\u2029]/g, '' );
								else
									link.removeChildAt(j);
							}
						}
					}
				}
			}
		}
		
		public override function addChild(child:FlowElement):FlowElement
		{
			super.addChild(child);
			
			//	Add a SpanElement afterwords if the new element is not a SpanElement
			if ( !(child is SpanElement) )
			{
				super.addChild( new SpanElement() );
				//	[FORMATING]
//				getChildAt( numChildren-1 ).format = computedFormat ? TextLayoutFormat(computedFormat) : format ? TextLayoutFormat(format) : new TextLayoutFormat();
			}
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
					getChildAt( index+2 ).format = computedFormat ? TextLayoutFormat(computedFormat) : format ? TextLayoutFormat(format) : new TextLayoutFormat();
				}
			}
			return child;
		}
		
		//	KK - Removed on 05/24/2010 - it was causing selection issues (could never select the last atom of any ListItemElement)
		//		tlf_internal override function ensureTerminatorAfterReplace(oldLastLeaf:FlowLeafElement):void
		//		{
		//			//	Nothing, to prevent extra line breaks
		//		}
		
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
						//	KK - Removed to stop elements merging together
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
				//	[FORMATING]
//				s.format = computedFormat ? TextLayoutFormat(computedFormat) : format ? TextLayoutFormat(format) : new TextLayoutFormat();
				replaceChildren(0,0,s);
				s.normalizeRange(0,s.textLength);
			}
		}
		
		// [TA] 06-30-2010 :: Added argument for IExportStyleHelper instance. Proper implementation needed for export and strip of styles from applied and explicit formatting.
		// [TA] 07-12-2010 :: ADDED IHTMLExport argument to properly export child elements from list item element.
		public function export( exporter:IHTMLExporter, styleExporter:IExportStyleHelper ):XML
		{
		// [END TA]
			var xml:XML = <li/>;
			var i:int;
			
			for ( i = numChildren-1; i > -1; i-- )
			{
				if ( getChildAt(i) is SpanElement )
				{
					if ( SpanElement( getChildAt(i) ).text.indexOf( getSeparator() ) > -1 )
						removeChildAt(i);
				}
			}
			
			correctChildren();
			
			//	Remove the paragraphStartIndent for applying styles
			var origIndent:int = indent;
			indent = 0;
			
			styleExporter.applyStyleAttributesFromElement( xml, this );
			
			//	Apply the indent once more
			indent = origIndent;
			
			for ( i = 1; i < numChildren; i++ )
			{
				var child:FlowElement = getChildAt(i);
				var childXML:XML = exporter.exportElementToFragment( child );
				// [TA] 07-12-2010 :: REMOVED and used IHTMLExporter imeplementation to properly export child elements.
//				switch ( Class( getDefinitionByName( getQualifiedClassName( child ) ) ) )
//				{
//					case VarElement:	//	Must come before SpanElement as VarElement extends SpanElement
//						var vEl:VarElement = child as VarElement;
//						childXML = <span class="cc-var" title="whatever">{vEl.textContent}</span>;
//						styleExporter.applyStyleAttributesFromElement( childXML, vEl );
//						if ( vEl.id && vEl.id.length > 0 )
//							childXML.@id = vEl.id;
//						break;
//					case SpanElement:
//						var span:SpanElement = child as SpanElement;
//						childXML = <span>{span.text}</span>;
//						var hasStyles:Boolean = styleExporter.applyStyleAttributesFromElement( childXML, span );
//						if ( span.id && span.id.length > 0 )
//							childXML.@id = span.id;
//						
//						if ( !hasStyles && (!span.id || !(span.id && span.id.length > 0)) )
//							childXML = new XML(span.text);
//						break;
//					case InlineGraphicElement:
//						var img:InlineGraphicElement = child as InlineGraphicElement;
//						if ( img.source && img.source.hasOwnProperty( 'export' ) )	//	EditableImageElement or VariableElement
//							childXML = img.source.export();	//	May not be an <img/> tag
//						else
//						{
//							childXML = <img/>;
//							childXML.@src = img.source.toString();
//							if ( img.id && img.id.length > 0 )
//								childXML.@id = childXML.@alt = img.id;
//						}
//						styleExporter.applyStyleAttributesFromElement( childXML, img );
//						break;
//					case ExtendedLinkElement:
//					case LinkElement:
//						var link:LinkElement = child as LinkElement;
//						childXML = <a/>;
//						childXML.@href = link.href;
//						childXML.@target = link.target;
//						if ( link.id && link.id.length > 0 )
//							childXML.@id = link.id;
//						childXML.appendChild( link.getText() );
//						
//						styleExporter.applyStyleAttributesFromElement( childXML, link );
//						break;
//					default:
//						trace('Could not export:', child, 'from:', this);
//						break;
//				}
				// [END TA]
				if ( childXML )
					xml.appendChild( childXML );
			}
			
			var cleanMargin:RegExp = /margin-left:\d+;/i;
			if ( cleanMargin.test( xml.@style.toString() ) )
				xml.@style = xml.@style.toString().replace( cleanMargin, '' );
			
			if ( xml.@style.toString().length < 1 )
				delete xml.@style;
			
			return xml;//xml.toXMLString() != '<li/>' ? xml : null;
		}
		
		protected function getSeparator():String
		{
			var seperator:String = "";
			var styleType:String = _computedStyle.listStyleType;
			if ( _mode == ListItemModeEnum.UNORDERED )
			{
				var modifier:Number = ( paragraphStartIndent ) ? (paragraphStartIndent / 24) : Number.NaN;
				seperator = ListStyleConversionUtil.convertUnordered( styleType, modifier - 1, number );
			}
			else
			{
				seperator = ListStyleConversionUtil.convertOrdered( styleType, number );
			}
			seperator += ( seperator.length > 0 ) ? " " : "";
			return seperator;
		}
		
		protected function iaddChildAt(index:uint, child:FlowElement):FlowElement
		{
			return super.addChildAt(index, child);
		}
		
		
		
		public override function set paragraphStartIndent(paragraphStartIndentValue:*):void
		{
			var origIndent:uint = paragraphStartIndent;
			super.paragraphStartIndent = paragraphStartIndentValue;
			update();
			
			if ( getTextFlow() && parent && origIndent != paragraphStartIndent )	//	Do not remove the end of this conditional, as it causes the entire build to fail and a restart is required to fix
				getTextFlow().dispatchEvent( new ListElementEvent( ListElementEvent.UPDATE, this, parent as ListElementX ) );
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
					//	[FORMATING]
//					childSpanFormat.apply(childSpan.computedFormat ? TextLayoutFormat(computedFormat) : format ? TextLayoutFormat(format) : new TextLayoutFormat());
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
			//	[FORMATING]
//			span.format = computedFormat ? TextLayoutFormat(computedFormat) : format ? TextLayoutFormat(format) : new TextLayoutFormat();
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
			else if ( numChildren == 0 )
				return 0;
			return getChildAt(0).getAbsoluteStart() + getChildAt(0).textLength;
		}
		
		public function get nonListRelatedContent():Array /* FlowElement[] */
		{
			return mxmlChildren.slice( 1, mxmlChildren.length );
		}
		
		public function get seperatorLength():uint
		{
			return getSeparator().length;
		}
		
		public function get modifiedTextLength():uint
		{
			//	Changed to textLength-2 because after implementation of Tidy (as of 6/10/2010) I noticed the text length was incorrect.
			var len:uint = 0;
			for ( var i:int = 1; i < numChildren; i++ )
			{
				var child:FlowElement = getChildAt(i);
				
				if ( child is SpanElement )
					len += (child as SpanElement).text.match( /\w/g ).length;
				else if ( child is LinkElement )
				{
					for ( var j:int = 0; j < (child as LinkElement).numChildren; j++ )
					{
						var linkChild:FlowElement = (child as LinkElement).getChildAt(j);
						
						if ( linkChild is SpanElement )
							len += (linkChild as SpanElement).text.match( /\w/g ).length;
						else
							len++;
					}
				}
				else
					len++;
			}
			return len;
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
		
		/**
		 * @inherit
		 * Override to perform specific operations based on changeType.
		 */
		tlf_internal override function modelChanged(changeType:String, changeStart:int, changeLen:int, needNormalize:Boolean = true, bumpGeneration:Boolean = true):void
		{
			super.modelChanged( changeType, changeStart, changeLen, needNormalize, bumpGeneration );
			switch( changeType )
			{
				case ModelChange.TEXTLAYOUT_FORMAT_CHANGED:
					updateBulletFormat();
					break;
				case ModelChange.ELEMENT_ADDED:
					updateBulletFormat();
					break;
				
			}
		}
		
		// [TA] 07-13-2010 :: Override shallow copy to push list item specific properties on copy creation.
		override public function shallowCopy(startPos:int=0, endPos:int=-1):FlowElement
		{
			var copy:ListItemElementX = super.shallowCopy( startPos, endPos ) as ListItemElementX;
			copy.indent = indent;
			copy.number = number;
			return copy;
		}
		// [END TA]
	}
}