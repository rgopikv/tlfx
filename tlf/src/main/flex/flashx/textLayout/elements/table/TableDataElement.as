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
	import flashx.textLayout.model.style.TableDataStyle;
	import flashx.textLayout.model.table.ITableBaseDecorationContext;
	import flashx.textLayout.model.table.ITableDataDecorationContext;
	import flashx.textLayout.model.table.TableData;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.AttributeUtil;
	import flashx.textLayout.utils.TextLayoutFormatUtils;
	
	use namespace tlf_internal;
	public class TableDataElement extends TableBaseElement
	{
		protected var _tableData:TableData;
		public static const DEFAULT_FORMAT_PROPERTY:String = "defaultTableDataFormat";
		
		public function TableDataElement()
		{
			super();
			_pendingInitializationStyle = new TableDataStyle();
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
		 * Returns the ITextLayoutFormat for this element by selecting any defaults from configuration. 
		 * @return ITextLayoutFormat
		 */
		protected function computeFormat():ITextLayoutFormat
		{
			var style:Object = getStyle( TableDataElement.DEFAULT_FORMAT_PROPERTY );
			if( style == null )
			{
				var tf:TextFlow = getTextFlow();
				return tf == null ? null : tf.configuration[TableDataElement.DEFAULT_FORMAT_PROPERTY];
			}
			else if( style is ITextLayoutFormat )
				return ITextLayoutFormat(style);
			
			var ca:TextLayoutFormatValueHolder = new TextLayoutFormatValueHolder();
			var desc:Object = TextLayoutFormat.description;
			for (var prop:String in desc)
			{
				if (style[prop] != undefined)
					ca[prop] = style[prop];
			}
			return ca;
		}
		
		/**
		 * @private
		 * 
		 * Override to due proper merge of default format from Configuration of link with any user defined styles perviously applied to the format. 
		 * @return ITextLayoutFormat
		 */
		tlf_internal override function get formatForCascade():ITextLayoutFormat
		{
			var superFormat:ITextLayoutFormat = format;
			var effectiveFormat:ITextLayoutFormat = computeFormat();
			if (effectiveFormat || superFormat)
			{
				if (effectiveFormat && superFormat)
				{
					var resultingTextLayoutFormat:TextLayoutFormatValueHolder = new TextLayoutFormatValueHolder(effectiveFormat);
					if (superFormat)
					{
						TextLayoutFormatUtils.apply( resultingTextLayoutFormat, superFormat );
					}
					return resultingTextLayoutFormat;
				}
				return superFormat ? superFormat : effectiveFormat;
			}
			return null;
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
		 * Returns computed attributes of element and parentin elements. 
		 * @return IAttribute
		 */
		override public function getComputedAttributes():IAttribute
		{
			var attributes:IAttribute = super.getComputedAttributes();
			var parentAttributes:IAttribute = ( parent is ITableBaseElement ) ? ( parent as ITableBaseElement ).getComputedAttributes() : null;
			if( parentAttributes == null ) return attributes;
			return AttributeUtil.createFromMerge( _context.getDefaultAttributes(), attributes, parentAttributes );
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