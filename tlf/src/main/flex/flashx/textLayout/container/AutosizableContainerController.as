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
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.InlineGraphicElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.events.AutosizableContainerControllerEvent;
	import flashx.textLayout.events.StatusChangeEvent;
	import flashx.textLayout.factory.TextFlowTextLineFactory;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;
	
	[Event(name="resizeComplete", type="flashx.textLayout.events.AutosizableContainerControllerEvent")]
	public class AutosizableContainerController extends ContainerController
	{	
		protected var _uid:String;
		protected var _elements:Vector.<FlowElement>;
		protected var _containerFlow:TextFlow;
		
		protected var _actualWidth:Number = Number.NaN;
		protected var _actualHeight:Number = Number.NaN;
		protected var _previousWidth:Number = Number.NaN;
		protected var _previousHeight:Number = Number.NaN;
		protected var _background:Sprite;
		
		protected var _processedElements:Vector.<MonitoredElementContent>;
		
		protected var _topElementAscent:Number = 0;
		protected var _numLines:int;
		
		protected static var UID:int;
		
		public function AutosizableContainerController( container:AutosizableControllerContainer, compositionWidth:Number=NaN, compositionHeight:Number=NaN )
		{
			super(container, compositionWidth, compositionHeight);
			
			container.initialize( this );
			
			_uid = "AutosizableContainerController" + AutosizableContainerController.UID++;
			_elements = new Vector.<FlowElement>();
			
			_containerFlow = new TextFlow();
			
			// TODO: See if we can grab a background color from styles. Might also be bitmap.
			_background = new Sprite();
			container.addChildAt( _background, 0 );
		}
		
		protected function handleLineCreation( line:TextLine ):void
		{
			var bounds:Rectangle = line.getBounds( container );
			var pt:Point = container.localToGlobal( new Point( bounds.left, bounds.top ) );
			_actualHeight = pt.y + bounds.height + line.descent;
			_actualWidth = Math.max( _actualWidth, bounds.width );
			
			_background.graphics.clear();
			_background.graphics.beginFill( 0xFF0000, 0.3 );
			_background.graphics.drawRect( 0, 0, _actualWidth, _actualHeight );
			_background.graphics.endFill();
			
			if( ++_numLines == 1 )
				_topElementAscent = line.ascent - line.descent;
		}
		
		protected function getMonitoredElements():Vector.<MonitoredElementContent>
		{
			if( textFlow == null || textFlow.mxmlChildren == null ) return new Vector.<MonitoredElementContent>();
			
			var elements:Vector.<MonitoredElementContent> = new Vector.<MonitoredElementContent>();
			recursivelyFindMonitoredElements( textFlow, elements );
			return elements;
		}
		
		protected function recursivelyFindMonitoredElements( parent:FlowGroupElement, elements:Vector.<MonitoredElementContent> ):void
		{
			var flowElements:Array = parent.mxmlChildren.slice();	
			var i:int;
			var element:FlowElement;
			for( i = 0; i < flowElements.length; i++ )
			{
				element = flowElements[i] as FlowElement;
				if( element is TableElement )
				{
					if( ( element as TableElement ).mxmlChildren == null ) continue; 
					recursivelyFindMonitoredElements( element as TableElement, elements );
				}
				else if( element.uid == _uid )
					elements.push( new MonitoredElementContent( parent, element, i ) );
			}
		}
		
		protected function returnMonitoredElements():void
		{
			var element:MonitoredElementContent;
			while( _processedElements.length > 0 )
			{
				element = _processedElements.shift();
				element.parent.addChildAt( element.index, element.element );
			}
		}
		
		protected function containsElement( element:FlowElement ):Boolean
		{
			while( element != null )
			{
				if( element.uid == _uid ) return true;
				element = element.parent;
			}
			return false;
		}
		
		protected function getElementIndex( element:FlowElement ):Number
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
		
		protected function removeElementFromList( element:FlowElement ):void
		{
			var index:Number = getElementIndex( element );
			if( !isNaN(index) )
			{
				_elements.splice( index, 1 );	
			}
		}
		
		public function addMonitoredElement( element:FlowElement ):void
		{
			if( !containsElement( element ) )
			{
				element.uid = _uid;
				_elements.push( element );
			}
		}
		public function removeMonitoredElement( element:FlowElement ):void
		{
			if( containsElement( element ) )
			{
				removeElementFromList( element );
				element.uid = null;
			}
		}
		
		public function containsMonitoredElement( element:FlowElement ):Boolean
		{
			return containsElement( element );
		}
		
		public function processContainerSize():void
		{
			var targetWidth:Number = ( isNaN(compositionWidth) || compositionWidth == 0 ) ? 1000000 : compositionWidth;
			var targetHeight:Number = ( isNaN(compositionHeight) || compositionHeight == 0 ) ? 1000000 : compositionHeight;
			_previousWidth = ( isNaN(_actualWidth) ) ? targetWidth : _actualWidth;
			_previousHeight = ( isNaN(_actualHeight) ) ? targetHeight : _actualHeight;
			_actualWidth = _actualHeight = 0;
			
			var format:ITextLayoutFormat = _computedFormat;
			var config:Configuration = new Configuration();
			config.textFlowInitialFormat = format;
			
			while( _containerFlow.numChildren > 0 )
			{
				_containerFlow.removeChildAt( 0 );
			}
			_containerFlow.format = format;
			
			var i:int = 0;
			_processedElements = getMonitoredElements();
			for( i = 0 ;i < _processedElements.length; i++ )
			{
				_processedElements[i].element.uid = _uid;
				_containerFlow.addChild( _processedElements[i].element );
			}
			
			_numLines = 0;
			var bounds:Rectangle = new Rectangle( 0, 0, targetWidth, 1000000 );
			var factory:TextFlowTextLineFactory = new TextFlowTextLineFactory();
			factory.compositionBounds = bounds;
			factory.createTextLines( handleLineCreation, _containerFlow );
			
			returnMonitoredElements();
			setCompositionSize( ( targetWidth == 1000000 ) ? _actualWidth : compositionWidth, _actualHeight );
			
			if( _actualHeight != _previousHeight || _actualWidth != _previousWidth )
			{
				container.dispatchEvent( new AutosizableContainerControllerEvent( AutosizableContainerControllerEvent.RESIZE_COMPLETE, this, _actualWidth, _actualHeight, _previousWidth, _previousHeight ) );
			}
		}
		
		public function removeAllMonitoredElements():void
		{
			while( _elements.length > 0 )
			{
				removeMonitoredElement( _elements[0] );
			}
		}
		
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
		
		public function getUID():String
		{
			return _uid;
		}
		
		public function get actualWidth():Number
		{
			return _actualWidth;
		}
		
		public function get actualHeight():Number
		{
			return _actualHeight;
		}
		
		public function get topElementAscent():Number
		{
			return _topElementAscent;	
		}
	}
}

import flashx.textLayout.elements.FlowElement;
import flashx.textLayout.elements.FlowGroupElement;

class MonitoredElementContent
{
	public var parent:FlowGroupElement;
	public var element:FlowElement;
	public var index:int;
	public function MonitoredElementContent( parent:FlowGroupElement, element:FlowElement, index:int )
	{
		this.parent = parent;
		this.element = element;
		this.index = index;
	}
}