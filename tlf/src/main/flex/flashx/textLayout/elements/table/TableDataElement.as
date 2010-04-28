package flashx.textLayout.elements.table
{
	import flashx.textLayout.edit.TextFlowEdit;
	import flashx.textLayout.elements.ContainerFormattedElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.SubParagraphGroupElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormatValueHolder;
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.attribute.TableDataAttribute;
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;
	public class TableDataElement extends ContainerFormattedElement
	{
		public var attributes:IAttribute;
		
		public function TableDataElement()
		{
			super();
			setDefaultAttributes();
		}
		
		protected function setDefaultAttributes():void
		{
			attributes = TableDataAttribute.getDefaultAttributes();
		}
		
		/**
		 * Override to mark this instance as not being abstract. 
		 * @return Boolean
		 */
		override protected function get abstract() : Boolean
		{
			return false;
		}
		
		override tlf_internal function canOwnFlowElement(elem:FlowElement):Boolean
		{
			return !(elem is TextFlow);
		}
		
		/**
		 * @private
		 * 
		 * Override to properly set up an empty table. 
		 * @param normalizeStart uint
		 * @param normalizeEnd uint
		 */
		override tlf_internal function normalizeRange(normalizeStart:uint,normalizeEnd:uint):void
		{
			// is this an absolutely element?
			if (this.numChildren == 0)
			{
				var p:ParagraphElement = new ParagraphElement();
				p.replaceChildren(0,0,new SpanElement());
				replaceChildren(0,0,p);
				p.normalizeRange(0,p.textLength);	
			}
			else
			{
				super.normalizeRange(normalizeStart,normalizeEnd);
			}
		}
		
		override tlf_internal function doComputeTextLayoutFormat(formatForCascade:ITextLayoutFormat):void
		{
			var element:FlowElement = parent;
			var parentFormatForCascade:ITextLayoutFormat;
			
			if (element)
			{
				parentFormatForCascade = element.formatForCascade;
				if (TextLayoutFormat.isEqual(formatForCascade,TextLayoutFormat.emptyTextLayoutFormat) && TextLayoutFormat.isEqual(parentFormatForCascade,TextLayoutFormat.emptyTextLayoutFormat))
				{
					_computedFormat = element.computedFormat;
					return;
				}
			}
			
			var tf:TextFlow;
			// compute the cascaded attributes	
			_scratchTextLayoutFormat.format = formatForCascade;
			if (element)
			{
				if (parentFormatForCascade)
					_scratchTextLayoutFormat.concatInheritOnly(parentFormatForCascade);
				while (element.parent)
				{
					element = element.parent;
					var concatAttrs:ITextLayoutFormat = element.formatForCascade;
					if (concatAttrs)
						_scratchTextLayoutFormat.concatInheritOnly(concatAttrs);
				}
				tf = element as TextFlow;
			}
			else
				tf = this as TextFlow;
			var defaultFormat:ITextLayoutFormat;
			var defaultFormatHash:uint;
			if (tf)
			{
				defaultFormat = tf.getDefaultFormat();
				defaultFormatHash = tf.getDefaultFormatHash();
			}
			_computedFormat = TextFlow.getCanonical(_scratchTextLayoutFormat,defaultFormat,defaultFormatHash);
		}
		
		/**
		 * Returns the default content associated with a TableDataElement. 
		 * @return FlowElement
		 */
		public static function getDefaultContent():FlowElement
		{
			var p:ParagraphElement = new ParagraphElement();
			var span:SpanElement = new SpanElement();
			span.text = "";
			p.addChild( span );
			return p;
		}
	}
}