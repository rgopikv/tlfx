package flashx.textLayout.elements.table
{
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	
	import flashx.textLayout.container.table.ICellContainer;
	import flashx.textLayout.container.table.TableCellContainer;
	import flashx.textLayout.container.table.TableDisplayContainer;
	import flashx.textLayout.converter.ITagAssembler;
	import flashx.textLayout.converter.ITagParser;
	import flashx.textLayout.converter.TableMapper;
	import flashx.textLayout.elements.ContainerFormattedElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.events.InlineStyleEvent;
	import flashx.textLayout.events.TableElementStatusEvent;
	import flashx.textLayout.events.TagParserCleanCompleteEvent;
	import flashx.textLayout.events.TagParserCleanProgressEvent;
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.style.ITableStyle;
	import flashx.textLayout.model.style.InlineStyles;
	import flashx.textLayout.model.style.TableStyle;
	import flashx.textLayout.model.table.ITableBaseDecorationContext;
	import flashx.textLayout.model.table.ITableDecorationContext;
	import flashx.textLayout.model.table.Table;
	import flashx.textLayout.model.table.TableRow;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.StyleAttributeUtil;
	
	use namespace tlf_internal;
	/**
	 * TableElement represents a table in the text flow. 
	 * @author toddanderson
	 */
	public class TableElement extends TableBaseElement
	{
		protected var _table:Table;
		protected var _tableMapper:TableMapper;
		protected var _fragment:*;
		protected var _importer:ITagParser;
		protected var _exporter:ITagAssembler;
		
		protected var _tableManager:ITableElementManager;
		
		protected var _elementalIndex:int;
		protected var _targetContainer:TableDisplayContainer;
		
		protected var _textFlow:TextFlow;
		protected var _isInitialized:Boolean;
		
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
		
		override tlf_internal function canReleaseContentElement() : Boolean
		{
			return false;
		}
		
		/**
		 * @private
		 * 
		 * Override to only allow element of TableRowElement as children. 
		 * @param elem FlowElement
		 * @return Boolean
		 */
		override tlf_internal function canOwnFlowElement(elem:FlowElement):Boolean
		{
			return ( elem is TableRowElement );
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
				var r:TableRowElement = new TableRowElement();
				var d:TableDataElement = new TableDataElement();
				var p:ParagraphElement = new ParagraphElement();
				p.replaceChildren(0,0,new SpanElement());
				d.replaceChildren(0,0,p);
				r.replaceChildren(0,0,d);
				replaceChildren(0,0,r);
				r.normalizeRange(0,r.textLength);
				d.normalizeRange(0,d.textLength);
				p.normalizeRange(0,p.textLength);	
			}
			else
			{
				super.normalizeRange(normalizeStart,normalizeEnd);
			}
		}
		
		/**
		 * @inherit
		 * 
		 * Override to apply proper properties to copy. 
		 * @param startPos int
		 * @param endPos int
		 * @return FlowElement
		 */
		override public function shallowCopy(startPos:int=0, endPos:int=-1):FlowElement
		{
			var copy:TableElement = super.shallowCopy(startPos, endPos) as TableElement;
			copy.importer = _importer;
			copy.exporter = _exporter;
			copy.fragment = serialize();
			copy.tableModel = _table;
			return copy;
		}
		
		/**
		 * @private
		 * 
		 * Updates the model map of rows and columns.
		 */
		protected function updateTableMap():void
		{
			_tableMapper.map( children() );
		}
		
		/**
		 * @private
		 * 
		 * Event handler for enter frame of traget display to run a refresh on display list. 
		 * @param evt Event
		 */
		protected function handleRenderFrame( evt:Event ):void
		{
			_targetContainer.removeEventListener( Event.ENTER_FRAME, handleRenderFrame, false );
			
			updateTableMap();
			_tableManager.compose();
			
			// Run update.
			var tf:TextFlow = getTextFlow();
			if (tf && tf.flowComposer)
			{
				tf.flowComposer.updateAllControllers();
			}
		}
		
		/**
		 * @private
		 * 
		 * Event handler for parser clean progress. Used to notify a client of progress. 
		 * @param evt TagParserCleanProgressEvent
		 */
		protected function handleParseCleanProgress( evt:TagParserCleanProgressEvent ):void
		{
			//
		}
		
		/**
		 * @private
		 * 
		 * Event handler for complete of parse clean. Moves on to continue parsing table and building textflow. 
		 * @param evt TagParserCleanCompleteEvent
		 */
		protected function handleParseCleanComplete( evt:TagParserCleanCompleteEvent ):void
		{
			_importer.removeEventListener( TagParserCleanCompleteEvent.CLEAN_COMPLETE, handleParseCleanComplete );
			_importer.removeEventListener( TagParserCleanProgressEvent.CLEAN_PROGRESS, handleParseCleanProgress );
			
			// Wipe out any possibility of empty constrcution which TLF loves to do.
			if( !_isInitialized )
			{
				while( numChildren > 0 )
				{
					removeChildAt( 0 );
				}
			}
			// Parse html string into a Table object using the importer.
			// Table serves as a model for rows and columns and holds attribues and styles.
			_table = _importer.parse( evt.xml.toString(), this ) as Table;
			_context = _table.getContextImplementation();
			_context.mergeStyle( _pendingInitializationStyle );
			_pendingInitializationStyle = null;
			
			// Table Mapper handles taking this Element Model and converting rows and columns
			// into iterators for fast manipulation of cell display.
			_tableMapper = new TableMapper( this );
			updateTableMap();
			
			// Initializes the main display of the visible table.
			_targetContainer.initialize();
			// Kicks on table creation based on models and displays.
			_tableManager.create( this, _targetContainer );
			
			_isInitialized = true;
			_textFlow.dispatchEvent( new TableElementStatusEvent( TableElementStatusEvent.INITIALIZED, this ) );
		}
		
		/**
		 * @inherit
		 */
		override protected function handleAppliedStyleChange(evt:InlineStyleEvent):Boolean
		{
			var requiresUpdate:Boolean = super.handleAppliedStyleChange( evt );
			// Run display refresh if available.
			if( requiresUpdate && _isInitialized && _tableManager ) 
				_tableManager.refresh();
			
			return requiresUpdate;
		}
		
		/**
		 * @inherit
		 */
		override protected function handleExplicitStyleChange(evt:InlineStyleEvent):Boolean
		{
			var requiresUpdate:Boolean = super.handleExplicitStyleChange( evt );
			// Run display refresh if available.
			if( requiresUpdate && _isInitialized && _tableManager ) 
				_tableManager.refresh();
			
			return requiresUpdate;
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
		 * Converts the flat array of children into a vector of TableRowElements 
		 * @return Vector.<TableRowElement>
		 */
		public function children():Vector.<TableRowElement>
		{
			if( !mxmlChildren ) return null;
			
			var rows:Vector.<TableRowElement> = new Vector.<TableRowElement>();
			var i:int;
			for( i = 0; i < mxmlChildren.length; i++ )
			{
				rows.push( mxmlChildren[i] as TableRowElement );
			}
			return rows;
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
		
		/**
		 * Returns the held TetFlow instance. 
		 * @return TextFlow
		 */
		override public function getTextFlow():TextFlow
		{
			return _textFlow;
		}
		
		/**
		 * Runs a refresh on the element construction and subsequent display.
		 */
		public function refesh():void
		{
			updateTableMap();
			_tableManager.compose();
		}
		
		/**
		 * Cleans table element for removal.
		 */
		override public function dispose():void
		{
			super.dispose();
			_importer = null;
			_exporter = null;
			_tableMapper = null;
			_table = null;
			_fragment = null;
			
			_targetContainer.dispose();
			_targetContainer = null;
			
			_tableManager.dispose();
			_tableManager = null;
		}
		
		/**
		 * Serializes and returns the table representation as valid table HTML markup. 
		 * @return String
		 */
		public function serialize():String
		{
			XML.prettyIndent = 4;
			XML.prettyPrinting = true;
			_fragment = XML( _exporter.createFragment( this ) )
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
		 * Returns the held concrete implmenebtaton of the ITableDecorationContext defained on the model. 
		 * @return ITableDecorationContext
		 */
		public function getDecorationContext():ITableDecorationContext
		{
			return _context as ITableDecorationContext;
		}
		
		/**
		 * Returns reference to table model. 
		 * @return Table
		 */
		public function getTableModel():Table
		{
			return _table;
		}
		tlf_internal function set tableModel( value:Table ):void
		{
			_table = value;
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