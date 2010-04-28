package flashx.textLayout.elements.table
{
	import flashx.textLayout.edit.TextFlowEdit;
	import flashx.textLayout.elements.ContainerFormattedElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.attribute.TableRowAttribute;
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;
	
	public class TableRowElement extends ContainerFormattedElement
	{
		public var attributes:IAttribute;
		
		// Flags for row pertaining to <thead />, <tfoot /> and <tbody />
		public var isHeader:Boolean;
		public var isFooter:Boolean;
		public var isBody:Boolean;
		
		public function TableRowElement()
		{
			super();
			setDefaultAttributes();
		}
		
		protected function setDefaultAttributes():void
		{
			attributes = TableRowAttribute.getDefaultAttributes();
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
			return elem is TableDataElement;
		}
		
		public override function shallowCopy(startPos:int = 0, endPos:int = -1):FlowElement
		{
			var copy:TableRowElement = super.shallowCopy(startPos, endPos) as TableRowElement;
			copy.attributes = attributes;
			copy.isBody = isBody;
			copy.isFooter = isFooter;
			copy.isHeader = isHeader;
			return copy;						
		}
		
		public function children():Vector.<TableDataElement>
		{
			if( mxmlChildren == null ) return null;
			
			var children:Vector.<TableDataElement> = new Vector.<TableDataElement>();
			var i:int;
			for( i = 0; i < mxmlChildren.length; i++ )
			{
				children.push( mxmlChildren[i] as TableDataElement );	
			}
			return children;
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
				var d:TableDataElement = new TableDataElement();
				var p:ParagraphElement = new ParagraphElement();
				p.replaceChildren(0,0,new SpanElement());
				d.replaceChildren(0,0,p);
				replaceChildren(0,0,d);
				d.normalizeRange(0,d.textLength);
				p.normalizeRange(0,p.textLength);	
			}
			else
			{
				super.normalizeRange(normalizeStart,normalizeEnd);
			}
		}
	}
}