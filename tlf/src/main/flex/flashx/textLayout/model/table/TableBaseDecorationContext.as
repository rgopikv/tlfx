package flashx.textLayout.model.table
{
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.attribute.TableAttribute;
	import flashx.textLayout.model.style.ITableStyle;
	
	/**
	 * TableBaseDecorationContext is an ITableBaseDecorationContext implementation to manage attiributes and styles. 
	 * @author toddanderson
	 */
	public class TableBaseDecorationContext implements ITableBaseDecorationContext
	{
		protected var _attributes:IAttribute;
		protected var _style:ITableStyle;
		
		/**
		 * Constructor. 
		 * @param attributes IAttribute
		 * @param style ITableStyle
		 */
		public function TableBaseDecorationContext( attributes:IAttribute = null, style:ITableStyle = null )
		{
			_attributes = attributes;
			_style = style;
		}
		
		/**
		 * @see ITableBaseDecorationContext#modifyAttributes
		 */
		public function modifyAttributes( overlay:Object ):void
		{
			_attributes.modifyAttributes( overlay );
		}
		/**
		 * @see ITableBaseDecorationContext#getStrippedAttributes
		 */
		public function getStrippedAttributes():Object
		{
			return _attributes.getStrippedAttributes();
		}
		/**
		 * @see ITableBaseDecorationContext#mergeStyle
		 */
		public function mergeStyle( overlay:ITableStyle ):void
		{
			if( _style )
			{
				_style.merge( overlay );	
			}
			else _style = overlay;
		}
		
		/**
		 * @see ITableBaseDecorationContext#attributes
		 */
		public function get attributes():IAttribute
		{
			return _attributes;
		}
		public function set attributes(value:IAttribute):void
		{
			_attributes = value;
		}
		
		/**
		 * @see ITableBaseDecorationContext#style
		 */
		public function get style():ITableStyle
		{
			return _style;
		}
		public function set style(value:ITableStyle):void
		{
			_style = value;
		}
	}
}