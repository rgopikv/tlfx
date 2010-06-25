package flashx.textLayout.container.table
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.engine.TextLine;
	
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.container.ISizableContainer;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.elements.Configuration;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowValueHolder;
	import flashx.textLayout.elements.IConfiguration;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.table.TableDataElement;
	import flashx.textLayout.events.table.TableCellContainerEvent;
	import flashx.textLayout.events.table.TableCellFocusEvent;
	import flashx.textLayout.factory.TextFlowTextLineFactory;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.model.attribute.TableDataAttribute;
	import flashx.textLayout.model.style.IBorderStyle;
	import flashx.textLayout.model.style.ITableStyle;
	import flashx.textLayout.model.table.ITableDataDecorationContext;
	import flashx.textLayout.model.table.ITableDecorationContext;
	import flashx.textLayout.model.table.TableBorderLeg;
	import flashx.textLayout.model.table.TableCellBorderRenderer;
	import flashx.textLayout.utils.ColorValueUtil;
	import flashx.textLayout.utils.TextLayoutFormatUtils;
	
	[Event(name="cellResize", type="com.constantcontact.texteditor.event.TableCellContainerEvent")]
	[Event(name="requestFocus", type="com.constantcontact.texteditor.event.TableCellFocusEvent")]
	/**
	 * TableCellContainer is an ICellContainer implemnetation that represents a single cell within a Table display. 
	 * @author toddanderson
	 */
	public class TableCellContainer extends Sprite implements ICellContainer, ISizableContainer
	{	
		protected var background:Sprite;
		protected var selectionBackground:Sprite;
		protected var border:Shape;
//		protected var actualBorder:Shape;
		protected var _tableBorderRenderer:TableCellBorderRenderer;
		
		protected var targetDisplay:TableCellDisplay;
		protected var _defaultConfiguration:Configuration;
		protected var _controller:ContainerController;
		
		protected var _width:Number = Number.NaN;
		protected var _height:Number = Number.NaN;
		
		protected var _actualWidth:Number = 0;
		protected var _actualHeight:Number = 0;
		
		protected var _minimumWidth:Number = 0;
		protected var _maximumWidth:Number = 1000000;
		protected var _minimumHeight:Number = 0;
		
		protected var _proposedMeasuredWidth:Number = Number.NaN;
		protected var _proposedMeasuredHeight:Number = Number.NaN;
		
		protected var _rowIndex:int;
		protected var _rowLength:int;
		protected var _columnIndex:int;
		protected var _columnLength:int;
		
		protected var _ascent:Number = 0;
		protected var _descent:Number = 0;
		
		protected var _data:TableDataElement;
		protected var _tableDataContext:ITableDataDecorationContext;
		protected var _htmlConverter:IHTMLImporter;
		protected var _tableContext:ITableDecorationContext;
		protected var _textFlow:TextFlow;
		
		protected var _lineBreakIdentifier:String = TableCellContainer.INTERNAL_LINE_BREAK_IDENTIFIER;
		protected var _selected:Boolean;
		
		protected var _numLines:int;
		protected var _proposedHeight:Number;
		protected var _previousHeight:Number;
		
		protected var _pendingRecompose:Boolean;
		protected var _pendingRecomposeWidth:Number;
		
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
		public function TableCellContainer( data:TableDataElement, tableContext:ITableDecorationContext, defaultConfiguration:Configuration, htmlImporter:IHTMLImporter )
		{
			_data = data;
			_tableContext = tableContext;
			_tableDataContext = _data.getDecorationContext();
			_defaultConfiguration = defaultConfiguration;
			_htmlConverter = htmlImporter;
			
			// Create text flow.
			_textFlow = new TextFlow( getDefaultConfiguration() );
			_textFlow.color = 0xFF0000;
			
			// Precompute index lengths.
			_rowLength = Math.max( ( _tableDataContext.attributes as Object ).rowspan - 1, 0 );
			_columnLength = Math.max( ( _tableDataContext.attributes as Object ).colspan - 1, 0 );
			
			// create background graphic.
			background = new Sprite();
			addChild( background );
			
			// Create selection display.
			selectionBackground = new Sprite();
			addChild( selectionBackground );
			
			// Create display for borders.
			border = new Shape();
			addChild( border );
			
//			actualBorder = new Shape();
//			addChild( actualBorder );
			
			// Create renderer for borders.
			_tableBorderRenderer = new TableCellBorderRenderer( border, _tableDataContext );
			
			// create the target display of the cell.
			targetDisplay = new TableCellDisplay( this );
			addChild( targetDisplay );
			
			// Add handlers
			addHandlers();
			
			// Set default values.
			var widthPadding:Number = _tableDataContext.getComputedWidthOfPaddingAndBorders();
			var heightPadding:Number = _tableDataContext.getComputedHeightOfPaddingAndBorders();
			_width = getDefinedWidth( widthPadding ); 
			_height = getDefinedHeight( heightPadding );
			_actualWidth = Math.max( widthPadding, _width - widthPadding );
			_actualHeight = Math.max( heightPadding, _height - heightPadding );
			
			// Set Unique ID associated with this cell container.
			_uid = TableCellContainer.UID_PREFIX + TableCellContainer.ID;
			TableCellContainer.ID++;
			
			_data.uid = _uid;
		}
		
		/**
		 * @private 
		 * 
		 * Assigns event handlers for interaction on this instance.
		 */
		protected function addHandlers():void
		{
			background.addEventListener( MouseEvent.CLICK, handleClick, false, 0, true );
			selectionBackground.addEventListener( MouseEvent.CLICK, handleClick, false, 0, true );
			border.addEventListener( MouseEvent.CLICK, handleClick, false, 0, true );
		}
		
		/**
		 * @private 
		 * 
		 * Removes event handlers for interaction on this instance.
		 */
		protected function removeHandlers():void
		{
			background.removeEventListener( MouseEvent.CLICK, handleClick, false );
			selectionBackground.removeEventListener( MouseEvent.CLICK, handleClick, false );
			border.removeEventListener( MouseEvent.CLICK, handleClick, false );
		}
		
		/**
		 * @private 
		 * 
		 * Validates the measured size of the container.
		 */
		protected function invalidateSize( w:Number, h:Number ):void
		{	
			decorate( w, h );
			positionTarget();
			
			// Update model based dimension references.
			_data.getTableDataModel().width = getDefinedWidth( w );
			_data.getTableDataModel().height = getDefinedHeight( h );
		}
		
		/**
		 * @private 
		 * 
		 * Validates the state of selection.
		 */
		protected function invalidateSelection():void
		{
			var w:Number = _data.getTableDataModel().width;
			var h:Number = _data.getTableDataModel().height;
			selectionBackground.graphics.clear();
			selectionBackground.graphics.beginFill( ( _selected ) ? 0xccccff : 0xFFFFFF, ( selected ) ? 1 : 0 );
			selectionBackground.graphics.drawRect( 0, 0, w, h );
			selectionBackground.graphics.endFill();
			
			// If we have multi-select than update selection to encompass the whole range of the cell.
			if( _selected )
			{
				var start:int = getAbsoluteStart();
				var end:int = getAbsoluteEnd();
				var selectionState:SelectionState = controller.textFlow.interactionManager.getSelectionState();
				var active:int = selectionState.activePosition;
				var anchor:int = selectionState.anchorPosition;
				if( anchor > active )
				{
					selectionState.anchorPosition = Math.max( anchor, end );
					selectionState.activePosition = Math.min( active, start );
				}
				else
				{
					selectionState.anchorPosition = Math.min( anchor, start );
					selectionState.activePosition = Math.max( active, end );
				}
				controller.textFlow.interactionManager.setSelectionState( selectionState );	
			}
		}
		
		/**
		 * @private
		 * 
		 * Returns the absolute start of content. 
		 * @return int
		 */
		protected function getAbsoluteStart():int
		{
			return _data.getAbsoluteStart();
		}
		
		/**
		 * @private
		 * 
		 * Returns the absolute end of content. 
		 * @return int
		 */
		protected function getAbsoluteEnd():int
		{
			return getAbsoluteStart() + _data.textLength - 1;
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
			// Create textflow and import data as HTML.
			if( _data.mxmlChildren ) determineCellSize( _data.mxmlChildren, toWidth, notify );
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
			
			var heightPadding:Number = _tableDataContext.getComputedHeightOfPaddingAndBorders();
			var tempHeight:Number = _actualHeight;
			var tempNumLines:int = _numLines;
			
			// If we are rerendering based on setting explicit values.
			// 	forget about tryint to update dfault min values.
			_minimumWidth = 0;
			_minimumHeight = 0;
			
			_actualWidth = 0; 
			_actualHeight = 0;
			
			_numLines = 0;
			
			cleanTextFlow();
			var element:FlowElement;
			var elementList:Array = []; // CellElement[]
			var previousFormat:ITextLayoutFormat;
			var computedFormat:ITextLayoutFormat;
			// Loop through elements and pop from Array and place on TextFlow instance.
			while( elements.length > 0 )
			{
				element = ( elements.shift() as FlowElement );
				previousFormat = new FlowValueHolder( ( element.format as FlowValueHolder ) );
				computedFormat = _data.computedFormat;
				element.format = ( element.format ) ? TextLayoutFormatUtils.mergeFormats( computedFormat, element.format ) : computedFormat;
				element.uid = _uid;
				// Add to held list of elements.
				elementList.push( CellElementPool.getCellElement( element, previousFormat ) );
				// Push to stack of TextFlow
				_textFlow.addChild( element );
			}
			
			// Run textFlow through factry to determine the actual size of the cell container.
			var factory:TextFlowTextLineFactory = new TextFlowTextLineFactory();
			factory.compositionBounds = new Rectangle( 0, 0, fixedWidth, 1000000 );
			factory.createTextLines( updateActualBounds, _textFlow );
			
			var elementLength:int = elementList.length;
			var cellElement:CellElement;
			// Add back to element.
			while( elementList.length > 0 )
			{
				cellElement = elementList.shift() as CellElement;
				_data.addChild( cellElement.element );
				CellElementPool.returnCellElement( cellElement );
			}
			
			// If we ran through construction and an image was found at a size larger than the detemrined fixed width, we need to run it again and make sure it fits.
			if( _pendingRecompose )
			{
				_width = _pendingRecomposeWidth + _tableDataContext.getComputedWidthOfPaddingAndBorders();
				_pendingRecompose = false;
				_pendingRecomposeWidth = -1;
				update();
				return;
			}
			
			// Update measured properties.
			updateMeasuredBounds();
			
			// Notify listening clients.
			_previousHeight = tempHeight;
			_proposedHeight = _actualHeight;
			if( _previousHeight != _proposedHeight )
			{
				// Update visual display.
				invalidateSize( ( isNaN( _proposedMeasuredWidth ) ) ? _width : _proposedMeasuredWidth, _height );	
			}
			// If we want to notify and the elements weren;t reassmebled due to line breaks, notify.
			if( notify && original.length == elementLength )
			{
				notifyOfChange();
			}
				// Else elements were reassembled due to line breaks. Wait a frame.
			else if( notify && original.length != elementLength )
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
		 * Draws a border on the display. 
		 * @param border TableBorderLeg
		 */
		protected function drawLeg( leg:TableBorderLeg, w:Number, h:Number ):void
		{
			_tableBorderRenderer.drawBorder( leg, w, h );
		}
		
		protected function decorate( w:Number, h:Number ):void
		{
			// Render background.
			var style:ITableStyle = _tableDataContext.style;
			var backgroundColor:Number = style.getComputedStyle().backgroundColor;
			background.graphics.clear();
			background.graphics.beginFill( ( !isNaN(backgroundColor) ) ? backgroundColor : 0xFF0000, ( !isNaN(backgroundColor) ) ? 1 : 0 );
			background.graphics.drawRect( 0, 0, w, h );
			background.graphics.endFill();
			
			// Render borders.
			border.graphics.clear();
			var cellStyle:ITableStyle = _tableDataContext.style.getComputedStyle();
			var legs:Vector.<TableBorderLeg> = new Vector.<TableBorderLeg>();
			var i:int;
			var thickness:Number;
			var color:uint;
			var borderStyle:String;
			var borderWidth:Array = _tableDataContext.determineBorderWidth();
			var cellBorderStyle:IBorderStyle = cellStyle.getBorderStyle();
			// Determine the border legs to be drawn.
			for( i = 0; i < borderWidth.length; i++ )
			{
				thickness = borderWidth[i];
				color = cellBorderStyle.borderColor[i];
				borderStyle = cellBorderStyle.computeBorderStyleBasedOnWidth( thickness, cellBorderStyle.borderStyle[i] );
				legs.push( new TableBorderLeg( i, thickness, color, borderStyle ) );
			}
			// Draw the legs to the display based on availability.
			var leg:TableBorderLeg;
			while( legs.length > 0 )
			{
				drawLeg( legs.shift(), w, h );
			}
		}
		
		/**
		 * @private 
		 * 
		 * Positions the target display based on attributes and dimensions.
		 */
		protected function positionTarget():void
		{
			// basing to wildcard in order to use Proxy.
			var attributes:* = _data.getComputedAttributes();
			var h:Number = ( isNaN( _proposedMeasuredHeight ) ) ? _height : _proposedMeasuredHeight;
			switch( attributes.valign )
			{
				case TableDataAttribute.MIDDLE:
					targetDisplay.y = ( h - _actualHeight ) * 0.5;
					break;
				case TableDataAttribute.BOTTOM:
					targetDisplay.y = h - _actualHeight - _tableDataContext.getBottomPadding();
					break;
				case TableDataAttribute.TOP:
				default:
					targetDisplay.y = _tableDataContext.getTopPadding();
					break;
			}
			
			// Alignment is handled by formatting in line factory and the access of composition width which determines the container controller bounds. 
			// THIS SWITCH HAS BEEN DEPRECATED. KEPT IN LINE AND COMMENTED FOR PRESERVATION.
//			switch( attributes.align )
//			{
//				case TableDataAttribute.CENTER:
//					targetDisplay.x = ( _width - _actualWidth ) / 2;
//					break;
//				case TableDataAttribute.RIGHT:
//					targetDisplay.x = _width - _actualWidth - _tableDataContext.getRightPadding();
//					break;
//				case TableDataAttribute.LEFT:
//				default:
//					targetDisplay.x = _tableDataContext.getLeftPadding();
//					break;
//			}
			// Default.
			targetDisplay.y += _descent - 1;
			// Just align along x axis based on left padding.
			targetDisplay.x = _tableDataContext.getLeftPadding();
			
//			actualBorder.graphics.clear();
//			actualBorder.graphics.lineStyle( 1, 0 );
//			actualBorder.graphics.drawRect( targetDisplay.x, targetDisplay.y, compositionWidth, _actualHeight );
		}
		
		/**
		 * @private 
		 * 
		 * Updates the dimensions based on new values determined from factory completion.
		 */
		protected function updateMeasuredBounds():void
		{
			var widthPadding:Number = _tableDataContext.getComputedWidthOfPaddingAndBorders();
			var heightPadding:Number = _tableDataContext.getComputedHeightOfPaddingAndBorders();
			// Redfine height on updated values.
			// Since we can grow in height, we run a max on explicit defined height and actual height.
			_height = Math.max( getDefinedHeight( _actualHeight + heightPadding ), _actualHeight + heightPadding );
			// Redefin width on updated values.
			_width = getDefinedWidth( _actualWidth + widthPadding );
		}
		
		/**
		 * @private
		 * 
		 * Call back for line creation to determine the estimated cell bounds. 
		 * @param line DisplayObject
		 */
		protected function updateActualBounds( line:DisplayObject ):void
		{
			// object could be background shape or line.
			var ascent:Number = ( line is TextLine ) ? ( line as TextLine ).ascent : 0;
			var descent:Number = ( line is TextLine ) ? ( line as TextLine ).descent : 0;
			var bounds:Rectangle = line.getBounds( this );
			_actualWidth = Math.max( _actualWidth, bounds.width );
			var pt:Point = localToGlobal( new Point( bounds.left, bounds.top ) );
			_actualHeight = pt.y + bounds.height + descent;//( descent * 2 );// ( ascent + descent );
			
			_ascent = ascent;
			_descent = descent;
			
			// Set the minimum values.
			_minimumWidth = Math.max( _minimumWidth, bounds.width );
			_minimumHeight = _actualHeight;
			
			_numLines++;
			
			// If we have encountered an image and its width is greater than we alloted for composition, we need to track it and recompose later.
			if( ( line is TextLine ) )
			{
				if( ( line as TextLine ).hasGraphicElement )
				{
					if( bounds.width > getDeterminedFixedWidth() )
					{
						_pendingRecompose = true;
						_pendingRecomposeWidth = bounds.width;
					}
				}
			}
		}
		
		/**
		 * @private
		 * 
		 * Event handler for click on background display. 
		 * @param evt MouseEvent
		 */
		protected function handleClick( evt:MouseEvent ):void
		{
			var target:InteractiveObject = ( evt.target as InteractiveObject );
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
		
		protected function getDefinedWidth( orDefault:Number = Number.NaN ):Number
		{
			var definedWidth:Number = _tableDataContext.getDefinedWidth();
			definedWidth = ( isNaN( definedWidth ) ) ? orDefault : definedWidth;
			definedWidth = ( isNaN( definedWidth ) ) ? _width : definedWidth;
			return Math.ceil( definedWidth );
		}
		
		protected function getDefinedHeight( orDefault:Number = Number.NaN ):Number
		{
			var definedHeight:Number = _tableDataContext.getDefinedHeight();
			definedHeight = ( isNaN( definedHeight ) ) ? orDefault : definedHeight;
			definedHeight = ( isNaN( definedHeight ) ) ? _height : definedHeight;
			return Math.ceil( definedHeight );
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
			var allotedWidth:Number = _tableDataContext.getAllotedWidth( this );
			return ( isNaN(allotedWidth) ) ? orDefault : allotedWidth;
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
			var allotedHeight:Number = _tableDataContext.getAllotedHeight( this );
			return ( isNaN(allotedHeight) ) ? orDefault : allotedHeight;
		}
		
		/**
		 * @private
		 * 
		 * Returns the determined fixed width to start composition. 
		 * @return Number
		 */
		protected function getDeterminedFixedWidth():Number
		{
			var widthPadding:Number = _tableDataContext.getComputedWidthOfPaddingAndBorders();
			return Math.max( getDefinedWidth( _width ), getTargetWidth( _width ) ) - widthPadding;
		}
		
		/**
		 * Processes the supplied data into content elements used for display of cell.
		 */
		public function process( notify:Boolean = true ):void
		{
			// Compose cell based on determined width.
			var fixed:Number = getDeterminedFixedWidth();
			composeCell( fixed, notify );
		}
		
		/**
		 * Process the supplied data based on display mentions prior to creation.
		 */
		public function preprocess():void
		{
			// Request to compose cell in order to gain measured and actual size prior to processing.
			var widthPadding:Number = _tableDataContext.getComputedWidthOfPadding();
			composeCell( getTargetWidth( 1000000 ) - widthPadding );
		}
		
		/**
		 * Updates held TableData instance with new value based on supplied FlowElement list. 
		 * @param elements Array An array of FlowElements.
		 */
		public function update():void
		{
			var fixed:Number = getDeterminedFixedWidth();
			composeCell( fixed );
		}
		
		/**
		 * Measure forces an update to composition and invalidates the measured width of the cell. 
		 * @param w Number
		 */
		public function measureOnWidth( w:Number ):void
		{
			if( w == _proposedMeasuredWidth ) return;
			
			var widthPadding:Number = _tableDataContext.getComputedWidthOfPaddingAndBorders();
			var fixed:Number = Math.max( getDefinedWidth( w ), getTargetWidth( w ) ) - widthPadding;
			composeCell( fixed, false );
			
			_proposedMeasuredWidth = w;
			invalidateSize( w, _height );
		}
		
		public function measureOnHeight( h:Number ):void
		{	
			_proposedMeasuredHeight = h;
			invalidateSize( ( isNaN(_proposedMeasuredWidth) ) ? _width : _proposedMeasuredWidth, _proposedMeasuredHeight );
		}
		
		/**
		 * Creates and returns a default configuration for a cell container. 
		 * @return IConfiguration
		 */
		public function getDefaultConfiguration():IConfiguration
		{
			return _defaultConfiguration;
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
		public function getData():TableDataElement
		{
			return _data;
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
		
		/**
		 * Accessor/Modifier to get the height bounds of the overall display for the cell.
		 * MeasuredHeight corresponds to the overall height that the cell container uses.
		 * @return Number
		 */
		public function get measuredHeight():Number
		{
			return Math.ceil( _height );
		}
		
		/**
		 * Accessor/Modifier for the explicitly set width size on the cell attribute. 
		 * ExplicitWidth relates to any value set on the widht property of the attribute of the data related to this cell.
		 * @return Number
		 */
		public function get explicitWidth():Number
		{
			return getDefinedWidth();
		}
		public function set explicitWidth( value:Number ):void
		{
			_tableDataContext.setDefinedWidth( Math.ceil( value ) );
			process( false );
		}
		
		/**
		 * Accessor/Modifier for the explicitly set height size on the cell attirbute.
		 * ExplicitHeight relates to any value set on the height property of the attribute of the data related to this cell.
		 * @return Number
		 */
		public function get explicitHeight():Number
		{
			return getDefinedHeight();
		}
		public function set explicitHeight( value:Number ):void
		{
			_tableDataContext.setDefinedHeight( Math.ceil( value ) );
			process( false );
		}
		
		public function get compositionWidth():Number
		{
			return getDefinedWidth( _proposedMeasuredWidth ) - _tableDataContext.getComputedWidthOfPaddingAndBorders();
		}
		
		public function get compositionHeight():Number
		{
			return _actualHeight;
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
			var widthPadding:Number = _tableDataContext.getComputedWidthOfPaddingAndBorders();
			return Math.ceil( _minimumWidth + widthPadding );
		}
		
		/**
		 * Returns the minimum height of the cell determined from content. 
		 * @return Number
		 */
		public function get minimumHeight():Number
		{
			var heightPadding:Number = _tableDataContext.getComputedHeightOfPaddingAndBorders();
			return Math.ceil( _minimumHeight + heightPadding );
		}
		
		/**
		 * Accessor/Modifier for maximum allot width for cell based on layout context. 
		 * @return Number
		 */
		public function get maximumWidth():Number
		{
			return _maximumWidth;
		}
		public function set maximumWidth( value:Number ):void
		{
			_maximumWidth = value;
		}
		
		/**
		 * Sets the identifier for a line break to be used to recompose elements with possible line breaks upon a paste operation. 
		 * @param value String
		 */
		public function set lineBreakIdentifier( value:String ):void
		{
			_lineBreakIdentifier = value;
		}
		
		/**
		 * Access/Modifier to denote selection of whole cell. This can hapen when a user selects more than one cell
		 * and is used to determine if a whole cell can be deleted, not just its contents. 
		 * @return Boolean
		 */
		public function get selected():Boolean
		{
			return _selected;
		}
		public function set selected( value:Boolean ):void
		{
			_selected = value;
			invalidateSelection();
		}
	}
}

import flashx.textLayout.elements.FlowElement;
import flashx.textLayout.formats.ITextLayoutFormat;

class CellElement
{
	public var element:FlowElement;
	public var previousFormat:ITextLayoutFormat;
	public function CellElement( element:FlowElement, previousFormat:ITextLayoutFormat )
	{
		this.element = element;
		this.previousFormat = previousFormat;
	}
}

class CellElementPool
{
	private static var _pool:Array = [];
	static public function getCellElement( element:FlowElement, previousFormat:ITextLayoutFormat ):CellElement
	{
		if( _pool.length == 0 )
			_pool.push( new CellElement( element, previousFormat ) );
		
		var cellElement:CellElement = _pool.shift() as CellElement;
		cellElement.element = element;
		cellElement.previousFormat = previousFormat;
		return cellElement;
	}
	
	static public function returnCellElement( cellElement:CellElement ):void
	{
		cellElement.element.format = cellElement.previousFormat;
		_pool.push( cellElement );
	}
}