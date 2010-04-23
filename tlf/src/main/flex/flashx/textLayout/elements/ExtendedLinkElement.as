package flashx.textLayout.elements
{
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormatValueHolder;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.TextLayoutFormatUtils;
	
	use namespace tlf_internal;
	
	public class ExtendedLinkElement extends LinkElement
	{
		public function ExtendedLinkElement()
		{
			super();
		}
		
		/**
		 * The purpose of creating this class is to solve the future implementation problem of LinkElement being able to accept at least one other LinkElement
		 * as HTML allows.
		 * 
		 * This implementation hasn't yet been elected to be developed, but it may be in the future.
		 */		
		
		override tlf_internal function canOwnFlowElement(elem:FlowElement) : Boolean
		{
			return elem is FlowLeafElement;
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
			var effectiveFormat:ITextLayoutFormat = effectiveLinkElementTextLayoutFormat;
			if (effectiveFormat || superFormat)
			{
				if (effectiveFormat && superFormat)
				{
					var resultingTextLayoutFormat:TextLayoutFormatValueHolder = new TextLayoutFormatValueHolder(effectiveFormat);
					if (superFormat)
					{
						TextLayoutFormatUtils.mergeFormats( resultingTextLayoutFormat, superFormat );
					}
					return resultingTextLayoutFormat;
				}
				return superFormat ? superFormat : effectiveFormat;
			}
			return null;
		}
	}
}