package flashx.textLayout.elements.table
{
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.elements.ContainerFormattedElement;
	import flashx.textLayout.events.InlineStyleEvent;
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.style.IBoxModelUnitStyle;
	import flashx.textLayout.model.style.ITableStyle;
	import flashx.textLayout.model.style.InlineStyles;
	import flashx.textLayout.model.style.TableStyle;
	import flashx.textLayout.model.table.ITableBaseDecorationContext;
	import flashx.textLayout.utils.StyleAttributeUtil;
	
	public class TableBaseElement extends ContainerFormattedElement implements ITableBaseElement
	{
		protected var _userStyles:Object;
		protected var _context:ITableBaseDecorationContext;
		protected var _pendingInitializationStyle:ITableStyle;
		
		/**
		 * Constructor.
		 */
		public function TableBaseElement()
		{
			super();
			_pendingInitializationStyle = new TableStyle();
		}
		
		/**
		 * @private
		 * 
		 * Undefines applied style properies from external style sheet. Ensuring only styles applied directly by user or within @style attribute are kept. 
		 * @param previousStyle Object The ky/value pairs of applied style.
		 * @param tableStyle ITableStyle The held style to undefine applied properties from.
		 */
		protected function undefinePreviousAppliedStyle( previousStyle:Object, style:IBoxModelUnitStyle ):void
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
					// unsupported style on ITableStyle.
				}
			}
		}
		
		/**
		 * @private
		 * 
		 * Event handler for change in applied styles on inline styles held on userStyles. 
		 * @param evt InlineStyleEvent
		 */
		protected function handleAppliedStyleChange( evt:InlineStyleEvent ):Boolean
		{
			var tableStyle:ITableStyle = ( _context ) ? _context.style : _pendingInitializationStyle;
			undefinePreviousAppliedStyle( evt.oldStyle, tableStyle );
			
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
					if( tableStyle.isUndefined( tableStyle[styleProperty] ) )
					{
						requiresUpdate = true;
						tableStyle[styleProperty] = appliedStyle[property];
					}
				}
				catch( e:Error )
				{
					trace( "[" + getQualifiedClassName( this ) + "] :: Style property of type '" + property + "' cannot be set on " + getQualifiedClassName( tableStyle ) + "." );
				}
			}
			// styleNames property assumes that it is a list of declared rules of a style in the order that they appeared reversed.
			if( appliedStyle && appliedStyle.styleNames )
			{
				tableStyle.defineWeight( ( appliedStyle.styleNames as Array ).reverse() );
			}
			else
			{
				tableStyle.defineWeight( [] );
			}
			return requiresUpdate;
		}
		
		/**
		 * @private
		 * 
		 * Event hanlde for change to explicit styles on InlineStyle object. This occurs when inline @style attribute is parse and applied. 
		 * @param evt InlineStyleEvent
		 */
		protected function handleExplicitStyleChange( evt:InlineStyleEvent ):Boolean
		{
			var explicitStyle:Object = evt.newStyle;
			var property:String;	
			var styleProperty:String;
			var requiresUpdate:Boolean;
			var style:ITableStyle = ( _context ) ? _context.style : _pendingInitializationStyle;
			for( property in explicitStyle )
			{
				try 
				{
					styleProperty = StyleAttributeUtil.camelize(property);
					style[styleProperty] = explicitStyle[property];
					requiresUpdate = true;
				}
				catch( e:Error )
				{
					trace( "[" + getQualifiedClassName( this ) + "] :: Style property of type '" + property + "' cannot be set on " + getQualifiedClassName( style ) + "." );
				}
			}
			return requiresUpdate;
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
		
		/**
		 * Returns the decoration context implementation instance. 
		 * @return ITableBaseDecorationContext
		 */
		public function getContext():ITableBaseDecorationContext
		{
			return _context;
		}
		
		/**
		 * Returns the held concrete implmenentation of the ITableStyle instance defined on the context model. 
		 * @return ITableStyle
		 */
		public function getContextStyle():ITableStyle
		{
			return _context.style;
		}
		
		/**
		 * Returns computed attributes of element and parentin elements. 
		 * @return IAttribute
		 */
		public function getComputedAttributes():IAttribute
		{
			// abstract.
			return _context.getDefinedAttributes();
		}
		
		/**
		 * Performs any cleanup.
		 */
		public function dispose():void
		{	
			_userStyles = null;
			_context = null;
			_pendingInitializationStyle = null;
		}
	}
}