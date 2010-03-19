package flashx.textLayout.container.table
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.engine.TextLine;
	import flash.utils.Timer;
	
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.conversion.TextConverter;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.converter.TableDataElementConverter;
	import flashx.textLayout.elements.Configuration;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.IConfiguration;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.events.table.TableCellContainerEvent;
	import flashx.textLayout.events.table.TableCellFocusEvent;
	import flashx.textLayout.factory.TextFlowTextLineFactory;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.attribute.TableAttribute;
	import flashx.textLayout.model.attribute.TableDataAttribute;
	import flashx.textLayout.model.table.TableData;
	import flashx.textLayout.model.table.TableHeading;
	import flashx.textLayout.utils.FragmentAttributeUtil;
	import flashx.textLayout.utils.StyleAttributeUtil;
	import flashx.textLayout.utils.TextLayoutFormatUtils;
	
	[Event(name="cellResize", type="com.constantcontact.texteditor.event.TableCellContainerEvent")]
	[Event(name="requestFocus", type="com.constantcontact.texteditor.event.TableCellFocusEvent")]
	/**
	 * TableCellContainer is an ICellContainer implemnetation that represents a single cell within a Table display. 
	 * @author toddanderson
	 */
	public class TableCellContainer extends Sprite implements ICellContainer
	{	
		protected var background:Sprite;
		protected var border:Shape;
		protected var targetDisplay:TableCellDisplay;
		protected var _controller:ContainerController;
		
		protected var _width:Number = 0;
		protected var _height:Number = 0;
		
		protected var _actualWidth:Number = 0;
		protected var _actualHeight:Number = 0;
		
		protected var _minimumWidth:Number = 0;
		protected var _minimumHeight:Number = 0;
		
		protected var _rowIndex:int;
		protected var _rowLength:int;
		protected var _columnIndex:int;
		protected var _columnLength:int;
		
		protected var _ascent:Number = 0;
		protected var _descent:Number = 0;
		
		protected var _data:TableData;
		protected var _htmlConverter:IHTMLImporter;
		protected var _tableAttributes:IAttribute;
		protected var _textFlow:TextFlow;
		protected var _elementList:Array; /* FlowElement[] */
		
		protected var _lineBreakIdentifier:String = TableCellContainer.INTERNAL_LINE_BREAK_IDENTIFIER;
		protected var _numLines:int;
		protected var _proposedHeight:Number;
		protected var _previousHeight:Number;
		
		private var _uid:String;
		public static const UID_PREFIX:String = "TableCellContainer";
		protected static var ID:int;
		
		private static const DEFAULT_HTML_HORIZ_PADDING:int = 1;
		private static const INTERNAL_LINE_BREAK_IDENTIFIER:String = "table_cell_container_line_break_identifier";
		
		/**
		 * Constructor.
		 *  
		 * @param data The HTML table data to be presented.
		 */
		public function TableCellContainer( data:TableData, tableAttributes:IAttribute, htmlImporter:IHTMLImporter )
		{
			_data = data;
			_tableAttributes = tableAttributes;
			_htmlConverter = htmlImporter;
			
			// Create text flow.
			_textFlow = new TextFlow( getDefaultConfiguration() );
			
			// Precompute index lengths.
			_rowLength = Math.max( ( _data.attributes as Object ).rowspan - 1, 0 );
			_columnLength = Math.max( ( _data.attributes as Object ).colspan - 1, 0 );
			
			// create background graphic.
			background = new Sprite();
			addChild( background );
			background.addEventListener( MouseEvent.CLICK, handleClick, false, 0, true );
			
			border = new Shape();
			addChild( border );
			
			// create the target display of the cell.
			targetDisplay = new TableCellDisplay();
			addChild( targetDisplay );
			
			// Set default values.
			var attributes:Object = _data.attributes;
			_width = getDefinedWidth();
			_height = getDefinedHeight();
			_actualWidth = _width - getUnifiedPadding();
			_actualHeight = _height - getUnifiedPadding();
			
			// Set Unique ID associated with this cell container.
			_uid = TableCellContainer.UID_PREFIX + TableCellContainer.ID;
			TableCellContainer.ID++;
		}
		
		/**
		 * @private 
		 * 
		 * Validates the measured size of the container.
		 */
		protected function invalidateSize():void
		{
			//TODO: Get background color from styles.
			background.graphics.clear();
			background.graphics.beginFill( 0xFFFFFF, 1 );
			background.graphics.drawRect( 0, 0, _width, _height );
			background.graphics.endFill();
			
			_actualWidth = getTargetWidth() - getUnifiedPadding();
			positionTarget();
		}
		
		/**
		 * @private 
		 * 
		 * Clears element list.
		 */
		protected function cleanElementList():void
		{
			_elementList = [];
		}
		
		/**
		 * @private 
		 * 
		 * Clears currently held TextFlow instance for GC.
		 */
		protected function cleanTextFlow():void
		{
			if( _textFlow == null ) return;
			
			while( _textFlow.numChildren > 0 )
			{
				_textFlow.removeChildAt( 0 );
			}
		}
		
		/**
		 * @private
		 * 
		 * Updates held TableData instance with new value based on supplied FlowElement list. 
		 * @param elements Array An array of FlowElements.
		 */
		protected function updateData( elements:Array /* FlowElement[] */ ):void
		{
			var node:XML = ( _data is TableHeading ) ? <th /> : <td />;
			var fragment:XML = XML( TableDataElementConverter.createFragmentFromElements( node, elements ) );
			FragmentAttributeUtil.assignAttributes( fragment, _data.attributes );
			_data.data = fragment;
		}
		
		/**
		 * @private
		 * 
		 * Pasting in content with line breaks kills a table. As such a keyword as been added in replacement of a line break when a paste operation
		 * is encountered for a cell. This method goes through elements and detects if that break key is available and cerates appropriate 
		 * paragraph and span elements to accomidate. 
		 * @param elements Array Original llist of elements.
		 * @return Array The new list of elements based on possible line breaks.
		 */
		protected function resolvePossibleBreaks( elements:Array ):Array
		{
			var parsedElements:Array = [];
			var hasParsedBreaks:Boolean;
			var para:FlowGroupElement;
			var span:SpanElement;
			var i:int;
			var j:int;
			for( i = 0; i < elements.length; i++ )
			{
				hasParsedBreaks = false;
				para = elements[i] as FlowGroupElement;
				for( j = 0; j < para.mxmlChildren.length; j++ )
				{
					span = para.mxmlChildren[j] as SpanElement;
					if( span )
					{
						var spans:Array = span.text.split( _lineBreakIdentifier );
						if( spans.length > 1 )
						{
							for( var k:int = 0; k < spans.length; k++ )
							{
								var paraElem:ParagraphElement = new ParagraphElement();
								var spanElem:SpanElement = new SpanElement();
								spanElem.text = spans[k];
								paraElem.addChild( spanElem );
								parsedElements.push( paraElem );
							}
							hasParsedBreaks = true;
						}
					}
				}
				if( !hasParsedBreaks )
					parsedElements.push( para );
			}
			return parsedElements;
		}
											
		
		/**
		 * Composes cell to defined width. 
		 * @param toWidth Number
		 */
		protected function composeCell( toWidth:Number, notify:Boolean = true ):void
		{	
			// TODO: Apply format from Style of Table.
			var config:IConfiguration = getDefaultConfiguration();
			// Create textflow and import data as HTML.
			
			// TODO: For custom html importer.
//			var composedFlow:TextFlow = _htmlConverter.importToFlow( _data.content );
//			determineCellSize( composedFlow.mxmlChildren, toWidth, notify );
			var composedFlow:TextFlow = TextConverter.importToFlow( _data.content, TextConverter.TEXT_LAYOUT_FORMAT );
			var div:DivElement = composedFlow.getElementByID( TableData.CONTENT_PARENT_ID ) as DivElement;
//			// Update cell size container bounds based on composed children.
			determineCellSize( div.mxmlChildren, toWidth, notify );
		}
		
		/**
		 *@private 
		 * 
		 * Determines cell display size using non-display factory.
		 * @param elements Array An array of FlowElements.
		 */
		protected function determineCellSize( elements:Array /* FlowElement[] */, fixedWidth:Number, notify:Boolean = true ):void
		{
			removeEventListener( Event.ENTER_FRAME, handleDelayedNotification, false );
			
			// Update held data.
			var original:Array = elements.slice(0);
			// Resolve any line breaks.
			if( _lineBreakIdentifier != TableCellContainer.INTERNAL_LINE_BREAK_IDENTIFIER )
			{
				elements = resolvePossibleBreaks( elements );	
			}
			// Update table data element.
			updateData( elements );
			
			var unifiedPadding:Number = getUnifiedPadding();
			// If we are rerendering based on setting explicit values.
			// 	forget about tryint to update dfault min values.
			_minimumWidth = 0;
			_minimumHeight = 0;
			
			var tempWidth:Number = _actualWidth + unifiedPadding;
			var tempHeight:Number = _actualHeight + unifiedPadding;
			var tempNumLines:int = _numLines;
			_numLines = 0;
			
			// Create TextFlow to be passed to factory.
			var config:IConfiguration = ( _textFlow != null ) ? _textFlow.configuration : getDefaultConfiguration();
			
			cleanElementList();
			cleanTextFlow();
			var element:FlowElement;
			// Loop through elements and pop from Array and place on TextFlow instance.
			while( elements.length > 0 )
			{
				element = elements.shift() as FlowElement;
				element.format = ( element.format ) ? TextLayoutFormatUtils.mergeFormats( config.textFlowInitialFormat, element.format ) : config.textFlowInitialFormat;
//				StyleAttributeUtil.applyUserStyles( element );
				element.uid = _uid;
				// Add to held list of elements.
				_elementList.push( element );
				// Push to stack of TextFlow
				_textFlow.addChild( element );
			}
			
			// Run textFlow through factry to determine the actual size of the cell container.
			var factory:TextFlowTextLineFactory = new TextFlowTextLineFactory();
			factory.compositionBounds = new Rectangle( 0, 0, fixedWidth, 1000000 );
			factory.createTextLines( updateActualBounds, _textFlow );
			
			// Redfine height on updated values.
			var predefinedHeight:Number = getDefinedHeight();
			if( predefinedHeight != 0 )
			{
				explicitHeight = Math.max( predefinedHeight, _actualHeight + unifiedPadding );
				_height = explicitHeight;
			}
			else
			{
				_height = _actualHeight + unifiedPadding;
			}
			
			// Reposition inner cell.
			positionTarget();
			// Notify listening clients.
			_previousHeight = tempHeight;
			_proposedHeight = _actualHeight + getUnifiedPadding();
			// If we want to notify and the elements weren;t reassmebled due to line breaks, notify.
			if( notify && original.length == _elementList.length )
			{
				notifyOfChange();
			}
			// Else elements were reassembled due to line breaks. Wait a frame.
			else if( notify && original.length != _elementList.length )
			{
				addEventListener( Event.ENTER_FRAME, handleDelayedNotification, false, 0, true );
			}
		}
		
		/**
		 * @private 
		 * 
		 * Notifies any listening clients to a change in size.
		 */
		protected function notifyOfChange():void
		{
			dispatchEvent( new TableCellContainerEvent( TableCellContainerEvent.CELL_RESIZE, _proposedHeight, _proposedHeight - _previousHeight ) );
		}
		
		/**
		 * @private 
		 * 
		 * Positions the target display based on attributes and dimensions.
		 */
		protected function positionTarget():void
		{
			// basing to wildcard in order to use Proxy.
			var attributes:* = _data.attributes;
			var padding:Number = getPadding();
			
			switch( attributes.valign )
			{
				case TableDataAttribute.MIDDLE:
					targetDisplay.y = ( _height - _actualHeight ) * 0.5;
					break;
				case TableDataAttribute.BOTTOM:
					targetDisplay.y = _height - _actualHeight - padding;
					break;
				case TableDataAttribute.TOP:
				default:
					targetDisplay.y = padding;
					break;
			}
			// Default.
			targetDisplay.y += _descent - 1;// - getPadding();
			targetDisplay.x = getPadding();// ( _width - _actualWidth ) * 0.5;
			
//			border.graphics.clear();
//			border.graphics.lineStyle( 1 );
//			border.graphics.drawRect( targetDisplay.x, targetDisplay.y, _actualWidth, _actualHeight );
		}
		
		/**
		 * @private
		 * 
		 * Call back for line creation to determine the estimated cell bounds. 
		 * @param line DisplayObject
		 */
		protected function updateActualBounds( line:TextLine ):void
		{
			var ascent:Number = line.ascent;
			var descent:Number = line.descent;
			var bounds:Rectangle = line.getBounds( this );
			_actualWidth = Math.max( getTargetWidth() - getUnifiedPadding(), Math.max( _actualWidth, bounds.width ) );
			var pt:Point = localToGlobal( new Point( bounds.left, bounds.top ) );
			_actualHeight = pt.y + bounds.height + descent;//( descent * 2 );// ( ascent + descent );
			
			_ascent = ascent;
			_descent = descent;
			
			// Set the minimum values.
			_minimumWidth = Math.max( _minimumWidth, bounds.width );
			_minimumHeight = _actualHeight;
			
			_numLines++;
		}
		
		/**
		 * @private 
		 * 
		 * Returns padding within cell.
		 */
		protected function getPadding():Number
		{
			var attributes:* = _tableAttributes;
			return attributes.cellpadding;
		}
		
		/**
		 * @private
		 * 
		 * Returns double padding to represent area of padding uniformly on cell. 
		 * @return Number
		 */
		protected function getUnifiedPadding():Number
		{
			var attributes:* = _tableAttributes;
			return attributes.cellpadding * 2;
		}
		
		/**
		 * @private
		 * 
		 * Event handler for click on background display. 
		 * @param evt MouseEvent
		 */
		protected function handleClick( evt:MouseEvent ):void
		{
			dispatchEvent( new TableCellFocusEvent( controller ) );
		}
		
		/**
		 * @private
		 * 
		 * Handler for notification timer to notify clients of resize. 
		 * @param evt TimerEvent
		 */
		protected function handleDelayedNotification( evt:Event ):void
		{
			removeEventListener( Event.ENTER_FRAME, handleDelayedNotification, false );
			notifyOfChange();
		}
		
		/**
		 * @private
		 * 
		 * Returns the target width of the cell based on supplied width value for the data. 
		 * @param orDefault Number Optional default valu to pass back if width property on data is not set.
		 * @return Number
		 */
		protected function getTargetWidth( orDefault:Number = -1 ):Number
		{
			// If width roperty of cell data is not set.
			if( _data.attributes[TableDataAttribute.WIDTH] == TableDataAttribute.DEFAULT_DIMENSION )
				return ( orDefault == -1 ) ? _width : orDefault;
			
			return getDefinedWidth();
		}
		
		/**
		 * @private
		 * 
		 * Returns the traget height of the cell based on supplied height value for the data. 
		 * @param orDefault Number optionsl default value for pass back if height property on data is not set.
		 * @return Number
		 */
		protected function getTargetHeight( orDefault:Number = -1 ):Number
		{
			if( _data.attributes[TableDataAttribute.HEIGHT] == TableDataAttribute.DEFAULT_DIMENSION )
				return ( orDefault == -1 ) ? _height : orDefault;
			
			return getDefinedHeight();	
		}
		
		/**
		 * Processes the supplied data into content elements used for display of cell.
		 */
		public function process( notify:Boolean = true ):void
		{
			_actualHeight = 0;
			
			// Compose cell based on determined width.
			composeCell( getTargetWidth() - getUnifiedPadding(), notify );
		}
		
		/**
		 * Process the supplied data based on display mentions prior to creation.
		 */
		public function preprocess():void
		{
			var unifiedPadding:Number = getUnifiedPadding();
			// Request to compose cell in order to gain measured and actual size prior to processing.
			composeCell( ( _width == 0 ) ? getTargetWidth( 1000000 ) : _width );
			_width = _actualWidth + unifiedPadding;
		}
		
		/**
		 * Updates the rendered content display based on a deepcopy of the supplied paragraph element. 
		 * @param elements Array An Array of FlowElements
		 */
		public function update( elements:Array /* FlowElement */ ):void
		{
			// Update content size using factory.
			determineCellSize( elements, getTargetWidth() - getUnifiedPadding() );
		}
		
		/**
		 * Appends elements to the list and runs a refresh operation. 
		 * @param elements Array An Array of FlowElements
		 */
		public function appendAndUpdate( elements:Array /* FlowElement */ ):void
		{
			_elementList = _elementList.concat( elements );
//			update( _elementList );
		}
		
		/**
		 * Creates and returns a default configuration for a cell container. 
		 * @return IConfiguration
		 */
		public function getDefaultConfiguration():IConfiguration
		{
			var format:TextLayoutFormat = new TextLayoutFormat();
			// TODO: Pull font treatments form outside source.
			format.fontFamily = "Arial";
			format.fontSize = 12;
			format.whiteSpaceCollapse = "preserve";
			_data.attributes.applyAttributesToFormat( format );
			
			var config:Configuration = new Configuration();
			config.textFlowInitialFormat = format;
			return config;
		}
		
		/**
		 * Returns the target dsiplay to be added to the display list that represents a cell. 
		 * @return Sprite
		 */
		public function getDisplay():Sprite
		{
			return targetDisplay;
		}
		
		/**
		 * Sets a reference to the master display on which the cell display is added to when referencing a container controller. 
		 * @param display DisplayObjectContainer
		 */
		public function setMasterDisplay( display:DisplayObjectContainer ):void
		{
			targetDisplay.master = display;
		}
		/**
		 * Retruns a referecne to the master display on which the cell display resides. 
		 * @return DisplayObjectContainer
		 */
		public function getMasterDisplay():DisplayObjectContainer
		{
			return ( targetDisplay.master ) ? targetDisplay.master : targetDisplay.parent;
		}
		
		/**
		 * Returns the initial TextFlow instance that was used to create content. 
		 * @return TextFlow
		 */
		public function getFlow():TextFlow
		{
			return _textFlow;
		}
		
		/**
		 * Retruns derived list of elements associated with TableData. 
		 * @return Array Array of FlowElement
		 */
		public function getContent():Array /* FlowElement[] */
		{
			return _elementList;//_textFlow.mxmlChildren;
		}
		
		/**
		 * Returns the unique id of the container.
		 * @return String
		 */
		public function getUID():String
		{
			return _uid;
		}
		
		/**
		 * Returns the target model for this cell. 
		 * @return TableData
		 */
		public function getData():TableData
		{
			return _data;
		}
		
		/**
		 * @private
		 * 
		 * Returns the sepcified widht property held on the data attribute. 
		 * @return Number
		 */
		protected function getDefinedWidth():Number
		{
			var attWidth:* = _data.attributes[TableDataAttribute.WIDTH];
			return isNaN( Number(attWidth) ) ? 0 : Number(attWidth);
		}
		
		/**
		 * @private
		 * 
		 * Returns the specified height property held on the data attribute. 
		 * @return Number
		 */
		protected function getDefinedHeight():Number
		{
			var attHeight:* = _data.attributes[TableDataAttribute.HEIGHT];
			return isNaN( Number(attHeight) ) ? 0 : Number(attHeight);
		}
		
		/**
		 * Accessor/Modifier to get the width bounds of the cell representation.
		 * ActualWidth corresponds to the cell width, not the overall width of the display.
		 * @return Number
		 */
		public function get actualWidth():Number
		{
			return Math.ceil( _actualWidth );
		}
		public function set actualWidth( value:Number ):void
		{
			_actualWidth = value;
		}
		
		/**
		 * Accessor/Modifier to get the height bounds of the cell representation.
		 * ActualWidth corresponds to the cell height, not the overall height of the display.
		 * @return Number
		 */
		public function get actualHeight():Number
		{
			return Math.ceil( _actualHeight );
		}
		public function set actualHeight( value:Number ):void
		{
			_actualHeight = value;
		}
		
		/**
		 * Accessor/Modifier to get the width bounds of the overall display for the cell.
		 * MeasuredWidth corresponds to the overall width that the cell container uses.
		 * @return Number
		 */
		public function get measuredWidth():Number
		{
			return Math.ceil( _width );
		}
		public function set measuredWidth( value:Number ):void
		{
			if( _width == value ) return;
			
			_width = value;
			invalidateSize();
		}
		
		/**
		 * Accessor/Modifier to get the height bounds of the overall display for the cell.
		 * MeasuredHeight corresponds to the overall height that the cell container uses.
		 * @return Number
		 */
		public function get measuredHeight():Number
		{
			return Math.ceil( _height );
		}
		public function set measuredHeight( value:Number ):void
		{
			if( _height == value ) return;
			
			_height = value;
			invalidateSize();
		}
		
		/**
		 * Accessor/Modifier for the explicitly set width size on the cell attribute. 
		 * ExplicitWidth relates to any value set on the widht property of the attribute of the data related to this cell.
		 * @return Number
		 */
		public function get explicitWidth():Number
		{
			var predefinedWidth:Number = getDefinedWidth();
			return predefinedWidth == 0 ? Math.round( _actualWidth + getUnifiedPadding() ) : predefinedWidth;
		}
		public function set explicitWidth( value:Number ):void
		{
			_data.attributes[TableDataAttribute.WIDTH] = Math.round( value );
			measuredWidth = Math.ceil( value );
			process( false );
		}
		
		/**
		 * Accessor/Modifier for the explicitly set height size on the cell attirbute.
		 * ExplicitHeight relates to any value set on the height property of the attribute of the data related to this cell.
		 * @return Number
		 */
		public function get explicitHeight():Number
		{
			var predefinedHeight:Number = getDefinedHeight();
			return predefinedHeight == 0 ? Math.round( _actualHeight + getUnifiedPadding() ) : predefinedHeight;
		}
		public function set explicitHeight( value:Number ):void
		{
			if( _data.attributes[TableAttribute.HEIGHT] == Math.round( value ) ) return;
			
			_data.attributes[TableDataAttribute.HEIGHT] = Math.round( value );
			measuredHeight = Math.ceil( value );
			process( false );
		}
		
		/**
		 * Accessor/Modifier to the direct controller managing this cell. Assign from composition of flow. 
		 * @return ContainerController
		 */
		public function get controller():ContainerController
		{
			return _controller;
		}
		public function set controller( value:ContainerController ):void
		{
			_controller = value;
		}
		
		/**
		 * Accessor/Modifier of the correponsing row index that this cell resides in. 
		 * @return int
		 */
		public function get rowIndex():int
		{
			return _rowIndex;
		}
		public function set rowIndex( value:int ):void
		{
			_rowIndex = value;
		}
		
		/**
		 * Accessor/Modifier of the corresponding column index that this cell resides in. 
		 * @return 
		 * 
		 */
		public function get columnIndex():int
		{
			return _columnIndex;
		}
		public function set columnIndex( value:int ):void
		{
			_columnIndex = value;
		}
		
		/**
		 * Returns the span length between rows. 
		 * @return int
		 */
		public function get maxRowIndex():int
		{
			return _rowIndex + _rowLength;
		}
		/**
		 * Returns the span length between columns. 
		 * @return int
		 */
		public function get maxColumnIndex():int
		{
			return _columnIndex + _columnLength;
		}
		
		/**
		 * Returns the minimum width of the cell determined from content. 
		 * @return Number
		 */
		public function get minimumWidth():Number
		{
			return Math.ceil( _minimumWidth + getUnifiedPadding() );
		}
		
		/**
		 * Returns the minimum height of the cell determined from content. 
		 * @return Number
		 */
		public function get minimumHeight():Number
		{
			return Math.ceil( _minimumHeight + getUnifiedPadding() );
		}
		
		/**
		 * Sets the identifier for a line break to be used to recompose elements with possible line breaks upon a paste operation. 
		 * @param value String
		 */
		public function set lineBreakIdentifier( value:String ):void
		{
			_lineBreakIdentifier = value;
		}
	}
}