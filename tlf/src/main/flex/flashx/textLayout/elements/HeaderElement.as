package flashx.textLayout.elements
{
	import flash.text.engine.FontWeight;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.events.InlineStyleEvent;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormatValueHolder;
	import flashx.textLayout.model.style.HeaderStyle;
	import flashx.textLayout.model.style.IHeaderStyle;
	import flashx.textLayout.model.style.InlineStyles;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.DimensionTokenUtil;
	import flashx.textLayout.utils.StyleAttributeUtil;
	import flashx.textLayout.utils.TextLayoutFormatUtils;
	
	use namespace tlf_internal;

	// TODO: 
	//		2. Look into how text is applied, on split a SpanElement is added. May override for normalize range.
	//		3. Figure out end of heading content, and if enter, then add a default <p><span> and not use shallow copy/split paragraph.
	//		
	public class HeaderElement extends ParagraphElement
	{
		public static const H1:String = 'h1';
		public static const H2:String = 'h2';
		public static const H3:String = 'h3';
		public static const H4:String = 'h4';
		public static const H5:String = 'h5';
		public static const H6:String = 'h6';
		
		public static const DEFAULT_FORMAT_PROPERTY:String = "defaultHeaderFormat";
		
		protected var _userStyles:Object;
		protected var _style:IHeaderStyle;
		
		protected var _type:String = HeaderElement.H3;
		protected var _contentHolder:SpanElement;
		
		public function HeaderElement( $type:String = HeaderElement.H3 )
		{
			super();	
			type = $type;
			_style = new HeaderStyle();
		}
		
		//	[KK]	These two overrides should prevent other text / elements from merging with header elements
		override tlf_internal function canReleaseContentElement():Boolean
		{
			return false;
		}
		override tlf_internal function mergeToPreviousIfPossible():Boolean
		{
			return false;
		}
		
		tlf_internal function setHeaderStyle( value:IHeaderStyle ):void
		{
			_style = value;
		}
		
		protected function invalidateType():void
		{
//			doComputeTextLayoutFormat( formatForCascade );
			if( getTextFlow() ) normalizeRange(0, textLength);
		}
		
		protected function createContentHolderIfNotExist():void
		{
			if( _contentHolder == null )
			{
				_contentHolder = new SpanElement();
			}
			
			if( numChildren == 0 || getChildAt( 0 ) != _contentHolder )
			{
				trace( "set content" );
				replaceChildren( 0, 0, _contentHolder );
			}
		}
		
		protected function getPointSize( type:String ):uint
		{
			switch ( type )
			{
				case H1:
					return 24;
				case H2:
					return 18;
				case H4:
					return 12;
				case H5:
					return 10;
				case H6:
					return 8;
				case H3:
				default:
					return 14;
			}
			return 14;
		}
		
		/**
		 * @private
		 * 
		 * Returns the ITextLayoutFormat for this element by selecting any defaults from configuration. 
		 * @return ITextLayoutFormat
		 */
		protected function computeFormat():ITextLayoutFormat
		{
			var ca:ITextLayoutFormat;
			var style:Object = getStyle( HeaderElement.DEFAULT_FORMAT_PROPERTY );
			if( style == null )
			{
				var tf:TextFlow = getTextFlow();
				ca = tf == null ? null : tf.configuration[HeaderElement.DEFAULT_FORMAT_PROPERTY] as ITextLayoutFormat;
			}
			else if( style is ITextLayoutFormat )
			{
				ca = ITextLayoutFormat(style);
			}
			else
			{
				ca = new TextLayoutFormatValueHolder();
				var desc:Object = TextLayoutFormat.description;
				for (var prop:String in desc)
				{
					if (style[prop] != undefined)
						ca[prop] = style[prop];
				}
			}
			
			// set new values based on type.
			if( ca is TextLayoutFormatValueHolder )
			{
				var caTL:TextLayoutFormatValueHolder = ( ca as TextLayoutFormatValueHolder );
				caTL.fontSize = DimensionTokenUtil.convertPointToPixel( ( format.fontSize ) ? format.fontSize : getPointSize( _type ) );
				caTL.lineHeight = _style.getComputedLineHeight( caTL.fontSize );
				caTL.paddingBottom = caTL.lineHeight;
				return caTL;
			}
			return ca;
		}
		
		/**
		 * @private
		 * 
		 * Override to due proper merge of default format from Configuration of link with any user defined styles perviously applied to the format. 
		 * @return ITextLayoutFormat
		 */
		tlf_internal override function get formatForCascade():ITextLayoutFormat
		{
			var superFormat:ITextLayoutFormat = format;
			var effectiveFormat:ITextLayoutFormat = computeFormat();
			if (effectiveFormat || superFormat)
			{
				if (effectiveFormat && superFormat)
				{
					var resultingTextLayoutFormat:TextLayoutFormatValueHolder = new TextLayoutFormatValueHolder(effectiveFormat);
					if (superFormat)
					{
						TextLayoutFormatUtils.apply( resultingTextLayoutFormat, superFormat );
					}
					return resultingTextLayoutFormat;
				}
				return superFormat ? superFormat : effectiveFormat;
			}
			return null;
		}
		
		/**
		 * @inherit
		 * Override to apply specific properties related to header elements on copy.
		 */
		public override function shallowCopy(startPos:int=0, endPos:int=-1):FlowElement
		{
			var copy:HeaderElement = super.shallowCopy( startPos, endPos ) as HeaderElement;
			copy.type = type;
			copy.setHeaderStyle( _style );
			return copy;
		}
		
		/**
		 * Simple transfer of necessary properties to related FlowElement. 
		 * @param element FlowElement
		 */
		public function shallowTransfer( element:FlowElement ):void
		{
			element.uid = uid;
		}
		
		protected function undefinePreviousAppliedStyle( previousStyle:Object, style:IHeaderStyle ):Boolean
		{
			var property:String;
			var requiresUpdate:Boolean;
			for( property in previousStyle )
			{
				try
				{
					if( style[property] == previousStyle[property] )
					{
						style.undefineStyleProperty( property );
						requiresUpdate = true;
					}
				}
				catch( e:Error )
				{
					// unsupported style on IHeaderStyle.
				}
			}
			return requiresUpdate;
		}
		
		
		protected function handleAppliedStyleChange( evt:InlineStyleEvent ):void
		{
			var requiresUpdate:Boolean = undefinePreviousAppliedStyle( evt.oldStyle, _style );
			
			var appliedStyle:Object = evt.newStyle;
			var property:String;	
			var styleProperty:String;
			for( property in appliedStyle )
			{
				try 
				{
					styleProperty = StyleAttributeUtil.camelize(property);
					// Only ovewrite if not explicitly set which happens when reading in explicit style from @style attribute.
					if( _style.isUndefined( styleProperty ) )
					{
						_style[styleProperty] = appliedStyle[property];
						requiresUpdate = true;
					}
				}
				catch( e:Error )
				{
//					trace( "[HeaderElement] :: Style property of type '" + property + "' cannot be set on " + getQualifiedClassName( _style ) + ". " + e.message );
				}
			}
			
			if( requiresUpdate ) invalidateType();
		}
		
		protected function handleExplicitStyleChange( evt:InlineStyleEvent ):void
		{
			var explicitStyle:Object = evt.newStyle;
			var property:String;
			var styleProperty:String;
			var requiresUpdate:Boolean;
			for( property in explicitStyle )
			{
				try 
				{
					styleProperty = StyleAttributeUtil.camelize(property);
					_style[styleProperty] = explicitStyle[property];
					requiresUpdate = true;
				}
				catch( e:Error )
				{
//					trace( "[HeaderElement] :: Style property of type '" + property + "' cannot be set on " + getQualifiedClassName( _style ) + "." );
				}
			}
			
			if( requiresUpdate ) invalidateType();
		}
		
		/**
		 * @inherit
		 * 
		 * Override to apply defined InlineStyle object on user styles and establish event listeners to change on styles. 
		 * @return Object
		 */
		override public function get userStyles():Object
		{
			if( _userStyles == null )
			{
				var predefinedStyles:Object = super.userStyles;
				_userStyles = ( predefinedStyles ) ? predefinedStyles : {};
				var hasPredefinedInlineStyle:Boolean = _userStyles.hasOwnProperty( "inline" );
				var inline:InlineStyles = ( hasPredefinedInlineStyle ) ? _userStyles.inline : new InlineStyles();
				inline.addEventListener( InlineStyleEvent.APPLIED_STYLE_CHANGE, handleAppliedStyleChange );
				inline.addEventListener( InlineStyleEvent.EXPLICIT_STYLE_CHANGE, handleExplicitStyleChange );
				if( !hasPredefinedInlineStyle ) _userStyles.inline = inline;
				super.userStyles = _userStyles;
			}
			return super.userStyles;
		}
		
		public function get type():String
		{
			return _type;
		}
		public function set type( value:String ):void
		{
			if ( value !== H1 && value !== H2 && value !== H3 && 
					value !== H4 && value != H5 && value !== H6 )
			{
				_type = HeaderElement.H3;
			}
			else
			{
				_type = value;
			}
			invalidateType();
		}
		
		// Override to flip off oringal flag on span if child element. This can accure form a split operation, such as placing the cursor in the middle of a header and pressing ENTER.
		//	When it is split, two spans are created, the last being past to a new header and marked as original. We want to unmark it as original as it is the default content of the header.
		override public function addChild(child:FlowElement):FlowElement
		{
			if( child is SpanElement ) child.original = false;
			return super.addChild( child );
		}
		
//		tlf_internal override function ensureTerminatorAfterReplace(oldLastLeaf:FlowLeafElement):void
//		{
//			//	Nothing here in order to ensure that no extra spaces are added between lines
//		}
		
		public function get text():String
		{
			return ( !_contentHolder ) ? "" : _contentHolder.text;
		}
		public function set text( value:String ):void
		{
			createContentHolderIfNotExist();
			_contentHolder.text = value;
		}
	}
}