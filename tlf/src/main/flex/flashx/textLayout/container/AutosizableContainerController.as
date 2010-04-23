package flashx.textLayout.container
{
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.engine.TextLine;
	
	import flashx.textLayout.elements.Configuration;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.IConfiguration;
	import flashx.textLayout.elements.InlineGraphicElement;
	import flashx.textLayout.elements.InlineGraphicElementStatus;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.events.AutosizableContainerEvent;
	import flashx.textLayout.events.StatusChangeEvent;
	import flashx.textLayout.factory.TextFlowTextLineFactory;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.TextLayoutFormatUtils;
	
	use namespace tlf_internal;
	
	/**
	 * AutosizableContainerController is a custom container controller for items that do not contain tables in the flow composer. 
	 * @author toddanderson
	 */
	public class AutosizableContainerController extends ContainerController
	{	
		protected var _uid:String;
		protected var _elements:Vector.<FlowElement>;
		protected var _containerFlow:TextFlow;
		
		protected var _actualHeight:Number = Number.NaN;
		protected var _previousHeight:Number = Number.NaN;
		protected var _background:Sprite;
		protected var _lineHolder:Sprite;
		
		protected var _processedElements:Vector.<MonitoredElementContent>;
		
		protected var _topElementAscent:Number = 0;
		protected var _numLines:int;
		
		protected static var UID:int;
		
		/**
		 * Constructor. 
		 * @param container AutosizableDisplayContainer The target display container onto which TextLines are added.
		 * @param compositionWidth Number The width of the display container.
		 * @param compositionHeight Number The height of the display container.
		 */
		public function AutosizableContainerController( container:AutosizableDisplayContainer, textFlowConfiguration:Configuration, compositionWidth:Number=100, compositionHeight:Number=100 )
		{
			super(container, compositionWidth, compositionHeight);
			
			container.initialize( this );
			
			_uid = "AutosizableContainerController" + AutosizableContainerController.UID++;
			_elements = new Vector.<FlowElement>();
			
			_containerFlow = new TextFlow( textFlowConfiguration );
		}
		
		/**
		 * @private
		 * 
		 * Method handler for factory of TextLine creation to determine the size of the container based on line bounds. 
		 * @param line TextLine
		 */
		protected function handleLineCreation( line:TextLine ):void
		{
			var bounds:Rectangle = line.getBounds( container );
			var pt:Point = container.localToGlobal( new Point( bounds.left, bounds.top ) );
			_actualHeight = pt.y + bounds.height + line.descent;
			
			if( ++_numLines == 1 )
				_topElementAscent = line.ascent - line.descent;
		}
		
		/**
		 * @private
		 * 
		 * Returns all elements from the flow that relate to this container based on uid. 
		 * @return Vector.<MonitoredElementContent>
		 */
		protected function getMonitoredElements():Vector.<MonitoredElementContent>
		{
			if( textFlow == null || textFlow.mxmlChildren == null ) return new Vector.<MonitoredElementContent>();
			
			var flowElements:Array = textFlow.mxmlChildren.slice();
			var i:int;
			var element:FlowElement;
			var elements:Vector.<MonitoredElementContent> = new Vector.<MonitoredElementContent>();
			for( i = 0; i < flowElements.length; i++ )
			{
				element = flowElements[i] as FlowElement;
				if( element.uid == _uid )
					elements.push( new MonitoredElementContent( element, i ) );
			}
			return elements;
		}
		
		/**
		 * @private
		 * 
		 * Returns the monitored elements back to the text flow. Elements are removed from the flow and put through a factory to determine the size of the container.
		 * Once this is complete, we return those elements back to the flow for composition.
		 */
		protected function returnMonitoredElements():void
		{
			if( _processedElements.length == 0 ) return;
			
			var element:MonitoredElementContent;
			while( _processedElements.length > 0 )
			{
				element = _processedElements.shift();
				textFlow.addChildAt( element.index, element.element );
			}
			
			// workaround for change introduced in 10.1 where graphics would be left on the other display list.
			var index:int = 0;
			while(index < textFlow.textLength)
			{
				var elem:FlowElement = textFlow.findLeaf(index);
				index += elem.textLength;
				if(elem is InlineGraphicElement)
				{
					var ige:InlineGraphicElement = InlineGraphicElement(elem);
					if(ige.status == InlineGraphicElementStatus.READY)
					{
						ige.setGraphic(ige.graphic);
					}
				}
			}
			
		}
		
		/**
		 * @private
		 * 
		 * Returns flag of element being related to this container based on uid. 
		 * @param element FlowElement
		 * @return Boolean
		 */
		protected function containsElement( element:FlowElement ):Boolean
		{
			while( element != null )
			{
				if( element.uid == _uid ) return true;
				element = element.parent;
			}
			return false;
		}
		
		/**
		 * @private
		 * 
		 * Returns elemental index of item within monitored list. 
		 * @param element FlowElement
		 * @return int
		 */
		protected function getElementIndex( element:FlowElement ):int
		{
			var index:Number;
			var i:int = _elements.length;
			while( --i > -1 )
			{
				if( _elements[i] == element )
				{
					index = i;
					break;
				}
			}
			return index;
		}
		
		/**
		 * @private
		 * 
		 * Removes the element from the list of monitored elements (if exists). 
		 * @param element FlowElement
		 */
		protected function removeElementFromList( element:FlowElement ):void
		{
			var index:Number = getElementIndex( element );
			if( !isNaN(index) )
			{
				_elements.splice( index, 1 );	
			}
		}
		
		/**
		 * Adds an element to the monitored elements list. 
		 * @param element FlowElement
		 */
		public function addMonitoredElement( element:FlowElement ):void
		{
			if( !containsElement( element ) )
			{
				element.uid = _uid;
				_elements.push( element );
			}
		}
		
		/**
		 * Removes the element from the list of monitored elements (if exists). 
		 * @param element FlowElement
		 */
		public function removeMonitoredElement( element:FlowElement ):void
		{
			if( containsElement( element ) )
			{
				removeElementFromList( element );
				element.uid = null;
			}
		}
		
		/**
		 * Returns flag of existance of element in monitored elements list. 
		 * @param element FlowElement
		 * @return Boolean
		 */
		public function containsMonitoredElement( element:FlowElement ):Boolean
		{
			return containsElement( element );
		}
		
		/**
		 * Determines the height of this container based on the created TextLines from the monitored element list.
		 */
		public function processContainerHeight():void
		{	
			_previousHeight = ( isNaN(_actualHeight) ) ? compositionHeight : _actualHeight;
			
			while( _containerFlow.numChildren > 0 )
			{
				_containerFlow.removeChildAt( 0 );
			}
			
			// Get monitored elements and add to internal text flow for TextLine creation.
			var i:int = 0;
			_processedElements = getMonitoredElements();
			var element:FlowElement;
			for( i = 0 ;i < _processedElements.length; i++ )
			{
				element = _processedElements[i].element;
				element.uid = _uid;
				_containerFlow.addChild( element );
			}
			
			// Pump elements through creation factory to determine the size of this container.
			_numLines = 0;
			var bounds:Rectangle = new Rectangle( 0, 0, compositionWidth, 1000000 );
			var factory:TextFlowTextLineFactory = new TextFlowTextLineFactory();
			factory.compositionBounds = bounds;
			factory.createTextLines( handleLineCreation, _containerFlow );
			
			// Return the elements and resize.
			returnMonitoredElements();
			setCompositionSize( compositionWidth, _actualHeight );
			
			// Notify of change in size if applicable.
			var offset:Number = _actualHeight - _previousHeight;
			if( offset != 0 )
			{
				// notify of change through container.
				container.dispatchEvent( new AutosizableContainerEvent( AutosizableContainerEvent.RESIZE_COMPLETE, _actualHeight, _previousHeight ) );
			}
		}
		
		/**
		 * Removes all monitored elements from the track list.
		 */
		public function removeAllMonitoredElements():void
		{
			while( _elements.length > 0 )
			{
				removeMonitoredElement( _elements[0] );
			}
		}
		
		/**
		 * Returns all monitored elements of this containr based on uid. 
		 * @return Array An array of FlowElement
		 */
		public function getAllMonitoredElements():Array
		{
			if( textFlow == null || textFlow.mxmlChildren == null ) return [];
			
			var flowElements:Array = textFlow.mxmlChildren;
			var i:int;
			var element:FlowElement;
			var elements:Array = []
			for( i = 0; i < flowElements.length; i++ )
			{
				element = flowElements[i] as FlowElement;
				if( element.uid == _uid )
					elements.push( element );
			}
			return elements;
		}
		
		/**
		 * Return the unique id of this container. Used as basis to locate monitored elements. 
		 * @return String
		 */
		public function getUID():String
		{
			return _uid;
		}
		
		/**
		 * Returns the actual height of this container determined from TextLine factory output. 
		 * @return Number
		 */
		public function get actualHeight():Number
		{
			return _actualHeight;
		}
		
		/**
		 * Returns the ascent of the top line to determine the placement of this container in the editor. 
		 * @return Number
		 */
		public function get topElementAscent():Number
		{
			return _topElementAscent;	
		}
	}
}

import flashx.textLayout.elements.FlowElement;
/**
 * MonitoredElementContent is an internal class to use for monitoring elements associated with this container instance. 
 * @author toddanderson
 */
class MonitoredElementContent
{
	public var element:FlowElement;
	public var index:int;
	/**
	 * Constructor. 
	 * @param element FlowElement
	 * @param index int
	 */
	public function MonitoredElementContent( element:FlowElement, index:int )
	{
		this.element = element;
		this.index = index;
	}
}