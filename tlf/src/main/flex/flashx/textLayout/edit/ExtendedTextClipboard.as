package flashx.textLayout.edit
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.container.table.TableDisplayContainer;
	import flashx.textLayout.conversion.ConversionType;
	import flashx.textLayout.converter.IHTMLExporter;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.converter.TableParser;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.list.ListElementX;
	import flashx.textLayout.elements.list.ListItemElementX;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.tlf_internal;

	use namespace tlf_internal;
	public class ExtendedTextClipboard
	{
		protected var _htmlImporter:IHTMLImporter;
		protected var _htmlExporter:IHTMLExporter;
		
		public static const FORMAT_NODE_NAME:String = "extendedtextscrap";
		public static const ROOT_FLOW_ID:String = "cc-root-container";
		
		public function ExtendedTextClipboard( htmlImporter:IHTMLImporter, htmlExporter:IHTMLExporter )
		{
			_htmlImporter = htmlImporter;
			_htmlExporter = htmlExporter;
		}
		
		protected function setClipboardContents( htmlString:String ):void
		{
			if( htmlString == null ) return;
			Clipboard.generalClipboard.setData( ClipboardFormats.TEXT_FORMAT, htmlString );
		}
		
		protected function createHTMLFlowExportString( scrap:TextScrap ):String
		{
			if( scrap == null ) return null;
			var export:* = _htmlExporter.export( scrap.textFlow, ConversionType.XML_TYPE );
			return export.toXMLString();
		}
		
		protected function getMissingArray( missingChild:XML, textFlow:TextFlow ):Array
		{
			var missingArray:Array = new Array();
			var curFlElement:FlowElement = textFlow;
			if (missingChild != null)
			{
				var value:String = (missingChild.@value != undefined) ? String(missingChild.@value) : "";
				missingArray.push(textFlow);
				var posOfComma:int = value.indexOf(",");
				var startPos:int;
				var endPos:int;
				var curStr:String;
				var indexIntoFlowElement:int;
				while (posOfComma >= 0)
				{
					startPos = posOfComma + 1;
					posOfComma = value.indexOf(",", startPos);
					if (posOfComma >= 0)
					{
						endPos = posOfComma;
					} else {
						endPos = value.length;
					}
					curStr = value.substring(startPos, endPos);
					if (curStr.length > 0)
					{
						indexIntoFlowElement = parseInt(curStr);
						if (curFlElement is FlowGroupElement)
						{
							curFlElement = (curFlElement as FlowGroupElement).getChildAt(indexIntoFlowElement);
							missingArray.push(curFlElement);
						}
					}
				}				
			}
			return missingArray.reverse();
		}
		
		protected function assembleMissingArrayNode( nodeName:String, missingArray:Array ):XML
		{
			var node:XML = <{nodeName}/>
			
			var missingString:String = "";
			var curPos:int = missingArray.length - 2;
			var curFlElement:FlowElement;
			var curFlElementIndex:int;
			
			if( missingArray.length > 0 )
			{
				missingString = "0";
				while (curPos >= 0)
				{
					curFlElement = missingArray[curPos];
					curFlElementIndex = curFlElement.parent.getChildIndex(curFlElement);
					missingString = missingString + "," + curFlElementIndex;
					curPos--;
				}
			}
			
			if( missingString != "" )
				node.@value = missingString
					
			return node;
		}
		
		public function getContents():TextScrap
		{
			try
			{
				if( Clipboard.generalClipboard.hasFormat( ClipboardFormats.TEXT_FORMAT ) )
				{
					var textOnClipboard:String = String(Clipboard.generalClipboard.getData( ClipboardFormats.TEXT_FORMAT ));
					if( textOnClipboard != null && textOnClipboard != "" )
					{
						if( isExtendedClipboardContent( textOnClipboard ) )
						{
							var previousSettings:Object = XML.settings();
							XML.prettyIndent = 0;
							XML.prettyPrinting = false;
							var xmlContent:XML = XML( textOnClipboard );
							var rootTextFlow:XML = xmlContent..div.(@id == ExtendedTextClipboard.ROOT_FLOW_ID)[0];
							var textFlow:TextFlow = _htmlImporter.importToFlow( rootTextFlow.toString() );
							if (textFlow)
							{
								var i:int;
								var table:TableElement;
								for( i = 0; i < textFlow.mxmlChildren.length; i++ )
								{
									// If we have a table we need to fill it using a parser so elements are created.
									table = textFlow.mxmlChildren[i] as TableElement
									if( table )
									{
										new TableParser( _htmlImporter, "" ).parse( table.fragment, table );
									}
								}
								var beginMissingChild:XML = xmlContent..BeginMissingElements[0];
								var endMissingChild:XML = xmlContent..EndMissingElements[0];
								var retTextScrap:TextScrap = new TextScrap(textFlow);
								retTextScrap.beginMissingArray = getMissingArray( beginMissingChild, textFlow );
								retTextScrap.endMissingArray = getMissingArray( endMissingChild, textFlow );
								XML.setSettings( previousSettings );
								return retTextScrap;
							}
							XML.setSettings( previousSettings );
						}
					}
				}
			}
			catch( e:Error )
			{
				// may not be html, move on to super default.
				trace( "[" + getQualifiedClassName( this ) + "] - Error converting to TextScrap from clipboard:: " + e.message );
			}
			return TextClipboard.getContents();
		}
		
		public function isExtendedClipboardContent( source:String ):Boolean
		{
			try {
				var xml:XML = XML(source);
				return xml.name() == ExtendedTextClipboard.FORMAT_NODE_NAME;
			} 
			catch(e:*) {
				// fail silently and return false.
			}
			return false;
		}
		
		public function setContents( scrap:TextScrap ):void
		{
			var systemClipboard:Clipboard = Clipboard.generalClipboard;
			systemClipboard.clear();
			// ExtendedTextClipboard will handle setting html based on IHTMLImporter implementation.
			var htmlFlowExportString:String = createHTMLFlowExportString( scrap );
			var xmlExport:XML = XML( htmlFlowExportString );
			var xmlScrap:XML = <{ExtendedTextClipboard.FORMAT_NODE_NAME}/>;
			xmlScrap.appendChild( assembleMissingArrayNode( "BeginMissingElements", scrap.beginMissingArray ) );
			xmlScrap.appendChild( assembleMissingArrayNode( "EndMissingElements", scrap.endMissingArray ) );
			xmlScrap.appendChild( xmlExport );
			trace( "Pasting text scrap: " + xmlScrap );
			setClipboardContents( xmlScrap.toString() );
		}
	}
}