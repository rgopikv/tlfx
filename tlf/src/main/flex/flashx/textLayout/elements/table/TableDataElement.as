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