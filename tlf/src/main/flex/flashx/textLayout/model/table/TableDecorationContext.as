package flashx.textLayout.model.table
{
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.attribute.TableAttribute;
	import flashx.textLayout.model.style.IBorderStyle;
	import flashx.textLayout.model.style.ITableStyle;
	import flashx.textLayout.model.style.TableCollapseStyleEnum;
	import flashx.textLayout.utils.BoxModelStyleUtil;
	
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
		public function TableDecorationContext(model:TableModelBase, attributes:IAttribute=null, style:ITableStyle=null)
		{
			super(model, attributes, style);
		}
		
		/**
		 * Returns the cummulative height based on top and bottom border widths. 
		 * @return Number
		 */
		public function getComputedHeightOfBorders():Number
		{
			var borderWidth:Array = determineBorderWidth();
			return borderWidth[0] + borderWidth[2];
		}
		
		/**
		 * Returns the cummulative width based on left and right border widths. 
		 * @return Number
		 */
		public function getComputedWidthOfBorders():Number
		{
			var borderWidth:Array = determineBorderWidth();
			return borderWidth[1] + borderWidth[3];
		}
		
		/**
		 * @see ITableDecorationContext#determineBorderWidth
		 */
		public function determineBorderWidth():Array
		{
			var borderStyle:IBorderStyle = _style.getBorderStyle();
			var borderWidth:Array = _style.getComputedStyle().getBorderStyle().borderWidth;
			var attributeOverridesStyle:Boolean;
			if( borderStyle.isUndefined( borderStyle.borderWidth ) )
			{
				if( _attributes.hasProperty( "border" ) )
				{
					var b:int = BoxModelStyleUtil.normalizeBorderUnit( _attributes["border"] );
					if( b != TableAttribute.DEFAULT_BORDER )
						borderWidth = [b, b, b, b];
				}
			}
			return borderWidth;
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
			if( !_style.isUndefined(_style.borderCollapse) )
			{
				spacing = ( _style.borderCollapse == TableCollapseStyleEnum.COLLAPSE_COLLAPSE ) ? 2 : spacing;
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