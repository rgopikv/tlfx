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
	import flashx.textLayout.elements.InlineGraphicElement;
	import flashx.textLayout.elements.InlineGraphicElementStatus;
	import flashx.textLayout.elements.TextFlow;
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
		
		protected var _actualHeight:Number = Number.NaN;
		protected var _previousHeight:Number = Number.NaN;
		protected var _background:Sprite;
		protected var _lineHolder:Sprite;
		
		protected var _processedElements:Vector.<MonitoredElementContent>;
		
		protected var _topElementAscent:Number = 0;
		protected var _numLines:int;
		
		protected static var UID:int;
		
		public function AutosizableContainerController( container:AutosizableControllerContainer, compositionWidth:Number=100, compositionHeight:Number=100 )
		{
			super(container, compositionWidth, compositionHeight);
			
			container.initialize( this );
			
			_uid = "AutosizableContainerController" + AutosizableContainerController.UID++;
			_elements = new Vector.<FlowElement>();
			
			_containerFlow = new TextFlow();
			
			// TODO: See if we can grab a background color from styles. Might also be bitmap.
//			_background = new Sprite();
//			_background.graphics.beginFill( Math.random() * 0xFFFFFF, 0.3 );
//			_background.graphics.drawRect( 0, 0, compositionWidth, compositionHeight );
//			_background.graphics.endFill();
//			container.addChildAt( _background, 0 );
			
//			_lineHolder = new Sprite();
//			container.addChild( _lineHolder );
		}
		
		protected function handleLineCreation( line:TextLine ):void
		{
			var bounds:Rectangle = line.getBounds( container );
			var pt:Point = container.localToGlobal( new Point( bounds.left, bounds.top ) );
			_actualHeight = pt.y + bounds.height + line.descent;
			
//			_background.graphics.clear();
//			_background.graphics.beginFill( 0xFF0000, 0.3 );
//			_background.graphics.drawRect( 0, 0, compositionWidth, _actualHeight );
//			_background.graphics.endFill();
			
			if( ++_numLines == 1 )
				_topElementAscent = line.ascent - line.descent;
			
//			_lineHolder.addChild( line );
		}
		
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
		
		protected function returnMonitoredElements():void
		{
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
		
		public function processContainerHeight():void
		{
//			while( _lineHolder.numChildren > 0 )
//				_lineHolder.removeChildAt( 0 );
			
			_previousHeight = ( isNaN(_actualHeight) ) ? compositionHeight : _actualHeight;
			
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
			var bounds:Rectangle = new Rectangle( 0, 0, compositionWidth, 1000000 );
			var factory:TextFlowTextLineFactory = new TextFlowTextLineFactory();
			factory.compositionBounds = bounds;
			factory.createTextLines( handleLineCreation, _containerFlow );
			
			returnMonitoredElements();
			setCompositionSize( compositionWidth, _actualHeight );
			
			var offset:Number = _actualHeight - _previousHeight;
			if( offset != 0 )
			{
				container.dispatchEvent( new AutosizableContainerControllerEvent( AutosizableContainerControllerEvent.RESIZE_COMPLETE, this, offset ) );
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
class MonitoredElementContent
{
	public var element:FlowElement;
	public var index:int;
	public function MonitoredElementContent( element:FlowElement, index:int )
	{
		this.element = element;
		this.index = index;
	}
}