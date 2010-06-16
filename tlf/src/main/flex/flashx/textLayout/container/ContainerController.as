////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2008-2009 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
//////////////////////////////////////////////////////////////////////////////////
package flashx.textLayout.container 
{
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.IMEEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.engine.TextLine;
	import flash.text.engine.TextLineValidity;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuClipboardItems;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.compose.FlowDamageType;
	import flashx.textLayout.compose.IFlowComposer;
	import flashx.textLayout.compose.TextFlowLine;
	import flashx.textLayout.compose.TextLineRecycler;
	import flashx.textLayout.debug.Debugging;
	import flashx.textLayout.debug.assert;
	import flashx.textLayout.edit.EditingMode;
	import flashx.textLayout.edit.IInteractionEventHandler;
	import flashx.textLayout.edit.ISelectionManager;
	import flashx.textLayout.edit.SelectionFormat;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.elements.BackgroundManager;
	import flashx.textLayout.elements.ContainerFormattedElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.FlowValueHolder;
	import flashx.textLayout.elements.InlineGraphicElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.events.DamageEvent;
	import flashx.textLayout.events.TextLayoutEvent;
	import flashx.textLayout.events.UpdateCompleteEvent;
	import flashx.textLayout.formats.BlockProgression;
	import flashx.textLayout.formats.Float;
	import flashx.textLayout.formats.FormatValue;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormatValueHolder;
	import flashx.textLayout.property.Property;
	import flashx.textLayout.tlf_internal;

	use namespace tlf_internal;
		
	/** 
	 * The  ContainerController class defines the relationship between a TextFlow object and a container.
	 * A TextFlow may have one or more rectangular areas that can hold text; the text is said to be flowing
	 * through the containers. Each container is a Sprite that is the parent DisplayObject for the TextLines.
	 * Each container has a ContainerController that manages the container; the controller holds the target 
	 * width and height for the text area, populates the container with TextLines, and handles scrolling. A
	 * controller also has a format associated with it that allows some formatting attributes to be applied 
	 * to the text in the container. This allows, for instance, a TextFlow to have one container where the
	 * text appears in a single column, and a second container in the same TextFlow with two column text. Not
	 * all formatting attributes that can be applied to the container will affect the text; only the ones that
	 * affect container-level layout. The diagram below illustrates the relationship between the TextFlow,
	 * its flowComposer, and the display list.
	 *
	 * <p><img src="../../../images/textLayout_multiController.gif" alt="IContainerController"></img></p>
	 *
	 * @includeExample examples\ContainerControllerExample1.as -noswf
	 * @includeExample examples\ContainerControllerExample2.as -noswf
	 *
	 * @playerversion Flash 10
	 * @playerversion AIR 1.5
	 * @langversion 3.0
	 *
	 * @see flashx.textLayout.compose.IFlowComposer
	 * @see flashx.textLayout.elements.TextFlow
	 * @see flashx.textLayout.container.TextContainerController
	 */
	public class ContainerController implements IInteractionEventHandler, ITextLayoutFormat, ISandboxSupport
	{		
		private var _textFlowCache:TextFlow;
		private var _rootElement:ContainerFormattedElement;
		
		private var _absoluteStart:int;
		private var _textLength:int;
		
		private var _container:Sprite;
		
		// note must be protected - subclass sets or gets this variable but can't be public
		/** computed container attributes.  @private */
		protected var _computedFormat:ITextLayoutFormat;
		
		// Generated column information
		// Generated column information
		private var _columnState:ColumnState;
		
		/** Container size to be composed */
		private var _compositionWidth:Number = 0;
		private var _compositionHeight:Number = 0;
		private var _measureWidth:Boolean; // true if we're measuring (isNaN(compositionWidth) optimization so we don't call isNaN too much
		private var _measureHeight:Boolean; // true if we're measuring (isNaN(compositionHeight) optimization so we don't call isNaN too much
		
		/* Text bounds after composition */
		private var _contentLeft:Number;
		private var _contentTop:Number;
		private var _contentWidth:Number;
		private var _contentHeight:Number;
		
		private var _composeCompleteRatio:Number;	// 1 if composition was complete when contentHeight, etc registered, greater than one otherwise

		// Scroll policy -- determines whether scrolling is enabled or not
		private var _horizontalScrollPolicy:String;
		private var _verticalScrollPolicy:String;
		
		// x, y location of the text in the container relative to the underlying scrollable area
		private var _xScroll:Number;
		private var _yScroll:Number;
		
		/** Are event listeners attached to the container */
		private var _minListenersAttached:Boolean = false;
		private var _allListenersAttached:Boolean = false;
		private var _selectListenersAttached:Boolean = false;
		
		/** @private */
		tlf_internal function get allListenersAttached():Boolean
		{ return _allListenersAttached; }
	
		/** Are the displayed shapes out of date? */
		private var _shapesInvalid:Boolean = false;

		private var _backgroundShape:Shape;
		
		private var _scrollTimer:Timer = null;
		
		/**
		 * @private use this boolean to determine if container.scrollRect is set.  Accessing scrollRect when null changes the rendering behavior of flash player.	
		*/
		protected var _hasScrollRect:Boolean;
		
		/** 
		 * @private
		 * 
		 * <p>This property enables a client to test for a ScrollRect object without accessing 
		 * the DisplayObject.scrollRect property, which can have side effects in some cases.</p> 
		 *
		 * @return true if the controller has attached a ScrollRect instance.
		 */
		tlf_internal function get hasScrollRect():Boolean
		{ return _hasScrollRect; }
		
		CONFIG::debug
		{
			protected var id:String;
			private static var contCount:int = 0;
		}
		
		private var _shapeChildren:Array;

		private var _formatValueHolder:FlowValueHolder;
		
		private var _containerRoot:DisplayObject;
		
		/* Controller have a non-zero default width and height so that if you construct a text example with a container and don't
		 * specify width and height you will still see some text so that you can then have a clue what to do to correct its appearance.
		 */
		 
		/** 
		 * Constructor - creates a ContainerController instance. The ContainerController has a default <code>compositionWidth</code>
		 * and <code>compositionHeight</code> so that some text appears in the container if you don't specify its width
		 * height.
		 *
		 * @param container The DisplayObjectContainer in which to manage the text lines.
		 * @param compositionWidth The initial width for composing text in the container.
		 * @param compositionHeight The initial height for composing text in the container.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		 
		public function ContainerController(container:Sprite,compositionWidth:Number=100,compositionHeight:Number=100)
		{
			initialize(container,compositionWidth,compositionHeight);
		}
		
		private function initialize(container:Sprite,compositionWidth:Number,compositionHeight:Number):void
		{
			_container = container;
			_containerRoot =  null;
			
			_textLength = 0;
			_absoluteStart = -1;
		
			_columnState = new ColumnState(null/*blockProgression*/, null/*columnDirection*/, null/*controller*/, 0/*compositionWidth*/, 0/*compositionHeight*/);
			//_visibleRect = new Rectangle();
			_xScroll = _yScroll = 0;
			_contentWidth = _contentHeight = 0;
			_composeCompleteRatio = 1;

			// We have to set the flag so that we will get double click events. This
			// is a change to the container we are given, but a minor one.
			if (_container is InteractiveObject)
				InteractiveObject(_container).doubleClickEnabled = true;

			_horizontalScrollPolicy = _verticalScrollPolicy = String(ScrollPolicy.scrollPolicyPropertyDefinition.defaultValue);
			_hasScrollRect = false;

			CONFIG::debug { id = contCount.toString(); ++contCount; }

			_shapeChildren = [ ];
			
			setCompositionSize(compositionWidth, compositionHeight);
			format = _containerControllerInitialFormat;
		}

		/** @private */
		tlf_internal function get effectiveBlockProgression():String
		{
			return _rootElement ? _rootElement.computedFormat.blockProgression : BlockProgression.TB;
		}
		
		/** @private  Determine containerRoot in case the stage is not accessible. Normally the root is the stage. */
		tlf_internal function getContainerRoot():DisplayObject
		{
			// safe to test for stage existence
			if (_containerRoot == null && _container && _container.stage)
			{
				// if the stage is accessible lets use it.
				// trace("BEFORE COMPUTING CONTAINERROOT");
				try
				{
					var x:int = _container.stage.numChildren;
					_containerRoot = _container.stage;
				}
				catch(e:Error)
				{
					// TODO: some way to find the highest level accessible root???
					_containerRoot = _container.root;
				}
				// trace("AFTER COMPUTING CONTAINERROOT");
			}
			return _containerRoot;
		}
		
		/** 
		 * Returns the flow composer object that composes and highlights text into the container that this 
		 * controller manages. 
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 * 
	 	 * @see flashx.textLayout.compose.IFlowComposer
	 	 */

		public function get flowComposer():IFlowComposer
		{ return textFlow ? textFlow.flowComposer : null; }
		
		/** @private */
		tlf_internal function get shapesInvalid():Boolean
		{ return _shapesInvalid; }
		/** @private */
		tlf_internal function set shapesInvalid(val:Boolean):void
		{ _shapesInvalid = val;	}
		
		/** 
		 * Returns a ColumnState object, which describes the number and characteristics of columns in
		 * the container. These values are updated when the text is recomposed, either as a result
		 * of <code>IFlowComposer.compose()</code> or <code>IFlowComposer.updateAllControllers()</code>.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @see ColumnState
	 	 */
		 
		public function get columnState():ColumnState
		{
			if (_rootElement == null)
				return null;
			
			if (_computedFormat == null)
				computedFormat;
				
			_columnState.computeColumns();

			return _columnState; 
		}
		
		/** 
		 * Returns the container display object that holds the text lines for this ContainerController instance. 
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @see #ContainerController()
	 	 */
	 	 		 
		public function get container():Sprite
		{ return _container; }
		
		/** 
		 * Returns the horizontal extent allowed for text inside the container. The value is specified in pixels.
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @see #setCompositionSize()
		 */
		 
		public function get compositionWidth():Number
		{ return _compositionWidth; }
		
		/** 
		 * Returns the vertical extent allowed for text inside the container. The value is specified in pixels.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @see #setCompositionSize()
	 	 */
 		 
		public function get compositionHeight():Number
		{ return _compositionHeight; }
		
		/** @private */
		tlf_internal function get measureWidth():Boolean
		{ return _measureWidth; }
				
		/** @private */
		tlf_internal function get measureHeight():Boolean
		{ return _measureHeight; }
			
		/** 
		 * Sets the width and height allowed for text in the container. 
		 *
		 * @param w The width in pixels that's available for text in the container.
		 * @param h The height in pixels that's available for text in the container.
		 *
		 * @includeExample examples\ContainerController_setCompositionSizeExample.as -noswf
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 */
		
		public function setCompositionSize(w:Number,h:Number):void
		{
			// note: NaN == NaN is always false
			var widthChanged:Boolean  =  !(_compositionWidth == w || (isNaN(_compositionWidth) && isNaN(w)));
			var heightChanged:Boolean =  !(_compositionHeight == h || (isNaN(_compositionHeight) && isNaN(h)));
			
			if (widthChanged || heightChanged)
			{
				_compositionHeight = h;
				_measureHeight = isNaN(_compositionHeight);
				_compositionWidth = w;
				_measureWidth = isNaN(_compositionWidth);
				// otherwise the reset will happen when the cascade is done
				if (_computedFormat)
					resetColumnState();
				invalidateContents();
				attachTransparentBackgroundForHit(false);
			}
		}
		
		/** 
		 * Returns the TextFlow object whose content appears in the container. Either the <code>textFlow</code> and  
		 * <code>rootElement</code> values are the same, or this is the root element's TextFlow object. For example,
		 * if the container's root element is a DivElement, the value would be the TextFlow object to which the
		 * DivElement belongs.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 * 
	 	 * @see flashx.textLayout.elements#TextFlow TextFlow
	 	 */
		 
		public function get textFlow():TextFlow
		{ 
			if (!_textFlowCache && _rootElement)
				_textFlowCache = _rootElement.getTextFlow();
			return _textFlowCache;
		}
		
		 // Reserve possibility for future use as a ContainerFormattedElement within the TextFlow.
		 
		/** 
		 * Returns the root element that appears in the container. The root element could be a DivElement or TextFlow
		 * instance, for example.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 * 
	 	 * @see flashx.textLayout.elements.ContainerFormattedElement
	 	 * @see flashx.textLayout.elements.DivElement
	 	 * @see flashx.textLayout.elements.TextFlow
	 	 */
		 
		public function get rootElement():ContainerFormattedElement
		{ return _rootElement; }
		
		/** Protected method used when updating the rootElement. 
		 * @param value new container to be controlled
		 * 
		 * @private
		 */
		tlf_internal function setRootElement(value:ContainerFormattedElement):void
		{
			if (_rootElement != value)
			{
				clearCompositionResults();
				detachContainer();
				_rootElement = value;
				_textFlowCache = null;
				_textLength = 0;
				_absoluteStart = -1;
				attachContainer();
				if (_rootElement)
					formatChanged();
			}
		}

		/** 
		 * @copy flashx.textLayout.elements.TextFlow#interactionManager
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * 
		 * @see flashx.textLayout.elements.TextFlow#interactionManager
		 */
		 
		public function get interactionManager():ISelectionManager
		{
			return textFlow ? textFlow.interactionManager : null;
		}
		
		//--------------------------------------------------------------------------
		//
		//  Start and length
		//
		//--------------------------------------------------------------------------
		
		/** 
		 * Returns the first character in the container. If this is not the first container in the flow,
		 * this value is updated when the text is composed, that is when the IFlowComposer's <code>compose()</code> or 
 		 * <code>updateAllControllers()</code> methods are called.
		 * 
	 	 * @see flashx.textLayout.compose.IFlowComposer
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 */
		 
		public function get absoluteStart():int
		{
			if (_absoluteStart != -1)
				return _absoluteStart;
				
			var rslt:int = 0;
			var composer:IFlowComposer = flowComposer;
			if (composer)
			{
				var stopIdx:int = composer.getControllerIndex(this);
				if (stopIdx != 0)
				{
					var prevController:ContainerController = composer.getControllerAt(stopIdx-1);
					rslt = prevController.absoluteStart + prevController.textLength;
				}
			}
			_absoluteStart = rslt;
				
			return rslt;
		}
		
		/** Returns the total number of characters in the container. This can include text that is not currently in view,
		 * if the container is scrollable. This value is updated when the text is composed (when the IFlowComposer's <code>compose()</code> 
		 * or <code>updateAllControllers()</code> methods are called).
		 * 
	 	 * @see flashx.textLayout.compose.IFlowComposer
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 */
		 
		public function get textLength():int
		{
			return _textLength;
		}
		/** @private */
		tlf_internal function setTextLengthOnly(numChars:int):void
		{ 
			if (_textLength != numChars)
			{
				_textLength = numChars; 
				// all following containers must have absoluteStart invalidated
				if (_absoluteStart != -1)
				{
					var composer:IFlowComposer = flowComposer;
					if (composer)
					{
						var idx:int = composer.getControllerIndex(this)+1;
						while (idx < flowComposer.numControllers)
						{
							var controller:ContainerController = composer.getControllerAt(idx++);
							if (controller._absoluteStart == -1)
								break;
							controller._absoluteStart = -1;
						}
					}
				}
			}
		}
		
		/** @private */
		tlf_internal function setTextLength(numChars:int):void
		{
			CONFIG::debug { assert(numChars >= 0,"bad set textLength"); }

			// If its a scrollable container, and it is the last one, then it gets all the characters even though we might not have composed them all
			_composeCompleteRatio = 1;
			if (textFlow)
			{
				var verticalText:Boolean = effectiveBlockProgression == BlockProgression.RL;
				var flowComposer:IFlowComposer = textFlow.flowComposer;
				if (numChars != 0 && flowComposer.getControllerIndex(this) == flowComposer.numControllers - 1 &&
					((!verticalText && _verticalScrollPolicy != ScrollPolicy.OFF)||
					(verticalText && _horizontalScrollPolicy != ScrollPolicy.OFF)))
				{
					var containerAbsoluteStart:int = absoluteStart;
					CONFIG::debug { assert(textFlow.textLength >= containerAbsoluteStart,"ContainerController.setTextLength bad absoluteStart"); }
					_composeCompleteRatio = (textFlow.textLength-containerAbsoluteStart) / numChars;
					// _composeCompleteRatio = (textFlow.textLength-containerAbsoluteStart) == numChars ? 1 : 1.1;
					// var scaledContentHeight:Number = _composeCompleteRatio * _contentHeight;
					// trace("composeCompleteRatio:",_composeCompleteRatio,"composedContentHeight",_contentHeight,"scaledContentHeight",scaledContentHeight,"textLength",textFlow.textLength,"numChars",numChars);
					// include all remaining characters in this container when scroll enabled
					numChars = textFlow.textLength - containerAbsoluteStart;
				}
			}

			setTextLengthOnly(numChars); 
			CONFIG::debug
			{
				if (Debugging.debugOn && textFlow)
					assert(Math.min(textFlow.textLength, absoluteStart)+_textLength <= textFlow.textLength, "container textLength may not extend past end of root element!");
			}			
		}
		
		/** Updates the text within the container.
		 * Called after an editing change or composition to keep absoluteStart and textLength up to date.
		 * @private
		 */
		tlf_internal function updateLength(pos:int, lengthToAdd:int):void
		{
			CONFIG::debug { assert(_textLength+lengthToAdd >= 0,"bad set textLength"); }
			setTextLengthOnly(_textLength + lengthToAdd);
		}

		/** 
		 * Determines whether the container has text that requires composing. 
		 *
		 * @return 	true if the container requires composing.
		 *
		 * @includeExample examples\ContainerController_isDamagedExample.as -noswf
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 */
		
		public function isDamaged():Boolean
		{
			return flowComposer.isDamaged(absoluteStart + _textLength);
		}

		/** called whenever the container attributes are changed.  Mark computed attributes and columnstate as out of date. 
		 * @private
		 */
		tlf_internal function formatChanged():void
		{
			// The associated container, if there is one, inherits its container
			// attributes from here. So we need to tell it that these attributes
			// have changed.
			_computedFormat = null;
			invalidateContents();
		}
		
		/**
		 *  Removes inlines that should no longer be on the display list and
		 *  adds inlines that are new to the display list.
		 *  @private
		 */
		 
		tlf_internal function updateInlineChildren():void
		{
		}
		
		/** determines the shapechildren in the container and applies VJ. @private */
		protected function fillShapeChildren(sc:Array,tempSprite:Sprite):void
		{ 
			if (_textLength == 0)
				return;	// none				
			
			var wmode:String = effectiveBlockProgression;

			var width:Number = _measureWidth ? _contentWidth : _compositionWidth;
			var height:Number = _measureHeight ? _contentHeight : _compositionHeight;
			var scrollAdjustRect:Rectangle;
			if (wmode == BlockProgression.RL)
				scrollAdjustRect = new Rectangle(_xScroll - width, _yScroll, width, height);
			else
				scrollAdjustRect = new Rectangle(_xScroll, _yScroll, width, height);
			
			// If scrolling is turned off, and flow is vertical, then we need to adjust the positions of all the lines. With
			// scrolling turned on, we don't need to do this because the adjustment is done in the Player when the scrollRect
			// is set up correctly. But with the scrollRect, we also get clipping, and if scrolling is turned off we want to
			// have the clipping turned off as well. So in this case we do the adjustment manually so the scrollRect can be null.
			// NOTE: similar adjustments are made in TextContainerManager
			var adjustLines:Boolean = (wmode == BlockProgression.RL) &&
				(_horizontalScrollPolicy == ScrollPolicy.OFF && 
				_verticalScrollPolicy == ScrollPolicy.OFF);
				
			// Iterate over the lines in the container, setting the x and y positions and 
			// adding them to the list to go into the container. Keep track of the width 
			// and height of the actual text in the container.
			var firstLine:int = flowComposer.findLineIndexAtPosition(absoluteStart);
			var lastLine:int = flowComposer.findLineIndexAtPosition(absoluteStart + _textLength - 1);
			// Build the list in reverse order and than reverse it at the end.
			// This fixes bug 2509360 ARGO: Unselectable lines appear while scrolling
			// new bug filed because this is a small performance hit on the reverse - but this is the safest thing to do late in dev cycle
			for (var lineIndex:int = firstLine; lineIndex <= lastLine; lineIndex++)
			{
				var curLine:TextFlowLine = flowComposer.getLineAt(lineIndex);	
				if (curLine == null || curLine.controller != this)
					continue;

				var textLine:TextLine = curLine.createShape(wmode);
				if (!textLine)
					continue;
				
				CONFIG::debug { assert(textLine == curLine.peekTextLine(),"Bad textLine in fillShapeChildren "+Debugging.getIdentity(textLine)+" "+Debugging.getIdentity(curLine)); }
					
				var curBounds:Rectangle = getPlacedTextLineBounds(textLine); 
				
				// trace("fillShapeChildren:",lineIndex.toString(),curBounds.toString(),textLine.x.toString(),textLine.y.toString(),scrollRect.toString());
				if ((wmode == BlockProgression.RL) ? curBounds.x + curBounds.width >= scrollAdjustRect.left && curBounds.x < scrollAdjustRect.x + scrollAdjustRect.width :
					curBounds.y + curBounds.height >= scrollAdjustRect.top && curBounds.y < scrollAdjustRect.y + scrollAdjustRect.height)	
				{
					if (adjustLines)
					{
						textLine.x -= scrollAdjustRect.x;
						textLine.y -= scrollAdjustRect.y;
					}
					sc.push(textLine);
					if (textLine.parent == null)
						tempSprite.addChild(textLine);
				}
			}
			
			if (adjustLines)
			{
				_contentLeft -= scrollAdjustRect.x;
				_contentTop  -= scrollAdjustRect.y;
			}
		}
		
		//--------------------------------------------------------------------------
		//
		//  Scrolling
		//
		//--------------------------------------------------------------------------
	
		/** 
		 * Specifies the horizontal scrolling policy, which you can set by assigning one of the constants of
		 * the ScrollPolicy class: ON, OFF, or AUTO.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 * 
	 	 * @see ScrollPolicy
	 	 */
	 	 
		public function get horizontalScrollPolicy():String
		{
			return _horizontalScrollPolicy;
		}
		public function set horizontalScrollPolicy(scrollPolicy:String):void
		{
			var newScrollPolicy:String = ScrollPolicy.scrollPolicyPropertyDefinition.setHelper(_horizontalScrollPolicy, scrollPolicy) as String;

			if (newScrollPolicy != _horizontalScrollPolicy)
			{
				_horizontalScrollPolicy = newScrollPolicy;
				if (_horizontalScrollPolicy == ScrollPolicy.OFF)
					horizontalScrollPosition = 0;
				formatChanged();	// scroll policy affects composition
			}
		}
		
		/** Specifies the vertical scrolling policy, which you can set by assigning one of the constants of the ScrollPolicy
		 * class: ON, OFF, or, AUTO.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @see ScrollPolicy
		 */
	 	 
		public function get verticalScrollPolicy():String
		{
			return _verticalScrollPolicy;
		}
		public function set verticalScrollPolicy(scrollPolicy:String):void
		{
			var newScrollPolicy:String = ScrollPolicy.scrollPolicyPropertyDefinition.setHelper(_verticalScrollPolicy, scrollPolicy) as String;
			if (newScrollPolicy != _verticalScrollPolicy)
			{
				_verticalScrollPolicy = newScrollPolicy;
				if (_verticalScrollPolicy == ScrollPolicy.OFF)
					verticalScrollPosition = 0;
				formatChanged();	// scroll policy affects composition
			}
		}
		
		/** Specifies the current horizontal scroll location on the stage. The value specifies the number of
		 * pixels from the left.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 */

		public function get horizontalScrollPosition():Number
		{
			return _xScroll;
		}
		
		public function set horizontalScrollPosition(x:Number):void
		{
			if (!_rootElement)
				return;
				
			if (_horizontalScrollPolicy == ScrollPolicy.OFF)
			{
				_xScroll = 0;
				return;
			}
			var oldScroll:Number = _xScroll;
			var newScroll:Number = computeHorizontalScrollPosition(x,true);
			
			if (newScroll != oldScroll)
			{	
				_shapesInvalid = true;
				_xScroll = newScroll;
				updateForScroll();
			}
		}
		
		static private function pinValue(value:Number, minimum:Number, maximum:Number):Number
		{
			return Math.min(Math.max(value, minimum), maximum);						
		}
		
		private function computeHorizontalScrollPosition(x:Number,okToCompose:Boolean):Number
		{
			var wmode:String = effectiveBlockProgression;
			var curEstimatedWidth:Number = contentWidth;
			var newScroll:Number = 0;
			
			if (curEstimatedWidth > _compositionWidth && !_measureWidth)
			{
				// Pin the lower and upper bounds of _x. If we're doing vertical text, then the right edge is 0 and the left edge is negative
				// We may not have composed all the way to the indicated position. If not, force composition so that we can be sure we're at
				// a legal position.
				if (wmode == BlockProgression.RL)
				{
					newScroll = pinValue(x, _contentLeft + _compositionWidth, _contentLeft + curEstimatedWidth);
					if (okToCompose && _composeCompleteRatio != 1 && newScroll != _xScroll)
					{
						// in order to compose have to set _xScroll
						_xScroll = x;
						if (_xScroll > _contentLeft + _contentWidth)
							_xScroll = _contentLeft + _contentWidth;
						flowComposer.composeToController(flowComposer.getControllerIndex(this));
						newScroll = pinValue(x, _contentLeft + _compositionWidth, _contentLeft + _contentWidth);
					}
				}
				else
					newScroll = pinValue(x, _contentLeft, (_contentLeft + curEstimatedWidth) - _compositionWidth);
			}
			return newScroll;
		}

		
		/** Specifies the current vertical scroll location on the stage. The value specifies the number of 
		 * pixels from the top.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 */

		public function get verticalScrollPosition():Number
		{
			return _yScroll;
		}

		public function set verticalScrollPosition(y:Number):void
		{
			if (!_rootElement)
				return;
				
			if (_verticalScrollPolicy == ScrollPolicy.OFF)
			{
				_yScroll = 0;
				return;
			}
			
			var oldScroll:Number = _yScroll;
			var newScroll:Number = computeVerticalScrollPosition(y,true);
			
			if (newScroll != oldScroll)
			{			
				_shapesInvalid = true;
				_yScroll = newScroll;
				updateForScroll();
			}
		}	
		
		private function computeVerticalScrollPosition(y:Number,okToCompose:Boolean):Number
		{
			var newScroll:Number = 0;
			var curcontentHeight:Number = contentHeight;
			var wmode:String = effectiveBlockProgression;
			
			// Only try to scroll if the content height is greater than the composition height, then there is text that is not visible to scroll to
			if (curcontentHeight > _compositionHeight)
			{
				// new scroll value is somewhere between the topmost content, and the top of the last containerfull
				newScroll = pinValue(y, _contentTop, _contentTop + (curcontentHeight - _compositionHeight));

				// if we're not composed to the end, compose further so we can scroll to it. Sets the scroll position and then 
				// recomposes the container, which will compose through the end of the screenfull that starts at the requested position.
				if (okToCompose && _composeCompleteRatio != 1 && wmode == BlockProgression.TB)
				{
					_yScroll = y;
					if (_yScroll < _contentTop)
						_yScroll = _contentTop;
					flowComposer.composeToController(flowComposer.getControllerIndex(this));
					newScroll = pinValue(y, _contentTop, _contentTop + (curcontentHeight - _compositionHeight));
				}
			}
			return newScroll;
		}
		
		/** 
		 * Returns the area that the text occupies, as reflected by the last compose or update operation. 
		 * The width and the height might be estimated, if the container is scrollable and the text exceeds the 
		 * visible area.
		 * 
		 * @return describes the area that the text occupies.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @includeExample examples\ContainerController_getContentBoundsExample.as -noswf
	 	 *
	 	 * @see flash.geom.Rectangle Rectangle
	 	 */
		public function getContentBounds():Rectangle
		{
			return new Rectangle(_contentLeft, _contentTop, contentWidth, contentHeight);
		}
		
		/**
		 * @private
		 */
		
		tlf_internal function get contentLeft():Number
		{
			return _contentLeft;
		}
		
		/**
		 * @private
		 */
		
		tlf_internal function get contentTop():Number
		{
			return _contentTop;
		}
		
		/** 
		 * @private
		 *
		 * Returns the vertical extent of the text. For horizontal text, it includes space taken for descenders on the last line. 
		 * If not all the text is composed, this returns an estimated value based on how much text is already composed; the
		 * more text that is composed, the more accurate s the estimate. To get a completely accurate value, recompose
		 * with the rootElement's flowComposer before accessing contentHeight.
		 * You can get the composed bounds of the text by getting the contentLeft, contentTop, contentWidth, contentHeight properties.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 */
		 
		tlf_internal function get contentHeight():Number
		{
			return (effectiveBlockProgression == BlockProgression.TB) ? _contentHeight * _composeCompleteRatio : _contentHeight;
		}
		
		/** 
		 * @private
		 *
		 * Returns the horizontal extent of the text. For vertical text, it includes space taken for descenders on the last line. 
		 * If not all the text is composed, this returns an estimated value based on how much text is already composed; the
		 * more text that is composed, the more accurate is the estimate. To get a completely accurate value, recompose
		 * with the rootElement's flowComposer before accessing contentWidth.
		 * You can get the composed bounds of the text by getting the contentLeft, contentTop, contentWidth, contentHeight properties.
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 */
		 
		tlf_internal function get contentWidth():Number
		{			
			return (effectiveBlockProgression == BlockProgression.RL) ? _contentWidth * _composeCompleteRatio : _contentWidth;
		}

		/** @private */
		tlf_internal function setContentBounds(contentLeft:Number, contentTop:Number, contentWidth:Number, contentHeight:Number):void
		{
			_contentWidth = contentWidth;
			_contentHeight = contentHeight;
			_contentLeft = contentLeft;
			_contentTop = contentTop;
		}

		private function updateForScroll():void
		{
			var flowComposer:IFlowComposer = textFlow.flowComposer;
			flowComposer.updateToController(flowComposer.getControllerIndex(this));
	
			attachTransparentBackgroundForHit(false);
			
			// notify client that we scrolled.
			textFlow.dispatchEvent(new TextLayoutEvent(TextLayoutEvent.SCROLL));
			
		//	trace("contentHeight", contentHeight, "contentWidth", contentWidth);
		//	trace("contentHeight", contentHeight, "contentWidth", contentWidth);
		}
				
		/** @private */
		CONFIG::debug tlf_internal function validateLines():void
		{
			if (!Debugging.containerLineValidation)
				return;
			
			var flowComposer:IFlowComposer = textFlow.flowComposer;
			var textLine:TextLine;
			
			/*for (var ii:int = 0; ii < flowComposer.numLines; ii++)
			{
				textLine = flowComposer.getLineAt(ii).peekTextLine()
				trace("    // flowComposer",ii,textLine ? Debugging.getIdentity(textLine) : "null");
			}*/
			
			// find first textline
			var numContainerChildren:int = _container.numChildren;
			for (var containerIndex:int = 0; containerIndex < numContainerChildren; containerIndex++)
			{
				textLine = _container.getChildAt(containerIndex) as TextLine;
				if (textLine)
					break;
			}	
			
			if (textLine == null)
				return;	// no lines in this container

			var textFlowLine:TextFlowLine;
			// find the index of the first line
			for (var flowComposerIndex:int = 0; flowComposerIndex < flowComposer.numLines; flowComposerIndex++)
			{
				textFlowLine = flowComposer.getLineAt(flowComposerIndex);
				if (textFlowLine.peekTextLine() == textLine)
					break;
			}
			
			assert(flowComposerIndex != flowComposer.numLines,"BAD FIRST LINE IN CONTAINER");
			
			while (containerIndex < numContainerChildren)
			{
				textLine = _container.getChildAt(containerIndex) as TextLine;
				if (textLine == null)
				{
					// the very last thing can be the selection sprite
					assert(containerIndex == numContainerChildren-1,"Wrong location for selectionsprite");
					assert(_container.getChildAt(containerIndex) == getSelectionSprite(false),"expected selectionsprite but not found");
					break;
				}
				textFlowLine = flowComposer.getLineAt(flowComposerIndex);
				assert(textLine == textFlowLine.peekTextLine(),"BAD TEXTLINE IN TEXTFLOWLINE");
				containerIndex++;
				flowComposerIndex++;
			}
		}
		
		private function get containerScrollRectLeft():Number
		{
			var rslt:Number;
			if (horizontalScrollPolicy == ScrollPolicy.OFF && verticalScrollPolicy == ScrollPolicy.OFF)
				rslt = 0;
			else
				rslt= effectiveBlockProgression == BlockProgression.RL ? horizontalScrollPosition - compositionWidth : horizontalScrollPosition;
			//CONFIG::debug { assert(container.scrollRect == null && rslt == 0 || int(rslt) == container.scrollRect.left,"Bad containerScrollRectLeft"); }
			return rslt;
		}
		
		private function get containerScrollRectRight():Number
		{
			var rslt:Number = containerScrollRectLeft+compositionWidth;
			//CONFIG::debug { assert(container.scrollRect == null && rslt == compositionWidth || int(rslt) == container.scrollRect.right,"Bad containerScrollRectRight"); }
			return rslt;
		}
				
		private function get containerScrollRectTop():Number
		{
			var rslt:Number;
			if (horizontalScrollPolicy == ScrollPolicy.OFF && verticalScrollPolicy == ScrollPolicy.OFF)
				rslt = 0;
			else
				rslt = verticalScrollPosition;;
			//CONFIG::debug { assert(container.scrollRect == null && rslt == 0 || int(rslt) == container.scrollRect.top,"Bad containerScrollRectTop"); }
			return rslt;
		}
		
		private function get containerScrollRectBottom():Number
		{
			var rslt:Number = containerScrollRectTop+compositionHeight;
			//CONFIG::debug { assert(container.scrollRect == null && rslt == compositionHeight || int(rslt) == container.scrollRect.bottom,"Bad containerScrollRectBottom"); }
			return rslt;
		}
							
		/** 
		 * Scrolls so that the text range is visible in the container.
		 *
		 * @param activePosition	The end of the selection that is changed when you extend the selection. It can be
		 * 	either the start or the end of the selection, expressed as an offset from the start of the text flow.
		 * @param anchorPosition   	The stable end of the selection when you extend the selection. It can be either 
		 * 	the start or the end of the selection.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
		 */

		public function scrollToRange(activePosition:int,anchorPosition:int):void
		{

			// return if we're not scrolling, or if it's not the last controller
			if (!_hasScrollRect || !flowComposer || flowComposer.getControllerAt(flowComposer.numControllers-1) != this)
				return;
			
			// clamp values to range absoluteStart,absoluteStart+_textLength
			var controllerStart:int = absoluteStart;
			var lastPosition:int = Math.min(controllerStart+_textLength, textFlow.textLength - 1);
			activePosition = Math.max(controllerStart,Math.min(activePosition,lastPosition));
			anchorPosition = Math.max(controllerStart,Math.min(anchorPosition,lastPosition));
								
			var verticalText:Boolean = effectiveBlockProgression == BlockProgression.RL;
			var begPos:int = Math.min(activePosition,anchorPosition);
			var endPos:int = Math.max(activePosition,anchorPosition);
			
			// is part of the selection in view?
			var begLineIndex:int = flowComposer.findLineIndexAtPosition(begPos,(begPos == textFlow.textLength));
			var endLineIndex:int = flowComposer.findLineIndexAtPosition(endPos,(endPos == textFlow.textLength));
			
			// no scrolling if any part of the selection is in view
			var prevLine:TextFlowLine = begLineIndex == 0 ? null : flowComposer.getLineAt(begLineIndex-1);
			var currLine:TextFlowLine = flowComposer.getLineAt(begLineIndex);
			var accumulatedIntersection:int = 0;
			
			var scrollRectLeft:Number = containerScrollRectLeft;
			var scrollRectTop:Number  = containerScrollRectTop;
			var scrollRectRight:Number = containerScrollRectRight;
			var scrollRectBottom:Number = containerScrollRectBottom;
			var scrollRect:Rectangle = new Rectangle(scrollRectLeft, scrollRectTop, scrollRectRight-scrollRectLeft, scrollRectBottom-scrollRectTop);
			
			for (var lineIndex:int = begLineIndex; lineIndex <= endLineIndex; lineIndex++)
			{
				var nextLine:TextFlowLine = lineIndex+1 == flowComposer.numLines ? null : flowComposer.getLineAt(lineIndex+1);
				var lineEnd:int = currLine.absoluteStart+currLine.textLength;
				if (currLine.controller == this)
				{
					accumulatedIntersection += currLine.selectionWillIntersectScrollRect(scrollRect,begPos,Math.min(lineEnd,endPos),prevLine,nextLine);
					if (accumulatedIntersection >= 2)
						return;	// dont scroll
				}
				if (lineIndex == endLineIndex)
					break;
				prevLine = currLine;
				currLine = nextLine;
				begPos = lineEnd;
			}
			
			var rect:Rectangle = posToRectangle(activePosition);
			if (!rect)
			{
				flowComposer.composeToPosition(activePosition);
				rect = posToRectangle(activePosition);
			} 
			if (rect) 
			{
				var firstVisibleLine:TextFlowLine;
				var lastVisibleLine:TextFlowLine;

				// vertical scroll
				if (rect.top < scrollRectTop)
					verticalScrollPosition = rect.top;
				if (verticalText) {					
					// horizontal scroll
					if (rect.left < scrollRectLeft)
						horizontalScrollPosition = rect.left + _compositionWidth;
					if (rect.right > scrollRectRight)
						horizontalScrollPosition = rect.right;
					// set the rect to the previous character for the test on the bottom of the scrollRect.
					// Note, when dealing with the "bottommost" character (t-to-b), we actually need to position
					// pos at pos-1 because pos is looking at the character following the insertion point.
					// However, we can only look at the previous character if we're not on the first character in
					// a line.
					// This tests for pos being the first char on a line. If not, reset rect.
					if (flowComposer.findLineAtPosition(activePosition).absoluteStart != activePosition)
						rect = posToRectangle(activePosition-1);
					// If we're showing a blinking insertion point, we need to scroll far enough that
					// we can see the insertion point, and it comes just after the character.
					if (activePosition == anchorPosition)
						rect.bottom += 2;							
					// vertical scroll
					if (rect && rect.bottom > scrollRectBottom)
						verticalScrollPosition = rect.bottom - _compositionHeight;
					// now, we need to determine if the scrollRect is full or only partially full.
					// A partially full scrollRect can happen when you're deleting text at the end of the
					// container. When that happens, the bottomExtreme line in the scrollRect has space between
					// it and the left edge of the scrollRect. So, if it's partially full, then we need to scroll
					// to bring more of the Flow into view.
					var a:Array = findFirstAndLastVisibleLine();
					firstVisibleLine = a[0];
					lastVisibleLine = a[1];
					if (lastVisibleLine && lastVisibleLine.x - lastVisibleLine.descent - lastVisibleLine.spaceAfter > scrollRectLeft)
						horizontalScrollPosition = lastVisibleLine.x - lastVisibleLine.descent + _compositionWidth;
				}
				else 
				{
					// vertical scroll
					if (rect.bottom > scrollRectBottom)
						verticalScrollPosition = rect.bottom - _compositionHeight;
					// horizontal scroll
					if (rect.left < scrollRectLeft)
						horizontalScrollPosition = rect.left;
					// set the rect to the previous character for the test on the right side of the scrollRect.
					// Note, when dealing with the "rightmost" character (l-to-r), we actually need to position
					// pos at pos-1 because pos is looking at the character following the insertion point.
					// However, we can only look at the previous character if we're not on the first character in
					// a line.
					// This tests for pos being the first char on a line. If not, reset rect.
					if (flowComposer.findLineAtPosition(activePosition).absoluteStart != activePosition)
						rect = posToRectangle(activePosition-1);
					// If we're showing a blinking insertion point, we need to scroll far enough to see the
					// insertion point, and it comes up to the right
					if (activePosition == anchorPosition)
						rect.right += 2;
					if (rect && rect.right > scrollRectRight)
						horizontalScrollPosition = rect.right - _compositionWidth;
					// now, we need to determine if the scrollRect is full or only partially full.
					// A partially full scrollRect can happen when you're deleting text at the end of the
					// container. When that happens, the bottomExtreme line in the scrollRect has space between
					// it and the bottom edge of the scrollRect. So, if it's partially full, then we need to scroll
					// to bring more of the Flow into view.
					var b:Array = findFirstAndLastVisibleLine();
					firstVisibleLine = b[0];
					lastVisibleLine = b[1];
					if (rect.top > scrollRectTop && lastVisibleLine && lastVisibleLine.y + lastVisibleLine.height + lastVisibleLine.spaceAfter < scrollRectBottom)
						verticalScrollPosition = lastVisibleLine.y + lastVisibleLine.height;
				}
			}
		}		

		private function posToRectangle(pos:int):Rectangle
		{
			var line:TextFlowLine = flowComposer.findLineAtPosition(pos);
			// should the textLine ever be null? It is after some operations -- dunno why (rlw)
			if (!line.textLineExists || line.isDamaged())
				return null;


			var textLine:TextLine = line.getTextLine(true);
			var atomBounds:Rectangle;
			var atomIdx:int = textLine.getAtomIndexAtCharIndex(pos-line.paragraph.getAbsoluteStart());
			CONFIG::debug { assert(atomIdx > -1, "How'd we get here?"); }
			if (atomIdx > -1) 
				atomBounds = textLine.getAtomBounds(atomIdx);
	
			// special handling for TCY - no line height adjustments TCY is perpendicular to the height direction
			if (effectiveBlockProgression == BlockProgression.RL)
			{
				var leafElement:FlowLeafElement = _rootElement.getTextFlow().findLeaf(pos);
				if (leafElement.getParentByType(flashx.textLayout.elements.TCYElement) != null)
					return new Rectangle(line.x+atomBounds.x+line.y+atomBounds.y+atomBounds.width,atomBounds.height);
			}
				
			return effectiveBlockProgression == BlockProgression.RL ? 
				new Rectangle(line.x, line.y + atomBounds.y, line.height, atomBounds.height) :
				new Rectangle(line.x + atomBounds.x, line.y-line.height+line.ascent, atomBounds.width, line.height+textLine.descent);

		}
		
		/**
		 * @private
		 */

		tlf_internal function resetColumnState():void
		{
			if (_rootElement)
				_columnState.updateInputs(effectiveBlockProgression, _rootElement.computedFormat.direction, this, _compositionWidth, _compositionHeight);
		}
		
		/** 
		 * Marks all the text in this container as needing composing. 
		 *
		 * @includeExample examples\ContainerController_invalidateContentsExample.as -noswf
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 */
		 
		public function invalidateContents():void
		{
			if (textFlow && _textLength)
				textFlow.damage(absoluteStart, _textLength, FlowDamageType.GEOMETRY, false);
		}
		
		/** @private */
		private var _transparentBGX:Number;
		/** @private */
		private var _transparentBGY:Number;
		/** @private */
		private var _transparentBGWidth:Number;
		/** @private */
		private var _transparentBGHeight:Number;
				
		/** No mouse clicks or moves will be generated for the container unless it has a background covering its area.  Text Layout Framework
		 * wants those events so that clicking on a container will select the text in it.  This code
		 * adds or updates (on size change) that background for Sprite containers only. This may cause clients problems 
		 * - definitely no hits is a problem - add this code to explore the issues - expect feedback.  
		 * We may have to make this configurable. @private */
		

		tlf_internal function attachTransparentBackgroundForHit(justClear:Boolean):void
		{
			if (_minListenersAttached && attachTransparentBackground)
			{
				var s:Sprite = _container as Sprite;
				if (s)
				{
					if (justClear)
					{
						s.graphics.clear();
						CONFIG::debug { Debugging.traceFTECall(null,s,"clearTransparentBackground()"); }
						_transparentBGX = _transparentBGY = _transparentBGWidth = _transparentBGHeight = NaN;
					}
					else
					{		
						var bgwidth:Number = _measureWidth ? _contentWidth : _compositionWidth;
						var bgheight:Number = _measureHeight ? _contentHeight : _compositionHeight;
						
						var adjustHorizontalScroll:Boolean = effectiveBlockProgression == BlockProgression.RL && _horizontalScrollPolicy != ScrollPolicy.OFF;
						var bgx:Number = adjustHorizontalScroll ? _xScroll - bgwidth : _xScroll;
						var bgy:Number = _yScroll;

						CONFIG::debug { assert(!isNaN(bgx) && !isNaN(bgy) && !isNaN(bgwidth) && ! isNaN(bgheight),"Bad background rectangle"); }
						
						if (bgx != _transparentBGX || bgy != _transparentBGY || bgwidth != _transparentBGWidth || bgheight != _transparentBGHeight)
						{
							s.graphics.clear();
							CONFIG::debug { Debugging.traceFTECall(null,s,"clearTransparentBackground()"); }
							if (bgwidth != 0 && bgheight != 0 )
							{
								s.graphics.beginFill(0, 0);
								s.graphics.drawRect(bgx, bgy, bgwidth, bgheight);
								s.graphics.endFill();
								CONFIG::debug { Debugging.traceFTECall(null,s,"drawTransparentBackground",bgx, bgy, bgwidth, bgheight); }
							}
							_transparentBGX = bgx;
							_transparentBGY = bgy;
							_transparentBGWidth = bgwidth;
							_transparentBGHeight = bgheight;
						}
					}
				}
			} 
		}
		
		/** @private */
		tlf_internal	function interactionManagerChanged(newInteractionManager:ISelectionManager):void
		{
			if (newInteractionManager)
				attachContainer();
			else
				detachContainer();
		}
				
		//--------------------------------------------------------------------------
		//  Event handlers for editing
		//  Listeners are attached on first compose
		//--------------------------------------------------------------------------
				
		/** @private */
		tlf_internal function attachContainer():void
		{
			if (!_minListenersAttached && textFlow && textFlow.interactionManager)
			{
				_minListenersAttached = true;
				
				if (_container)
				{
		   			_container.addEventListener(FocusEvent.FOCUS_IN, requiredFocusInHandler);
		   			_container.addEventListener(MouseEvent.MOUSE_OVER, requiredMouseOverHandler);
	    			
	    			attachTransparentBackgroundForHit(false);
					
					// If the container already has focus, we have to attach all listeners
					if (_container.stage && _container.stage.focus == _container)
						attachAllListeners();
				}
			}
	 	}
	 	
	 	/** @private */
		tlf_internal function attachInteractionHandlers():void
		{
			// the receiver is either this or another class that is going to handle the methods.
			var receiver:IInteractionEventHandler = getInteractionHandler();
			
			// the required handlers are implemented here and forwarded to the receiver
			_container.addEventListener(MouseEvent.MOUSE_DOWN, requiredMouseDownHandler);
		   	_container.addEventListener(FocusEvent.FOCUS_OUT, requiredFocusOutHandler);
			_container.addEventListener(MouseEvent.DOUBLE_CLICK, receiver.mouseDoubleClickHandler);
			_container.addEventListener(Event.ACTIVATE, receiver.activateHandler);
		   	_container.addEventListener(FocusEvent.MOUSE_FOCUS_CHANGE, receiver.focusChangeHandler);
		   	_container.addEventListener(FocusEvent.KEY_FOCUS_CHANGE, receiver.focusChangeHandler);
		   	_container.addEventListener(TextEvent.TEXT_INPUT, receiver.textInputHandler);
		   	_container.addEventListener(MouseEvent.MOUSE_OUT, receiver.mouseOutHandler);
			_container.addEventListener(MouseEvent.MOUSE_WHEEL, receiver.mouseWheelHandler);
			_container.addEventListener(Event.DEACTIVATE, receiver.deactivateHandler);
			// attach by literal event name to avoid Argo dependency
			// normally this would be IMEEvent.START_COMPOSITION
			_container.addEventListener("imeStartComposition", receiver.imeStartCompositionHandler);

			if (_container.contextMenu)
	        	_container.contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, receiver.menuSelectHandler);
		   	_container.addEventListener(Event.COPY, receiver.editHandler);
		   	_container.addEventListener(Event.SELECT_ALL, receiver.editHandler);
		   	_container.addEventListener(Event.CUT, receiver.editHandler);
		   	_container.addEventListener(Event.PASTE, receiver.editHandler);
		   	_container.addEventListener(Event.CLEAR, receiver.editHandler);
		}
		
	 	/** @private */
		tlf_internal function removeInteractionHandlers():void
		{
			var receiver:IInteractionEventHandler = getInteractionHandler();

			_container.removeEventListener(MouseEvent.MOUSE_DOWN, requiredMouseDownHandler);
			_container.removeEventListener(FocusEvent.FOCUS_OUT, requiredFocusOutHandler);
			_container.removeEventListener(MouseEvent.DOUBLE_CLICK, receiver.mouseDoubleClickHandler);
			_container.removeEventListener(Event.ACTIVATE, receiver.activateHandler);
			_container.removeEventListener(FocusEvent.MOUSE_FOCUS_CHANGE, receiver.focusChangeHandler);
			_container.removeEventListener(FocusEvent.KEY_FOCUS_CHANGE, receiver.focusChangeHandler);
			_container.removeEventListener(TextEvent.TEXT_INPUT, receiver.textInputHandler);
 			_container.removeEventListener(MouseEvent.MOUSE_OUT, receiver.mouseOutHandler);
			_container.removeEventListener(MouseEvent.MOUSE_WHEEL, receiver.mouseWheelHandler);
			_container.removeEventListener(Event.DEACTIVATE, receiver.deactivateHandler);
		//	_container.removeEventListener(IMEEvent.IME_START_COMPOSITION, receiver.imeStartCompositionHandler); 
			// attach by literal event name to avoid Argo dependency
			_container.removeEventListener("imeStartComposition", receiver.imeStartCompositionHandler); 

	        if (_container.contextMenu) 
	        	_container.contextMenu.removeEventListener(ContextMenuEvent.MENU_SELECT, receiver.menuSelectHandler);
			_container.removeEventListener(Event.COPY, receiver.editHandler); 
			_container.removeEventListener(Event.SELECT_ALL, receiver.editHandler);
			_container.removeEventListener(Event.CUT, receiver.editHandler);
			_container.removeEventListener(Event.PASTE, receiver.editHandler);
			_container.removeEventListener(Event.CLEAR, receiver.editHandler);
			
			clearSelectHandlers();	
		}
		
		/** @private */
		tlf_internal function detachContainer():void
		{
			if (_minListenersAttached)
			{
				if (_container)
				{
		   			_container.removeEventListener(FocusEvent.FOCUS_IN, requiredFocusInHandler);
		   			_container.removeEventListener(MouseEvent.MOUSE_OVER, requiredMouseOverHandler);

					if(_allListenersAttached)
					{
						removeInteractionHandlers();				
						_container.contextMenu = null;
						
						attachTransparentBackgroundForHit(true);
						_allListenersAttached = false;
					}
	  			 }
	  			 _minListenersAttached = false;
	  		}
 	 	}
		
		private function attachAllListeners():void
		{	
			if (!_allListenersAttached && textFlow && textFlow.interactionManager)
			{
				CONFIG::debug { assert(_minListenersAttached,"Bad call to attachAllListeners - won't detach"); }
				_allListenersAttached = true;
				if (_container)
				{
					_container.contextMenu = createContextMenu();
					attachInteractionHandlers();
				}
			}
		}
		
		/** @private  
		 *
		 * Shared so that TextContainerManager can create the same ContextMenu. 
		 */
		static tlf_internal function createDefaultContextMenu():ContextMenu
		{
			var contextMenu:ContextMenu = new ContextMenu();
			contextMenu.clipboardMenu = true;
			contextMenu.clipboardItems.clear = true;
			contextMenu.clipboardItems.copy = true;
			contextMenu.clipboardItems.cut = true;
			contextMenu.clipboardItems.paste = true;
			contextMenu.clipboardItems.selectAll = true;
			return contextMenu;
		}
		
		/** 
		 * Creates a context menu for the ContainerController. Use the methods of the ContextMenu class to 
		 * add items to the menu.
		 * <p>You can override this method to define a custom context menu.</p>
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @see flash.ui.ContextMenu ContextMenu
	 	 */
		protected function createContextMenu():ContextMenu
		{
			return createDefaultContextMenu();
		}
		
		/** @private */
		tlf_internal function scrollTimerHandler(event:Event):void
		{
			// trace("BEGIN scrollTimerHandler");
			if (!_scrollTimer)
				return;

			// shut it down if not in this container
			if (textFlow.interactionManager == null || textFlow.interactionManager.activePosition < absoluteStart || textFlow.interactionManager.activePosition > absoluteStart+textLength)
				event = null;
				
						
			// We're listening for MOUSE_UP so we can cancel autoscrolling
			if (event is MouseEvent)
			{
				_scrollTimer.stop();
				_scrollTimer.removeEventListener(TimerEvent.TIMER, scrollTimerHandler);
				CONFIG::debug { assert(_container.stage ==  null || getContainerRoot() == event.currentTarget,"scrollTimerHandler bad target"); }
				event.currentTarget.removeEventListener(MouseEvent.MOUSE_UP, scrollTimerHandler);
				_scrollTimer = null;
			}
			else if (!event)
			{
				_scrollTimer.stop();
				_scrollTimer.removeEventListener(TimerEvent.TIMER, scrollTimerHandler);
				if (getContainerRoot())
					getContainerRoot().removeEventListener(	MouseEvent.MOUSE_UP, scrollTimerHandler);	
				_scrollTimer = null;
			}
			else if (_container.stage)
			{
				var containerPoint:Point = new Point(_container.stage.mouseX, _container.stage.mouseY);
				containerPoint = _container.globalToLocal(containerPoint);
				var scrollChange:int = autoScrollIfNecessaryInternal(containerPoint);
				if (scrollChange != 0 && interactionManager)		// force selection update if we actually scrolled and we have a selection manager
				{
					var mouseEvent:MouseEvent = new PsuedoMouseEvent(MouseEvent.MOUSE_MOVE,false,false,_container.stage.mouseX, _container.stage.mouseY,_container.stage,false,false,false,true);
					var stashedScrollTimer:Timer = _scrollTimer;	
					try
					{
						_scrollTimer =  null;
						interactionManager.mouseMoveHandler(mouseEvent);
					}
					catch (e:Error)
					{
						throw(e);
					}
					finally
					{
						_scrollTimer = stashedScrollTimer;
					}
				}
			}
			// trace("AFTER scrollTimerHandler");
		}

		/** 
		 * Handle a scroll event during a "drag" selection. 
		 *
		 * @param mouseX	The horizontal position of the mouse cursor on the stage.
		 * @param mouseY	The vertical position of the mouse cursor  on the stage.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 */
		 
		public function autoScrollIfNecessary(mouseX:int, mouseY:int):void
		{ 			
 			if (flowComposer.getControllerAt(flowComposer.numControllers-1) != this)
 			{
 				var verticalText:Boolean = (effectiveBlockProgression == BlockProgression.RL);
 				var lastController:ContainerController = flowComposer.getControllerAt(flowComposer.numControllers - 1);
 				if ((verticalText && _horizontalScrollPolicy == ScrollPolicy.OFF) ||
 					(!verticalText && _verticalScrollPolicy == ScrollPolicy.OFF))
					return;
				var r:Rectangle = lastController.container.getBounds(_container.stage);
				if (verticalText)
				{
					if (mouseY >= r.top && mouseY <= r.bottom)
						lastController.autoScrollIfNecessary(mouseX, mouseY);
				}
				else
				{
					if (mouseX >= r.left && mouseX <= r.right)
						lastController.autoScrollIfNecessary(mouseX, mouseY);
				}
 			}
			
			// even if not the last container - may scroll if there are explicit linebreaks
			if (!_hasScrollRect)
				return;
			var containerPoint:Point = new Point(mouseX, mouseY);
			containerPoint = _container.globalToLocal(containerPoint); 			
			autoScrollIfNecessaryInternal(containerPoint);
		}

		/** 
		 * Handle a scroll event during a "drag" selection. 
		 *
		 * @param mouseX	The horizontal position of the mouse cursor on the stage.
		 * @param mouseY	The vertical position of the mouse cursor  on the stage.
		 * @returns positive number if scroll went forward in reading order, negative number if it went backwards, and 0 if no scroll
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 */
		 
		private function autoScrollIfNecessaryInternal(extreme:Point):int
		{
			CONFIG::debug 
			{ 
				assert(_hasScrollRect, "internal scrolling function called on non-scrollable container");
			}
				
			
			var scrollDirection:int = 0;
			
			if (extreme.y - containerScrollRectBottom > 0) {
				verticalScrollPosition += textFlow.configuration.scrollDragPixels;
				scrollDirection = 1;
			}
			else if (extreme.y - containerScrollRectTop < 0) {
				verticalScrollPosition -= textFlow.configuration.scrollDragPixels;
				scrollDirection = -1;
			}
				
			if (extreme.x - containerScrollRectRight > 0) {
				horizontalScrollPosition += textFlow.configuration.scrollDragPixels;
				scrollDirection = -1;
			}
			else if (extreme.x - containerScrollRectLeft < 0) {
				horizontalScrollPosition -= textFlow.configuration.scrollDragPixels;
				scrollDirection = 1;
			}

			// we need a timer so that the mouse doesn't have to continue moving when the mouse is outside the content area
			if (scrollDirection != 0 && !_scrollTimer) 
			{
				_scrollTimer = new Timer(textFlow.configuration.scrollDragDelay);	// 35 ms is the default auto-repeat interval for ScrollBars.
				_scrollTimer.addEventListener(TimerEvent.TIMER, scrollTimerHandler, false, 0, true);
				if (getContainerRoot())
				{
					getContainerRoot().addEventListener(MouseEvent.MOUSE_UP, scrollTimerHandler, false, 0, true);
					beginMouseCapture(); // TELL CLIENTS WE WANT mouseUpSomewhere events
				}
				_scrollTimer.start();
			}
			
			return scrollDirection;
		}

		/** @private */
		tlf_internal function findFirstAndLastVisibleLine():Array
		{
			var firstLine:int = flowComposer.findLineIndexAtPosition(absoluteStart);
			var lastLine:int = flowComposer.findLineIndexAtPosition(absoluteStart + _textLength - 1);
			var lastColumn:int = _columnState.columnCount - 1;
			var firstVisibleLine:TextFlowLine;
			var lastVisibleLine:TextFlowLine;
			
			// no visible lines?
			if (firstLine == flowComposer.numLines)
				return [null,null];
				
			for (var lineIndex:int = firstLine; lineIndex <= lastLine; lineIndex++) 
			{
				var curLine:TextFlowLine = flowComposer.getLineAt(lineIndex);	
				if (curLine.controller != this)
					continue;
			
				// skip until we find the lines in the last column
				if (curLine.columnIndex != lastColumn)
					continue;
			
				if (curLine.textLineExists)
				{
					var curTextLine:TextLine = curLine.getTextLine();
					if (curTextLine && curTextLine.parent)
					{
						if (!firstVisibleLine)
							firstVisibleLine = curLine;
							
						lastVisibleLine = curLine;
					}
				}		
			}
			
			return [firstVisibleLine, lastVisibleLine];
		}
		
		/** 
		* Figure out the scroll distance required to scroll up or down by the specified number of lines.
		* Negative numbers scroll upward, bringing more of the top of the TextFlow into view. Positive numbers 
		* scroll downward, bringing the next line from the bottom into full view.
		* 
		* <p>When scrolling up, for example, the method makes the next line fully visible. If the next line is partially
		* obscured and the number of lines specified is 1, the partially obscured line becomes fully visible.</p>
		*
		* @param nLines	The number of lines to scroll.
		*
		* @return 	the delta amount of space to scroll
		*
		* @playerversion Flash 10
		* @playerversion AIR 1.5
	 	* @langversion 3.0
	 	*/
		 
		public function getScrollDelta(numLines:int):Number
		{
			if (flowComposer.numLines == 0)
				return 0;

			// Now we want to calculate the top & bottom lines within the scrollRect. It's ok if they're just partially
			// visible. Once we determine these lines, we figure out how much we need to scroll in order to bring the
			// lines completely into view.
			
			var a:Array = findFirstAndLastVisibleLine();
			var firstVisibleLine:TextFlowLine = a[0];
			var lastVisibleLine:TextFlowLine = a[1];
			// trace("    // findFirstAndLastVisibleLine ",flowComposer.findLineIndexAtPosition(firstVisibleLine.absoluteStart),flowComposer.findLineIndexAtPosition(lastVisibleLine.absoluteStart));
						
			var newLineIndex:int;
			var lineIndex:int;
			if (numLines > 0) 
			{
				lineIndex = flowComposer.findLineIndexAtPosition(lastVisibleLine.absoluteStart);
				// If the last visible line is only partly visible, don't count it as visible. But make sure it overlaps by
				// at least two pixels, otherwise it doesn't look like its clipped.
				if (lastVisibleLine)
				{
					var lastTextLine:TextLine = lastVisibleLine.getTextLine(true);
					if (effectiveBlockProgression == BlockProgression.TB)
					{
						if ((lastTextLine.y + lastTextLine.descent) - containerScrollRectBottom > 2)
							--lineIndex;
					}
					else if (containerScrollRectLeft - (lastTextLine.x - lastTextLine.descent)  > 2)
						--lineIndex;
				}

				// if we hit the end, force composition so that we get more lines - I picked a random amount to scroll forward, if its not enough, it will keep going
				while (lineIndex + numLines > flowComposer.numLines - 1 && flowComposer.damageAbsoluteStart < textFlow.textLength)	
					flowComposer.composeToPosition(flowComposer.damageAbsoluteStart + 1000);
				newLineIndex = Math.min(flowComposer.numLines-1, lineIndex + numLines);
			}
			if (numLines < 0) 
			{
				lineIndex = flowComposer.findLineIndexAtPosition(firstVisibleLine.absoluteStart);

				// If the first visible line is only partly visible, don't count it as visible. But make sure it overlaps by
				// at least two pixels, otherwise it doesn't look like its clipped.
				if (firstVisibleLine)
				{
					if (effectiveBlockProgression == BlockProgression.TB)
					{
						if (firstVisibleLine.y + 2 < containerScrollRectTop)
							++lineIndex;
					}
					else if (firstVisibleLine.x + firstVisibleLine.ascent > containerScrollRectRight + 2)
						++lineIndex;
				} 

				newLineIndex = Math.max(0, lineIndex + numLines);
			}
			
			var line:TextFlowLine = flowComposer.getLineAt(newLineIndex);
			if (line.absoluteStart < absoluteStart)		// don't scroll past the start of this controller -- previous text is in previous controller
				return 0;
			if (line.validity != TextLineValidity.VALID)
			{
				var leaf:FlowLeafElement = textFlow.findLeaf(line.absoluteStart);
				var paragraph:ParagraphElement = leaf.getParagraph();
				textFlow.flowComposer.composeToPosition(paragraph.getAbsoluteStart() + paragraph.textLength);
				line = flowComposer.getLineAt(newLineIndex);
				CONFIG::debug { assert(line.validity == TextLineValidity.VALID, "expected valid line after recomposing"); }
			}
			
			var verticalText:Boolean = effectiveBlockProgression == BlockProgression.RL;

			var newScrollPosition:Number;
			if (verticalText)
			{
				
				newScrollPosition =  numLines < 0 ? line.x + line.textHeight : line.x - line.descent + _compositionWidth;
				return newScrollPosition - horizontalScrollPosition;
			}

			newScrollPosition = numLines < 0 ? line.y : line.y + line.textHeight - _compositionHeight;
			return newScrollPosition - verticalScrollPosition;
		}
		
		/** 
		 * Processes the <code>MouseEvent.MOUSE_OVER</code> event when the client manages events. 
		 *
		 * @param event The MouseEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @includeExample examples\ContainerController_mouseOverHandlerExample.as -noswf
		 *
		 * @see flash.events.MouseEvent#MOUSE_OVER MouseEvent.MOUSE_OVER
		 */
		 
		public function mouseOverHandler(event:MouseEvent):void
		{
			if (interactionManager)
				interactionManager.mouseOverHandler(event);
		}

		/** @private Does required mouseOver handling.  Calls mouseOverHandler.  @see #mouseOverHandler */
		tlf_internal function requiredMouseOverHandler(event:MouseEvent):void
		{
			attachAllListeners();
			getInteractionHandler().mouseOverHandler(event);
		}

		/** Processes the <code>MouseEvent.MOUSE_OUT</code> event when the client manages events.
		 *
		 * @param event The MouseEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @see flash.events.MouseEvent#MOUSE_OUT MouseEvent.MOUSE_OUT
		 */				
		public function mouseOutHandler(event:MouseEvent):void
		{
			if (interactionManager)
				interactionManager.mouseOutHandler(event);
		}
		
		/** Processes the <code>MouseEvent.MOUSE_WHEEL</code> event when the client manages events.
		 *
		 * @param event The MouseEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @see flash.events.MouseEvent#MOUSE_WHEEL MouseEvent.MOUSE_WHEEL
		 */
		public function mouseWheelHandler(event:MouseEvent):void
		{
			// Do the scroll and call preventDefault only if the there is enough text to scroll. Otherwise
			// we let the event bubble up and cause scrolling at the next level up in the client's container hierarchy.
			var verticalText:Boolean = effectiveBlockProgression == BlockProgression.RL;
			if (verticalText)
			{
				if (contentWidth > _compositionWidth && !_measureWidth)
				{
					horizontalScrollPosition += event.delta * textFlow.configuration.scrollMouseWheelMultiplier;
					event.preventDefault();
				}
			}
			else if (contentHeight > _compositionHeight && !_measureHeight)
			{
				verticalScrollPosition -= event.delta * textFlow.configuration.scrollMouseWheelMultiplier;
				event.preventDefault();
			}
		}
		
		
		/** Processes the <code>MouseEvent.MOUSE_DOWN</code> event when the client manages events. 
		 *
		 * @param event The MouseEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @see flash.events.MouseEvent#MOUSE_DOWN MouseEvent.MOUSE_DOWN
		 */
		 
		public function mouseDownHandler(event:MouseEvent):void
		{
			if (interactionManager)
			{
				interactionManager.mouseDownHandler(event);
				// grab the focus - alternative is to listen to keyevents on the Application
				// is this necessary?
				if ( interactionManager.hasSelection())
					setFocus();
			}
		}

		/** @private Does required mouseDown handling.  Calls mouseDownHandler.  @see #mouseDownHandler */
		tlf_internal function requiredMouseDownHandler(event:MouseEvent):void
		{
			if (!_selectListenersAttached)
			{
				var containerRoot:DisplayObject = getContainerRoot();
				if (containerRoot)
				{
		   			containerRoot.addEventListener(MouseEvent.MOUSE_MOVE, rootMouseMoveHandler, false, 0, true); 
					containerRoot.addEventListener(MouseEvent.MOUSE_UP,   rootMouseUpHandler, false, 0, true);
					
					beginMouseCapture(); // TELL CLIENTS THAT WE WANT moueUpSomewhere EVENTS
					
	
					_selectListenersAttached = true;
				}
			}
			getInteractionHandler().mouseDownHandler(event); 
		}
		
		/** 
		 * Processes the <code>MouseEvent.MOUSE_UP</code> event when the client manages events.
		 *
		 * @param event The MouseEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @see flash.events.MouseEvent#MOUSE_UP MouseEvent.MOUSE_UP
		 *
		 */
		public function mouseUpHandler(event:MouseEvent):void
		{
			if (interactionManager)
			{
				interactionManager.mouseUpHandler(event);
			}
		}		
		
		/** @private */
		tlf_internal function rootMouseUpHandler(event:MouseEvent):void
		{
			clearSelectHandlers();
			getInteractionHandler().mouseUpHandler(event);
		}
		
				
		private function clearSelectHandlers():void
		{	
			if (_selectListenersAttached)
			{
				CONFIG::debug { assert(getContainerRoot() != null,"No container root"); }
   				getContainerRoot().removeEventListener(MouseEvent.MOUSE_MOVE, rootMouseMoveHandler); 					
				getContainerRoot().removeEventListener(MouseEvent.MOUSE_UP,   rootMouseUpHandler);
				endMouseCapture(); // TELL CLIENTS WE NO LONGER WANT mouseUpSomewhere EVENTS
				_selectListenersAttached = false;
			}
		}

		/** 
		 * Called to request clients to begin the forwarding of mouseup and mousemove events from outside a security sandbox.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 */
		public function beginMouseCapture():void
		{
			// trace("BEGIN MOUSECAPTURE");
			var sandboxManager:ISandboxSupport = getInteractionHandler() as ISandboxSupport
			if (sandboxManager && sandboxManager != this)
				sandboxManager.beginMouseCapture();
		}
		/** 
		 * Called to inform clients that the the forwarding of mouseup and mousemove events from outside a security sandbox is no longer needed.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 */
		 public function endMouseCapture():void
		{
			// trace("END MOUSECAPTURE");
			var sandboxManager:ISandboxSupport = getInteractionHandler() as ISandboxSupport
			if (sandboxManager && sandboxManager != this)
				sandboxManager.endMouseCapture();
		}
		/** Client call to forward a mouseUp event from outside a security sandbox.  Coordinates of the mouse up are not needed.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 */
		public function mouseUpSomewhere(event:Event):void
		{
			rootMouseUpHandler(null);
			scrollTimerHandler(null);
		}
		/** Client call to forward a mouseMove event from outside a security sandbox.  Coordinates of the mouse move are not needed.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 */
		public function mouseMoveSomewhere(event:Event):void
		{
			return;	// do nothing right now
		}

		// What'd I hit???
		private function hitOnMyFlowExceptLastContainer(event:MouseEvent):Boolean
		{
			if (event.target is TextLine)
			{
				var tfl:TextFlowLine = TextLine(event.target).userData as TextFlowLine;
				if (tfl)
				{
					var para:ParagraphElement = tfl.paragraph;
					if(para.getTextFlow() == textFlow)
						return true;
				}
			}
			else if (event.target is Sprite)
			{
				// skip the last container in the chain
				for (var idx:int = 0; idx < textFlow.flowComposer.numControllers-1; idx++)
					if (textFlow.flowComposer.getControllerAt(idx).container == event.target)
						return true;
			}
			return false;
		}
		/** 
		 * Processes the <code>MouseEvent.MOUSE_MOVE</code> event when the client manages events.
		 *
		 * @param event The MouseEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @see flash.events.MouseEvent#MOUSE_MOVE MouseEvent.MOUSE_MOVE
		 */
		 
		public function mouseMoveHandler(event:MouseEvent):void
		{
			if (interactionManager)
			{
				// only autoscroll if we haven't hit something on the stage related to this particular TextFlow
				if (event.buttonDown && !hitOnMyFlowExceptLastContainer(event))
					autoScrollIfNecessary(event.stageX, event.stageY);
				interactionManager.mouseMoveHandler(event);
			}
		}
		
		/** @private */
		tlf_internal function rootMouseMoveHandler(event:MouseEvent):void
		{   
			getInteractionHandler().mouseMoveHandler(event); 
		}
		
		/** Processes the <code>MouseEvent.DOUBLE_CLICK</code> event when the client manages events.
		 *
		 * @param event The MouseEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @includeExample examples\ContainerController_mouseDoubleClickHandlerExample.as -noswf
		 *
		 * @see flash.events.MouseEvent#DOUBLE_CLICK MouseEvent.DOUBLE_CLICK
		 */
		public function mouseDoubleClickHandler(event:MouseEvent):void
		{
			if (interactionManager)
			{
				interactionManager.mouseDoubleClickHandler(event);
				// grab the focus - alternative is to listen to keyevents on the Application
				// is this necessary?
				if ( interactionManager.hasSelection())
					setFocus();
			}
		}
		
		/** Give focus to the text container. @private */
		tlf_internal function setFocus():void
		{
			//trace("setFocus container", id);
			if (_container.stage)
				_container.stage.focus = _container; 
		}
		
		private function getContainerController(container:DisplayObject):ContainerController
		{
			while (container)
			{
				var flowComposer:IFlowComposer = flowComposer;
				for (var i:int = 0; i < flowComposer.numControllers; i++)
				{
					var controller:ContainerController = flowComposer.getControllerAt(i);
					if (controller.container == container)
						return controller;
				}
				container = container.parent;
			}
			return null;
		}
		
		/** 
		 * Processes the <code>FocusEvent.KEY_FOCUS_CHANGE</code> and <code>FocusEvent.MOUSE_FOCUS_CHANGE</code> events
		 * when the client manages events.
		 *
		 * @param event The FocusEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @see flash.events.FocusEvent#KEY_FOCUS_CHANGE FocusEvent.KEY_FOCUS_CHANGE
		 * @see flash.events.FocusEvent#MOUSE_FOCUS_CHANGE FocusEvent.MOUSE_FOCUS_CHANGE
		 */
		
		public function focusChangeHandler(event:FocusEvent):void
		{
			// Figure out which controllers, if any, correspond to the DisplayObjects passed in the event.
			// Disallow the focus change if it comes back to this controller again -- this prevents
			// a focusOut followed by a focusIn, which we would otherwise get after clicking in the 
			// container that already has focus.
			
				// This is the controller that currently has the focus
			var focusController:ContainerController = getContainerController(DisplayObject(event.target));
			
				// This is the controller that is about to get the focus
			var newFocusController:ContainerController = getContainerController(event.relatedObject);

			/*trace("focusChange from controller", 
				focusController is ContainerControllerBase ? ContainerControllerBase(focusController).id : "unknownType", 
				newFocusController is ContainerControllerBase ? ContainerControllerBase(newFocusController).id : "unknownType");
		*/
			if (newFocusController == focusController)
			{
			//	trace("prevent focus change");
				event.preventDefault();
			}
		}
		
		/** Processes the <code>FocusEvent.FOCUS_IN</code> event when the client manages events.
		 *
		 * @param event The FocusEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @includeExample examples\ContainerController_focusInHandlerExample.as -noswf
		 *
		 * @see flash.events.FocusEvent#FOCUS_IN FocusEvent.FOCUS_IN
		 */
		public function focusInHandler(event:FocusEvent):void
		{
			var blinkRate:int = 0;
		//	trace("container", id, "focusIn");
			if (interactionManager)
			{
				interactionManager.focusInHandler(event);

				if (interactionManager.editingMode == EditingMode.READ_WRITE)
					blinkRate = interactionManager.focusedSelectionFormat.pointBlinkRate;				
			} 
			setBlinkInterval(blinkRate);
		}
		
		/** @private - does whatever focusIn handling is required and cannot be overridden */
		tlf_internal function requiredFocusInHandler(event:FocusEvent):void
		{
			attachAllListeners();
			// trace("ContainerController requiredFocusInHandler adding key handlers");
  			_container.addEventListener(KeyboardEvent.KEY_DOWN, getInteractionHandler().keyDownHandler);
   			_container.addEventListener(KeyboardEvent.KEY_UP,   getInteractionHandler().keyUpHandler);		
   			_container.addEventListener(FocusEvent.KEY_FOCUS_CHANGE,   getInteractionHandler().keyFocusChangeHandler);		
			getInteractionHandler().focusInHandler(event);
		}
		
		/** Processes the <code>FocusEvent.FOCUS_OUT</code> event when the client manages events.
		 *
		 * @param event The FocusEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @see flash.events.FocusEvent#FOCUS_OUT FocusEvent.FOCUS_OUT
		 */
		 
		public function focusOutHandler(event:FocusEvent):void
		{
			if (interactionManager)
			{
				interactionManager.focusOutHandler(event);
				setBlinkInterval(interactionManager.unfocusedSelectionFormat.pointBlinkRate);
			}
			else
				setBlinkInterval(0);
		}

		/** @private Does required focusOut handling.  Calls focusOutHandler.  @see #focusOutHandler */
		tlf_internal function requiredFocusOutHandler(event:FocusEvent):void
		{
			// trace("ContainerController requiredFocusOutHandler removing key handlers");
 			_container.removeEventListener(KeyboardEvent.KEY_DOWN, getInteractionHandler().keyDownHandler);
   			_container.removeEventListener(KeyboardEvent.KEY_UP,   getInteractionHandler().keyUpHandler);   			
   			_container.removeEventListener(FocusEvent.KEY_FOCUS_CHANGE,   getInteractionHandler().keyFocusChangeHandler);   			
			getInteractionHandler().focusOutHandler(event);
		}
		
		/** Processes the <code>Event.ACTIVATE</code> event when the client manages events.
		 *
		 * @param event The Event object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @includeExample examples\ContainerController_activateHandlerExample.as -noswf
		 *
		 * @see flash.events.Event#ACTIVATE Event.ACTIVATE
		 */						
		public function activateHandler(event:Event):void
		{
			if (interactionManager)
				interactionManager.activateHandler(event);
		}
		
		/** Processes the <code>Event.DEACTIVATE</code> event when the client manages events. 
		 *
		 * @param event The Event object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * 
		 * @see flash.events.Event#DEACTIVATE Event.DEACTIVATE
		 */
		 
		public function deactivateHandler(event:Event):void
		{
			if (interactionManager)
				interactionManager.deactivateHandler(event);
		}		
		
		/** Processes the <code>KeyboardEvent.KEY_DOWN</code> event when the client manages events.
		 *
		 * @param The KeyboardEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @see flash.events.KeyboardEvent#KEY_DOWN KeyboardEvent.KEY_DOWN
		 */
		public function keyDownHandler(event:KeyboardEvent):void
		{
			if (interactionManager)
				interactionManager.keyDownHandler(event);
		}
		
		/** Processes the <code>Keyboard.KEY_UP</code> event when the client manages events.
		 *
		 * @param event The KeyboardEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @includeExample examples\ContainerController_keyUpHandlerExample.as -noswf
		 *
		 * @see flash.events.KeyboardEvent#KEY_UP KeyboardEvent.KEY_UP
		 */
		 
		public function keyUpHandler(event:KeyboardEvent):void
		{
			if (interactionManager)
				interactionManager.keyUpHandler(event);
		}

		/** Processes the <code>FocusEvent.KEY_FOCUS_CHANGE</code> event when the client manages events.
		 *
		 * @param event The FocusEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @see flash.events.FocusEvent#KEY_FOCUS_CHANGE FocusEvent.KEY_FOCUS_CHANGE
		 */
		public function keyFocusChangeHandler(event:FocusEvent):void
		{
			if (interactionManager)
				interactionManager.keyFocusChangeHandler(event);
		}		
		/** Processes the <code>TextEvent.TEXT_INPUT</code> event when the client manages events.
		 *
		 * @param event  The TextEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * 
		 * @includeExample examples\ContainerController_textInputHandlerExample.as -noswf
		 *
		 * @see flash.events.TextEvent#TEXT_INPUT TextEvent.TEXT_INPUT
		 */
		 
		public function textInputHandler(event:TextEvent):void
		{
			if (interactionManager)
				interactionManager.textInputHandler(event);
		}
		
		/** Processes the <code>IMEEvent.IME_START_COMPOSITION</code> event when the client manages events.
		 *
		 * @param event  The IMEEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * 
		 * @see flash.events.IMEEvent.IME_START_COMPOSITION
		 */
		 
		public function imeStartCompositionHandler(event:IMEEvent):void
		{
			if (interactionManager)
				interactionManager.imeStartCompositionHandler(event);
		}
		
		
		/** 
		 * Processes the <code>ContextMenuEvent.MENU_SELECT</code> event when the client manages events.
		 * 
		 * @param The ContextMenuEvent object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @includeExample examples\ContainerController_menuSelectHandlerExample.as -noswf
		 * 
		 * @see flash.events.ContextMenuEvent#MENU_SELECT ContextMenuEvent.MENU_SELECT
		 */						
		public function menuSelectHandler(event:ContextMenuEvent):void
		{
			var tf:DisplayObjectContainer = _container as DisplayObjectContainer;

			if (interactionManager)
			{
				interactionManager.menuSelectHandler(event);
			}
    		else
    		{
				var cbItems:ContextMenuClipboardItems = tf.contextMenu.clipboardItems
				cbItems.copy = false;
				cbItems.cut = false;
				cbItems.paste = false;
				cbItems.selectAll = false;
				cbItems.clear = false;
			}
		}
		
		/**
		 * Processes an edit event (CUT, COPY, PASTE, SELECT_ALL) when the client manages events.
		 * 
		 * @param The Event object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @includeExample examples\ContainerController_editHandlerExample.as -noswf
		 * 
		 * @see flash.events.Event Event
		 */	
			    
	    	public function editHandler(event:Event):void
	    	{
	    		if (interactionManager)
	    			interactionManager.editHandler(event);

	    		// re-enable context menu so following keyboard shortcuts will work
	    		var contextMenu:ContextMenu = _container.contextMenu;
	    		if (contextMenu)
	    		{
					contextMenu.clipboardItems.clear = true;
					contextMenu.clipboardItems.copy = true;
					contextMenu.clipboardItems.cut = true;
					contextMenu.clipboardItems.paste = true;
					contextMenu.clipboardItems.selectAll = true;
	    		}
	    	}
	    
		 /** 
		 * Sets the range of selected text in a component implementing ITextSupport.
		 * If either of the arguments is out of bounds the selection should not be changed.
		 * Components which wish to support inline IME should call into this method.
		 * 
		 * @param anchorIndex The zero-based index value of the character at the anchor end of the selection
		 *
		 * @param activeIndex The zero-based index value of the character at the active end of the selection.
		 * 
		 * @playerversion Flash 10.0
		 * @langversion 3.0
		 */
	    public function selectRange(anchorIndex:int, activeIndex:int):void
	    {
	    	if(interactionManager && interactionManager.editingMode != EditingMode.READ_ONLY)
	    	{
		    	interactionManager.selectRange(anchorIndex, activeIndex);
	    	}
	    }
	    
		//--------------------------------------------------------------------------
		//
		//  Cursor blinking code
		//
		//--------------------------------------------------------------------------
		
		// TODO Want to evaluate whether there's a cleaner way to do this
		
		private var blinkTimer:Timer;
		private var blinkObject:DisplayObject;

		/**
		 * Starts a DisplayObject cursor blinking by changing its alpha value
		 * over time.
		 * 
		 * @param obj The DisplayObject to use as the cursor.
		 * 
		 */
		private function startBlinkingCursor(obj:DisplayObject, blinkInterval:int):void
		{
			if (!blinkTimer)
				blinkTimer = new Timer(blinkInterval,0);
			blinkObject = obj;
			blinkTimer.addEventListener(TimerEvent.TIMER,blinkTimerHandler, false, 0, true);
			blinkTimer.start();
		}

		/**
		 * Stops cursor from blinking
		 * @private
		 */
		protected function stopBlinkingCursor():void
		{
			if (blinkTimer)
				blinkTimer.stop();
			blinkObject = null;
		}	
		
		private function blinkTimerHandler(event:TimerEvent):void
		{
			blinkObject.alpha = (blinkObject.alpha == 1.0) ? 0.0 : 1.0;
		}
		
		/** 
		 * Set the blink interval.
		 * 
		 * @param intervalMS - number of microseconds between blinks
		 * @private
		 */
		protected function setBlinkInterval(intervalMS:int):void
		{
			var blinkInterval:int = intervalMS;
			if (blinkInterval == 0)
			{
				// turn off the blinking
				if (blinkTimer)
					blinkTimer.stop();
				if (blinkObject)
					blinkObject.alpha = 1.0;
			}
			else if (blinkTimer)
			{
				blinkTimer.delay = blinkInterval;
				if (blinkObject)
					blinkTimer.start();
			}
		}
		
		/** Draw the caret for a selection 
		 * @param x	x-location where caret is drawn
		 * @param y y-location where caret is drawn
		 * @param w	width of caret
		 * @param h	height of caret
		 * @private
		 */
		tlf_internal function drawPointSelection(selFormat:SelectionFormat, x:Number,y:Number,w:Number,h:Number):void
        {
            var selObj:Shape = new Shape();
            
            if (interactionManager.activePosition == interactionManager.anchorPosition)
				selObj.graphics.beginFill(selFormat.pointColor)
			else
				selObj.graphics.beginFill(selFormat.rangeColor);
				
			// Oh, this is ugly. If we are in right aligned text, and there is no padding, and the scrollRect is set, 
			// then in an empty line (or if the point is at the right edge of the line), the blinking cursor is not
			// visible because it is clipped out. Move it in so we can see it. 
			if (_hasScrollRect)
			{
				if (effectiveBlockProgression == BlockProgression.TB)
				{
					if (x >= containerScrollRectRight)
						x -= w;
				} 
				else
					if (y >= containerScrollRectBottom)
						y -= h;
			}
				
			selObj.graphics.drawRect(int(x),int(y),w,h);
			selObj.graphics.endFill();
			
			// make it blink
			if (selFormat.pointBlinkRate != 0 && interactionManager.editingMode == EditingMode.READ_WRITE)
				startBlinkingCursor(selObj, selFormat.pointBlinkRate);

			addSelectionChild(selObj);
        }
        
        /** Add selection shapes to the displaylist. @private */
        tlf_internal function addSelectionShapes(selFormat:SelectionFormat, selectionAbsoluteStart:int, selectionAbsoluteEnd:int): void
		{
			if (!interactionManager || _textLength == 0 || selectionAbsoluteStart == -1 || selectionAbsoluteEnd == -1)
				return;
						
			var prevLine:TextFlowLine;
			var nextLine:TextFlowLine;
			
			if (selectionAbsoluteStart != selectionAbsoluteEnd)
			{
				// adjust selectionAbsoluteStart and selectionAbsoluteEnd to be within this controller
				var absoluteControllerStart:int = this.absoluteStart;
				var absoluteControllerEnd:int = this.absoluteStart+this._textLength;
				
				if (selectionAbsoluteStart < absoluteControllerStart)
					selectionAbsoluteStart = absoluteControllerStart;
				else if (selectionAbsoluteStart >= absoluteControllerEnd)
					return;	// nothing to do
					
				// backup one so that 
				if (selectionAbsoluteEnd > absoluteControllerEnd)
					selectionAbsoluteEnd = absoluteControllerEnd;
				else if (selectionAbsoluteEnd < absoluteControllerStart)
					return;	// nothing to do
					
				CONFIG::debug { assert(selectionAbsoluteStart <= selectionAbsoluteEnd,"addSelectionShapes: bad range"); }
				CONFIG::debug { assert(selectionAbsoluteStart >= absoluteControllerStart,"addSelectionShapes: bad range"); }
				CONFIG::debug { assert(selectionAbsoluteEnd <= absoluteControllerEnd,"addSelectionShapes: bad range"); }
					
				var begLine:int = flowComposer.findLineIndexAtPosition(selectionAbsoluteStart);
				var endLine:int = selectionAbsoluteStart == selectionAbsoluteEnd ? begLine : flowComposer.findLineIndexAtPosition(selectionAbsoluteEnd);
				// watch for going past the end
				if (endLine >= flowComposer.numLines)
					endLine = flowComposer.numLines-1;
					
				var selObj:Shape = new Shape();
				prevLine = begLine ? flowComposer.getLineAt(begLine-1) : null;
				var line:TextFlowLine = flowComposer.getLineAt(begLine); 
					
				for (var idx:int = begLine; idx <= endLine; idx++)
				{
					nextLine = idx != flowComposer.numLines - 1 ? flowComposer.getLineAt(idx+1) : null;
						
					line.hiliteBlockSelection(selObj, selFormat, DisplayObject(this._container),
						selectionAbsoluteStart < line.absoluteStart ? line.absoluteStart : selectionAbsoluteStart,
						selectionAbsoluteEnd > line.absoluteStart+line.textLength ? line.absoluteStart+line.textLength : selectionAbsoluteEnd, prevLine, nextLine);
							
					var temp:TextFlowLine = line;
					line = nextLine;
					prevLine = temp;
				}

				addSelectionChild(selObj);		
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
					trace( "[TA] Entered Possible Missing Line clause" );
					return;
				}
				// End [TA]
				if (flowComposer.getLineAt(lineIdx).controller == this)
				{
					prevLine = lineIdx != 0 ? flowComposer.getLineAt(lineIdx-1) : null;
					nextLine = lineIdx != flowComposer.numLines-1 ? flowComposer.getLineAt(lineIdx+1) : null;
					flowComposer.getLineAt(lineIdx).hilitePointSelection(selFormat, selectionAbsoluteStart, DisplayObject(this._container), prevLine, nextLine);
				}
			}
		}

		/** Remove all selection shapes. @private */
		tlf_internal function clearSelectionShapes(): void
		{
			stopBlinkingCursor();
			
			var selectionSprite:DisplayObjectContainer = getSelectionSprite(false);
			if (selectionSprite != null)
			{
				if (selectionSprite.parent)
					removeSelectionContainer(selectionSprite);
				while (selectionSprite.numChildren > 0)
					selectionSprite.removeChildAt(0);
				return;
			}
		}
	
		/** Add a selection child. @private */
		tlf_internal function addSelectionChild(child:DisplayObject):void
		{
			// If there's no selectionSprite on this controller, we use the parent's.
			// That means we have to translate the coordinates.
			// TODO: this only supports one level of ntesting
			var selectionSprite:DisplayObjectContainer = getSelectionSprite(true);
			
			if (selectionSprite == null)
			{
				return;
			}

			var selFormat:SelectionFormat = interactionManager.currentSelectionFormat;
			var curBlendMode:String = (interactionManager.activePosition == interactionManager.anchorPosition) ? selFormat.pointBlendMode : selFormat.rangeBlendMode;
			var curAlpha:Number = (interactionManager.activePosition == interactionManager.anchorPosition) ? selFormat.pointAlpha : selFormat.rangeAlpha;
			if (selectionSprite.blendMode != curBlendMode)
				selectionSprite.blendMode = curBlendMode;
				
			if (selectionSprite.alpha != curAlpha)
				selectionSprite.alpha = curAlpha;
			
			if (selectionSprite.numChildren == 0)
				addSelectionContainer(selectionSprite);
				
			selectionSprite.addChild(child);
		}
		
		/** Test for a selection child. @private */
		tlf_internal function containsSelectionChild(child:DisplayObject):Boolean
		{ 
			var selectionSprite:DisplayObjectContainer = getSelectionSprite(false);
			if (selectionSprite == null)
			{
				return false;
			}
			return selectionSprite.contains(child); 
		}

		/** @private */
		tlf_internal function getBackgroundShape():Shape
		{
			if(!_backgroundShape)
			{
				_backgroundShape = new Shape();
				addBackgroundShape(_backgroundShape);
			}
			
			return _backgroundShape;
		}
		
		CONFIG::debug private function containsFloats(textFlow:TextFlow):Boolean
 		{
 			if (textFlow)
 				for (var leaf:FlowLeafElement = textFlow.getFirstLeaf(); leaf != null; leaf = leaf.getNextLeaf())
 					if (leaf is InlineGraphicElement && InlineGraphicElement(leaf).float != Float.NONE)
 						return true;
 			return false;
		}
		/**
		 * @private
		 */
		tlf_internal function get effectivePaddingLeft():Number
		{ return computedFormat.paddingLeft + (_rootElement ? _rootElement.computedFormat.paddingLeft : 0); }
		/**
		 * @private
		 */
		 tlf_internal function get effectivePaddingRight():Number
		{ return computedFormat.paddingRight + (_rootElement ? _rootElement.computedFormat.paddingRight : 0); }
		/**
		 * @private
		 */
		 tlf_internal function get effectivePaddingTop():Number
		{ return computedFormat.paddingTop + (_rootElement ? _rootElement.computedFormat.paddingTop : 0); }
		/**
		 * @private
		 */
		 tlf_internal function get effectivePaddingBottom():Number
		{ return computedFormat.paddingBottom + (_rootElement ? _rootElement.computedFormat.paddingBottom : 0); }

		private var _selectionSprite:Sprite;
		
		/** @private */
		tlf_internal function getSelectionSprite(createIfNull:Boolean):DisplayObjectContainer
		{
			if (_selectionSprite == null && createIfNull)
			{
				_selectionSprite = new Sprite();
				_selectionSprite.mouseEnabled = false;
				_selectionSprite.mouseChildren = false;
			}
			return _selectionSprite;
		}
		
		static private function createContainerControllerInitialFormat():ITextLayoutFormat
		{
			var ccif:TextLayoutFormatValueHolder = new TextLayoutFormatValueHolder();
			ccif.columnCount = FormatValue.INHERIT;
			ccif.columnGap = FormatValue.INHERIT;
			ccif.columnWidth = FormatValue.INHERIT;
			ccif.verticalAlign = FormatValue.INHERIT;
			return ccif;
		}
		
		static private var _containerControllerInitialFormat:ITextLayoutFormat = createContainerControllerInitialFormat();
		
		/** 
		* @private
		* Specifies the initial format (ITextLayoutFormat instance) for a new ContainerController. The runtime
		* applies this to the format property of all new containers on creation.
		*
		* By default, sets the column format values to "inherit"; all other format values are inherited.
		*
		* @playerversion Flash 10
		* @playerversion AIR 1.5
		* @langversion 3.0
		*
		* @see TextFlow
		*/
		
		static public function get containerControllerInitialFormat():ITextLayoutFormat
		{ return _containerControllerInitialFormat; }
		static public function set containerControllerInitialFormat(val:ITextLayoutFormat):void
		{ _containerControllerInitialFormat = val; }
		
		
		/** @private */
		protected function get attachTransparentBackground():Boolean
		{ return true; }
		
		/** @private */
		tlf_internal function clearCompositionResults():void
		{
			setTextLength(0); 

			for each (var textLine:TextLine in _shapeChildren)
			{
				removeTextLine(textLine);
				CONFIG::debug { Debugging.traceFTECall(null,_container,"removeTextLine",textLine); }
			}
			_shapeChildren.length = 0;
		}
		
		/** The TextLines being added to the array in fillShapeChildren are added to tempSprite because they are about to be displayed
		 * and the TextFlowLine code needs to know that as it keeps all displayed lines in the TextFlowLine textLineCache.  This tells them that.
		 */
		static private var tempLineHolder:Sprite = new Sprite();
		
		/** Add DisplayObjects that were created by composition to the container. @private */
		tlf_internal function updateCompositionShapes():void
		{
			if(!shapesInvalid)
			{
				return;
			}			
			
			// reclamp vertical/horizontal scrollposition - addresses Watson 2380962
			var scrolled:Boolean = false;	// true if scroll values were changed - we need to notify in this case
			var tmp:Number = _yScroll;
			if (verticalScrollPolicy != ScrollPolicy.OFF && !_measureHeight)
				_yScroll = computeVerticalScrollPosition(_yScroll,false);
			scrolled = (tmp != _yScroll);
			tmp = _xScroll;
			if (horizontalScrollPolicy != ScrollPolicy.OFF && !_measureWidth)
				_xScroll = computeHorizontalScrollPosition(_xScroll,false);
			scrolled = scrolled || (tmp != _xScroll);

			// Post all the new TextLines to the display list, and remove any old TextLines left from last time. Do this
			// in a non-destructive way so that lines that have not been changed are not touched. This reduces redraw time.
			var newShapeChildren:Array = [ ];
			fillShapeChildren(newShapeChildren,tempLineHolder);
			
			var childIdx:int = getFirstTextLineChildIndex(); // index where the first text line must appear at in its container  
			var oldIdx:int = 0;		// offset into shapeChildren
			var newIdx:int = 0;		// offset into newShapeChildren

			while (newIdx != newShapeChildren.length)
			{
				var newChild:TextLine = newShapeChildren[newIdx];
				if (newChild == _shapeChildren[oldIdx])
				{
					// Same shape is in both lists, no change necessary, advance to next item in each list
					childIdx++;
					newIdx++;
					oldIdx++;
					continue;
				}

				var newChildIdx:int = _shapeChildren.indexOf(newChild);
				if (newChildIdx == -1)
				{
					// Shape is in the new list, but not in the old list, add it to the display list at the current location, and advance to next item
					addTextLine(newChild, childIdx++);
					CONFIG::debug { Debugging.traceFTECall(null,_container,"addTextLine",newChild); }
					newIdx++;
				}
				else
				{
					// The shape is on both lists, but there are several intervening "old" shapes in between. We'll remove the old shapes that
					// come before the new one we want to insert.
					removeAndRecycleTextLines (oldIdx, newChildIdx);
					oldIdx = newChildIdx;
				}
			}

			// remove any trailing children no longer displayed
			removeAndRecycleTextLines (oldIdx, _shapeChildren.length);

			_shapeChildren = newShapeChildren;
			shapesInvalid = false;
									
			// TODO: support for inline children (tables)
			// synchronize the inline shapes beginning at childIdx 
			updateInlineChildren();
			
			// _textFrame.updateVisibleRectangle(this._visibleRect);
			updateVisibleRectangle();
			
			// If we're measuring, then the measurement values may have changed since last time.
			// Force the transparent background to redraw, so that mouse events will work for the 
			// entire content area.
			if (_measureWidth || _measureHeight)
				attachTransparentBackgroundForHit(false);
			
			var tf:TextFlow = this.textFlow;
			if (tf.backgroundManager)
			{
				tf.backgroundManager.onUpdateComplete(this);
			}
			
			// If we updated the scroll values, we need to send an event
			if (scrolled && tf.hasEventListener(TextLayoutEvent.SCROLL))
			{
				tf.dispatchEvent(new TextLayoutEvent(TextLayoutEvent.SCROLL));
			}

			if (tf.hasEventListener(UpdateCompleteEvent.UPDATE_COMPLETE))
			{
				tf.dispatchEvent(new UpdateCompleteEvent(UpdateCompleteEvent.UPDATE_COMPLETE,false,false,tf, this));
			}
			
			CONFIG::debug { assert(tempLineHolder.numChildren == 0,"Uh oh"); }
			CONFIG::debug { validateLines(); }
			// prevent leaks here - this code should't be needed
			while (tempLineHolder.numChildren)
				tempLineHolder.removeChildAt(0);
		}
		
		private function removeAndRecycleTextLines (beginIndex:int, endIndex:int):void
		{
			var backgroundManager:BackgroundManager = textFlow.backgroundManager;
			
			var child:TextLine;
			while (beginIndex < endIndex)
			{
				child = _shapeChildren[beginIndex++];
				
				removeTextLine(child);
				CONFIG::debug { Debugging.traceFTECall(null,_container,"removeTextLine",child); }
				
				// Recycle if its not displayed and not connected to the textblock
				if (TextLineRecycler.textLineRecyclerEnabled && !child.parent)
				{
					if (child.userData == null)
					{
						TextLineRecycler.addLineForReuse(child);
						if (backgroundManager)
							backgroundManager.removeLineFromCache(child);
					}
					else if (child.validity == TextLineValidity.INVALID)
					{
						if (child.nextLine == null && child.previousLine == null && (!child.textBlock || child.textBlock.firstLine != child))
						{
							child.userData.releaseTextLine();
							child.userData = null;
							TextLineRecycler.addLineForReuse(child);
							if (backgroundManager)
								backgroundManager.removeLineFromCache(child);
						}
					}
				}
			}
		} 
		
		/**
		 * Gets the index at which the first text line must appear in its parent.
		 * The default implementation of this method, which may be overriden, returns the child index 
		 * of the first <code>flash.text.engine.TextLine</code> child of <code>container</code>
		 * if one exists, and that of the last child of <code>container</code> otherwise. 
		 * 
		 * @return the index at which the first text line must appear in its parent.
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * 
		 * @see flash.text.engine.TextLine
		 * @see #container
		 */	
		protected function getFirstTextLineChildIndex():int
		{			
			// skip past any non-TextLine children below the text in the container,
			// This also means that in a container devoid of text, we will always
			// populate the text starting at index container.numChildren, which is intentional.
			var firstTextLine:int;
			for(firstTextLine = 0; firstTextLine<_container.numChildren; ++firstTextLine)
			{
				if(_container.getChildAt(firstTextLine) is TextLine)
				{
					break;
				}
			}
			return firstTextLine;
		}
			 
		/**
		 * Adds a <code>flash.text.engine.TextLine</code> object as a descendant of <code>container</code>.
		 * The default implementation of this method, which may be overriden, adds the object
		 * as a direct child of <code>container</code> at the specified index.
		 * 
		 * @param textLine the <code>flash.text.engine.TextLine</code> object to add
		 * @param index insertion index of the text line in its parent 
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * 
		 * @see flash.text.engine.TextLine
		 * @see #container
		 * 
		 */	
		protected function addTextLine(textLine:TextLine, index:int):void
		{
			_container.addChildAt(textLine, index);
		}
		
		/**
		 * Removes a <code>flash.text.engine.TextLine</code> object from its parent. 
		 * The default implementation of this method, which may be overriden, removes the object
		 * from <code>container</code> if it is a direct child of the latter.
		 * 
		 * This method may be called even if the object is not a descendant of <code>container</code>.
		 * Any implementation of this method must ensure that no action is taken in this case.
		 * 
		 * @param textLine the <code>flash.text.engine.TextLine</code> object to remove 
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * 
		 * @see flash.text.engine.TextLine
		 * @see #container
		 * 
		 */	
		protected function removeTextLine(textLine:TextLine):void
		{
			if (_container.contains(textLine))
  				_container.removeChild(textLine);
		}

		/**
		 * Adds a <code>flash.display.Shape</code> object on which background shapes (such as background color) are drawn.
		 * The default implementation of this method, which may be overriden, adds the object to <code>container</code>
		 * just before the first <code>flash.text.engine.TextLine</code> child, if one exists, and after the last exisiting
		 * child otherwise. 
		 * 
		 * @param shape <code>flash.display.Shape</code> object to add
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * 
		 * @see flash.display.Shape
		 * @see flash.text.engine.TextLine
		 * @see #container
		 * 
		 */
		protected function addBackgroundShape(shape:Shape):void
		{
			_container.addChildAt(_backgroundShape, getFirstTextLineChildIndex());
		}
		
		/**
		 * Adds a <code>flash.display.DisplayObjectContainer</code> object to which selection shapes (such as block selection highlight, cursor etc.) are added.
		 * The default implementation of this method, which may be overriden, has the following behavior:
		 * The object is added just before first <code>flash.text.engine.TextLine</code> child of <code>container</code> if one exists 
		 * and the object is opaque and has normal blend mode. 
		 * In all other cases, it is added as the last child of <code>container</code>.
		 * 
		 * @param selectionContainer <code>flash.display.DisplayObjectContainer</code> object to add
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * 
		 * @see flash.display.DisplayObjectContainer
		 * @see flash.text.engine.TextLine
		 * @see #container
		 */
		protected function addSelectionContainer(selectionContainer:DisplayObjectContainer):void
		{
			if (selectionContainer.blendMode == BlendMode.NORMAL && selectionContainer.alpha == 1)
			{
				// don't put selection behind background color or existing content in container, put it behind first text line
				_container.addChildAt(selectionContainer, getFirstTextLineChildIndex());
			}
			else
				_container.addChild(selectionContainer);
		}
		
		/**
		 * Removes the <code>flash.display.DisplayObjectContainer</code> object which contains selection shapes (such as block selection highlight, cursor etc.).
		 * The default implementation of this method, which may be overriden, removes the object from its parent if one exists.
		 * 
		 * @param selectionContainer <code>flash.display.DisplayObjectContainer</code> object to remove
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * 
		 * @see flash.display.DisplayObjectContainer
		 * @see #container
		 * 
		 */
		protected function removeSelectionContainer(selectionContainer:DisplayObjectContainer):void
		{	
			selectionContainer.parent.removeChild(selectionContainer);
		}
		
		/**
		 * @private
		 */
		tlf_internal function get textLines():Array
		{
			return _shapeChildren;
		}
		
		/** 
		 * If scrolling, sets the scroll rectangle to the container rectangle so that any lines that are 
		 * halfway in view are clipped to the scrollable region. If not scrolling, clear the
		 * scroll rectangle so that no clipping occurs.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		 
		protected function updateVisibleRectangle() :void
		{
			if (horizontalScrollPolicy == ScrollPolicy.OFF && verticalScrollPolicy == ScrollPolicy.OFF)
			{
				if (_hasScrollRect)
				{
					_container.scrollRect = null;
					_hasScrollRect = false;
					
				}
			}
			else
			{
				var contentRight:Number = _contentLeft+contentWidth;
				var contentBottom:Number = _contentTop+contentHeight;
				var width:Number;
				var compositionRight:Number;
				if (_measureWidth)
				{
					width = contentWidth;
					compositionRight = _contentLeft + width
				}
				else
				{
					width = _compositionWidth;
					compositionRight = width;
				}
				var height:Number;
				var compositionBottom:Number;
				if (_measureHeight)
				{
					height = contentHeight;
					compositionBottom = _contentTop + height;
				}
				else
				{
					height = _compositionHeight;
					compositionBottom = height;
				}
				var xOrigin:Number = (effectiveBlockProgression == BlockProgression.RL) ? -width : 0;
				var xpos:int = horizontalScrollPosition + xOrigin;
				var ypos:int = verticalScrollPosition;
				
				if (textLength == 0 || xpos == 0 && ypos == 0 && _contentLeft >= xOrigin && _contentTop >= 0 && contentRight <= compositionRight && contentBottom <= compositionBottom)
				{
					if(_hasScrollRect)
					{
						_container.scrollRect = null;
						CONFIG::debug { Debugging.traceFTECall(null,_container,"clearContainerScrollRect()"); }
						_hasScrollRect = false;
					}
				}
				else 
				{
					// don't look at hasScrollRect but do look at scrollRect - client may have messed with it; okay to touch it because about to set it
					var rect:Rectangle = _container.scrollRect;
					if (!rect || rect.x != xpos || rect.y != ypos || rect.width != width || rect.height != height)
					{
						_container.scrollRect = new Rectangle(xpos, ypos, width, height);
						CONFIG::debug { Debugging.traceFTECall(null,_container,"setContainerScrollRect",xpos, ypos, width, height); }
						_hasScrollRect = true;
					}
				}
			}
			
			//Fix for Watson 2347938 - re-add the transparent background as the dimension of the
			//container are altered by sutting down the scrolls in vertical text.
			this.attachTransparentBackgroundForHit(false);
		}
		
		//include "../formats/TextLayoutFormatInc.as";
		
		// START OF TextLayoutFormatInc.as
		/**
		 * TextLayoutFormat:
		 * Color of the text. A hexadecimal number that specifies three 8-bit RGB (red, green, blue) values; for example, 0xFF0000 is red and 0x00FF00 is green. 
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of 0.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get color():*
		{
			return _formatValueHolder ? _formatValueHolder.color : undefined;
		}
		public function set color(colorValue:*):void
		{
			writableTextLayoutFormatValueHolder().color = colorValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Background color of the text (adopts default value if undefined during cascade). Can be either the constant value  <code>BackgroundColor.TRANSPARENT</code>, or a hexadecimal value that specifies the three 8-bit RGB (red, green, blue) values; for example, 0xFF0000 is red and 0x00FF00 is green.
		 * <p>Legal values as a string are flashx.textLayout.formats.BackgroundColor.TRANSPARENT, flashx.textLayout.formats.FormatValue.INHERIT and uints from 0x0 to 0xffffffff.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will have a value of TRANSPARENT.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.BackgroundColor
		 */
		public function get backgroundColor():*
		{
			return _formatValueHolder ? _formatValueHolder.backgroundColor : undefined;
		}
		public function set backgroundColor(backgroundColorValue:*):void
		{
			writableTextLayoutFormatValueHolder().backgroundColor = backgroundColorValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * If <code>true</code>, applies strikethrough, a line drawn through the middle of the text.
		 * <p>Legal values are true, false and flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of false.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get lineThrough():*
		{
			return _formatValueHolder ? _formatValueHolder.lineThrough : undefined;
		}
		public function set lineThrough(lineThroughValue:*):void
		{
			writableTextLayoutFormatValueHolder().lineThrough = lineThroughValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Alpha (transparency) value for the text. A value of 0 is fully transparent, and a value of 1 is fully opaque. Display objects with <code>textAlpha</code> set to 0 are active, even though they are invisible.
		 * <p>Legal values are numbers from 0 to 1 and flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of 1.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get textAlpha():*
		{
			return _formatValueHolder ? _formatValueHolder.textAlpha : undefined;
		}
		public function set textAlpha(textAlphaValue:*):void
		{
			writableTextLayoutFormatValueHolder().textAlpha = textAlphaValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Alpha (transparency) value for the background (adopts default value if undefined during cascade). A value of 0 is fully transparent, and a value of 1 is fully opaque. Display objects with alpha set to 0 are active, even though they are invisible.
		 * <p>Legal values are numbers from 0 to 1 and flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will have a value of 1.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get backgroundAlpha():*
		{
			return _formatValueHolder ? _formatValueHolder.backgroundAlpha : undefined;
		}
		public function set backgroundAlpha(backgroundAlphaValue:*):void
		{
			writableTextLayoutFormatValueHolder().backgroundAlpha = backgroundAlphaValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * The size of the text in pixels.
		 * <p>Legal values are numbers from 1 to 720 and flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of 12.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get fontSize():*
		{
			return _formatValueHolder ? _formatValueHolder.fontSize : undefined;
		}
		public function set fontSize(fontSizeValue:*):void
		{
			writableTextLayoutFormatValueHolder().fontSize = fontSizeValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Amount to shift the baseline from the <code>dominantBaseline</code> value. Units are in pixels, or a percentage of <code>fontSize</code> (in which case, enter a string value, like 140%).  Positive values shift the line up for horizontal text (right for vertical) and negative values shift it down for horizontal (left for vertical). 
		 * <p>Legal values are flashx.textLayout.formats.BaselineShift.SUPERSCRIPT, flashx.textLayout.formats.BaselineShift.SUBSCRIPT, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Legal values as a number are from -1000 to 1000.</p>
		 * <p>Legal values as a percent are numbers from -1000 to 1000.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of 0.0.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.BaselineShift
		 */
		public function get baselineShift():*
		{
			return _formatValueHolder ? _formatValueHolder.baselineShift : undefined;
		}
		public function set baselineShift(baselineShiftValue:*):void
		{
			writableTextLayoutFormatValueHolder().baselineShift = baselineShiftValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Number in pixels (or percent of <code>fontSize</code>, like 120%) indicating the amount of tracking (manual kerning) to be applied to the left of each character. If kerning is enabled, the <code>trackingLeft</code> value is added to the values in the kerning table for the font. If kerning is disabled, the <code>trackingLeft</code> value is used as a manual kerning value. Supports both positive and negative values. 
		 * <p>Legal values as a number are from -1000 to 1000.</p>
		 * <p>Legal values as a percent are numbers from -1000% to 1000%.</p>
		 * <p>Legal values include flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of 0.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get trackingLeft():*
		{
			return _formatValueHolder ? _formatValueHolder.trackingLeft : undefined;
		}
		public function set trackingLeft(trackingLeftValue:*):void
		{
			writableTextLayoutFormatValueHolder().trackingLeft = trackingLeftValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Number in pixels (or percent of <code>fontSize</code>, like 120%) indicating the amount of tracking (manual kerning) to be applied to the right of each character.  If kerning is enabled, the <code>trackingRight</code> value is added to the values in the kerning table for the font. If kerning is disabled, the <code>trackingRight</code> value is used as a manual kerning value. Supports both positive and negative values. 
		 * <p>Legal values as a number are from -1000 to 1000.</p>
		 * <p>Legal values as a percent are numbers from -1000% to 1000%.</p>
		 * <p>Legal values include flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of 0.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get trackingRight():*
		{
			return _formatValueHolder ? _formatValueHolder.trackingRight : undefined;
		}
		public function set trackingRight(trackingRightValue:*):void
		{
			writableTextLayoutFormatValueHolder().trackingRight = trackingRightValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Leading controls for the text. The distance from the baseline of the previous or the next line (based on <code>LeadingModel</code>) to the baseline of the current line is equal to the maximum amount of the leading applied to any character in the line. This is either a number or a percent.  If specifying a percent, enter a string value, like 140%.<p><img src='../../../images/textLayout_lineHeight1.jpg' alt='lineHeight1' /><img src='../../../images/textLayout_lineHeight2.jpg' alt='lineHeight2' /></p>
		 * <p>Legal values as a number are from -720 to 720.</p>
		 * <p>Legal values as a percent are numbers from -1000% to 1000%.</p>
		 * <p>Legal values include flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of 120%.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get lineHeight():*
		{
			return _formatValueHolder ? _formatValueHolder.lineHeight : undefined;
		}
		public function set lineHeight(lineHeightValue:*):void
		{
			writableTextLayoutFormatValueHolder().lineHeight = lineHeightValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Controls where lines are allowed to break when breaking wrapping text into multiple lines. Set to <code>BreakOpportunity.AUTO</code> to break text normally. Set to <code>BreakOpportunity.NONE</code> to <em>not</em> break the text unless the text would overrun the measure and there are no other places to break the line. Set to <code>BreakOpportunity.ANY</code> to allow the line to break anywhere, rather than just between words. Set to <code>BreakOpportunity.ALL</code> to have each typographic cluster put on a separate line (useful for text on a path).
		 * <p>Legal values are flash.text.engine.BreakOpportunity.ALL, flash.text.engine.BreakOpportunity.ANY, flash.text.engine.BreakOpportunity.AUTO, flash.text.engine.BreakOpportunity.NONE, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of AUTO.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flash.text.engine.BreakOpportunity
		 */
		public function get breakOpportunity():*
		{
			return _formatValueHolder ? _formatValueHolder.breakOpportunity : undefined;
		}
		public function set breakOpportunity(breakOpportunityValue:*):void
		{
			writableTextLayoutFormatValueHolder().breakOpportunity = breakOpportunityValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * The type of digit case used for this text. Setting the value to <code>DigitCase.OLD_STYLE</code> approximates lowercase letterforms with varying ascenders and descenders. The figures are proportionally spaced. This style is only available in selected typefaces, most commonly in a supplemental or expert font. The <code>DigitCase.LINING</code> setting has all-cap height and is typically monospaced to line up in charts.<p><img src='../../../images/textLayout_digitcase.gif' alt='digitCase' /></p>
		 * <p>Legal values are flash.text.engine.DigitCase.DEFAULT, flash.text.engine.DigitCase.LINING, flash.text.engine.DigitCase.OLD_STYLE, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of DEFAULT.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flash.text.engine.DigitCase
		 */
		public function get digitCase():*
		{
			return _formatValueHolder ? _formatValueHolder.digitCase : undefined;
		}
		public function set digitCase(digitCaseValue:*):void
		{
			writableTextLayoutFormatValueHolder().digitCase = digitCaseValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Type of digit width used for this text. This can be <code>DigitWidth.PROPORTIONAL</code>, which looks best for individual numbers, or <code>DigitWidth.TABULAR</code>, which works best for numbers in tables, charts, and vertical rows.<p><img src='../../../images/textLayout_digitwidth.gif' alt='digitWidth' /></p>
		 * <p>Legal values are flash.text.engine.DigitWidth.DEFAULT, flash.text.engine.DigitWidth.PROPORTIONAL, flash.text.engine.DigitWidth.TABULAR, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of DEFAULT.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flash.text.engine.DigitWidth
		 */
		public function get digitWidth():*
		{
			return _formatValueHolder ? _formatValueHolder.digitWidth : undefined;
		}
		public function set digitWidth(digitWidthValue:*):void
		{
			writableTextLayoutFormatValueHolder().digitWidth = digitWidthValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Specifies which element baseline snaps to the <code>alignmentBaseline</code> to determine the vertical position of the element on the line. A value of <code>TextBaseline.AUTO</code> selects the dominant baseline based on the <code>locale</code> property of the parent paragraph.  For Japanese and Chinese, the selected baseline value is <code>TextBaseline.IDEOGRAPHIC_CENTER</code>; for all others it is <code>TextBaseline.ROMAN</code>. These baseline choices are determined by the choice of font and the font size.<p><img src='../../../images/textLayout_baselines.jpg' alt='baselines' /></p>
		 * <p>Legal values are flashx.textLayout.formats.FormatValue.AUTO, flash.text.engine.TextBaseline.ROMAN, flash.text.engine.TextBaseline.ASCENT, flash.text.engine.TextBaseline.DESCENT, flash.text.engine.TextBaseline.IDEOGRAPHIC_TOP, flash.text.engine.TextBaseline.IDEOGRAPHIC_CENTER, flash.text.engine.TextBaseline.IDEOGRAPHIC_BOTTOM, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of flashx.textLayout.formats.FormatValue.AUTO.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flash.text.engine.TextBaseline
		 */
		public function get dominantBaseline():*
		{
			return _formatValueHolder ? _formatValueHolder.dominantBaseline : undefined;
		}
		public function set dominantBaseline(dominantBaselineValue:*):void
		{
			writableTextLayoutFormatValueHolder().dominantBaseline = dominantBaselineValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Kerning adjusts the pixels between certain character pairs to improve readability. Kerning is supported for all fonts with kerning tables.
		 * <p>Legal values are flash.text.engine.Kerning.ON, flash.text.engine.Kerning.OFF, flash.text.engine.Kerning.AUTO, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of AUTO.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flash.text.engine.Kerning
		 */
		public function get kerning():*
		{
			return _formatValueHolder ? _formatValueHolder.kerning : undefined;
		}
		public function set kerning(kerningValue:*):void
		{
			writableTextLayoutFormatValueHolder().kerning = kerningValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Controls which of the ligatures that are defined in the font may be used in the text. The ligatures that appear for each of these settings is dependent on the font. A ligature occurs where two or more letter-forms are joined as a single glyph. Ligatures usually replace consecutive characters sharing common components, such as the letter pairs 'fi', 'fl', or 'ae'. They are used with both Latin and Non-Latin character sets. The ligatures enabled by the values of the LigatureLevel class - <code>MINIMUM</code>, <code>COMMON</code>, <code>UNCOMMON</code>, and <code>EXOTIC</code> - are additive. Each value enables a new set of ligatures, but also includes those of the previous types.<p><b>Note: </b>When working with Arabic or Syriac fonts, <code>ligatureLevel</code> must be set to MINIMUM or above.</p><p><img src='../../../images/textLayout_ligatures.png' alt='ligatureLevel' /></p>
		 * <p>Legal values are flash.text.engine.LigatureLevel.MINIMUM, flash.text.engine.LigatureLevel.COMMON, flash.text.engine.LigatureLevel.UNCOMMON, flash.text.engine.LigatureLevel.EXOTIC, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of COMMON.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flash.text.engine.LigatureLevel
		 */
		public function get ligatureLevel():*
		{
			return _formatValueHolder ? _formatValueHolder.ligatureLevel : undefined;
		}
		public function set ligatureLevel(ligatureLevelValue:*):void
		{
			writableTextLayoutFormatValueHolder().ligatureLevel = ligatureLevelValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Specifies the baseline to which the dominant baseline aligns. For example, if you set <code>dominantBaseline</code> to ASCENT, setting <code>alignmentBaseline</code> to DESCENT aligns the top of the text with the DESCENT baseline, or below the line.  The largest element in the line generally determines the baselines.<p><img src='../../../images/textLayout_baselines.jpg' alt='baselines' /></p>
		 * <p>Legal values are flash.text.engine.TextBaseline.ROMAN, flash.text.engine.TextBaseline.ASCENT, flash.text.engine.TextBaseline.DESCENT, flash.text.engine.TextBaseline.IDEOGRAPHIC_TOP, flash.text.engine.TextBaseline.IDEOGRAPHIC_CENTER, flash.text.engine.TextBaseline.IDEOGRAPHIC_BOTTOM, flash.text.engine.TextBaseline.USE_DOMINANT_BASELINE, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of USE_DOMINANT_BASELINE.</p>
		 * @includeExample examples\TextLayoutFormat_alignmentBaselineExample.as -noswf
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flash.text.engine.TextBaseline
		 */
		public function get alignmentBaseline():*
		{
			return _formatValueHolder ? _formatValueHolder.alignmentBaseline : undefined;
		}
		public function set alignmentBaseline(alignmentBaselineValue:*):void
		{
			writableTextLayoutFormatValueHolder().alignmentBaseline = alignmentBaselineValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * The locale of the text. Controls case transformations and shaping. Standard locale identifiers as described in Unicode Technical Standard #35 are used. For example en, en_US and en-US are all English, ja is Japanese. 
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of en.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get locale():*
		{
			return _formatValueHolder ? _formatValueHolder.locale : undefined;
		}
		public function set locale(localeValue:*):void
		{
			writableTextLayoutFormatValueHolder().locale = localeValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * The type of typographic case used for this text. Here are some examples:<p><img src='../../../images/textLayout_typographiccase.png' alt='typographicCase' /></p>
		 * <p>Legal values are flashx.textLayout.formats.TLFTypographicCase.DEFAULT, flashx.textLayout.formats.TLFTypographicCase.CAPS_TO_SMALL_CAPS, flashx.textLayout.formats.TLFTypographicCase.UPPERCASE, flashx.textLayout.formats.TLFTypographicCase.LOWERCASE, flashx.textLayout.formats.TLFTypographicCase.LOWERCASE_TO_SMALL_CAPS, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of DEFAULT.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.TLFTypographicCase
		 */
		public function get typographicCase():*
		{
			return _formatValueHolder ? _formatValueHolder.typographicCase : undefined;
		}
		public function set typographicCase(typographicCaseValue:*):void
		{
			writableTextLayoutFormatValueHolder().typographicCase = typographicCaseValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 *  The name of the font to use, or a comma-separated list of font names. The Flash runtime renders the element with the first available font in the list. For example Arial, Helvetica, _sans causes the player to search for Arial, then Helvetica if Arial is not found, then _sans if neither is found.
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of Arial.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get fontFamily():*
		{
			return _formatValueHolder ? _formatValueHolder.fontFamily : undefined;
		}
		public function set fontFamily(fontFamilyValue:*):void
		{
			writableTextLayoutFormatValueHolder().fontFamily = fontFamilyValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Decoration on text. Use to apply underlining; default is none.
		 * <p>Legal values are flashx.textLayout.formats.TextDecoration.NONE, flashx.textLayout.formats.TextDecoration.UNDERLINE, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of NONE.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.TextDecoration
		 */
		public function get textDecoration():*
		{
			return _formatValueHolder ? _formatValueHolder.textDecoration : undefined;
		}
		public function set textDecoration(textDecorationValue:*):void
		{
			writableTextLayoutFormatValueHolder().textDecoration = textDecorationValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Weight of text. May be <code>FontWeight.NORMAL</code> for use in plain text, or <code>FontWeight.BOLD</code>. Applies only to device fonts (<code>fontLookup</code> property is set to flash.text.engine.FontLookup.DEVICE).
		 * <p>Legal values are flash.text.engine.FontWeight.NORMAL, flash.text.engine.FontWeight.BOLD, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of NORMAL.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flash.text.engine.FontWeight
		 */
		public function get fontWeight():*
		{
			return _formatValueHolder ? _formatValueHolder.fontWeight : undefined;
		}
		public function set fontWeight(fontWeightValue:*):void
		{
			writableTextLayoutFormatValueHolder().fontWeight = fontWeightValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Style of text. May be <code>FontPosture.NORMAL</code>, for use in plain text, or <code>FontPosture.ITALIC</code> for italic. This property applies only to device fonts (<code>fontLookup</code> property is set to flash.text.engine.FontLookup.DEVICE).
		 * <p>Legal values are flash.text.engine.FontPosture.NORMAL, flash.text.engine.FontPosture.ITALIC, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of NORMAL.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flash.text.engine.FontPosture
		 */
		public function get fontStyle():*
		{
			return _formatValueHolder ? _formatValueHolder.fontStyle : undefined;
		}
		public function set fontStyle(fontStyleValue:*):void
		{
			writableTextLayoutFormatValueHolder().fontStyle = fontStyleValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Collapses or preserves whitespace when importing text into a TextFlow. <code>WhiteSpaceCollapse.PRESERVE</code> retains all whitespace characters. <code>WhiteSpaceCollapse.COLLAPSE</code> removes newlines, tabs, and leading or trailing spaces within a block of imported text. Line break tags (<br/>) and Unicode line separator characters are retained.
		 * <p>Legal values are flashx.textLayout.formats.WhiteSpaceCollapse.PRESERVE, flashx.textLayout.formats.WhiteSpaceCollapse.COLLAPSE, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of COLLAPSE.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.WhiteSpaceCollapse
		 */
		public function get whiteSpaceCollapse():*
		{
			return _formatValueHolder ? _formatValueHolder.whiteSpaceCollapse : undefined;
		}
		public function set whiteSpaceCollapse(whiteSpaceCollapseValue:*):void
		{
			writableTextLayoutFormatValueHolder().whiteSpaceCollapse = whiteSpaceCollapseValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * The rendering mode used for this text.  Applies only to embedded fonts (<code>fontLookup</code> property is set to <code>FontLookup.EMBEDDED_CFF</code>).
		 * <p>Legal values are flash.text.engine.RenderingMode.NORMAL, flash.text.engine.RenderingMode.CFF, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of CFF.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flash.text.engine.RenderingMode
		 */
		public function get renderingMode():*
		{
			return _formatValueHolder ? _formatValueHolder.renderingMode : undefined;
		}
		public function set renderingMode(renderingModeValue:*):void
		{
			writableTextLayoutFormatValueHolder().renderingMode = renderingModeValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * The type of CFF hinting used for this text. CFF hinting determines whether the Flash runtime forces strong horizontal stems to fit to a sub pixel grid or not. This property applies only if the <code>renderingMode</code> property is set to <code>RenderingMode.CFF</code>, and the font is embedded (<code>fontLookup</code> property is set to <code>FontLookup.EMBEDDED_CFF</code>). At small screen sizes, hinting produces a clear, legible text for human readers.
		 * <p>Legal values are flash.text.engine.CFFHinting.NONE, flash.text.engine.CFFHinting.HORIZONTAL_STEM, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of HORIZONTAL_STEM.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flash.text.engine.CFFHinting
		 */
		public function get cffHinting():*
		{
			return _formatValueHolder ? _formatValueHolder.cffHinting : undefined;
		}
		public function set cffHinting(cffHintingValue:*):void
		{
			writableTextLayoutFormatValueHolder().cffHinting = cffHintingValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Font lookup to use. Specifying <code>FontLookup.DEVICE</code> uses the fonts installed on the system that is running the SWF file. Device fonts result in a smaller movie size, but text is not always rendered the same across different systems and platforms. Specifying <code>FontLookup.EMBEDDED_CFF</code> uses font outlines embedded in the published SWF file. Embedded fonts increase the size of the SWF file (sometimes dramatically), but text is consistently displayed in the chosen font.
		 * <p>Legal values are flash.text.engine.FontLookup.DEVICE, flash.text.engine.FontLookup.EMBEDDED_CFF, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of DEVICE.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flash.text.engine.FontLookup
		 */
		public function get fontLookup():*
		{
			return _formatValueHolder ? _formatValueHolder.fontLookup : undefined;
		}
		public function set fontLookup(fontLookupValue:*):void
		{
			writableTextLayoutFormatValueHolder().fontLookup = fontLookupValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Determines the number of degrees to rotate this text.
		 * <p>Legal values are flash.text.engine.TextRotation.ROTATE_0, flash.text.engine.TextRotation.ROTATE_180, flash.text.engine.TextRotation.ROTATE_270, flash.text.engine.TextRotation.ROTATE_90, flash.text.engine.TextRotation.AUTO, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of AUTO.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flash.text.engine.TextRotation
		 */
		public function get textRotation():*
		{
			return _formatValueHolder ? _formatValueHolder.textRotation : undefined;
		}
		public function set textRotation(textRotationValue:*):void
		{
			writableTextLayoutFormatValueHolder().textRotation = textRotationValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * A Number that specifies, in pixels, the amount to indent the first line of the paragraph.
		 * A negative indent will push the line into the margin, and possibly out of the container.
		 * <p>Legal values are numbers from -1000 to 1000 and flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of 0.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get textIndent():*
		{
			return _formatValueHolder ? _formatValueHolder.textIndent : undefined;
		}
		public function set textIndent(textIndentValue:*):void
		{
			writableTextLayoutFormatValueHolder().textIndent = textIndentValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * A Number that specifies, in pixels, the amount to indent the paragraph's start edge. Refers to the left edge in left-to-right text and the right edge in right-to-left text. 
		 * <p>Legal values are numbers from 0 to 1000 and flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of 0.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get paragraphStartIndent():*
		{
			return _formatValueHolder ? _formatValueHolder.paragraphStartIndent : undefined;
		}
		public function set paragraphStartIndent(paragraphStartIndentValue:*):void
		{
			writableTextLayoutFormatValueHolder().paragraphStartIndent = paragraphStartIndentValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * A Number that specifies, in pixels, the amount to indent the paragraph's end edge. Refers to the right edge in left-to-right text and the left edge in right-to-left text. 
		 * <p>Legal values are numbers from 0 to 1000 and flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of 0.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get paragraphEndIndent():*
		{
			return _formatValueHolder ? _formatValueHolder.paragraphEndIndent : undefined;
		}
		public function set paragraphEndIndent(paragraphEndIndentValue:*):void
		{
			writableTextLayoutFormatValueHolder().paragraphEndIndent = paragraphEndIndentValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * A Number that specifies the amount of space, in pixels, to leave before the paragraph. 
		 * Collapses in tandem with <code>paragraphSpaceAfter</code>.
		 * <p>Legal values are numbers from 0 to 1000 and flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of 0.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get paragraphSpaceBefore():*
		{
			return _formatValueHolder ? _formatValueHolder.paragraphSpaceBefore : undefined;
		}
		public function set paragraphSpaceBefore(paragraphSpaceBeforeValue:*):void
		{
			writableTextLayoutFormatValueHolder().paragraphSpaceBefore = paragraphSpaceBeforeValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * A Number that specifies the amount of space, in pixels, to leave after the paragraph.
		 * Collapses in tandem with  <code>paragraphSpaceBefore</code>.
		 * <p>Legal values are numbers from 0 to 1000 and flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of 0.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get paragraphSpaceAfter():*
		{
			return _formatValueHolder ? _formatValueHolder.paragraphSpaceAfter : undefined;
		}
		public function set paragraphSpaceAfter(paragraphSpaceAfterValue:*):void
		{
			writableTextLayoutFormatValueHolder().paragraphSpaceAfter = paragraphSpaceAfterValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Alignment of lines in the paragraph relative to the container.
		 * <code>TextAlign.LEFT</code> aligns lines along the left edge of the container. <code>TextAlign.RIGHT</code> aligns on the right edge. <code>TextAlign.CENTER</code> positions the line equidistant from the left and right edges. <code>TextAlign.JUSTIFY</code> spreads the lines out so they fill the space. <code>TextAlign.START</code> is equivalent to setting left in left-to-right text, or right in right-to-left text. <code>TextAlign.END</code> is equivalent to setting right in left-to-right text, or left in right-to-left text.
		 * <p>Legal values are flashx.textLayout.formats.TextAlign.LEFT, flashx.textLayout.formats.TextAlign.RIGHT, flashx.textLayout.formats.TextAlign.CENTER, flashx.textLayout.formats.TextAlign.JUSTIFY, flashx.textLayout.formats.TextAlign.START, flashx.textLayout.formats.TextAlign.END, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of START.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.TextAlign
		 */
		public function get textAlign():*
		{
			return _formatValueHolder ? _formatValueHolder.textAlign : undefined;
		}
		public function set textAlign(textAlignValue:*):void
		{
			writableTextLayoutFormatValueHolder().textAlign = textAlignValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Alignment of the last (or only) line in the paragraph relative to the container in justified text.
		 * If <code>textAlign</code> is set to <code>TextAlign.JUSTIFY</code>, <code>textAlignLast</code> specifies how the last line (or only line, if this is a one line block) is aligned. Values are similar to <code>textAlign</code>.
		 * <p>Legal values are flashx.textLayout.formats.TextAlign.LEFT, flashx.textLayout.formats.TextAlign.RIGHT, flashx.textLayout.formats.TextAlign.CENTER, flashx.textLayout.formats.TextAlign.JUSTIFY, flashx.textLayout.formats.TextAlign.START, flashx.textLayout.formats.TextAlign.END, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of START.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.TextAlign
		 */
		public function get textAlignLast():*
		{
			return _formatValueHolder ? _formatValueHolder.textAlignLast : undefined;
		}
		public function set textAlignLast(textAlignLastValue:*):void
		{
			writableTextLayoutFormatValueHolder().textAlignLast = textAlignLastValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Specifies options for justifying text.
		 * Default value is <code>TextJustify.INTER_WORD</code>, meaning that extra space is added to the space characters. <code>TextJustify.DISTRIBUTE</code> adds extra space to space characters and between individual letters. Used only in conjunction with a <code>justificationRule</code> value of <code>JustificationRule.SPACE</code>.
		 * <p>Legal values are flashx.textLayout.formats.TextJustify.INTER_WORD, flashx.textLayout.formats.TextJustify.DISTRIBUTE, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of INTER_WORD.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.TextJustify
		 */
		public function get textJustify():*
		{
			return _formatValueHolder ? _formatValueHolder.textJustify : undefined;
		}
		public function set textJustify(textJustifyValue:*):void
		{
			writableTextLayoutFormatValueHolder().textJustify = textJustifyValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Rule used to justify text in a paragraph.
		 * Default value is <code>FormatValue.AUTO</code>, which justifies text based on the paragraph's <code>locale</code> property. For all languages except Japanese and Chinese, <code>FormatValue.AUTO</code> becomes <code>JustificationRule.SPACE</code>, which adds extra space to the space characters.  For Japanese and Chinese, <code>FormatValue.AUTO</code> becomes <code>JustficationRule.EAST_ASIAN</code>. In part, justification changes the spacing of punctuation. In Roman text the comma and Japanese periods take a full character's width but in East Asian text only half of a character's width. Also, in the East Asian text the spacing between sequential punctuation marks becomes tighter, obeying traditional East Asian typographic conventions. Note, too, in the example below the leading that is applied to the second line of the paragraphs. In the East Asian version, the last two lines push left. In the Roman version, the second and following lines push left.<p><img src='../../../images/textLayout_justificationrule.png' alt='justificationRule' /></p>
		 * <p>Legal values are flashx.textLayout.formats.JustificationRule.EAST_ASIAN, flashx.textLayout.formats.JustificationRule.SPACE, flashx.textLayout.formats.FormatValue.AUTO, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of flashx.textLayout.formats.FormatValue.AUTO.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.JustificationRule
		 */
		public function get justificationRule():*
		{
			return _formatValueHolder ? _formatValueHolder.justificationRule : undefined;
		}
		public function set justificationRule(justificationRuleValue:*):void
		{
			writableTextLayoutFormatValueHolder().justificationRule = justificationRuleValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * The style used for justification of the paragraph. Used only in conjunction with a <code>justificationRule</code> setting of <code>JustificationRule.EAST_ASIAN</code>.
		 * Default value of <code>FormatValue.AUTO</code> is resolved to <code>JustificationStyle.PUSH_IN_KINSOKU</code> for all locales.  The constants defined by the JustificationStyle class specify options for handling kinsoku characters, which are Japanese characters that cannot appear at either the beginning or end of a line. If you want looser text, specify <code>JustificationStyle.PUSH-OUT-ONLY</code>. If you want behavior that is like what you get with the  <code>justificationRule</code> of <code>JustificationRule.SPACE</code>, use <code>JustificationStyle.PRIORITIZE-LEAST-ADJUSTMENT</code>.
		 * <p>Legal values are flash.text.engine.JustificationStyle.PRIORITIZE_LEAST_ADJUSTMENT, flash.text.engine.JustificationStyle.PUSH_IN_KINSOKU, flash.text.engine.JustificationStyle.PUSH_OUT_ONLY, flashx.textLayout.formats.FormatValue.AUTO, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of flashx.textLayout.formats.FormatValue.AUTO.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flash.text.engine.JustificationStyle
		 */
		public function get justificationStyle():*
		{
			return _formatValueHolder ? _formatValueHolder.justificationStyle : undefined;
		}
		public function set justificationStyle(justificationStyleValue:*):void
		{
			writableTextLayoutFormatValueHolder().justificationStyle = justificationStyleValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Specifies the default bidirectional embedding level of the text in the text block. 
		 * Left-to-right reading order, as in Latin-style scripts, or right-to-left reading order, as in Arabic or Hebrew. This property also affects column direction when it is applied at the container level. Columns can be either left-to-right or right-to-left, just like text. Below are some examples:<p><img src='../../../images/textLayout_direction.gif' alt='direction' /></p>
		 * <p>Legal values are flashx.textLayout.formats.Direction.LTR, flashx.textLayout.formats.Direction.RTL, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of LTR.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.Direction
		 */
		public function get direction():*
		{
			return _formatValueHolder ? _formatValueHolder.direction : undefined;
		}
		public function set direction(directionValue:*):void
		{
			writableTextLayoutFormatValueHolder().direction = directionValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Specifies the tab stops associated with the paragraph.
		 * Setters can take an array of flashx.textLayout.formats.TabStopFormat, a condensed string representation, undefined, or <code>FormatValue.INHERIT</code>. The condensed string representation is always converted into an array of flashx.textLayout.formats.TabStopFormat. <p>The string-based format is a list of tab stops, where each tab stop is delimited by one or more spaces.</p><p>A tab stop takes the following form: &lt;alignment type&gt;&lt;alignment position&gt;|&lt;alignment token&gt;.</p><p>The alignment type is a single character, and can be S, E, C, or D (or lower-case equivalents). S or s for start, E or e for end, C or c for center, D or d for decimal. The alignment type is optional, and if its not specified will default to S.</p><p>The alignment position is a Number, and is specified according to FXG spec for Numbers (decimal or scientific notation). The alignment position is required.</p><p>The vertical bar is used to separate the alignment position from the alignment token, and should only be present if the alignment token is present.</p><p> The alignment token is optional if the alignment type is D, and should not be present if the alignment type is anything other than D. The alignment token may be any sequence of characters terminated by the space that ends the tab stop (for the last tab stop, the terminating space is optional; end of alignment token is implied). A space may be part of the alignment token if it is escaped with a backslash (\ ). A backslash may be part of the alignment token if it is escaped with another backslash (\\). If the alignment type is D, and the alignment token is not specified, it will take on the default value of null.</p><p>If no tab stops are specified, a tab action defaults to the end of the line.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of null.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get tabStops():*
		{
			return _formatValueHolder ? _formatValueHolder.tabStops : undefined;
		}
		public function set tabStops(tabStopsValue:*):void
		{
			writableTextLayoutFormatValueHolder().tabStops = tabStopsValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Specifies the leading model, which is a combination of leading basis and leading direction.
		 * Leading basis is the baseline to which the <code>lineHeight</code> property refers. Leading direction determines whether the <code>lineHeight</code> property refers to the distance of a line's baseline from that of the line before it or the line after it. The default value of <code>FormatValue.AUTO</code> is resolved based on the paragraph's <code>locale</code> property.  For Japanese and Chinese, it is <code>LeadingModel.IDEOGRAPHIC_TOP_DOWN</code> and for all others it is <code>LeadingModel.ROMAN_UP</code>.<p><strong>Leading Basis:</strong></p><p><img src='../../../images/textLayout_LB1.png' alt='leadingBasis1' />    <img src='../../../images/textLayout_LB2.png' alt='leadingBasis2' />    <img src='../../../images/textLayout_LB3.png' alt='leadingBasis3' /></p><p><strong>Leading Direction:</strong></p><p><img src='../../../images/textLayout_LD1.png' alt='leadingDirection1' />    <img src='../../../images/textLayout_LD2.png' alt='leadingDirection2' />    <img src='../../../images/textLayout_LD3.png' alt='leadingDirection3' /></p>
		 * <p>Legal values are flashx.textLayout.formats.LeadingModel.ROMAN_UP, flashx.textLayout.formats.LeadingModel.IDEOGRAPHIC_TOP_UP, flashx.textLayout.formats.LeadingModel.IDEOGRAPHIC_CENTER_UP, flashx.textLayout.formats.LeadingModel.IDEOGRAPHIC_TOP_DOWN, flashx.textLayout.formats.LeadingModel.IDEOGRAPHIC_CENTER_DOWN, flashx.textLayout.formats.LeadingModel.APPROXIMATE_TEXT_FIELD, flashx.textLayout.formats.LeadingModel.ASCENT_DESCENT_UP, flashx.textLayout.formats.LeadingModel.AUTO, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of AUTO.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.LeadingModel
		 */
		public function get leadingModel():*
		{
			return _formatValueHolder ? _formatValueHolder.leadingModel : undefined;
		}
		public function set leadingModel(leadingModelValue:*):void
		{
			writableTextLayoutFormatValueHolder().leadingModel = leadingModelValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Specifies the amount of gutter space, in pixels, to leave between the columns (adopts default value if undefined during cascade).
		 * Value is a Number
		 * <p>Legal values are numbers from 0 to 1000 and flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will have a value of 20.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get columnGap():*
		{
			return _formatValueHolder ? _formatValueHolder.columnGap : undefined;
		}
		public function set columnGap(columnGapValue:*):void
		{
			writableTextLayoutFormatValueHolder().columnGap = columnGapValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Left inset in pixels (adopts default value if undefined during cascade).
		 * Space between the left edge of the container and the text.  Value is a Number.<p> With vertical text, in scrollable containers with multiple columns, the first and following columns will show the padding as blank space at the end of the container, but for the last column, if the text doesn't all fit, you may have to scroll in order to see the padding.</p>
		 * <p>Legal values are numbers from 0 to 1000 and flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will have a value of 0.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get paddingLeft():*
		{
			return _formatValueHolder ? _formatValueHolder.paddingLeft : undefined;
		}
		public function set paddingLeft(paddingLeftValue:*):void
		{
			writableTextLayoutFormatValueHolder().paddingLeft = paddingLeftValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Top inset in pixels (adopts default value if undefined during cascade).
		 * Space between the top edge of the container and the text.  Value is a Number.
		 * <p>Legal values are numbers from 0 to 1000 and flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will have a value of 0.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get paddingTop():*
		{
			return _formatValueHolder ? _formatValueHolder.paddingTop : undefined;
		}
		public function set paddingTop(paddingTopValue:*):void
		{
			writableTextLayoutFormatValueHolder().paddingTop = paddingTopValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Right inset in pixels (adopts default value if undefined during cascade).
		 * Space between the right edge of the container and the text.  Value is a Number.
		 * <p>Legal values are numbers from 0 to 1000 and flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will have a value of 0.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get paddingRight():*
		{
			return _formatValueHolder ? _formatValueHolder.paddingRight : undefined;
		}
		public function set paddingRight(paddingRightValue:*):void
		{
			writableTextLayoutFormatValueHolder().paddingRight = paddingRightValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Botttom inset in pixels (adopts default value if undefined during cascade).
		 * Space between the bottom edge of the container and the text.  Value is a Number. <p> With horizontal text, in scrollable containers with multiple columns, the first and following columns will show the padding as blank space at the bottom of the container, but for the last column, if the text doesn't all fit, you may have to scroll in order to see the padding.</p>
		 * <p>Legal values are numbers from 0 to 1000 and flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will have a value of 0.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get paddingBottom():*
		{
			return _formatValueHolder ? _formatValueHolder.paddingBottom : undefined;
		}
		public function set paddingBottom(paddingBottomValue:*):void
		{
			writableTextLayoutFormatValueHolder().paddingBottom = paddingBottomValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Number of text columns (adopts default value if undefined during cascade).
		 * The column number overrides the  other column settings. Value is an integer, or <code>FormatValue.AUTO</code> if unspecified. If <code>columnCount</code> is not specified,<code>columnWidth</code> is used to create as many columns as can fit in the container.
		 * <p>Legal values as a string are flashx.textLayout.formats.FormatValue.AUTO, flashx.textLayout.formats.FormatValue.INHERIT and from ints from 1 to 50.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will have a value of AUTO.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.FormatValue
		 */
		public function get columnCount():*
		{
			return _formatValueHolder ? _formatValueHolder.columnCount : undefined;
		}
		public function set columnCount(columnCountValue:*):void
		{
			writableTextLayoutFormatValueHolder().columnCount = columnCountValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Column width in pixels (adopts default value if undefined during cascade).
		 * If you specify the width of the columns, but not the count, TextLayout will create as many columns of that width as possible, given the  container width and <code>columnGap</code> settings. Any remainder space is left after the last column. Value is a Number.
		 * <p>Legal values as a string are flashx.textLayout.formats.FormatValue.AUTO, flashx.textLayout.formats.FormatValue.INHERIT and numbers from 0 to 8000.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will have a value of AUTO.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.FormatValue
		 */
		public function get columnWidth():*
		{
			return _formatValueHolder ? _formatValueHolder.columnWidth : undefined;
		}
		public function set columnWidth(columnWidthValue:*):void
		{
			writableTextLayoutFormatValueHolder().columnWidth = columnWidthValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Specifies the baseline position of the first line in the container. Which baseline this property refers to depends on the container-level locale.  For Japanese and Chinese, it is <code>TextBaseline.IDEOGRAPHIC_BOTTOM</code>; for all others it is <code>TextBaseline.ROMAN</code>.
		 * The offset from the top inset (or right inset if <code>blockProgression</code> is RL) of the container to the baseline of the first line can be either <code>BaselineOffset.ASCENT</code>, meaning equal to the ascent of the line, <code>BaselineOffset.LINE_HEIGHT</code>, meaning equal to the height of that first line, or any fixed-value number to specify an absolute distance. <code>BaselineOffset.AUTO</code> aligns the ascent of the line with the container top inset.<p><img src='../../../images/textLayout_FBO1.png' alt='firstBaselineOffset1' /><img src='../../../images/textLayout_FBO2.png' alt='firstBaselineOffset2' /><img src='../../../images/textLayout_FBO3.png' alt='firstBaselineOffset3' /><img src='../../../images/textLayout_FBO4.png' alt='firstBaselineOffset4' /></p>
		 * <p>Legal values as a string are flashx.textLayout.formats.BaselineOffset.AUTO, flashx.textLayout.formats.BaselineOffset.ASCENT, flashx.textLayout.formats.BaselineOffset.LINE_HEIGHT, flashx.textLayout.formats.FormatValue.INHERIT and numbers from 0 to 1000.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of AUTO.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.BaselineOffset
		 */
		public function get firstBaselineOffset():*
		{
			return _formatValueHolder ? _formatValueHolder.firstBaselineOffset : undefined;
		}
		public function set firstBaselineOffset(firstBaselineOffsetValue:*):void
		{
			writableTextLayoutFormatValueHolder().firstBaselineOffset = firstBaselineOffsetValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Vertical alignment or justification (adopts default value if undefined during cascade).
		 * Determines how TextFlow elements align within the container.
		 * <p>Legal values are flashx.textLayout.formats.VerticalAlign.TOP, flashx.textLayout.formats.VerticalAlign.MIDDLE, flashx.textLayout.formats.VerticalAlign.BOTTOM, flashx.textLayout.formats.VerticalAlign.JUSTIFY, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will have a value of TOP.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.VerticalAlign
		 */
		public function get verticalAlign():*
		{
			return _formatValueHolder ? _formatValueHolder.verticalAlign : undefined;
		}
		public function set verticalAlign(verticalAlignValue:*):void
		{
			writableTextLayoutFormatValueHolder().verticalAlign = verticalAlignValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Specifies a vertical or horizontal progression of line placement.
		 * Lines are either placed top-to-bottom (<code>BlockProgression.TB</code>, used for horizontal text) or right-to-left (<code>BlockProgression.RL</code>, used for vertical text).
		 * <p>Legal values are flashx.textLayout.formats.BlockProgression.RL, flashx.textLayout.formats.BlockProgression.TB, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will inherit its value from an ancestor. If no ancestor has set this property, it will have a value of TB.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.BlockProgression
		 */
		public function get blockProgression():*
		{
			return _formatValueHolder ? _formatValueHolder.blockProgression : undefined;
		}
		public function set blockProgression(blockProgressionValue:*):void
		{
			writableTextLayoutFormatValueHolder().blockProgression = blockProgressionValue;
			formatChanged();
		}
		
		/**
		 * TextLayoutFormat:
		 * Controls word wrapping within the container (adopts default value if undefined during cascade).
		 * Text in the container may be set to fit the width of the container (<code>LineBreak.TO_FIT</code>), or can be set to break only at explicit return or line feed characters (<code>LineBreak.EXPLICIT</code>).
		 * <p>Legal values are flashx.textLayout.formats.LineBreak.EXPLICIT, flashx.textLayout.formats.LineBreak.TO_FIT, flashx.textLayout.formats.FormatValue.INHERIT.</p>
		 * <p>Default value is undefined indicating not set.</p>
		 * <p>If undefined during the cascade this property will have a value of TO_FIT.</p>
		 * 
		 * @throws RangeError when set value is not within range for this property
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 * @see flashx.textLayout.formats.LineBreak
		 */
		public function get lineBreak():*
		{
			return _formatValueHolder ? _formatValueHolder.lineBreak : undefined;
		}
		public function set lineBreak(lineBreakValue:*):void
		{
			writableTextLayoutFormatValueHolder().lineBreak = lineBreakValue;
			formatChanged();
		}
		
		// END OF TextLayoutFormatInc.as
		
		/** 
		 * The <code>userStyles</code> object for a ContainerController instance.  The getter makes a copy of the 
		 * <code>userStyles</code> object, which is an array of <em>stylename-value</em> pairs.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
		 */
		public function get userStyles():Object
		{
			var styles:Object = _formatValueHolder == null ? null : _formatValueHolder.userStyles;
			return styles ? Property.shallowCopy(styles) : null;
		}
		public function set userStyles(styles:Object):void
		{
			var newStyles:Object = new Object();
			for (var val:Object in styles)
				newStyles[val] = styles[val];
			writableTextLayoutFormatValueHolder().userStyles = newStyles;
			formatChanged(); // modelChanged(ModelChange.USER_STYLE_CHANGED,0,this.textLength,true);
		}

		/** Returns the <code>coreStyles</code> on this ContainerController.  Note that the getter makes a copy of the core 
		 * styles dictionary. The coreStyles object encapsulates those formats that are defined by TextLayoutFormat. The
		 * <code>coreStyles</code> object consists of an array of <em>stylename-value</em> pairs.
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
		 */
		 
		public function get coreStyles():Object
		{
			var styles:Object = _formatValueHolder == null ? null : _formatValueHolder.coreStyles;
			return styles ? Property.shallowCopy(styles) : null;
		}		
		
		/** 
		 * Stores the ITextLayoutFormat object that contains the attributes for this container. 
		 * The controller inherits the container properties from the TextFlow of which it is part. 
		 * This property allows different controllers in the same text flow to have, for example, 
		 * different column settings or padding.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @see flashx.textLayout.formats.ITextLayoutFormat
	 	 */
		public function get format():ITextLayoutFormat
		{ return _formatValueHolder; }
		public function set format(value:ITextLayoutFormat):void
		{
			formatInternal = value;
			formatChanged();
		}
		
		private function writableTextLayoutFormatValueHolder():FlowValueHolder
		{
			if (_formatValueHolder == null)
				_formatValueHolder = new FlowValueHolder();
			return _formatValueHolder;
		}

		/** Sets the _format data member. No side effects.
		 * @private
		 */
		tlf_internal function set formatInternal(value:ITextLayoutFormat):void
		{	
			if (value == null)
			{
				if (_formatValueHolder == null || _formatValueHolder.coreStyles == null)
					return; // no change
				_formatValueHolder.coreStyles = null;
			}
			else
				writableTextLayoutFormatValueHolder().format = value;
		}

		/** Returns the value of the style specified by the <code>styleProp</code> parameter.
		 *
		 * @param styleProp The name of the style property whose value you want.
		 *
		 * @return	The current value for the specified style.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 */
		public function getStyle(styleProp:String):*
		{
			if (TextLayoutFormat.description.hasOwnProperty(styleProp))
				return computedFormat[styleProp];
			return getUserStyleWorker(styleProp);
		}
		
		/** 
		* Sets the value of the style specified by the <code>styleProp</code> parameter to the value
		* specified by the <code>newValue</code> parameter.
		*
		* @param styleProp The name of the style property whose value you want to set.
		* @param newValue The value that you want to assign to the style.
		*
		* @playerversion Flash 10
		* @playerversion AIR 1.5
	 	* @langversion 3.0
		*/
		
		public function setStyle(styleProp:String,newValue:*):void
		{
			if (TextLayoutFormat.description[styleProp] !== undefined)
				this[styleProp] = newValue;
			else
			{
				_formatValueHolder.setUserStyle(styleProp,newValue);
				formatChanged(); // modelChanged(ModelChange.USER_STYLE_CHANGED,0,this.textLength,true);
			}
		}
		
		/** Clears the style specified by <code>styleProp</code> from this FlowElement. Sets the value to
		 * <code>undefined</code>.
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 */
		public function clearStyle(styleProp:String):void
		{ setStyle(styleProp,undefined); }
		
		/** @private worker function - any styleProp */
		tlf_internal function getUserStyleWorker(styleProp:String):*
		{
			CONFIG::debug { assert(TextLayoutFormat.description[styleProp] === undefined,"bad call to getUserStyleWorker"); }
				
			var userStyle:* = _formatValueHolder.getUserStyle(styleProp)
			if (userStyle !== undefined)
				return userStyle;
				
			var tf:TextFlow = _rootElement ? _rootElement.getTextFlow() : null;
			if (tf && tf.formatResolver)
			{
				userStyle = tf.formatResolver.resolveUserFormat(this,styleProp);
				if (userStyle !== undefined)
					return userStyle;
			}
			// or should it go to the container?
			return _rootElement ? _rootElement.getUserStyleWorker(styleProp) : undefined;
		}
		
		/** 
		 * Returns an ITextLayoutFormat instance with the attributes applied to this container, including the attributes inherited from its
   		 * root element.
		 * 
		 * @return 	object that describes the container's attributes.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @see #rootElement
	 	 */
		public function get computedFormat():ITextLayoutFormat
		{
			if (!_computedFormat)
			{
				FlowElement._scratchTextLayoutFormat.format = formatForCascade;
				var element:FlowElement = _rootElement;
				if (element)
				{
					while (1)
					{
						var attrs:ITextLayoutFormat = ContainerFormattedElement(element).formatForCascade;
						if (attrs)
							FlowElement._scratchTextLayoutFormat.concatInheritOnly(attrs);
						if (element.parent == null)
							break;
						element = element.parent;
					}
				}
				var defaultFormat:ITextLayoutFormat;
				var defaultFormatHash:uint;
				var tf:TextFlow = element as TextFlow;
				if (tf)
				{
					defaultFormat = tf.getDefaultFormat();
					defaultFormatHash = tf.getDefaultFormatHash();
				}
				_computedFormat= TextFlow.getCanonical(FlowElement._scratchTextLayoutFormat,defaultFormat,defaultFormatHash);
				
				resetColumnState();
			}
			return _computedFormat;
		}
		
		/** @private */
		tlf_internal function get formatForCascade():ITextLayoutFormat
		{
			if (_rootElement)
			{
				var tf:TextFlow = _rootElement.getTextFlow();
				if (tf)
				{
					var elemStyle:ITextLayoutFormat  = tf.getTextLayoutFormatStyle(this);
					if (elemStyle)
					{
						var localFormat:ITextLayoutFormat = format;
						if (localFormat == null)
							return elemStyle;
							
						var rslt:TextLayoutFormat = new TextLayoutFormat(elemStyle);
						rslt.apply(localFormat);
						return rslt;
					}
				}
			}
			return format;
		}
		
		/** @private */
		tlf_internal function getPlacedTextLineBounds(textLine:TextLine):Rectangle
		{
			var curBounds:Rectangle;
			if (!textLine.parent)
			{
				// Has to be in the container to get the bounds
				addTextLine(textLine,0);
				curBounds = textLine.getBounds(_container);
				removeTextLine(textLine);
			}
			else
			{
				// Note: Relative to its parent, which may not be _container
				// but in all reasonable cases, should share its origin with _container -- really???
				curBounds = textLine.getBounds(textLine.parent);
			}
				
			return curBounds;
		}
			
		/** @private */
		tlf_internal function getInteractionHandler():IInteractionEventHandler
		{ return this; }
	}

}
import flash.events.MouseEvent;
import flash.display.InteractiveObject;
	
class PsuedoMouseEvent extends MouseEvent
{
	public function PsuedoMouseEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false, localX:Number = NaN, localY:Number = NaN, relatedObject:InteractiveObject = null, ctrlKey:Boolean = false, altKey:Boolean = false, shiftKey:Boolean = false, buttonDown:Boolean = false)
	{
		super(type,bubbles,cancelable,localX,localY,relatedObject,ctrlKey,altKey,shiftKey,buttonDown);
	}
	public override function get currentTarget():Object
	{ return relatedObject; }
	public override function get target():Object
	{ return relatedObject; }
}
