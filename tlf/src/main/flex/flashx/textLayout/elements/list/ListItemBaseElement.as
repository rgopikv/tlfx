package flashx.textLayout.elements.list
{
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.events.InlineStyleEvent;
	import flashx.textLayout.model.style.IListStyle;
	import flashx.textLayout.model.style.InlineStyles;
	import flashx.textLayout.model.style.ListStyle;
	import flashx.textLayout.utils.StyleAttributeUtil;
	
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
		
		protected function getDefaultListStyle( defaultMode:int ):IListStyle
		{
			return new ListStyle( defaultMode );
		}
		
		protected function invalidateMode():void
		{
			_style.mode = _mode;
			updateDisplayForListStyle();
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
		protected function undefinePreviousAppliedStyle( previousStyle:Object, style:IListStyle ):void
		{
			var property:String;
			for( property in previousStyle )
			{
				try
				{
					if( style[property] == previousStyle[property] )
						style.undefineStyleProperty( property );
				}
				catch( e:Error )
				{
					// unsupported style on IListStyle.
				}
			}
		}
		
		/**
		 * @private
		 * 
		 * Event handler for change in applied styles on inline styles held on userStyles. 
		 * @param evt InlineStyleEvent
		 */
		protected function handleAppliedStyleChange( evt:InlineStyleEvent ):void
		{
			undefinePreviousAppliedStyle( evt.oldStyle, _style );
			
			var appliedStyle:Object = evt.newStyle;
			var property:String;	
			var styleProperty:String;
			var requiresUpdate:Boolean;
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
					trace( "[" + getQualifiedClassName( this ) + "] :: Style property of type '" + property + "' cannot be set on " + getQualifiedClassName( _style ) + "." );
				}
			}
			trace( getText() + ", " + _style.listStyleType );
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
					trace( "[" + getQualifiedClassName( this ) + "] :: Style property of type '" + property + "' cannot be set on " + getQualifiedClassName( _style ) + "." );
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
				_userStyles = {};
				var inline:InlineStyles = new InlineStyles();
				inline.addEventListener( InlineStyleEvent.APPLIED_STYLE_CHANGE, handleAppliedStyleChange );
				inline.addEventListener( InlineStyleEvent.EXPLICIT_STYLE_CHANGE, handleExplicitStyleChange );
				_userStyles.inline = inline;
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
	}
}