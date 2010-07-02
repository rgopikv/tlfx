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
package flashx.textLayout.elements
{
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.compose.IFlowComposer;
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.debug.Debugging;
	import flashx.textLayout.debug.assert;
	import flashx.textLayout.events.ModelChange;
	import flashx.textLayout.formats.FlowElementDisplayType;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormatValueHolder;
	import flashx.textLayout.property.Property;
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;
	
	[IMXMLObject]	

/**
 * The text in a flow is stored in tree form with the elements of the tree representing logical
 * divisions within the text. The FlowElement class is the abstract base class of all the objects in this tree.
 * FlowElement objects represent paragraphs, spans of text within paragraphs, and
 * groups of paragraphs.
 *
 * <p>The root of a composable FlowElement tree is always a TextFlow object. Leaf elements of the tree are always 
 * subclasses of the FlowLeafElement class. All leaves arranged in a composable TextFlow have a ParagraphElement ancestor.
 * </p> 
 *
 * <p>You cannot create a FlowElement object directly. Invoking <code>new FlowElement()</code> throws an error 
 * exception.</p>
 *
 * @playerversion Flash 10
 * @playerversion AIR 1.5
 * @langversion 3.0
 * 
 * @see FlowGroupElement
 * @see FlowLeafElement
 * @see InlineGraphicElement
 * @see ParagraphElement
 * @see SpanElement
 * @see TextFlow
 */
	public class FlowElement implements ITextLayoutFormat
	{
		//	[KK]	Added to figure out if the leaf is an original from HTML or has been put in to follow the TLF hierarchy
		protected var _original:Boolean;
		
		
		/** every FlowElement has at most one parent */
		private var _parent:FlowGroupElement;
		
		/** format settings on this FlowElement */
		private var _formatValueHolder:FlowValueHolder;
		
		/** @private computed formats applied to the element */
		protected var _computedFormat:ITextLayoutFormat;
		
		/** start, _start of element, relative to parent.  */
		private var _parentRelativeStart:int = 0;		
		
		/** _textLength (number of chars) in the element, including child content */
		private var _textLength:int = 0;	
		
		/**
		 * [TA] :: Added uid to allow client to set a unique identifier for the FlowElement 
		 */
		public var uid:String;
	
		/** Base class - invoking <code>new FlowElement()</code> throws an error exception.
		*
		* @playerversion Flash 10
		* @playerversion AIR 1.5
	 	* @langversion 3.0
	 	*/
		public function FlowElement()
		{
			// not a valid FlowElement class
			if (abstract)
				throw new Error(GlobalSettings.resourceStringFunction("invalidFlowElementConstruct"));
			
			_original = false;
		}
		
		/** Called for MXML objects after the implementing object has been created and all component properties specified on the MXML tag have been initialized. 
		 * @param document The MXML document that created the object.
		 * @param id The identifier used by document to refer to this object.
		 **/
		public function initialized(document:Object, id:String):void
		{
			this.id = id;
		}

		/** Returns true if the class is an abstract base class,
		 * false if its OK to construct. Attempting to instantiate an
		 * abstract FlowElement class will cause an exception.
		 * @return Boolean 	true if this is an abstract class
		 * @private
		 */
		protected function get abstract():Boolean
		{
			return true;
		}
		
		/** Allows you to read and write user styles on a FlowElement object.  Note that reading this property
		* makes a copy of the user-styles dictionary. 
		*
		* @playerversion Flash 10
		* @playerversion AIR 1.5
	 	* @langversion 3.0
		*
		*/
		public function get userStyles():Object
		{
			var styles:Object = _formatValueHolder == null ? null : _formatValueHolder.userStyles;
			return styles ? Property.shallowCopy(styles) : null;
		}
		public function set userStyles(styles:Object):void
		{
			var newStyles:Object;
			if (styles)
			{
				newStyles = new Object();
				for (var val:Object in styles)
					newStyles[val] = styles[val];
			}
			writableTextLayoutFormatValueHolder().userStyles = newStyles;
			modelChanged(ModelChange.USER_STYLE_CHANGED,0,this.textLength,true);
		}
		
		/** Returns the core styles on a FlowElement instance. Returns a copy of the core styles. 
		 *  
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
		 *
		 */
		 
		public function get coreStyles():Object
		{
			var styles:Object = _formatValueHolder == null ? null : _formatValueHolder.coreStyles;
			return styles ? Property.shallowCopy(styles) : null;
		}
		
		/** @private */
		tlf_internal function setCoreStylesInternal(styles:Object):void
		{
			var newStyles:Object;
			if (styles)
			{
				newStyles = new Object();
				for (var val:Object in styles)
				{
					var value:* = styles[val];
					if (value != undefined)
						newStyles[val] = value;
				}
			}
			writableTextLayoutFormatValueHolder().coreStyles = newStyles;
			formatChanged();		
		}
		
		/** Defines the formatting attributes used for links in normal state. This value will cascade down the hierarchy and apply to any links that are descendants.
		 * Equivalent to setStyle(linkNormalFormat,value).  Expects a dictionary of properties.  Converts an array of objects with key and value as members to a dictionary. */
		public function set linkNormalFormat(value:*):void
		{ setStyle(LinkElement.LINK_NORMAL_FORMAT_NAME,value); }
		public function get linkNormalFormat():*
		{ return getStyle(LinkElement.LINK_NORMAL_FORMAT_NAME); }
		
		/** Defines the formatting attributes used for links in active state, when the mouse is down on a link. This value will cascade down the hierarchy and apply to any links that are descendants.
		 * Equivalent to setStyle(linkActiveFormat,value).  Expects a dictionary of properties.  Converts an array of objects with key and value as members to a dictionary. */
		public function set linkActiveFormat(value:*):void
		{ setStyle(LinkElement.LINK_ACTIVE_FORMAT_NAME,value); }
		public function get linkActiveFormat():*
		{ return getStyle(LinkElement.LINK_ACTIVE_FORMAT_NAME); }
		
		/** Defines the formatting attributes used for links in hover state, when the mouse is within the bounds (rolling over) a link. This value will cascade down the hierarchy and apply to any links that are descendants.
		 * Equivalent to setStyle(linkHoverFormat,value).  Expects a dictionary of properties.  Converts an array of objects with key and value as members to a dictionary. */
		public function set linkHoverFormat(value:*):void
		{ setStyle(LinkElement.LINK_HOVER_FORMAT_NAME,value); }
		public function get linkHoverFormat():*
		{ return getStyle(LinkElement.LINK_HOVER_FORMAT_NAME); }
		
		/** Compare the userStyles of this with otherElement's userStyles. 
		 *
		 * @param otherElement the FlowElement object with which to compare user styles
		 *
		 * @return 	true if the user styles are equal; false otherwise.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
	 	 * @includeExample examples\FlowElement_equalUserStylesExample.as -noswf
	 	 * 
	 	 * @see #getStyle()
	 	 * @see #setStyle()
	 	 * @see #userStyles
		 */
		public function equalUserStyles(otherElement:FlowElement):Boolean
		{
			var myStyles:Object = _formatValueHolder ? _formatValueHolder.userStyles : null;
			var elemStyles:Object = otherElement._formatValueHolder ? otherElement._formatValueHolder.userStyles : null;
			return Property.equalStyleObjects(myStyles,elemStyles);
		}
		
		/** @private Compare the styles of two elements for merging.  Return true if they can be merged. */
		tlf_internal function equalStylesForMerge(elem:FlowElement):Boolean
		{
			return this.id == elem.id && this.styleName == elem.styleName && TextLayoutFormat.isEqual(elem.format,format) && equalUserStyles(elem);
		}
		
		/**
		 * Makes a copy of this FlowElement object, copying the content between two specified character positions.
		 * It returns the copy as a new FlowElement object. Unlike <code>deepCopy()</code>, <code>shallowCopy()</code> does
		 * not copy any of the children of this FlowElement object. 
		 * 
		 * <p>With no arguments, <code>shallowCopy()</code> defaults to copying all of the content.</p>
		 *
		 * @param relativeStart	The relative text position of the first character to copy. First position is 0.
		 * @param relativeEnd	The relative text position of the last character to copy. A value of -1 indicates copy to end.
		 *
		 * @return 	the object created by the copy operation.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @includeExample examples\FlowElement_shallowCopyExample.as -noswf
		 *
	 	 * @see #deepCopy()
	 	 */
		 
		public function shallowCopy(relativeStart:int = 0, relativeEnd:int = -1):FlowElement
		{
			if (relativeEnd == -1)
				relativeEnd = textLength;
				
			var retFlow:FlowElement = new (getDefinitionByName(getQualifiedClassName(this)) as Class);
			retFlow.styleName = styleName;
			retFlow.id = id;	// ???? copy me ?????
			//	[KK]	Mark as an original
			retFlow.original = true;
			// [TA] :: Added setting uid on shallow copy.
			retFlow.uid = uid;
			// [TA] :: Passing original
			retFlow.original = _original;
			if (_formatValueHolder !=  null)
				retFlow._formatValueHolder = new FlowValueHolder(_formatValueHolder);
			return retFlow;
		}

		/**
		 * Makes a deep copy of this FlowElement object, including any children, copying the content between the two specified
		 * character positions and returning the copy as a FlowElement object.
		 * 
		 * <p>With no arguments, <code>deepCopy()</code> defaults to copying the entire element.</p>
		 * 
		 * @param relativeStart	relative text position of the first character to copy. First position is 0.
		 * @param relativeEnd	relative text position of the last character to copy. A value of -1 indicates copy to end.
		 *
		 * @return 	the object created by the deep copy operation.
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @includeExample examples\FlowElement_deepCopyExample.as -noswf
	 	 * 
	 	 * @see #shallowCopy()
		 */
		 
		public function deepCopy(relativeStart:int = 0, relativeEnd:int = -1):FlowElement
		{
			if (relativeEnd == -1)
				relativeEnd = textLength;
				
			return shallowCopy(relativeStart, relativeEnd);
		}
		
		/** 
		 * Gets the specified range of text from a flow element.
		 * 
		 * @param relativeStart The starting position of the range of text to be retrieved, relative to the start of the FlowElement
		 * @param relativeEnd The ending position of the range of text to be retrieved, relative to the start of the FlowElement, -1 for up to the end of the element
		 * @param paragraphSeparator character to put between paragraphs
		 * 
		 * @return The requested text.
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
		 */
		public function getText(relativeStart:int=0, relativeEnd:int=-1, paragraphSeparator:String="\n"):String
		{
			return "";
		}

		/** 
		 * Splits this FlowElement object at the position specified by the <code>relativePosition</code> parameter, which is
		 * a relative position in the text for this element. This method splits only SpanElement and FlowGroupElement 
		 * objects.
		 *
		 * @param relativePosition the position at which to split the content of the original object, with the first position being 0.
		 * 
		 * @return	the new object, which contains the content of the original object, starting at the specified position.
		 *
		 * @throws RangeError if <code>relativePosition</code> is greater than <code>textLength</code>, or less than 0.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
		 */
		 
		public function splitAtPosition(relativePosition:int):FlowElement
		{
			if ((relativePosition < 0) || (relativePosition > textLength))
				throw RangeError(GlobalSettings.resourceStringFunction("invalidSplitAtPosition"));
			return this;
		}
		
		/** @private Set to indicate the element may be "bound" in Flex - only used on FlowLeafElement and SubParagraphBlock elements. */
		tlf_internal function get bindableElement():Boolean
		{ return getPrivateStyle("bindable") == true; }
		
		/** @private */
		tlf_internal function set bindableElement(value:Boolean):void
		{ setPrivateStyle("bindable", value); }

		
		/** Merge flow element into previous flow element if possible. @private
		 * @Return true--> did the merge
		 */
		 
		tlf_internal function mergeToPreviousIfPossible():Boolean
		{
			return false;
		}
		
		/** @private 
		 * Create and initialize the FTE data structure that corresponds to the FlowElement
		 */
		tlf_internal function createContentElement():void
		{
			// overridden in the base class -- we should not get here
			CONFIG::debug { assert(false,"invalid call to createContentElement"); }
		}
		
		/** @private 
		 * Release the FTE data structure that corresponds to the FlowElement, so it can be gc'ed
		 */
		tlf_internal function releaseContentElement():void
		{
			// overridden in the base class -- we should not get here
			CONFIG::debug { assert(false,"invalid call to createContentElement"); }
		}

		/** @private 
		 * True if it is safe to release the corresponding FTE data structure.
		 */
		tlf_internal function canReleaseContentElement():Boolean
		{
			return true;
		}
		
		/** Returns the parent of this FlowElement object. Every FlowElement has at most one parent.
		*
		* @playerversion Flash 10
		* @playerversion AIR 1.5
	 	* @langversion 3.0
	 	*/
	 	
		public function get parent():FlowGroupElement
		{ return _parent; }
		
		/** parent setter. @private */
		
		tlf_internal function setParentAndRelativeStart(newParent:FlowGroupElement,newStart:int):void
		{ _parent = newParent; _parentRelativeStart = newStart; attributesChanged(false); }
		
				
		/** Used when the textBlock.content is already correctly configured. @private */
		tlf_internal function setParentAndRelativeStartOnly(newParent:FlowGroupElement,newStart:int):void
		{ _parent = newParent;  _parentRelativeStart = newStart; }
			
		/**
		 * Returns the total length of text owned by this FlowElement object and its children.  If an element has no text, the 
		 * value of <code>textLength</code> is usually zero. 
		 * 
		 * <p>ParagraphElement objects have a final span with a paragraph terminator character for the last 
		 * SpanElement object.The paragraph terminator is included in the value of the <code>textLength</code> of that 
		 * SpanElement object and all its parents.  It is not included in <code>text</code> property of the SpanElement
		 * object.</p>
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @see #textLength
		 */
		 
		public function get textLength():int
		{ return _textLength; }
		
		/** textLength setter.  @private */
		tlf_internal function setTextLength(newLength:int):void
		{ _textLength = newLength; }	
		
		/** Returns the relative start of this FlowElement object in the parent. If parent is null, this value is always zero.  
		 * If parent is not null, the value is the sum of the text lengths of all previous siblings.
		 *
		 * @return offset
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 * 
	 	 * @see #textLength
		 */
		 
		public function get parentRelativeStart():int
		{ return _parentRelativeStart; }
		
		/** start setter. @private */
		tlf_internal function setParentRelativeStart(newStart:int):void
		{ _parentRelativeStart = newStart; }
		
		/** Returns the relative end of this FlowElement object in the parent. If the parent is null this is always equal to <code>textLength</code>.  If 
		 * the parent is not null, the value is the sum of the text lengths of this and all previous siblings, which is effectively
		 * the first character in the next FlowElement object.
		 *
		 * @return offset
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @see FlowGroupElement
	 	 * @see #textLength
		 */
		 
		public function get parentRelativeEnd():int
		{ return _parentRelativeStart + _textLength; }
				
		/**
		 * Tag for the item, used for debugging.
		 */
		CONFIG::debug public function get name():String
		{
			return flash.utils.getQualifiedClassName(this);
		}
		
		/** Returns the ContainerFormattedElement that specifies its containers for filling. This ContainerFormattedElement
		 * object has its own columns and can control ColumnDirection and BlockProgression. 
		 *
		 * @return 	the ancestor, with its container, of this FlowElement object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 * 
	 	 * @private
		 */
		 
		tlf_internal function getAncestorWithContainer():ContainerFormattedElement
		{
			var elem:FlowElement = this;
			while (elem)
			{
				var contElement:ContainerFormattedElement = elem as ContainerFormattedElement;
				if (contElement)
				{
					if (!contElement._parent || contElement.flowComposer)
						return contElement;
				}
				elem = elem._parent; 
			}
			return null;
		}
		
		
		/**
		 * @private
		 * Generic mechanism for fetching private data from the element.
		 * @param styleName	name of the property
		 */
		tlf_internal function getPrivateStyle(styleName:String):*
		{ return _formatValueHolder ? _formatValueHolder.getPrivateData(styleName) : undefined; }

		/**
		 * @private
		 * Generic mechanism for adding private data to the element.
		 * @param styleName	name of the property
		 * @param val value of the property
		 */
		tlf_internal function setPrivateStyle(styleName:String, val:*):void
		{
			if (getPrivateStyle(styleName) != val)
			{
				writableTextLayoutFormatValueHolder().setPrivateData(styleName,val);
				modelChanged(ModelChange.STYLE_SELECTOR_CHANGED,0,this.textLength);
			}
		}
		
		private static const idString:String ="id";

		/**
		 * Assigns an identifying name to the element, making it possible to set a style for the element
		 * by referencing the <code>id</code>. For example, the following line sets the color for
		 * a SpanElement object that has an id of span1:
		 *
		 * <listing version="3.0" >
		 * textFlow.getElementByID("span1").setStyle("color", 0xFF0000);
		 * </listing>
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @see TextFlow#getElementByID()
		 */
		public function get id():String
		{ return getPrivateStyle(idString); }
		public function set id(val:String):void
		{ return setPrivateStyle(idString, val);	}
		
		private static const styleNameString:String ="styleName";

		/**
		 * Assigns an identifying class to the element, making it possible to set a style for the element
		 * by referencing the <code>styleName</code>. 
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 */
		public function get styleName():String
		{ return getPrivateStyle(styleNameString); }
		public function set styleName(val:String):void
		{ return setPrivateStyle(styleNameString, val);	}
		
		private static const impliedElementString:String = "impliedElement";
		/** @private */
		tlf_internal function get impliedElement():Boolean
		{
			return getPrivateStyle(impliedElementString) !== undefined;
		}
		tlf_internal function set impliedElement(value:Boolean):void
		{
			setPrivateStyle(impliedElementString, "true");
		}
				
		// **************************************** 
		// Begin TLFFormat Related code
		// ****************************************
		//include "../formats/TextLayoutFormatInc.as"
		
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
		
		// END of TextLayoutFormatInc
		
		/** TextLayoutFormat properties applied directly to this element.
		 * <p>Each element may have properties applied to it as part of its format. Properties applied to this element override properties inherited from the parent. Properties applied to this element will in turn be inherited by element's children if they are not overridden on the child. If no properties are applied to the element, this will be null.</p>
		 * @see flashx.textLayout.formats.ITextLayoutFormat
		 */
		public function get format():ITextLayoutFormat
		{ return _formatValueHolder; }
		public function set format(value:ITextLayoutFormat):void
		{
			if (value == null)
			{
				if (_formatValueHolder == null || _formatValueHolder.coreStyles == null)
					return; // no change
				_formatValueHolder.coreStyles = null;
			}
			else
				writableTextLayoutFormatValueHolder().format = value;
			formatChanged();
		}
		
		private function writableTextLayoutFormatValueHolder():FlowValueHolder
		{
			if (_formatValueHolder == null)
				_formatValueHolder = new FlowValueHolder();
			return _formatValueHolder;
		}

		/** This gets called when an element has changed its attributes. This may happen because an
		 * ancestor element changed it attributes.
		 * @private 
		 */
		tlf_internal function formatChanged(notifyModelChanged:Boolean = true):void
		{
			if (notifyModelChanged)
				modelChanged(ModelChange.TEXTLAYOUT_FORMAT_CHANGED,0,textLength);
			// wipe out whatever values were cached
			_computedFormat = null;
		}
		
		/** 
		 * Concatenates tlf attributes with any other tlf attributes
		 * 
		 * Return the concatenated result
		 * 
		 * @private
		 */
		tlf_internal function get formatForCascade():ITextLayoutFormat
		{
			var tf:TextFlow = getTextFlow();
			if (tf)
			{
				var elemStyle:ITextLayoutFormat  = tf.getTextLayoutFormatStyle(this);
				if (elemStyle)
				{
					var localFormat:ITextLayoutFormat = format;
					if (localFormat == null)
						return elemStyle;
						
					var rslt:TextLayoutFormatValueHolder = new TextLayoutFormatValueHolder();
					rslt.apply(elemStyle);
					rslt.apply(localFormat);
					return rslt;
				}
			}
			return format;
		}
		
		/** @private  Shared scratch element for use in computedFormat methods only */
		static tlf_internal var _scratchTextLayoutFormat:TextLayoutFormatValueHolder = new TextLayoutFormatValueHolder();
		
		/** 
		 * Returns the computed format attributes that are in effect for this element.
		 * Takes into account the inheritance of attributes from parent elements.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
		 * @see flashx.textLayout.formats.ITextLayoutFormat ITextLayoutFormat
		 */

		public function get computedFormat():ITextLayoutFormat
		{		
			if (!_computedFormat)
				doComputeTextLayoutFormat(formatForCascade);
			return _computedFormat;
		}
		
		/** @private */
		tlf_internal function doComputeTextLayoutFormat(formatForCascade:ITextLayoutFormat):void
		{
			var element:FlowElement = parent;
			var parentFormatForCascade:ITextLayoutFormat;
			
			if (element)
			{
				parentFormatForCascade = element.formatForCascade;
				if (TextLayoutFormat.isEqual(formatForCascade,TextLayoutFormat.emptyTextLayoutFormat) && TextLayoutFormat.isEqual(parentFormatForCascade,TextLayoutFormat.emptyTextLayoutFormat))
				{
					_computedFormat = element.computedFormat;
					return;
				}
			}
			
			var tf:TextFlow;
			// compute the cascaded attributes	
			_scratchTextLayoutFormat.format = formatForCascade;
			if (element)
			{
				if (parentFormatForCascade)
					_scratchTextLayoutFormat.concatInheritOnly(parentFormatForCascade);
				while (element.parent)
				{
					element = element.parent;
					var concatAttrs:ITextLayoutFormat = element.formatForCascade;
					if (concatAttrs)
						_scratchTextLayoutFormat.concatInheritOnly(concatAttrs);
				}
				tf = element as TextFlow;
			}
			else
				tf = this as TextFlow;
			var defaultFormat:ITextLayoutFormat;
			var defaultFormatHash:uint;
			if (tf)
			{
				defaultFormat = tf.getDefaultFormat();
				defaultFormatHash = tf.getDefaultFormatHash();
			}
			_computedFormat = TextFlow.getCanonical(_scratchTextLayoutFormat,defaultFormat,defaultFormatHash);
		}

		// **************************************** 
		// End CharacterFormat Related code
		// ****************************************

		
		/** @private */
		tlf_internal function attributesChanged(notifyModelChanged:Boolean = true):void
		{
			// TODO: REMOVE ME???
			formatChanged(notifyModelChanged);
		}
		
		/** Returns the value of the style specified by the <code>styleProp</code> parameter, which specifies
		 * the style name and can include any user style name. Accesses an existing span, paragraph, text flow,
		 * or container style. Searches the parent tree if the style's value is <code>undefined</code> on a 
		 * particular element.
		 *
		 * @param styleProp The name of the style whose value is to be retrieved.
		 *
		 * @return The value of the specified style. The type varies depending on the type of the style being
		 * accessed. Returns <code>undefined</code> if the style is not set.
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @includeExample examples\FlowElement_getStyleExample.as -noswf
	 	 *
	 	 * @see #clearStyle()
		 * @see #setStyle()
		 * @see #userStyles
		 */
		public function getStyle(styleProp:String):*
		{
			if (TextLayoutFormat.description.hasOwnProperty(styleProp))
				return computedFormat[styleProp];
			return getUserStyleWorker(styleProp);
		}
		
		/** Sets the style specified by the <code>styleProp</code> parameter to the value specified by the
		* <code>newValue</code> parameter. You can set a span, paragraph, text flow, or container style, including
		* any user name-value pair.
		*
		* <p><strong>Note:</strong> If you assign a custom style, Text Layout Framework can import and export it but
		* compiled MXML cannot support it.</p>
		*
		* @param styleProp The name of the style to set.
		* @param newValue The value to which to set the style.
		*.
		* @playerversion Flash 10
		* @playerversion AIR 1.5
		* @langversion 3.0
		*
		* @includeExample examples\FlowElement_setStyleExample.as -noswf
		*		
		* @see #clearStyle()
		* @see #getStyle()
		* @see #userStyles
		*/
		public function setStyle(styleProp:String,newValue:*):void
		{
			if (TextLayoutFormat.description[styleProp] !== undefined)
				this[styleProp] = newValue;
			else
			{
				writableTextLayoutFormatValueHolder().setUserStyle(styleProp,newValue);
				modelChanged(ModelChange.USER_STYLE_CHANGED,0,this.textLength,true);
			}
		}
		
		/** Clears the style specified by the <code>styleProp</code> parameter from this FlowElement object. Sets 
		 * the value to <code>undefined</code>.
		 *
		 * @param styleProp The name of the style to clear.
		 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
		 * @langversion 3.0
		 *
		 * @includeExample examples\FlowElement_clearStyleExample.as -noswf
		 *
		 * @see #getStyle()
		 * @see #setStyle()
		 * @see #userStyles
		 * 
		 */
		public function clearStyle(styleProp:String):void
		{ setStyle(styleProp,undefined); }
		
		/** @private worker function - any styleProp */
		tlf_internal function getUserStyleWorker(styleProp:String):*
		{
			CONFIG::debug { assert(TextLayoutFormat.description[styleProp] === undefined,"bad call to getUserStyleWorker"); }
			
			if (_formatValueHolder != null)
			{
				var userStyle:* = _formatValueHolder.getUserStyle(styleProp)
				if (userStyle !== undefined)
					return userStyle;
			}
				
			var tf:TextFlow = getTextFlow();
			if (tf && tf.formatResolver)
			{
				userStyle = tf.formatResolver.resolveUserFormat(this,styleProp);
				if (userStyle !== undefined)
					return userStyle;
			}
			// TODO: does TextFlow need to ask a "psuedo parent"				
			return parent ? parent.getUserStyleWorker(styleProp) : undefined;
		}
		
		/**
		 * Called whenever the model is modified.  Updates the TextFlow and notifies the selection manager - if it is set.
		 * This method has to be called while the element is still in the flow
		 * @param changeType - type of change
		 * @param start - elem relative offset of start of damage
		 * @param len - length of damage
		 * @see flow.model.ModelChange
		 * @private
		 */
		tlf_internal function modelChanged(changeType:String, changeStart:int, changeLen:int, needNormalize:Boolean = true, bumpGeneration:Boolean = true):void
		{
			var tf:TextFlow = this.getTextFlow();
			if (tf)
				tf.processModelChanged(changeType, this, changeStart, changeLen, needNormalize, bumpGeneration);
		}
		
		/** @private */
		tlf_internal function appendElementsForDelayedUpdate(tf:TextFlow):void
		{ }
		
		/** @private */
		tlf_internal function applyDelayedElementUpdate(textFlow:TextFlow,okToUnloadGraphics:Boolean,hasController:Boolean):void
		{ }
						
		// **************************************** 
		// Begin display property Related code
		// ****************************************
		/**
		 * Indicates how the element should be composed. It may be either inline, and appear as part of a line, or be float, 
		 * in which case it appears in a container of its own.
		 * 
		 * @see text.elements.FlowElementDisplayType#INLINE
		 * @see text.elements.FlowElementDisplayType#FLOAT
		 * 
		 * This feature still in prototype phase - has to be the main namespace so it is accessible through mxml
		 * @private
		 */
		public function get display():String
		{
			return FlowElementDisplayType.INLINE;
		}
		
		// **************************************** 
		// End display property Related code
		// ****************************************	

 		// **************************************** 
		// Begin tracking property Related code
		// ****************************************

		/**
		 * Sets the tracking and is synonymous with the <code>trackingRight</code> property. Specified as a number of
		 * pixels or a percent of <code>fontSize</code>.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @see #trackingRight
		 */
		public function set tracking(trackingValue:Object):void
		{
			trackingRight = trackingValue;
		}
		
		// **************************************** 
		// End tracking property Related code
		// ****************************************	

		// **************************************** 
		// Begin import helper code
		// ****************************************			

		/**
		 * Create the default container for the element. @private
		 */
		tlf_internal function createGeometry(parentToBe:DisplayObjectContainer):void
		{
			return;
		}
		
		/** Strips white space from the element and its children, according to the whitespaceCollaspse
		 *  value that has been applied to the element or inherited from its parent.
		 *  If a FlowLeafElement's attrs are set to WhiteSpaceCollapse.PRESERVE, then collapse is
		 *  skipped.
		 *  @see text.formats.WhiteSpaceCollapse
		 * @private 
		 */
		tlf_internal function applyWhiteSpaceCollapse():void
		{
			if (_formatValueHolder && _formatValueHolder.whiteSpaceCollapse !== undefined)
				whiteSpaceCollapse = undefined;
			
			setPrivateStyle(impliedElementString, undefined);
		}
				
		// **************************************** 
		// End import helper code
		// ****************************************	

		// **************************************** 
		// Begin helper code for tables
		// ****************************************			
		
		/** Determines whether a particular FlowElement should be treated as a single selection.
		 * @private
		 */
		tlf_internal function isReadOnlyFlowElement():Boolean
		{
			return false;
		}

		/** Gets the highest parent that is a read only flow element
		 * @private
		 */		
		tlf_internal function getHighestReadOnlyFlowElement():FlowElement
		{
			var highestReadOnlyFlowElement:FlowElement = null;
			if (this.isReadOnlyFlowElement())
			{
				highestReadOnlyFlowElement = this;
			}
			
			var curFlowElement:FlowElement = parent;
			while (curFlowElement != null)
			{
				if (curFlowElement.isReadOnlyFlowElement())
				{
					highestReadOnlyFlowElement = curFlowElement;
				}
				curFlowElement = curFlowElement.parent;
			}
			return highestReadOnlyFlowElement;
		}
		
		// **************************************** 
		// End helper code for tables
		// ****************************************							

		// **************************************** 
		// Begin tree navigation code
		// ****************************************
		
		 /**
		 * Returns the start location of the element in the text flow as an absolute index. The first character in the flow
		 * is position 0.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
		 * 
		 * @includeExample examples\FlowElement_getAbsoluteStartExample.as -noswf
		 *
 		 * @return The index of the start of the element from the start of the TextFlow object.
 		 *
 		 * @see #parentRelativeStart
 		 * @see #TextFlow
	 	 */
	 	 
		public function getAbsoluteStart():int
		{
			var rslt:int = parentRelativeStart;
			for (var elem:FlowElement = parent; elem; elem = elem.parent)
				rslt += elem.parentRelativeStart;
			return rslt;
		}
		
		/**
		 * Returns the start of this element relative to an ancestor element. Assumes that the
		 * ancestor element is in the parent chain. If the ancestor element is the parent, this is the
		 * same as <code>this.parentRelativeStart</code>.  If the ancestor element is the grandparent, this is the same as 
		 * <code>parentRelativeStart</code> plus <code>parent.parentRelativeStart</code> and so on.
		 * 
		 * @param ancestorElement The element from which you want to find the relative start of this element.
		 *
		 * @return  the offset of this element.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @includeExample examples\FlowElement_getElementRelativeStartExample.as -noswf
		 * 
		 * @see #getAbsoluteStart()
		 */
		 
		public function getElementRelativeStart(ancestorElement:FlowElement):int
		{
			var rslt:int = parentRelativeStart;
			for (var elem:FlowElement = parent; elem && elem != ancestorElement; elem = elem.parent)
				rslt += elem.parentRelativeStart;
			return rslt;
		}
		
		/**
		 * Climbs the text flow hierarchy to return the root TextFlow object for the element.
		 *
		 * @return	The root TextFlow object for this FlowElement object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @includeExample examples\FlowElement_getTextFlowExample.as -noswf
	 	 *
	 	 * @see TextFlow
		 */
		 
		public function getTextFlow():TextFlow
		{
			// find the root element entry and either return null or the containing textFlow
			var elem:FlowElement = this;
			while (elem.parent != null)
				elem = elem.parent;
			return elem as TextFlow;		
		}	

		/**
		 * Returns the ParagraphElement object associated with this element. It looks up the text flow hierarchy and returns 
		 * the first ParagraphElement object.
		 *
		 * @return	the ParagraphElement object that's associated with this FlowElement object.
		 *
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0
	 	 *
	 	 * @includeExample examples\FlowElement_getParagraphExample.as -noswf
	 	 * 
	 	 * @see #getTextFlow()
	 	 * @see ParagraphElement
		 */
		 
		public function getParagraph():ParagraphElement
		{
			var rslt:FlowElement = this;
			while (rslt)
			{
				if (rslt is ParagraphElement)
					return rslt as ParagraphElement;
				rslt = rslt.parent;
			}
			return null;
		}
		
		
		/** 
		 * Returns the FlowElement object that contains this FlowElement object, if this element is contained within 
		 * an element of a particular type. 
		 * 
		 * Returns the FlowElement it is contained in. Otherwise, it returns null.
		 * 
		 * @private
		 *
		 * @param elementType	type of element for which to check
		 */
		public function getParentByType(elementType:Class):FlowElement
		{
			var curElement:FlowElement = parent;
			while (curElement)
			{
				if (curElement is elementType)
					return curElement;
				curElement = curElement.parent;
			}
			return null;
		}
		
		/** Returns the previous FlowElement sibling in the text flow hierarchy. 
		*
		* @includeExample examples\FlowElement_getPreviousSiblingExample.as -noswf
		*
		* @return 	the previous FlowElement object of the same type, or null if there is no previous sibling.
		*
		* @playerversion Flash 10
		* @playerversion AIR 1.5
	 	* @langversion 3.0
	 	*
	 	* @see #getNextSibling()
		*/
		public function getPreviousSibling():FlowElement
		{
			//this can happen if FE is on the scrap and doesn't have a parent. - gak 06.25.08
			if(!parent)
				return null;
				
			var idx:int = parent.getChildIndex(this);
			return idx == 0 ? null : parent.getChildAt(idx-1);
		}
		
		/** Returns the next FlowElement sibling in the text flow hierarchy. 
		*
		* @return the next FlowElement object of the same type, or null if there is no sibling.
		*
		* @includeExample examples\FlowElement_getNextSiblingExample.as -noswf
		*
		* @playerversion Flash 10
		* @playerversion AIR 1.5
	 	* @langversion 3.0
	 	*
	 	* @see #getPreviousSibling()
	 	*/
	 	
		public function getNextSibling():FlowElement
		{
			if (!parent)
				return null;

			var idx:int = parent.getChildIndex(this);
			return idx == parent.numChildren-1 ? null : parent.getChildAt(idx+1);
		}
		
		/** 
		* Returns the character at the specified position, relative to this FlowElement object. The first
		* character is at relative position 0.
		* 
		* @param relativePosition	The relative position of the character in this FlowElement object.
		* @return String containing the character.
		*
		* @playerversion Flash 10
		* @playerversion AIR 1.5
	 	* @langversion 3.0
	 	*
	 	* @includeExample examples\FlowElement_getCharAtPositionExample.as -noswf
	 	* 
	 	* @see #getCharCodeAtPosition()
	 	*/
		
		public function getCharAtPosition(relativePosition:int):String
		{
			return null;
		}
		
		/** Returns the character code at the specified position, relative to this FlowElement. The first
		* character is at relative position 0.
		*
		* @param relativePosition 	The relative position of the character in this FlowElement object.
		*
		* @return	the Unicode value for the character at the specified position.
		*
		* @playerversion Flash 10
		* @playerversion AIR 1.5
	 	* @langversion 3.0
	 	*
	 	* @includeExample examples\FlowElement_getCharCodeAtPositionExample.as -noswf
	 	*
	 	* @see #getCharAtPosition()
	 	*/
	 	
		public function getCharCodeAtPosition(relativePosition:int):int
		{
			var str:String = getCharAtPosition(relativePosition);
			return str && str.length > 0 ? str.charCodeAt(0) : 0;
		}
		
		/** @private return an element or matching idName. */
		tlf_internal function getElementByIDHelper(idName:String):FlowElement
		{
			if (this.id == idName)
				return this;
			return null;
		}
		
		/** @private return adding elements with matching styleName to an array. */
		tlf_internal function getElementsByStyleNameHelper(a:Array,styleName:String):void
		{
			if (this.styleName == styleName)
				a.push(this);
		}
		
		// **************************************** 
		// End tree navigation code
		// ****************************************	
		
		// **************************************** 
		// Begin tree modification support code
		// ****************************************	

		/**
		 * Update the FlowElement to account for text added before it.
		 *
		 * @param len	number of characters added (may be negative if deletion)
		 */
		private function updateRange(len:int): void
		{
			setParentRelativeStart(parentRelativeStart + len);
		}
		
		/** Update the FlowElements in response to an insertion or deletion.
		 *  The length of the element inserted to is updated, and the length of 
		 *  each of its ancestor element. Each of the elements following siblings
		 *  start index is updated (start index is relative to parent).
		 * @private
		 * @param startIdx		absolute index in flow where text was inserted
		 * @param len			number of characters added (negative if removed)
		 * updateLines			?? true if lines should be damaged??
		 * @private 
		 */
		tlf_internal function updateLengths(startIdx:int,len:int,updateLines:Boolean):void
		{
			setTextLength(textLength + len);		
			var p:FlowGroupElement = parent;	
			if (p)
			{
				// update the elements following this in parent's children				
				var idx:int = p.getChildIndex(this)+1;
				CONFIG::debug { assert(idx != -1,"bad parent in FlowElement.updateLengths"); }
				
				var pElementCount:int = p.numChildren;
				while (idx < pElementCount)
				{
					var child:FlowElement = p.getChildAt(idx++);
					child.updateRange(len);
				}
				
				// go up the tree to the root and update ancestor's lengths
				p.updateLengths(startIdx,len,updateLines);
			}
		}
		
		/** @private */
		tlf_internal function getEnclosingController(relativePos:int) : ContainerController
		{
			// CONFIG::debug { assert(pos <= length,"getEnclosingController - bad pos"); }
			
			var textFlow:TextFlow = getTextFlow();
			
			//more than likely, we are building up spans for the very first time.
			//the container has not yet been created
			if (textFlow == null || textFlow.flowComposer == null || textFlow.flowComposer.numLines == 0)
				return null;
			
			var curItem:FlowElement = this;
			while (curItem && (!(curItem is ContainerFormattedElement) || ContainerFormattedElement(curItem).flowComposer == null))
			{
				curItem = curItem.parent;
			}
			
			// [TA] 04-07-2010 :: Added null check fot curItem that may have been removed before reaching this method. RACE CONDITION.
			if( !curItem ) return null;
			
			var flowComposer:IFlowComposer = ContainerFormattedElement(curItem).flowComposer;
			if (!flowComposer)
				return null;
				
			var controllerIndex:int = ContainerFormattedElement(curItem).flowComposer.findControllerIndexAtPosition(getAbsoluteStart() + relativePos,false);
			return controllerIndex != -1 ? flowComposer.getControllerAt(controllerIndex) : null;
		}

		
		/** @private */
		tlf_internal function deleteContainerText(endPos:int,deleteTotal:int):void
		{
			// update container counts
					
			if (getTextFlow())		// update container lengths only for elements that are attached to the rootElement
			{
				var absoluteEndPos:int = getAbsoluteStart() + endPos;
				var absStartIdx:int = absoluteEndPos-deleteTotal;
				
				while (deleteTotal > 0)
				{
					var charsDeletedFromCurContainer:int;
					var enclosingController:ContainerController = getEnclosingController(endPos-1);
					if (!enclosingController)
					{
						// The end of the deleted text may be overset, so it doesn't appear in a container.
						// Find the last container that contains the deleted text.
						enclosingController = getEnclosingController(endPos - deleteTotal);
						if (enclosingController)
						{
							var flowComposer:IFlowComposer = enclosingController.flowComposer;
							var myIdx:int = flowComposer.getControllerIndex(enclosingController);
							CONFIG::debug { assert(myIdx >= 0,"FlowElement.deleteContainerText: bad return from getContainerControllerIndex"); }
							while (myIdx+1 < flowComposer.numControllers && enclosingController.absoluteStart + enclosingController.textLength < endPos)
							{
								enclosingController = flowComposer.getControllerAt(myIdx+1);
								if (enclosingController.textLength)
									break;
								myIdx++;
							}
						}
						if (!enclosingController)
							break;
					}
					var enclosingControllerBeginningPos:int = enclosingController.absoluteStart;
					if (absStartIdx < enclosingControllerBeginningPos)
					{
						charsDeletedFromCurContainer = absoluteEndPos - enclosingControllerBeginningPos + 1;
					}
					else if (absStartIdx < enclosingControllerBeginningPos + enclosingController.textLength)
					{
						charsDeletedFromCurContainer = deleteTotal;
					} 
					// Container textFlowLength may contain fewer characters than the those to be deleted in case of overset text. 
					var containerTextLengthDelta:int = enclosingController.textLength < charsDeletedFromCurContainer ? enclosingController.textLength : charsDeletedFromCurContainer;
					if (containerTextLengthDelta <= 0)
						break;		// overset text is not in the last container -- we've deleted the container count, so exit
					// working backwards - can't call setTextLength as it examines previous controllers and gets confused in the composeCompleteRatio logic
					ContainerController(enclosingController).setTextLengthOnly(enclosingController.textLength -  containerTextLengthDelta);
					deleteTotal -= containerTextLengthDelta;
					absoluteEndPos -= containerTextLengthDelta;
					endPos -= containerTextLengthDelta;
				}
			}
		}
		
		/** @private */
		tlf_internal function normalizeRange(normalizeStart:uint,normalizeEnd:uint):void
		{
			// default is do nothing
		}
		
		/** Support for splitting FlowLeafElements.  Does a quick copy of _characterFormat if necessary.  @private */
		tlf_internal function quickCloneTextLayoutFormat(sibling:FlowElement):void
		{
			_formatValueHolder = sibling._formatValueHolder ? new FlowValueHolder(sibling._formatValueHolder) : null;
		}
			
		// **************************************** 
		// End tree modification support code
		// ****************************************	
		
		/** @private This API supports the inputmanager */
		tlf_internal function updateForMustUseComposer(textFlow:TextFlow):Boolean
		{ return false; }

		// **************************************** 
		// Begin debug support code
		// ****************************************	
		
		CONFIG::debug static private var debugDictionary:Dictionary = new Dictionary(true);
		CONFIG::debug static private var nextKey:int = 1;
		
		CONFIG::debug static public function getDebugIdentity(o:Object):String
		{
			if (debugDictionary[o] == null)
			{
				var s:String = flash.utils.getQualifiedClassName(o);
				if (s)
					s = s.substr( s.lastIndexOf(":")+1);
				else
					s = "";
				debugDictionary[o] = s + "." + nextKey.toString();
				nextKey++;
			}
			return debugDictionary[o];
		}
		
		/**
		 * Check FlowElement for internal consistency.
		 * @private
		 * Lots of internal checks are done on FlowElements, some are dependent
		 * on the type of element. 
		 * @return Number of errors found
		 */
		CONFIG::debug public function debugCheckFlowElement(depth:int = 0, extraData:String = ""):int
		{
			if (Debugging.verbose)
			{			
				if (depth == 0)
					trace("----------------------------------");

				trace("FlowElement:",depth.toString(),getDebugIdentity(this),"start:",parentRelativeStart.toString(),"length:",textLength.toString(),extraData);
			}
			return 0;
		}
		
		CONFIG::debug public static function elementPath(element:FlowElement):String
		{
			var result:String;
			
			if (element != null)
			{
				if (element.parent != null)
					result = elementPath(element.parent) + "." + element.name + "[" + element.parent.getChildIndex(element) + "]";
				else
					result = element.name;
			}
			return result;
		}

		/**
		 * debugging only - show element as string
		 */
		CONFIG::debug public function toString():String
		{
			return "flowElement:" + name + " start:" + parentRelativeStart.toString() + " absStart:" + this.getAbsoluteStart().toString() + " textLength:" + textLength.toString();			
		}
		// **************************************** 
		// End debug support code
		// ****************************************	
		
		//	[KK]	Setter/getter for originality (determining whether the leaf is straight from HTML source or from the TLF hierarchy)
		public function set original( value:Boolean ):void
		{
			_original = value;
		}
		public function get original():Boolean
		{
			return _original;
		}
	}
}
