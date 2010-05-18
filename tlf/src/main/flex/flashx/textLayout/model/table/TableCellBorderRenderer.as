package flashx.textLayout.model.table
{
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class TableCellBorderRenderer extends TableBorderRenderer
	{
		public function TableCellBorderRenderer(targetDisplay:Shape, context:ITableDecorationContext)
		{
			super(targetDisplay, context);
		}
		
		/**
		 * @private
		 * 
		 * Composes the drawing points used for the drawing API based on the index of the border leg. 
		 * @param index int
		 * @return Vector.<Point>
		 */
		override protected function composePoints( border:TableBorderLeg, tableWidth:Number, tableHeight:Number ):Vector.<Point>
		{
			var index:int = border.index;
			var widths:Array = _context.determineBorderWidth();
			var top:Number = widths[0];
			var right:Number = widths[1];
			var bottom:Number = widths[2];
			var left:Number = widths[3];
			
			var pts:Vector.<Point> = new Vector.<Point>();
			switch( index )
			{
				case 0:
					pts.push( new Point( 0, 0 ) );
					pts.push( new Point( left, top  ) );
					pts.push( new Point( tableWidth - right, top ) );
					pts.push( new Point( tableWidth, 0 ) );
					pts.push( new Point( 0, 0 ) );
					break;
				case 1:
					pts.push( new Point( tableWidth, 0 ) );
					pts.push( new Point( tableWidth, tableHeight ) );
					pts.push( new Point( tableWidth - right, tableHeight - bottom ) );
					pts.push( new Point( tableWidth - right, top ) );
					pts.push( new Point( tableWidth, 0 ) );
					break;
				case 2:
					pts.push( new Point( tableWidth, tableHeight ) );
					pts.push( new Point( 0, tableHeight ) );
					pts.push( new Point( left, tableHeight - bottom ) );
					pts.push( new Point( tableWidth - right, tableHeight - bottom ) );
					pts.push( new Point( tableWidth, tableHeight ) );
					break;
				case 3:
					pts.push( new Point( 0, 0 ) );
					pts.push( new Point( left, top ) );
					pts.push( new Point( left, tableHeight - bottom ) );
					pts.push( new Point( 0, tableHeight ) );
					pts.push( new Point( 0, 0 ) );
					break;
			}
			return pts;
		}
		
		/**
		 * @private
		 * 
		 * Composes the stacked drawing points used for the drawing API based on the index of the border leg. 
		 * @param index int
		 * @return Vector.<Point>
		 */
		override protected function composeStackedPoints( border:TableBorderLeg, tableWidth:Number, tableHeight:Number ):Array /* Vector.<Point>[] */
		{
			var index:int = border.index;
			var widths:Array = _context.determineBorderWidth();
			var top:Number = widths[0];
			var right:Number = widths[1];
			var bottom:Number = widths[2];
			var left:Number = widths[3];
			
			var pts:Vector.<Point>;
			var stack:Array = [];
			switch( index )
			{
				case 0:
					pts = new Vector.<Point>();
					pts.push( new Point( 0, 0 ) );
					pts.push( new Point( left / 2, top / 2  ) );
					pts.push( new Point( tableWidth - ( right / 2 ), top / 2 ) );
					pts.push( new Point( tableWidth, 0 ) );
					pts.push( new Point( 0, 0 ) );
					stack.push( pts );
					pts = new Vector.<Point>();
					pts.push( new Point( left / 2, top / 2 ) );
					pts.push( new Point( left, top  ) );
					pts.push( new Point( tableWidth - right, top ) );
					pts.push( new Point( tableWidth - ( right / 2 ), top / 2 ) );
					pts.push( new Point( left / 2, top / 2 ) );
					stack.push( pts );
					break;
				case 1:
					pts = new Vector.<Point>();
					pts.push( new Point( tableWidth, 0 ) );
					pts.push( new Point( tableWidth, tableHeight ) );
					pts.push( new Point( tableWidth - ( right / 2 ), tableHeight - ( bottom / 2 ) ) );
					pts.push( new Point( tableWidth - ( right / 2 ), top / 2 ) );
					pts.push( new Point( tableWidth, 0 ) );
					stack.push( pts );
					pts = new Vector.<Point>();
					pts.push( new Point( tableWidth - ( right / 2 ), top / 2 ) );
					pts.push( new Point( tableWidth - ( right / 2 ), tableHeight - ( bottom / 2 ) ) );
					pts.push( new Point( tableWidth - right, tableHeight - bottom ) );
					pts.push( new Point( tableWidth - right, top ) );
					pts.push( new Point( tableWidth - ( right / 2 ), top / 2 ) );
					stack.push( pts );
					break;
				case 2:
					pts = new Vector.<Point>();
					pts.push( new Point( tableWidth, tableHeight ) );
					pts.push( new Point( 0, tableHeight ) );
					pts.push( new Point( left / 2, tableHeight - ( bottom / 2 ) ) );
					pts.push( new Point( tableWidth - ( right / 2 ), tableHeight - ( bottom / 2 ) ) );
					pts.push( new Point( tableWidth, tableHeight ) );
					stack.push( pts );
					pts = new Vector.<Point>();
					pts.push( new Point( tableWidth - ( right / 2 ), tableHeight - ( bottom / 2 ) ) );
					pts.push( new Point( left / 2, tableHeight - ( bottom / 2 ) ) );
					pts.push( new Point( left, tableHeight - bottom ) );
					pts.push( new Point( tableWidth - right, tableHeight - bottom ) );
					pts.push( new Point( tableWidth - ( right / 2 ), tableHeight - ( bottom / 2 ) ) );
					stack.push( pts );
					break;
				case 3:
					pts = new Vector.<Point>();
					pts.push( new Point( 0, 0 ) );
					pts.push( new Point( left / 2, top / 2 ) );
					pts.push( new Point( left / 2, tableHeight - ( bottom / 2 ) ) );
					pts.push( new Point( 0, tableHeight ) );
					pts.push( new Point( 0, 0 ) );
					stack.push( pts );
					pts = new Vector.<Point>();
					pts.push( new Point( left / 2, top / 2 ) );
					pts.push( new Point( left, top ) );
					pts.push( new Point( left, tableHeight - bottom ) );
					pts.push( new Point( left / 2, tableHeight - ( bottom / 2 ) ) );
					pts.push( new Point( left / 2, top / 2 ) );
					stack.push( pts );
					break;
			}
			return stack;
		}
		
		/**
		 * @private
		 * 
		 * Composes rectangular area for border based on table width and height and index. 
		 * @param border TableBorderLeg
		 * @param tableWidth Number
		 * @param tableHeight Number
		 * @return Vector.<Rectangle>
		 */
		override protected function composeRectangle( border:TableBorderLeg, tableWidth:Number, tableHeight:Number ):Rectangle
		{
			var index:int = border.index;
			var widths:Array = _context.determineBorderWidth();
			var top:Number = widths[0];
			var right:Number = widths[1];
			var bottom:Number = widths[2];
			var left:Number = widths[3];
			
			var rect:Rectangle = new Rectangle();
			switch( index )
			{
				case 0:
					rect = new Rectangle( 0, 0, tableWidth, top );
					break;
				case 1:
					rect = new Rectangle( tableWidth - right, 0, right, tableHeight );
					break;
				case 2:
					rect = new Rectangle( 0, tableHeight - bottom, tableWidth, bottom );
					break;
				case 3:
					rect = new Rectangle( 0, 0, left, tableHeight );
					break;
			}
			return rect;
		}
	}
}