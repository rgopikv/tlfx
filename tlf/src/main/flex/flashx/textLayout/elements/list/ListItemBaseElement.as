package flashx.textLayout.elements.list
{
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.events.InlineStyleEvent;
	import flashx.textLayout.events.list.ListElementEvent;
	import flashx.textLayout.format.StyleProperty;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.model.style.IListStyle;
	import flashx.textLayout.model.style.InlineStyles;
	import flashx.textLayout.model.style.ListStyle;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.FragmentAttributeUtil;
	import flashx.textLayout.utils.StyleAttributeUtil;
	
	use namespace tlf_internal;
	public class ListItemBaseElement extends ParagraphElement
	{
		protected var _mode:int;
		protected var _userStyles:Object;
		protected var _style:IListStyle;
		
		public function ListItemBaseElement()
		{
			super();
			_mode = ListItemModeEnum.UNORDERED;
			_style = getDefaultListStyle( _mode );
		}
		
		// [TA] 07-13-2010 :: Override shallow copy to push list item specific properties on copy creation.
		override public function shallowCopy(startPos:int=0, endPos:int=-1):FlowElement
		{
			use namespace tlf_internal;
			var copy:ListItemBaseElement = super.shallowCopy( startPos, endPos ) as ListItemBaseElement;
			copy.mode = _mode;
			copy.setListStyle( _style.clone() );
			return copy;
		}
		// [END TA]
		
		tlf_internal function setListStyle( style:IListStyle ):void
		{
			_style = style;
		}
		
		protected function getDefaultListStyle( defaultMode:int ):IListStyle
		{
			return new ListStyle( defaultMode );
		}
		
		protected function getInlineStyles():InlineStyles
		{
			if( userStyles )
			{
				if( _userStyles.inline as InlineStyles )
				{
					return _userStyles.inline;
				}
			}
			return null;
		}
		
		protected function invalidateMode():void
		{
			_style.mode = _mode;
			// Wipe out applied styles as they relate to mode.
			var inlineStyles:InlineStyles = getInlineStyles();
			if( inlineStyles )
			{
				inlineStyles.appliedStyle = null;
			}
			updateDisplayForListStyle();
			
			// Notify clients.
			var tf:TextFlow = getTextFlow();
			if( tf )
			{
				tf.dispatchEvent( new ListElementEvent( ListElementEvent.MODE_CHANGED, this, parent as ListElementX ) );
			}
		}
		
		protected function updateDisplayForListStyle():void
		{
			// abstract.
		}
		
		/**
		 * @private
		 * 
		 * Undefines applied style properies from external style sheet. Ensuring only styles applied directly by user or within @style attribute are kept. 
		 * @param previousStyle Object The ky/value pairs of applied style.
		 * @param tableStyle IListStyle The held style to undefine applied properties from.
		 */
		protected function undefinePreviousAppliedStyle( previousStyle:Object, style:IListStyle ):Boolean
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
					// unsupported style on IListStyle.
				}
			}
			return requiresUpdate;
		}
		
		/**
		 * @private
		 * 
		 * Event handler for change in applied styles on inline styles held on userStyles. 
		 * @param evt InlineStyleEvent
		 */
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
//					trace( "[ListItemBaseElement] :: Style property of type '" + property + "' cannot be set on " + getQualifiedClassName( _style ) + "." );
				}
			}
			
			if( requiresUpdate ) updateDisplayForListStyle();
		}
		
		/**
		 * @private
		 * 
		 * Event hanlde for change to explicit styles on InlineStyle object. This occurs when inline @style attribute is parse and applied. 
		 * @param evt InlineStyleEvent
		 */
		protected function handleExplicitStyleChange( evt:InlineStyleEvent ):void
		{
			var explicitStyle:Object = evt.newStyle;
			var property:String;	
			var styleProperty:String;
			var requiresUpdate:Boolean;
			var description:Object = TextLayoutFormat.description;
			var formatStyle:StyleProperty;
			var currentFormat:ITextLayoutFormat = ( format ) ? format : new TextLayoutFormat();
			for( property in explicitStyle )
			{
				try 
				{
					formatStyle = StyleProperty.normalizeForFormat( property, explicitStyle[property] );
					// First try and set it to the format.
					if( description.hasOwnProperty( formatStyle.property ) )
					{
						currentFormat[formatStyle.property] = formatStyle.value;
					}
					// Then if not found on description, set it the list style.
					else
					{
						styleProperty = StyleAttributeUtil.camelize(property);
						_style[styleProperty] = explicitStyle[property];
					}
					requiresUpdate = true;
				}
				catch( e:Error )
				{
//					trace( "[ListItemBaseElement] :: Style property of type '" + property + "' cannot be set on " + getQualifiedClassName( _style ) + "." );
				}
			}
			
			if( requiresUpdate ) updateDisplayForListStyle();
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
				inline.addEventListener( InlineStyleEvent.LIST_ITEM_PARENT_STYLE_CHANGE, handleExplicitStyleChange );
				if( !hasPredefinedInlineStyle ) _userStyles.inline = inline;
				super.userStyles = _userStyles;
			}
			return super.userStyles;
		}
		
		public function set mode( value:int ):void
		{
			if( _mode == value ) return;
			
			_mode = ( value != ListItemModeEnum.ORDERED ) ? ListItemModeEnum.UNORDERED : value;
			invalidateMode();
		}
		public function get mode():int
		{
			return _mode;
		}
		
		public function getNodeNameFromMode( mode:int ):String
		{
			return ( mode == ListItemModeEnum.ORDERED ) ? "ol" : "ul";
		}
		
		public function getParentingNodeCopy():XML
		{
			var inlineStyles:InlineStyles = getInlineStyles();
			if( inlineStyles )
			{
				var node:XML = inlineStyles.node;
				if( node )
				{
					var parentNode:XML = node.parent();
					return FragmentAttributeUtil.copyWithAttributes( parentNode, getNodeNameFromMode( _mode ) );
				}
			}
			return null;
		}
	}
}