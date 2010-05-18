package flashx.textLayout.edit
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.conversion.ConversionType;
	import flashx.textLayout.converter.IHTMLExporter;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.tlf_internal;

	use namespace tlf_internal;
	public class ExtendedTextClipboard
	{
		protected var _htmlImporter:IHTMLImporter;
		protected var _htmlExporter:IHTMLExporter;
		
		public function ExtendedTextClipboard( htmlImporter:IHTMLImporter, htmlExporter:IHTMLExporter )
		{
			_htmlImporter = htmlImporter;
			_htmlExporter = htmlExporter;
		}
		
		protected function setClipboardContents( htmlString:String ):void
		{
			if( htmlString == null ) return;
			Clipboard.generalClipboard.setData( ClipboardFormats.HTML_FORMAT, htmlString );
		}
		
		protected function createHTMLFlowExportString( scrap:TextScrap ):String
		{
			if( scrap == null ) return null;
			return _htmlExporter.export( scrap.textFlow, ConversionType.XML_TYPE ).toString();
		}
		
		public function getContents():TextScrap
		{
			// If HTML conversion fails, fall back to TextClipboard.
			try
			{
				if( Clipboard.generalClipboard.hasFormat( ClipboardFormats.HTML_FORMAT ) )
				{
					var textOnClipboard:String = String(Clipboard.generalClipboard.getData( ClipboardFormats.HTML_FORMAT ));
					if (textOnClipboard != null && textOnClipboard != "")
					{
						var textFlow:TextFlow = _htmlImporter.importToFlow( textOnClipboard );
						if (textFlow)
						{
							var retTextScrap:TextScrap = new TextScrap(textFlow);
							var firstLeaf:FlowLeafElement = textFlow.getFirstLeaf();
							if (firstLeaf)
							{
								retTextScrap.beginMissingArray.push(firstLeaf);
								retTextScrap.beginMissingArray.push(firstLeaf.parent);
								retTextScrap.beginMissingArray.push(textFlow);
								
								var lastLeaf:FlowLeafElement = textFlow.getLastLeaf();
								retTextScrap.endMissingArray.push(lastLeaf);
								retTextScrap.endMissingArray.push(lastLeaf.parent);
								retTextScrap.endMissingArray.push(textFlow);
							}
							return retTextScrap;
						}
					}
				}
			}
			catch( e:Error )
			{
				// may not be html, move on to super default.
				trace( "[" + getQualifiedClassName( this ) + "] - Error converting to HTML:: " + e.message );
			}
			return TextClipboard.getContents();
		}
		
		public function setContents( scrap:TextScrap ):void
		{
			// TextClipboard will handle adding plain text and TLF markup based on scrap.
			TextClipboard.setContents( scrap );
			// ExtendedTextClipboard will handle setting html based on IHTMLImporter implementation.
			var htmlFlowExportString:String = createHTMLFlowExportString( scrap );
			setClipboardContents( htmlFlowExportString );
		}
	}
}