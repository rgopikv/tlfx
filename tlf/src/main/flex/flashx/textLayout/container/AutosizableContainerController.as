package flashx.textLayout.container
{
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.engine.TextLine;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.compose.TextFlowLine;
	import flashx.textLayout.edit.SelectionFormat;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.edit.TextFlowEdit;
	import flashx.textLayout.edit.TextScrap;
	import flashx.textLayout.elements.Configuration;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.IConfiguration;
	import flashx.textLayout.elements.InlineGraphicElement;
	import flashx.textLayout.elements.InlineGraphicElementStatus;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.table.TableElement;
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
		protected var _initialMonitoredElements:Vector.<FlowElement>;
		protected var _containerFlow:TextFlow;
		
		protected var _actualHeight:Number = Number.NaN;
		protected var _previousHeight:Number = Number.NaN;
		protected var _background:Sprite;
		protected var _lineHolder:Sprite;
		
		protected var _cachedOffsetElement:FlowElement;
		protected var _cachedOffset:Number;
		
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
			_initialMonitoredElements = new Vector.<FlowElement>();
			
			_containerFlow = new TextFlow( textFlowConfiguration );
		}
		
		/**
		 * @private
		 * 
		 * Method handler for factory of TextLine creation to determine the size of the container based on line bounds. 
		 * @param line TextLine
		 */
		protected function handleLineCreation( line:DisplayObject ):void
		{
			var bounds:Rectangle = line.getBounds( container );
			var pt:Point = container.localToGlobal( new Point( bounds.left, bounds.top ) );
			_actualHeight = pt.y + bounds.height + ( ( line is TextLine ) ? ( line as TextLine ).descent : 0 );
			
			if( ++_numLines == 1 && line is TextLine )
				_topElementAscent = ( line as TextLine ).ascent - ( line as TextLine ).descent;
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
			
			var i:int;
			var element:FlowElement;
			var elements:Vector.<MonitoredElementContent> = new Vector.<MonitoredElementContent>();
			if( textLength > 0 )
			{
				removeInitialMonitoredElements();
				
				var startIndex:int = 0;
				var index:int = flowComposer.getControllerIndex( this );
				if( index != 0 )
				{
					var flowIndex:int = 0;
					for( i = 0; i < textFlow.numChildren; i++ )
					{
						element = textFlow.getChildAt( i );
						if( element is TableElement )
						{
							flowIndex += ( element as TableElement ).getTableModel().cellAmount;
						}
						if( flowIndex == index )
						{
							startIndex = i + 1;
							break;
						}
						else
						{
							flowIndex += 1;
						}
					}
				}
				
				for( i = startIndex; i < textFlow.numChildren; i++ )
				{
					element = textFlow.mxmlChildren[i] as FlowElement;
					// This container does not monitor tables. They have their own container controller monitoring system.
					// We could reach this from endIndex if the operation was a delete and the flow has not completed updating this contoller with final textlength.
					if( !( element is TableElement ) )
					{
						elements.push( new MonitoredElementContent( element, i ) );
					}
					else
					{
						break;
					}
				}
			}
			else
			{
				var flowElements:Array = textFlow.mxmlChildren.slice();
				for( i = 0; i < flowElements.length; i++ )
				{
					element = flowElements[i] as FlowElement;
					if( _initialMonitoredElements.indexOf( element ) > -1 )
						elements.push( new MonitoredElementContent( element, i ) );
				}
			}
			return elements;
		}
		
		/**
		 * @private
		 * 
		 * Returns all elements from the flow that relate to this container based on uid. 
		 * @return Vector.<MonitoredElementContent>
		 */
		protected function getLastMonitoredElement():FlowElement
		{
			if( textFlow == null || textFlow.mxmlChildren == null ) return null
			
			var i:int;
			var element:FlowElement;
			if( textLength > 0 )
			{
				var startIndex:int = textFlow.getChildIndex( findTopLevel( absoluteStart ) );
				var endIndex:int = textFlow.getChildIndex( findTopLevel( Math.max(absoluteStart + textLength - 1, 0) ) );
				for( i = startIndex; i <= endIndex; i++ )
				{
					element = textFlow.mxmlChildren[i] as FlowElement;
					// This container does not monitor tables. They have their own container controller monitoring system.
					// We could reach this from endIndex if the operation was a delete and the flow has not completed updating this contoller with final textlength.
					if( ( element is TableElement ) )
					{
						element = textFlow.mxmlChildren[i-1] as FlowElement;
						break;
					}
				}
			}
			return element;
		}
		
		protected function findTopLevel( position:int ):FlowElement
		{
			var topLevel:FlowElement = textFlow.findLeaf( position );
			findTopLevel: while( topLevel != null )
			{
				if( topLevel.parent == textFlow ) break findTopLevel;
				topLevel = topLevel.parent;
			}
			return topLevel;
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
		}
		
		/**
		 * @private
		 * 
		 * Empties inital monitored element list.
		 */
		protected function removeInitialMonitoredElements():void
		{
			if( _initialMonitoredElements.length > 0 )
				_initialMonitoredElements = new Vector.<FlowElement>();
		}
		
		/**
		 * @private 
		 * 
		 * Reset any cached values used for space offset.
		 */
		protected function resetCachedOffsets():void
		{
			if( _cachedOffsetElement )
			{
				_cachedOffsetElement.paragraphSpaceAfter = _cachedOffset;
				_cachedOffset = 0;
				_cachedOffsetElement = null;
			}
		}
		
		/**
		 * @private
		 * 
		 * Returns the offset in height based on the last element that is used to construct the internal flow.
		 * This is needed to find if the last element was a paragraph element, and if so, if it had space after.
		 * When constructing flows, if the last element is a paragraph the space after is disregarded as their is no other content below. 
		 * @param element FlowElement
		 * @return Number
		 */
		protected function ensureProperSpaceAfterController( element:FlowElement ):Number
		{
			// If we are the last container contrller, don't have to fake spacing between table elements.
			if( textFlow.flowComposer.getControllerAt(textFlow.flowComposer.numControllers - 1) == this )
			{
				return 0;
			}
			var offset:Number = 0;
			if( element is ParagraphElement ) 
			{
				offset = Number( element.paragraphSpaceAfter );
				offset = ( isNaN(offset) ) ? 0 : offset;
				if( offset > 0 && _cachedOffsetElement != element ) 
				{
					element.paragraphSpaceAfter = 0;
					_cachedOffsetElement = element;
					_cachedOffset = offset;
				}
			}
			else
			{
				if( element is FlowGroupElement )
				{
					var group:FlowGroupElement = ( element as FlowGroupElement );
					return ensureProperSpaceAfterController( group.getChildAt( group.numChildren - 1 ) );
				}
			}
			return offset;
		}
		
		/**
		 * Adds an initial element to the monitored elements list. these are used on start up, afterward once absolute start and textlength are update, it instictively knows what elements reside in the container. 
		 * @param element FlowElement
		 */
		public function addInitialMonitoredElement( element:FlowElement ):void
		{
			if( textLength > 0 ) return;
			
			_initialMonitoredElements.push( element );
		}
		
		/**
		 * Determines the height of this container based on the created TextLines from the monitored element list.
		 */
		public function processContainerHeight():void
		{	
			_previousHeight = ( isNaN(_actualHeight) ) ? compositionHeight : _actualHeight;
			
			var generation:int = textFlow.generation;
			while( _containerFlow.numChildren > 0 )
			{
				_containerFlow.removeChildAt( 0 );
			}
			// Get monitored elements and add to internal text flow for TextLine creation.
			var i:int = 0;
			resetCachedOffsets();
			_processedElements = getMonitoredElements();
			
			var element:FlowElement;
			var lastElement:FlowElement;
			for( i = 0 ;i < _processedElements.length; i++ )
			{
				element = _processedElements[i].element;
				if( i == _processedElements.length - 1 )
					lastElement = element;
				
				_containerFlow.addChild( element );
			}
			
			// Pump elements through creation factory to determine the size of this container.
			_numLines = 0;
			
			var bounds:Rectangle = new Rectangle( 0, 0, compositionWidth, Number.NaN );
			var factory:TextFlowTextLineFactory = new TextFlowTextLineFactory();
			factory.compositionBounds = bounds;
			factory.createTextLines( handleLineCreation, _containerFlow );
		
			// Grab offset based on last element to ensure proper sizing of container controller as it corresponds to the flow.
			ensureProperSpaceAfterController( lastElement );
			
			// Return the elements and resize.
			returnMonitoredElements();
			setCompositionSize( compositionWidth, _actualHeight );
			
			textFlow.setGeneration( generation );
			// Notify of change in size if applicable.
			var offset:Number = _actualHeight - _previousHeight;
			if( offset != 0 )
			{
				// notify of change through container.
				container.dispatchEvent( new AutosizableContainerEvent( AutosizableContainerEvent.RESIZE_COMPLETE, _actualHeight, _previousHeight ) );
			}
		}
		
		/** Add selection shapes to the displaylist. @private */
		override tlf_internal function addSelectionShapes(selFormat:SelectionFormat, selectionAbsoluteStart:int, selectionAbsoluteEnd:int): void
		{
			if (!interactionManager || textLength == 0 || selectionAbsoluteStart == -1 || selectionAbsoluteEnd == -1)
				return;
			
			var prevLine:TextFlowLine;
			var nextLine:TextFlowLine;
			
			if (selectionAbsoluteStart != selectionAbsoluteEnd)
			{
				super.addSelectionShapes(selFormat, selectionAbsoluteStart, selectionAbsoluteEnd);	
			}
			else
			{
				var lineIdx:int = flowComposer.findLineIndexAtPosition(selectionAbsoluteStart);
				// TODO: there is ambiguity - are we at the end of the currentLine or the beginning of the next one?
				// however must stick to the end of the last line
				if (lineIdx == flowComposer.numLines)
					lineIdx--;
				
				// [TA] 04-07-2010 Limiting access.
				lineIdx = Math.max( 0, lineIdx );
				if( flowComposer.getLineAt( lineIdx ) == null ) 
				{
					trace( "[TA] {" + getQualifiedClassName(this) + "} :: Entered Possible Missing Line clause" );
					//	[KK] 06/16/2010 Attempting to provide new TextLines by adding a ParagraphElement with a SpanElement inside of it
					try {
						//	Removed textFlow.createContentElement() because it doesn't do ANYTHING.
						textFlow.normalize();
						if( textFlow.numChildren == 0 )
						{
							var p:ParagraphElement = textFlow.addChild(new ParagraphElement()) as ParagraphElement;
							textFlow.flowComposer.updateAllControllers();
//							addMonitoredElement( p );
						
							if ( textFlow.interactionManager )
								textFlow.interactionManager.setSelectionState( new SelectionState( textFlow, p.getAbsoluteStart(), p.getAbsoluteStart() ) );
						}
					} catch (e:*) {
						trace( "[KK] {" + getQualifiedClassName(this) + "} :: Couldn't correct text line problem." );
						return;
					}
				}
				// End [TA]
				super.addSelectionShapes(selFormat, selectionAbsoluteStart, selectionAbsoluteEnd);
			}
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
		 * Returns the offset along the y axis supposed after the container, which can be the case wehn stripping paragraphSpaceAfter form the last element. 
		 * @return Number
		 */
		public function get controllerOffsetAfter():Number
		{
			return isNaN( _cachedOffset ) ? 0 : _cachedOffset;
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