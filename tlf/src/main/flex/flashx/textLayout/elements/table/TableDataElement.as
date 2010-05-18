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
	import flashx.textLayout.model.table.ITableBaseDecorationContext;
	import flashx.textLayout.model.table.ITableDataDecorationContext;
	import flashx.textLayout.model.table.TableData;
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;
	public class TableDataElement extends TableBaseElement
	{
		protected var _tableData:TableData;
		
		public function TableDataElement()
		{
			super();
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
		
		public override function shallowCopy(startPos:int = 0, endPos:int = -1):FlowElement
		{
			var copy:TableDataElement = super.shallowCopy(startPos, endPos) as TableDataElement;
			copy.tableDataModel = _tableData;
			return copy;						
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
		
		/**
		 * Returns reference to table model. 
		 * @return Table
		 */
		public function getTableDataModel():TableData
		{
			return _tableData;
		}
		tlf_internal function set tableDataModel( value:TableData ):void
		{
			_tableData = value;
			_context = _tableData.context;
		}
		
		/**
		 * Returns the held concrete implmenebtaton of the ITableDataDecorationContext defained on the model. 
		 * @return ITableDataDecorationContext
		 */
		public function getDecorationContext():ITableDataDecorationContext
		{
			return _context as ITableDataDecorationContext;
		}
	}
}