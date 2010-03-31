package flashx.textLayout.container.table
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.IEventDispatcher;
	
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.container.IEditorContainerManager;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.model.table.TableData;

	/**
	 * ICellContainer is an interface representing a cell of a Table. 
	 * @author toddanderson
	 */
	public interface ICellContainer extends IEventDispatcher
	{
		
		function precompose( textFlow:TextFlow, containerManager:IEditorContainerManager, flowIndex:int ):void;
		/**
		 * Runs any preprocesses.
		 */
		function preprocess():void
			
		/**
		 * Process container properties based on supplied data.
		 */
		function process( notify:Boolean = true ):void;
		/**
		 * Updates container properties based on elements.
		 * @param elements Array Array of FlowElement
		 * @param position int
		 */
		function update( elements:Array /* FlowElement[] */ ):void;
		
		/**
		 * Appends elements to the current list of elements and runs an update refresh. 
		 * @param elements Array
		 */
		function appendAndUpdate( elements:Array /* FlowElement[] */ ):void;
		
		/**
		 * Returns target display for the cell. 
		 * @return Sprite
		 */
		function getDisplay():Sprite;
		/**
		 * Returns elemental content of cell model. 
		 * @return Array
		 */
		function getContent():Array;
		/**
		 * Returns unique id for the cell. 
		 * @return String
		 */
		function getUID():String;
		
		/**
		 * Returns the model for the cell. 
		 * @return TableData
		 */
		function getData():TableData;
		
		/**
		 * Reference to the master display on which the display is added. 
		 * @param value DisplayObjectContainer
		 */
		function setMasterDisplay( value:DisplayObjectContainer ):void;
		function getMasterDisplay():DisplayObjectContainer;
		
		/**
		 * Accessor/Mutator of associated ContainerController instance with target display. 
		 * @return ContainerController
		 */
		function get controller():ContainerController;
		function set controller( value:ContainerController ):void;
		
		/**
		 * Accessor/Mutator for actual width of contained cell. Not the display size. 
		 * @return Number
		 */
		function get actualWidth():Number;
		function set actualWidth( value:Number ):void;
		/**
		 * Accessor/Mutator for actual height of contained cell. Not the display size. 
		 * @return Number
		 */
		function get actualHeight():Number;
		function set actualHeight( value:Number ):void;
		
		/**
		 * Accessor/Mutator for actual width of display size for the outerlying cell. 
		 * @return Number
		 */
		function get measuredWidth():Number;
		function set measuredWidth( value:Number ):void;
		/**
		 * Accessor/Mutator for actual height of display size for the outerlying cell. 
		 * @return Number
		 */
		function get measuredHeight():Number;
		function set measuredHeight( value:Number ):void;
		
		/**
		 * Accessor/Modifier for the explicitly set width size on the cell attribute. 
		 * @return Number
		 */
		function get explicitWidth():Number;
		function set explicitWidth( value:Number ):void;
		
		/**
		 * Accessor/Modifie for the explicitly set height size on the cell attirbute. 
		 * @return Number
		 */
		function get explicitHeight():Number;
		function set explicitHeight( value:Number ):void;
		
		/**
		 * Accessor/Modifier for index of row which this cell resides.  
		 * @return int
		 */
		function get rowIndex():int;
		function set rowIndex( value:int ):void;
			
		/**
		 * Accessor/Modifier for index of column which this cell resides. 
		 * @return int
		 */
		function get columnIndex():int;
		function set columnIndex( value:int ):void;
		
		/**
		 * Returns the row span length for this cell. 
		 * @return int
		 */
		function get maxRowIndex():int;
		/**
		 * Returns the column span length for this cell. 
		 * @return int
		 */
		function get maxColumnIndex():int;
		
		/**
		 * Returns the minimum width of the cell based on its content. 
		 * @return Number
		 */
		function get minimumWidth():Number;
		/**
		 * Returns the minimum height of the cell based on its content. 
		 * @return Number
		 */
		function get minimumHeight():Number;
		
		/**
		 * Sets the line break identifier used to recompose elements if line breaks available in a paste operation. 
		 * @param value String
		 */
		function set lineBreakIdentifier( value:String ):void;
		
		/* Standard DisplayObject properties. */
		function get x():Number;
		function set x( value:Number ):void;
		function get y():Number;
		function set y( value:Number ):void;
		function get width():Number;
		function set width( value:Number ):void;
		function get height():Number;
		function set height( value:Number ):void;
	}
}