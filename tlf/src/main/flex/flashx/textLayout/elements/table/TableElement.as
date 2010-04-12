package flashx.textLayout.elements.table
{
	import flash.display.DisplayObjectContainer;
	
	import flashx.textLayout.container.table.ICellContainer;
	import flashx.textLayout.container.table.TableCellContainer;
	import flashx.textLayout.container.table.TableDisplayContainer;
	import flashx.textLayout.converter.ITagAssembler;
	import flashx.textLayout.converter.ITagParser;
	import flashx.textLayout.elements.ContainerFormattedElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.events.TagParserCleanCompleteEvent;
	import flashx.textLayout.events.TagParserCleanProgressEvent;
	import flashx.textLayout.model.table.Table;
	import flashx.textLayout.model.table.TableData;
	import flashx.textLayout.model.table.TableRow;
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;
	/**
	 * TableElement represents a table in the text flow. 
	 * @author toddanderson
	 */
	public class TableElement extends ContainerFormattedElement
	{
		protected var _table:Table;
		protected var _fragment:*;
		protected var _importer:ITagParser;
		protected var _exporter:ITagAssembler;
		
		protected var _tableManager:ITableElementManager;
		protected var _elementalIndex:int;
		protected var _targetContainer:TableDisplayContainer;
		
		protected var _textFlow:TextFlow;
		
		public static const LINE_BREAK_IDENTIFIER:String = "|tlf_table_paste_break|";
		
		/**
		 * Constrcutor.
		 */
		public function TableElement()
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
		
		override public function shallowCopy(startPos:int=0, endPos:int=-1):FlowElement
		{
			var copy:TableElement = super.shallowCopy(startPos, endPos) as TableElement;
			copy.fragment = _fragment;
			return copy;
		}
		
		/**
		 * @private
		 * 
		 * Event handler for parser clean progress. Used to notify a client of progress. 
		 * @param evt TagParserCleanProgressEvent
		 */
		protected function handleParseCleanProgress( evt:TagParserCleanProgressEvent ):void
		{
//			// Create progress alert if not there.
//			if( _progressAlert == null )
//				_progressAlert = new TableProgressAlert();
//			
//			// Show and update.
//			_alertManager.showAlert( _progressAlert );
//			_progressAlert.message = evt.message;
//			_progressAlert.percent = evt.percent;
		}
		
		/**
		 * @private
		 * 
		 * Event handler for complete of parse clean. Moves on to continue parsing table and building textflow. 
		 * @param evt TagParserCleanCompleteEvent
		 */
		protected function handleParseCleanComplete( evt:TagParserCleanCompleteEvent ):void
		{
			// Kill progress alert if shown.
//			if( _progressAlert )
//			{
//				_alertManager.hideAlert( _progressAlert );
//				_progressAlert = null;
//			}
			
			// Parse html string into a Table object using the importer.
			_table = _importer.parse( evt.xml.toString() ) as Table;
			_targetContainer.initialize();
			
			_tableManager.create( this, _table, _targetContainer );
		}
		
		/**
		 * Initialized the table element with a reference to the target TextFlow and the target display object container on which to add visual cells. 
		 * @param textFlow TextFlow
		 * @param targetContainer DisplayObjectContainer
		 */
		public function initialize( textFlow:TextFlow, targetContainer:TableDisplayContainer ):void
		{
			_textFlow = textFlow;
			_targetContainer = targetContainer;
			
			_importer.addEventListener( TagParserCleanCompleteEvent.CLEAN_COMPLETE, handleParseCleanComplete );
			_importer.addEventListener( TagParserCleanProgressEvent.CLEAN_PROGRESS, handleParseCleanProgress );
			_importer.clean( _fragment );
		}
		
		/**
		 * Returns the cell container at the supplied position within the text flow. 
		 * @param position int
		 * @return ICellContainer
		 */
		public function getCellAtPosition( position:int ):ICellContainer
		{
			var i:int;
			var start:int;
			var end:int;
			var childElement:FlowElement;
			for( i = 0; i < numChildren; i++ )
			{
				childElement = getChildAt( i ) as FlowElement;
				start = childElement.getAbsoluteStart();
				end = start + childElement.textLength;
				if( start <= position && end >= position )
				{
					return _tableManager.findCellFromElement( childElement );
				}
			}
			return null;
		}
		
//		override tlf_internal function canOwnFlowElement(elem:FlowElement):Boolean
//		{
//			return ( elem is TableRowElement );
//		}
//		
//		override public function removeChild(child:FlowElement):FlowElement
//		{
//			return super.removeChild( child );
//		}
		
		/**
		 * Returns the held TetFlow instance. 
		 * @return TextFlow
		 */
		override public function getTextFlow():TextFlow
		{
			return _textFlow;
		}
		
		/**
		 * Serializes and returns the table representation as valid table HTML markup. 
		 * @return String
		 */
		public function serialize():String
		{
			XML.prettyIndent = 4;
			XML.prettyPrinting = true;
			_fragment = ( _table ) ? XML( _exporter.createFragment( _table ) ) : <table/>;
			return _fragment.toXMLString();
		}
		
		/**
		 * Returns reference to target container that cells are placed on. 
		 * @return DisplayObjectContainer
		 */
		public function getTargetContainer():TableDisplayContainer
		{
			return _targetContainer;
		}
		
		/**
		 * Returns reference to table model. 
		 * @return Table
		 */
		public function getTableModel():Table
		{
			return _table;
		}
		
		/**
		 * Accessor/Modifier for the target ITableElementManager impementation that handles layout and management of the table. 
		 * @return ITableElementManager
		 */
		public function get tableManager():ITableElementManager
		{
			return _tableManager;
		}
		public function set tableManager( value:ITableElementManager ):void
		{
			_tableManager = value;
		}
		
		/**
		 * Accessor/Modifier for the fragment to parse into a visual table for the textflow. 
		 * @return * an be XML or String
		 */
		public function get fragment():* /* String or XML */
		{
			return _fragment;
		}
		public function set fragment( value:* /* String or XML */ ):void
		{
			_fragment = value;
		}
		
		/**
		 * Accessor/Modifier for the table fragment parser. 
		 * @return ITagParser
		 */
		public function get importer():ITagParser
		{
			return _importer;
		}
		public function set importer( value:ITagParser ):void
		{
			_importer = value;
		}
		
		/**
		 * Accessor/Modifier for the converter of the current table model into a vlaie HTML markup. 
		 * @return ITagAssembler
		 */
		public function get exporter():ITagAssembler
		{
			return _exporter;
		}
		public function set exporter( value:ITagAssembler ):void
		{
			_exporter = value;
		}
		
		/**
		 * Accessor/Modifier of the index within the textflow that this element resides. 
		 * @return int
		 */
		public function get elementalIndex():int
		{
			return _elementalIndex;
		}
		public function set elementalIndex( value:int ):void
		{
			_elementalIndex = value;
		}
	}
}