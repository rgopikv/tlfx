package flashx.textLayout.model.table
{
	import flashx.textLayout.container.table.ICellContainer;
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.attribute.TableAttribute;
	import flashx.textLayout.model.attribute.TableDataAttribute;
	import flashx.textLayout.model.style.ITableStyle;
	
	public class TableDataDecorationContext extends TableBaseDecorationContext implements ITableDataDecorationContext
	{
		protected var _parentModel:Table;
		protected var _tableContext:ITableDecorationContext;
		
		public function TableDataDecorationContext( parentModel:TableModelBase, model:TableModelBase, attributes:IAttribute = null, style:ITableStyle = null )
		{
			super( model, attributes, style );
			_parentModel = parentModel as Table;
			_tableContext = _parentModel.getContextImplementation();
		}
		
		public function determinePadding():Array
		{
			var padding:Array;
			if( _style.isUndefined( _style.padding ) )
			{
				var cellpadding:Number = _tableContext.attributes[TableAttribute.CELLPADDING];
				padding = [cellpadding, cellpadding, cellpadding, cellpadding]; 
			}
			else
			{
				padding = _style.getComputedStyle().padding;	
			}
			return padding;
		}
		
		public function getLeftPadding():Number
		{
			var padding:Array = determinePadding();
			var borderWidth:Array = determineBorderWidth();
			return padding[3] + borderWidth[3]; 
		}
		
		public function getRightPadding():Number
		{
			var padding:Array = determinePadding();
			var borderWidth:Array = determineBorderWidth();
			return padding[1] + borderWidth[1]; 
		}
		
		public function getTopPadding():Number
		{
			var padding:Array = determinePadding();
			var borderWidth:Array = determineBorderWidth();
			return padding[0] + borderWidth[0];
		}
		
		public function getBottomPadding():Number
		{
			var padding:Array = determinePadding();
			var borderWidth:Array = determineBorderWidth();
			return padding[2] + borderWidth[2]; 
		}
		
		public function getComputedWidthOfPaddingAndBorders():Number
		{
			return getComputedWidthOfPadding() + getComputedWidthOfBorders();
		}
		
		public function getComputedHeightOfPaddingAndBorders():Number
		{
			return getComputedHeightOfPadding() + getComputedHeightOfBorders();
		}
		
		public function getComputedWidthOfPadding():Number
		{
			var padding:Array = determinePadding();
			return padding[1] + padding[3];
		}
		
		public function getComputedHeightOfPadding():Number
		{
			var padding:Array = determinePadding();
			return padding[0] + padding[2];
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
			var borderWidth:Array = _style.getComputedStyle().borderWidth;
			if( _style.isUndefined( _style.borderWidth ) )
			{
				if( _tableContext.attributes.hasProperty( "border" ) )
				{
					borderWidth = [1, 1, 1, 1];
				}
			}
			return borderWidth;
		}
		
		/**
		 * @see ITableDecorationContext#determineCellSpacing
		 */
		public function determineCellSpacing():Number
		{
			return _tableContext.determineCellSpacing();
		}
		/**
		 * @see ITableDecorationContext#determineCellPadding
		 */
		public function determineCellPadding():Number
		{	
			return _tableContext.determineCellPadding();
		}
		
		public function getDefinedWidth():Number
		{
			var width:Number = Number.NaN;
			if( !_style.isUndefined( _style.width ) )
			{
				width = _style.width;
			}
			else if( !_attributes.isUndefined( TableDataAttribute.WIDTH ) )
			{
				width = _attributes[TableDataAttribute.WIDTH];
				_style.width = width;
				delete _attributes[TableDataAttribute.HEIGHT];
			}
			return width;
		}
		
		public function getAllotedHeight( cell:ICellContainer ):Number
		{
			var height:Number = getDefinedHeight();
			return height;
		}
		
		public function getAllotedWidth( cell:ICellContainer ):Number
		{
			var width:Number = getDefinedWidth();
			if( isNaN( width ) )
			{
				if( !_tableContext.style.isUndefined( _tableContext.style.width ) )
				{
					// determine the width based on table style width and column span.
					var fixedWidth:Number = _tableContext.style.width;
					width = fixedWidth / _attributes[TableDataAttribute.COLSPAN];
				}
				else
				{
					// determine the amount of width available for cell based on maximum width of table and column span.
					var maxWidth:Number = _parentModel.maximumWidth;
					if( !isNaN( maxWidth ) )
					{
						width = _parentModel.maximumColumnWidth / _attributes[TableDataAttribute.COLSPAN];
					}
				}
			}
			return width;
		}
		
		public function getDefinedHeight():Number
		{
			var height:Number = Number.NaN;
			if( !_style.isUndefined( _style.height ) )
			{
				height = _style.height;
			}
			else if( !_attributes.isUndefined( TableDataAttribute.HEIGHT ) )
			{
				height = _attributes[TableDataAttribute.HEIGHT];
				_style.height = height;
				delete _attributes[TableDataAttribute.HEIGHT];
			}
			return height;
		}
	}
}