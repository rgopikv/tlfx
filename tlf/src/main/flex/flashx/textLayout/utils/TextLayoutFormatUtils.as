package flashx.textLayout.utils
{
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowValueHolder;
	import flashx.textLayout.formats.FormatValue;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.tlf_internal;

	use namespace tlf_internal;
	
	/**
	 * TextLayoutFormatUtils is a utility class to work with ITextLayoutFormat instances. 
	 * @author toddanderson
	 * 
	 */
	public class TextLayoutFormatUtils
	{
		/**
		 * Overlays defined formatting property to target format. 
		 * @param format ITextLayoutFormat The target format to overlay styles. 
		 * @param overlayFormat ITextLayoutFormat The format from which to apply defined styles to the target format.
		 * @return ITextLayoutFormat
		 */
		static public function mergeFormats( format:ITextLayoutFormat, overlayFormat:ITextLayoutFormat ):ITextLayoutFormat
		{	
			var property:String;
			for( property in TextLayoutFormat.description )
			{
				if( overlayFormat[property] != undefined )
					format[property] = overlayFormat[property];
			}
			return format;
		}
	}
}