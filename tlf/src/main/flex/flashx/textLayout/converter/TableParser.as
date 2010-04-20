package flashx.textLayout.converter
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.table.TableDataElement;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.elements.table.TableHeadingElement;
	import flashx.textLayout.elements.table.TableRowElement;
	import flashx.textLayout.events.TagParserCleanCompleteEvent;
	import flashx.textLayout.events.TagParserCleanProgressEvent;
	import flashx.textLayout.format.IStyle;
	import flashx.textLayout.format.TableStyle;
	import flashx.textLayout.model.attribute.TableDataAttribute;
	import flashx.textLayout.model.table.Table;
	import flashx.textLayout.model.table.TableColumn;
	import flashx.textLayout.model.table.TableRow;

	[Event(name="cleanComplete", type="flashx.textLayout.events.TagParserCleanCompleteEvent")]
	/**
	 * TableParser is an ITagParser implementation that parses valid html into a model representation of a Table. 
	 * @author toddanderson
	 */
	public class TableParser extends EventDispatcher implements ITagParser
	{
		protected var _htmlImporter:IHTMLImporter;
		protected var _cleaner:ITagCleaner;
		public static const TAG_TD:String = "td";
		public static const TAG_TH:String = "th";
		
		/**
		 * Constructor.
		 */
		public function TableParser( importer:IHTMLImporter, imageProxy:String = "" ) 
		{
			_htmlImporter = importer;
			_cleaner = new TableCleaner( imageProxy );
			_cleaner.addEventListener( TagParserCleanCompleteEvent.CLEAN_COMPLETE, handleCleanComplete, false, 0, true );
			_cleaner.addEventListener( TagParserCleanProgressEvent.CLEAN_PROGRESS, handleCleanProgress, false, 0, true );
		}
		
		/**
		 * @private
		 * 
		 * Parses style attribute. 
		 * @param tableNode XML
		 * @return IStyle
		 */
		protected function getStyle( tableNode:XML ):IStyle
		{
			// TODO. Check for attibute style and instantiate the TabStyle with it.
			var style:IStyle = new TableStyle();
			style.deserializeAttribute( tableNode.attribute("style") );
			( style as TableStyle ).border = int( tableNode.attribute("border") );
			return style;
		}
		
		/**
		 * @private 
		 * 
		 * Parses attributes on node into generic key/value Object.
		 * @param node XML
		 * @return Object
		 */
		protected function parseAttributes( node:XML ):Object
		{
			var attribute:XML;
			var attributes:Object = {};
			for each( attribute in node.attributes() )
			{
				var propertyName:String = attribute.name().localName;
				var propertyValue:String = attribute.toString();
				attributes[propertyName] = ( isNaN( Number(propertyValue) ) ) ? propertyValue : Number(propertyValue);
			}
			return attributes;
		}
		
		/**
		 * @private
		 * 
		 * Parses list of xml content into a TextFlow instance using the IHTMLImporter implementation. 
		 * @param list XMLList
		 * @return TextFlow
		 */
		protected function parseToFlow( list:XMLList ):TextFlow
		{
			var source:XML = <html />;
			var body:XML = <body />;
			var i:int;
			for( i = 0; i < list.length(); i++ )
			{
				body.appendChild( list[i] as XML );
			}
			source.appendChild( body );
			return _htmlImporter.importToFlow( source.toXMLString() );
		}
		
		/**
		 * @private
		 * 
		 * Parses each Table Data in a given Table Row. 
		 * @param td XML The markup representing a table cell.
		 * @param parentingAttributes Object The parenting attibutes of the Row.
		 * @return TableDataElement
		 */
		protected function parseTableData( td:XML, parentingAttributes:Object ):TableDataElement
		{
			var cell:TableDataElement = new TableDataElement();
			var content:Array = parseToFlow( td.children() ).mxmlChildren;
			var i:int;
			for( i = 0; i < content.length; i++ )
			{
				cell.addChild( content[i] as FlowElement );
			}
			cell.attributes.modifyAttributes( parentingAttributes );
			cell.attributes.modifyAttributes( parseAttributes( td ) );
			return cell;
		}
		
		/**
		 * @privtae
		 * 
		 * Parses and returns a TableHeading. 
		 * @param th XML The markup represeting a table heading.
		 * @param parentingAttributes Object The parenting attibutes of the Row.
		 * @return TableDataElement
		 */
		protected function parseTableHeading( th:XML, parentingAttributes:Object ):TableDataElement
		{
			var cell:TableDataElement = new TableHeadingElement();
			var content:Array = parseToFlow( th.children() ).mxmlChildren;
			var i:int;
			for( i = 0; i < content.length; i++ )
			{
				cell.addChild( content[i] as FlowElement );
			}
			cell.attributes.modifyAttributes( parentingAttributes );
			cell.attributes.modifyAttributes( parseAttributes( th ) );
			return cell;
		}
		
		/**
		 * @private
		 * 
		 * Parses each row in the Table. 
		 * @param tr XML XML fragment related to a single Table Row.
		 * @return TableRowElement
		 */
		protected function parseTableRow( tr:XML ):TableRowElement
		{
			var row:TableRowElement = new TableRowElement();
			var attributes:Object = parseAttributes( tr );
			var i:int = 0;
		
			var children:XMLList = tr.children();
			var child:XML;
			var tableData:TableDataElement;
			for( i = 0; i < children.length(); i++ )
			{
				child = children[i] as XML;
				if( child.name() == TableParser.TAG_TD )
				{
					tableData = parseTableData( child, attributes );
				}
				else if( child.name() == TableParser.TAG_TH )
				{
					tableData = parseTableHeading( child, attributes );
				}	
					
				if( tableData ) row.addChild( tableData );
				tableData = null;
			}
			row.attributes.modifyAttributes( attributes );
			return row;
		}
		
		/**
		 * @private
		 * 
		 * Parses the table (whether created generically or using thead, tfoot and tbody) into a constructed top-down sequence of rows. 
		 * @param xml XML
		 * @return Vector.<TableRowElement>
		 */
		protected function parseTableIntoSequenceRows( xml:XML ):Vector.<TableRowElement>
		{
			var rows:Vector.<TableRowElement> = new Vector.<TableRowElement>();
			
			// straight up list of normal constructed table.
			var trList:XMLList = xml.tr;
			var thList:XMLList = xml.th;
			
			// list of optional sections of table.
			var thead:XMLList = xml.thead;
			var tfoot:XMLList = xml.tfoot;
			var tbody:XMLList = xml.tbody;
			
			// First go through optional thead. tbody, tfoot construction.
			rows = rows.concat( parseHead( thead ) );
			
			// Then move on to normal construction.
			// first go through headers -> they are considered as rows.
			var i:int = 0;
			if( thList.length() > 0 )
			{
				// wrap the header in a row and push to stack.
				rows.push( parseTableRow( wrapHeadersInRow( thList ) ) );
			}
			
			// Then start on body.
			rows = rows.concat( parseBody( tbody ) );
			// then go through rows.
			for( i = 0; i < trList.length(); i++ )
			{
				rows.push( parseTableRow( trList[i] ) );
			}
			
			// Finish up with footer.
			rows = rows.concat( parseFoot( tfoot ) );
			
			return rows;
		}
		
		/**
		 * @private
		 * 
		 * Parses a list of <thead /> tags into a list of TableRow. 
		 * @param head XMLList A List of <thead />
		 * @return Vector.<TableRowElement>
		 */
		protected function parseHead( head:XMLList ):Vector.<TableRowElement>
		{
			var list:Vector.<TableRowElement> = new Vector.<TableRowElement>();
			var th:XMLList;
			var row:TableRowElement;
			var i:int;
			for( i = 0; i < head.length(); i++ )
			{
				th = XML( head[i] )..th;
				row = parseTableRow( wrapHeadersInRow( th ) );
				row.isHeader = true;
				list.push( row );
			}
			return list;
		}
		
		/**
		 * @private
		 * 
		 * Parses a list of <tbody /> tags into a list of TableRow. 
		 * @param body XMLList A List of <tbody />
		 * @return Vector.<TableRowElement>
		 */
		protected function parseBody( body:XMLList ):Vector.<TableRowElement>
		{
			var list:Vector.<TableRowElement> = new Vector.<TableRowElement>();
			var tr:XMLList;
			var row:TableRowElement;
			var i:int;
			var j:int;
			for( i = 0; i < body.length(); i++ )
			{
				tr = XML( body[i] ).tr;
				for( j = 0; j < tr.length(); j++ )
				{
					row = parseTableRow( tr[j] );
					row.isBody = true;
					list.push( row );
				}
			}
			return list;
		}
		
		/**
		 * @private
		 * 
		 * Parses a list of <tfoot /> tags into TableRow list. 
		 * @param foot XMLList A list of <tfoot />
		 * @return Vector.<TableRowElement>
		 */
		protected function parseFoot( foot:XMLList ):Vector.<TableRowElement>
		{
			var list:Vector.<TableRowElement> = new Vector.<TableRowElement>();
			var tr:XMLList;
			var row:TableRowElement;
			var i:int;
			var j:int;
			for( i = 0; i < foot.length(); i++ )
			{
				tr = XML( foot[i] ).tr;
				for( j = 0; j < tr.length(); j++ )
				{
					row = parseTableRow( tr[j] );
					row.isFooter = true;
					list.push( row );
				}
			}
			return list;
		}
		
		/**
		 * @private
		 * 
		 * Wraps <th /> tags in <tr /> in order to parse into TableRow. 
		 * @param headers XMLList List of <th />
		 * @return XML
		 */
		protected function wrapHeadersInRow( headers:XMLList ):XML
		{
			var rowFragment:XML = <tr />;
			var i:int;
			for( i = 0; i < headers.length(); i++ )
			{
				rowFragment.appendChild( headers[i] as XML );	
			}
			return rowFragment;
		}
		
		/**
		 * @private
		 * 
		 * Event handle for progress of clean. 
		 * @param evt TagParserCleanProgressEvent
		 */
		protected function handleCleanProgress( evt:TagParserCleanProgressEvent ):void
		{
			dispatchEvent( evt.clone() );
		}
		
		/**
		 * @private
		 * 
		 * Event handler for complete of clean. 
		 * @param evt TagParserCleanCompleteEvent
		 */
		protected function handleCleanComplete( evt:TagParserCleanCompleteEvent ):void
		{
			dispatchEvent( evt.clone() );
		}
		
		/**
		 * Cleans fragment into nice table, also used for loading images. 
		 * @param fragment String
		 */
		public function clean( fragment:String ):void
		{
			_cleaner.clean( fragment );
		}
		
		/**
		 * Parses HTML <table> element. 
		 * @param fragment String
		 */
		public function parse( fragment:String, tableElement:TableElement ):*
		{
			var table:Table;
			try
			{
				XML.ignoreComments = true;
				XML.ignoreWhitespace = true;
				XML.prettyPrinting = false;
				XML.prettyIndent = 0;
				var xml:XML = XML( fragment );
				// parse into flat row array.
				var rows:Vector.<TableRowElement> = parseTableIntoSequenceRows( xml );
				var i:int;
				for( i = 0; i < rows.length; i++ )
				{
					tableElement.addChild( rows[i] );
				}
				
				// instantiate a new Table instance.
				table = new Table( getStyle( xml ) );
				table.attributes.modifyAttributes( parseAttributes( xml ) );
			}
			catch( e:Error )
			{
				// Possibly a TypeError.
				trace( e );
			}
			return table;
		}
		
		/**
		 * Performs any necessary clean up instructions.
		 */
		public function dismantle():void
		{
			_cleaner.removeEventListener( TagParserCleanCompleteEvent.CLEAN_COMPLETE, handleCleanComplete, false );
			_cleaner.removeEventListener( TagParserCleanProgressEvent.CLEAN_PROGRESS, handleCleanProgress, false );
			_cleaner.dismantle();
		}
	}
}