package flashx.textLayout.container.table
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.container.IEditorContainerManager;
	import flashx.textLayout.converter.IHTMLExporter;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.events.table.TableCellContainerEvent;
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.attribute.TableAttribute;
	import flashx.textLayout.model.attribute.TableDataAttribute;
	import flashx.textLayout.model.table.TableData;
	
	public class TableCellContainer2 extends Sprite implements ICellContainer
	{
		protected var _data:TableData;
		protected var _tableAttributes:IAttribute;
		protected var _htmlImporter:IHTMLImporter;
		protected var _htmlExporter:IHTMLExporter;
		
		protected var _rowIndex:int;
		protected var _rowLength:int;
		protected var _columnIndex:int;
		protected var _columnLength:int;
		
		protected var _background:Sprite;
		protected var _border:Shape;
		protected var _targetDisplay:TableCellDisplay;
		
		protected var _elements:Array;
		protected var _containerManager:IEditorContainerManager;
		
		protected var _width:Number = 0; 				// Width is the visible width of the cell container.
		protected var _height:Number = 0; 				// Height is the visible height of the cell container.
		protected var _actualWidth:Number = 0;			// ActualWidth is the width of the content. Does not include attribute padding.
		protected var _actualHeight:Number = 0;			// ActualHeight is the height of the content. Does not include attribute padding.
		
		protected var _uid:String;
		
		private static var ID:int;
		private static const UID_PREFIX:String = "TableCellContainer";
		
		public function TableCellContainer2( data:TableData, tableAttributes:IAttribute, htmlImporter:IHTMLImporter, htmlExporter:IHTMLExporter )
		{
			_data = data;
			_tableAttributes = tableAttributes;
			_htmlImporter = htmlImporter;
			_htmlExporter = htmlExporter;
			
			// Create display children.
			createChildren();
			
			// Precompute index lengths.
			_rowLength = Math.max( ( _data.attributes as Object ).rowspan - 1, 0 );
			_columnLength = Math.max( ( _data.attributes as Object ).colspan - 1, 0 );
			
			// Set default values.
			_width = getDefinedWidth();
			_height = getDefinedHeight();
			_actualWidth = _width - getUnifiedPadding();
			_actualHeight = _height - getUnifiedPadding();
			
			// Set Unique ID associated with this cell container.
			_uid = TableCellContainer2.UID_PREFIX + TableCellContainer2.ID;
			TableCellContainer2.ID++;
			
			var field:TextField = new TextField();
			field.text = TableCellContainer2.ID.toString();
			_background.addChild( field );
		}
		
		protected function createChildren():void
		{
			// create background graphic.
			_background = new Sprite();
			_background.addEventListener( MouseEvent.CLICK, handleClick, false, 0, true );
			addChild( _background );
			
			_border = new Shape();
			addChild( _border );
			
			// create the target display of the cell.
			_targetDisplay = new TableCellDisplay();
			addChild( _targetDisplay );
		}
		
		protected function invalidateSize():void
		{
			//TODO: Get background color from styles.
			_background.graphics.clear();
			_background.graphics.beginFill( 0xDDDDDD, 1 );
			_background.graphics.drawRect( 0, 0, _width, _height );
			_background.graphics.endFill();
			
			_actualWidth = getTargetWidth() - getUnifiedPadding();
//			positionTarget();
		}
		
		protected function updateMeasurement( w:Number, h:Number ):void
		{
			_actualWidth = w;
			_actualHeight = h;
			// Redfine height on updated values.
			var unifiedPadding:Number = getUnifiedPadding();
			var predefinedWidth:Number = getDefinedWidth();
			var predefinedHeight:Number = getDefinedHeight();
			// Define measure width.
			if( predefinedWidth != 0 )
			{
				explicitWidth = Math.max( predefinedWidth, _actualWidth + unifiedPadding );
				_width = explicitWidth;
			}
			else
			{
				_width = _actualWidth + unifiedPadding;
			}
			// Define measured height.
			if( predefinedHeight != 0 )
			{
				explicitHeight = Math.max( predefinedHeight, _actualHeight + unifiedPadding );
				_height = explicitHeight;
			}
			else
			{
				_height = _actualHeight + unifiedPadding;
			}
//			positionTarget();
		}
		
		protected function positionTarget():void
		{
			// basing to wildcard in order to use Proxy.
			var attributes:* = _data.attributes;
			var padding:Number = getPadding();
			
			switch( attributes.valign )
			{
				case TableDataAttribute.MIDDLE:
					_targetDisplay.y = ( _height - _actualHeight ) * 0.5;
					break;
				case TableDataAttribute.BOTTOM:
					_targetDisplay.y = _height - _actualHeight - padding;
					break;
				case TableDataAttribute.TOP:
				default:
					_targetDisplay.y = padding;
					break;
			}
//			// Default.
//			targetDisplay.y += _descent - 1;// - getPadding();
			_targetDisplay.x = getPadding();// ( _width - _actualWidth ) * 0.5;
			
//			border.graphics.clear();
//			border.graphics.lineStyle( 1 );
//			border.graphics.drawRect( targetDisplay.x, targetDisplay.y, _actualWidth, _actualHeight );
		}
		
		protected function getPadding():Number
		{
			var attributes:* = _tableAttributes;
			return attributes.cellpadding; 
		}
		
		protected function getUnifiedPadding():Number
		{
			var attributes:* = _tableAttributes;
			return attributes.cellpadding * 2;
		}
		
		protected function getDefinedWidth():Number
		{
			var attWidth:* = _data.attributes[TableDataAttribute.WIDTH];
			return isNaN( Number(attWidth) ) ? 0 : Number(attWidth);
		}
		
		protected function getDefinedHeight():Number
		{
			var attHeight:* = _data.attributes[TableDataAttribute.HEIGHT];
			return isNaN( Number(attHeight) ) ? 0 : Number(attHeight);
		}
		
		protected function getTargetWidth( orDefault:Number = -1 ):Number
		{
			// If width roperty of cell data is not set.
			if( _data.attributes[TableDataAttribute.WIDTH] == TableDataAttribute.DEFAULT_DIMENSION )
				return ( orDefault == -1 ) ? _width : orDefault;
			
			return getDefinedWidth();
		}
		
		protected function getTargetHeight( orDefault:Number = -1 ):Number
		{
			if( _data.attributes[TableDataAttribute.HEIGHT] == TableDataAttribute.DEFAULT_DIMENSION )
				return ( orDefault == -1 ) ? _height : orDefault;
			
			return getDefinedHeight();	
		}
		
		protected function handleClick( evt:MouseEvent ):void
		{
			
		}
		
		protected function handleContainerManagerInitialize( evt:Event ):void 
		{
			_containerManager.removeEventListener( "initialize", handleContainerManagerInitialize, false );
			
			updateMeasurement( _containerManager.contentWidth, _containerManager.contentHeight);
			dispatchEvent( new Event( Event.COMPLETE ) );
		}
		
		protected function handleContainerManagerResize( evt:Event ):void
		{
			var event:* = evt;
			updateMeasurement( event.width, event.height );
			
			var unifiedPadding:Number = getUnifiedPadding();
			dispatchEvent( new TableCellContainerEvent( TableCellContainerEvent.CELL_RESIZE, _actualHeight + unifiedPadding, _actualHeight - event.oldHeight ) );
		}
		
		public function precompose( textFlow:TextFlow, containerManager:IEditorContainerManager, flowIndex:int ):void
		{
			var elements:Array = getContent();
			_containerManager = containerManager;
			_containerManager.targetDisplay = _targetDisplay;
			_containerManager.width = _width;
			_containerManager.height = _height;
			_containerManager.addEventListener( "initialize", handleContainerManagerInitialize, false, 0, true );
			_containerManager.addEventListener( "resize", handleContainerManagerResize, false, 0, true );
			_containerManager.composeContainers( textFlow, elements, flowIndex );
		}
		
		public function preprocess():void
		{
		}
		
		public function process(notify:Boolean=true):void
		{
		}
		
		public function update(elements:Array):void
		{
		}
		
		public function appendAndUpdate(elements:Array):void
		{
		}
		
		public function getDisplay():Sprite
		{
			return _targetDisplay;
		}
		
		public function getContent():Array
		{
			if( _elements == null )
			{
				_elements = _htmlImporter.importToFlow( _data.content ).mxmlChildren;
			}
			return _elements;
		}
		
		public function getUID():String
		{
			return _uid;
		}
		
		public function getData():TableData
		{
			return _data;
		}
		
		public function setMasterDisplay(value:DisplayObjectContainer):void
		{
		}
		
		public function getMasterDisplay():DisplayObjectContainer
		{
			return null;
		}
		
		public function get controller():ContainerController
		{
			return null;
		}
		
		public function set controller(value:ContainerController):void
		{
		}
		
		public function get actualWidth():Number
		{
			return Math.ceil( _actualWidth );
		}
		public function set actualWidth( value:Number ):void
		{
			_actualWidth = value;
		}
		
		public function get actualHeight():Number
		{
			return Math.ceil( _actualHeight );
		}
		public function set actualHeight( value:Number ):void
		{
			_actualHeight = value;
		}
		
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
		
		public function get rowIndex():int
		{
			return _rowIndex;
		}
		public function set rowIndex(value:int):void
		{
			_rowIndex = value;
		}
		
		public function get columnIndex():int
		{
			return _columnIndex;
		}
		public function set columnIndex(value:int):void
		{
			_columnIndex = value;
		}
		
		public function get maxRowIndex():int
		{
			return _rowIndex + _rowLength;
		}
		public function get maxColumnIndex():int
		{
			return _columnIndex + _columnLength;
		}
		
		public function get minimumWidth():Number
		{
			return Math.ceil( _actualWidth + getUnifiedPadding() );
		}
		
		public function get minimumHeight():Number
		{
			return Math.ceil( _actualHeight + getUnifiedPadding() );
		}
		
		public function set lineBreakIdentifier(value:String):void
		{
		}
		
		override public function set x( value:Number ):void
		{
			super.x = value;
		}
	}
}