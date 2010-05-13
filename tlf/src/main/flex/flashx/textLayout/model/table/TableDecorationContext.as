package flashx.textLayout.model.table
{
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.attribute.TableAttribute;
	import flashx.textLayout.model.style.ITableStyle;
	
	/**
	 * TableDecorationContext is an implementation of ITableDecorationContext that extends TableBaseDecorationContext to expose methods related to the context of attrbributes and styles for parenting Table element. 
	 * @author toddanderson
	 */
	public class TableDecorationContext extends TableBaseDecorationContext implements ITableDecorationContext
	{
		/**
		 * Constructor. 
		 * @param attributes IAttribute
		 * @param style ITableStyle
		 */
		public function TableDecorationContext(attributes:IAttribute=null, style:ITableStyle=null)
		{
			super(attributes, style);
		}
		
		/**
		 * @see ITableDecorationContext#determineCellSpacing
		 */
		public function determineCellSpacing():Number
		{
			var spacing:Number = _attributes[TableAttribute.CELLSPACING];
			if( !_style.isUndefined(_style.borderSpacing) )
			{
				spacing = _style.getComputedStyle().borderSpacing;
			}
			return spacing;
		}
		/**
		 * @see ITableDecorationContext#determineCellPadding
		 */
		public function determineCellPadding():Number
		{	
			return _attributes[TableAttribute.CELLPADDING];
		}
	}
}