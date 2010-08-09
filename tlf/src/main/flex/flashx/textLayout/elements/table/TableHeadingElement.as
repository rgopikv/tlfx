package flashx.textLayout.elements.table
{
	import flash.text.engine.FontWeight;
	
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextAlign;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormatValueHolder;
	import flashx.textLayout.model.attribute.TableHeadingAttribute;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.TextLayoutFormatUtils;

	use namespace tlf_internal;
	/**
	 * TableHeadingElement is an element model representing a tabel heading. 
	 * @author toddanderson
	 */
	public class TableHeadingElement extends TableDataElement
	{
		public static const DEFAULT_FORMAT_PROPERTY:String = "defaultTableHeaderFormat";
		/**
		 * Constructor.
		 */
		public function TableHeadingElement()
		{
			super();
		}
		
		/**
		 * @private
		 * 
		 * Returns the ITextLayoutFormat for this element by selecting any defaults from configuration. 
		 * @return ITextLayoutFormat
		 */
		override protected function computeFormat():ITextLayoutFormat
		{
			var style:Object = getStyle( TableHeadingElement.DEFAULT_FORMAT_PROPERTY );
			if( style == null )
			{
				var tf:TextFlow = getTextFlow();
				return tf == null ? null : tf.configuration[TableHeadingElement.DEFAULT_FORMAT_PROPERTY];
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
		
//		/**
//		 * @private
//		 * 
//		 * Override to due proper merge of default format from Configuration of link with any user defined styles perviously applied to the format. 
//		 * @return ITextLayoutFormat
//		 */
//		tlf_internal override function get formatForCascade():ITextLayoutFormat
//		{
//			var superFormat:ITextLayoutFormat = format;
//			var effectiveFormat:ITextLayoutFormat = computeFormat();
//			if (effectiveFormat || superFormat)
//			{
//				if (effectiveFormat && superFormat)
//				{
//					var resultingTextLayoutFormat:TextLayoutFormatValueHolder = new TextLayoutFormatValueHolder(effectiveFormat);
//					if (superFormat)
//					{
//						TextLayoutFormatUtils.apply( resultingTextLayoutFormat, superFormat );
//					}
//					return resultingTextLayoutFormat;
//				}
//				return superFormat ? superFormat : effectiveFormat;
//			}
//			return null;
//		}
	}
}