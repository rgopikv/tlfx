package flashx.textLayout.model.table
{
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import flashx.textLayout.model.style.BorderStyleEnum;
	import flashx.textLayout.model.style.IBorderStyle;
	import flashx.textLayout.model.style.ITableStyle;
	import flashx.textLayout.model.table.ITableDecorationContext;
	import flashx.textLayout.operations.PasteOperation;
	
	/**
	 * TableBorderRenderer is a helper class to render borders on a target display using the drawing API. 
	 * @author toddanderson
	 */
	public class TableBorderRenderer
	{
		protected var _targetDisplay:Shape;
		protected var _context:ITableDecorationContext;
		
		private static const DIRECTION_HORIZONTAL:uint = 0;
		private static const DIRECTION_VERTICAL:uint = 1;
		
		/**
		 * Constructor. 
		 * @param targetDisplay Shape The target display to draw graphics on.
		 * @param context ITableDecorationContext
		 */
		public function TableBorderRenderer( targetDisplay:Shape, context:ITableDecorationContext )
		{
			_targetDisplay = targetDisplay;
			_context = context;
		}
		
		/**
		 * @private
		 * 
		 * Determines if the border leg should be rendered on the display. 
		 * @param leg BorderLeg
		 * @return  Boolean
		 */
		protected function isBorderDrawable( leg:TableBorderLeg ):Boolean
		{
			return leg.thickness > 0 && leg.style != BorderStyleEnum.NONE && leg.style != BorderStyleEnum.HIDDEN && leg.style != BorderStyleEnum.UNDEFINED;
		}
		
		/**
		 * Returns flag of border sizes all being 1 px. 
		 * @param top Number
		 * @param right Number
		 * @param bottom Number
		 * @param left Number
		 * @return Boolean;
		 */
		protected function isOnePixelBorder( top:Number, right:Number, bottom:Number, left:Number ):Boolean
		{
			return top == 1 && right == 1 && bottom == 1 && left == 1;
		}
		
		/**
		 * @private
		 * 
		 * Composes the drawing points used for the drawing API based on the index of the border leg. 
		 * @param index int
		 * @return Vector.<Point>
		 */
		protected function composePoints( border:TableBorderLeg, tableWidth:Number, tableHeight:Number ):Vector.<Point>
		{
			var index:int = border.index;
			var widths:Array = _context.determineBorderWidth();
			var spacing:Number = _context.determineCellSpacing() * 2;
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
					pts.push( new Point( left + tableWidth + spacing, top ) );
					pts.push( new Point( left + tableWidth + right + spacing, 0 ) );
					pts.push( new Point( 0, 0 ) );
					break;
				case 1:
					pts.push( new Point( left + tableWidth + right + spacing, 0 ) );
					pts.push( new Point( left + tableWidth + right + spacing, top + tableHeight + bottom + spacing ) );
					pts.push( new Point( left + tableWidth + spacing, top + tableHeight + spacing ) );
					pts.push( new Point( left + tableWidth + spacing, top ) );
					pts.push( new Point( left + tableWidth + right + spacing, 0 ) );
					break;
				case 2:
					pts.push( new Point( left + tableWidth + right + spacing, top + tableHeight + bottom + spacing ) );
					pts.push( new Point( 0, top + tableHeight + bottom + spacing ) );
					pts.push( new Point( left, top + tableHeight + spacing ) );
					pts.push( new Point( left + tableWidth + spacing, top + tableHeight + spacing ) );
					pts.push( new Point( left + tableWidth + right + spacing, top + tableHeight + bottom + spacing ) );
					break;
				case 3:
					pts.push( new Point( 0, 0 ) );
					pts.push( new Point( left, top ) );
					pts.push( new Point( left, top + tableHeight + spacing ) );
					pts.push( new Point( 0, top + tableHeight + bottom + spacing ) );
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
		protected function composeStackedPoints( border:TableBorderLeg, tableWidth:Number, tableHeight:Number ):Array /* Vector.<Point>[] */
		{
			var index:int = border.index;
			var widths:Array = _context.determineBorderWidth();
			var spacing:Number = _context.determineCellSpacing() * 2;
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
					pts.push( new Point( left + tableWidth + spacing + (right / 2), top / 2 ) );
					pts.push( new Point( left + tableWidth + right + spacing, 0 ) );
					pts.push( new Point( 0, 0 ) );
					stack.push( pts );
					pts = new Vector.<Point>();
					pts.push( new Point( left / 2, top / 2 ) );
					pts.push( new Point( left, top  ) );
					pts.push( new Point( left + tableWidth + spacing, top ) );
					pts.push( new Point( left + tableWidth + spacing + ( right / 2 ), top / 2 ) );
					pts.push( new Point( left / 2, top / 2 ) );
					stack.push( pts );
					break;
				case 1:
					pts = new Vector.<Point>();
					pts.push( new Point( left + tableWidth + right + spacing, 0 ) );
					pts.push( new Point( left + tableWidth + right + spacing, top + tableHeight + bottom + spacing ) );
					pts.push( new Point( left + tableWidth + spacing + (right / 2 ), top + tableHeight + spacing + ( bottom / 2 ) ) );
					pts.push( new Point( left + tableWidth + spacing + (right / 2 ), top / 2 ) );
					pts.push( new Point( left + tableWidth + right + spacing, 0 ) );
					stack.push( pts );
					pts = new Vector.<Point>();
					pts.push( new Point( left + tableWidth + (right / 2) + spacing, top / 2 ) );
					pts.push( new Point( left + tableWidth + (right / 2) + spacing, top + tableHeight + (bottom / 2) + spacing ) );
					pts.push( new Point( left + tableWidth + spacing, top + tableHeight + spacing + bottom ) );
					pts.push( new Point( left + tableWidth + spacing, top ) );
					pts.push( new Point( left + tableWidth + (right / 2) + spacing, top / 2 ) );
					stack.push( pts );
					break;
				case 2:
					pts = new Vector.<Point>();
					pts.push( new Point( left + tableWidth + right + spacing, top + tableHeight + bottom + spacing ) );
					pts.push( new Point( 0, top + tableHeight + bottom + spacing ) );
					pts.push( new Point( left / 2, top + tableHeight + spacing + ( bottom / 2 ) ) );
					pts.push( new Point( left + tableWidth + spacing + ( right / 2 ), top + tableHeight + spacing + ( bottom / 2 ) ) );
					pts.push( new Point( left + tableWidth + right + spacing, top + tableHeight + bottom + spacing ) );
					stack.push( pts );
					pts = new Vector.<Point>();
					pts.push( new Point( left + tableWidth + ( right / 2 ) + spacing, top + tableHeight + ( bottom / 2 ) + spacing ) );
					pts.push( new Point( left / 2, top + tableHeight + ( bottom / 2 ) + spacing ) );
					pts.push( new Point( left, top + tableHeight + spacing ) );
					pts.push( new Point( left + tableWidth + spacing, top + tableHeight + spacing ) );
					pts.push( new Point( left + tableWidth + ( right / 2 ) + spacing, top + tableHeight + ( bottom / 2 ) + spacing ) );
					stack.push( pts );
					break;
				case 3:
					pts = new Vector.<Point>();
					pts.push( new Point( 0, 0 ) );
					pts.push( new Point( left / 2, top / 2 ) );
					pts.push( new Point( left / 2, top + tableHeight + spacing + ( bottom / 2 ) ) );
					pts.push( new Point( 0, top + tableHeight + bottom + spacing ) );
					pts.push( new Point( 0, 0 ) );
					stack.push( pts );
					pts = new Vector.<Point>();
					pts.push( new Point( left / 2, top / 2 ) );
					pts.push( new Point( left, top ) );
					pts.push( new Point( left, top + tableHeight + spacing ) );
					pts.push( new Point( left / 2, top + tableHeight + ( bottom / 2 ) + spacing ) );
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
		protected function composeRectangle( border:TableBorderLeg, tableWidth:Number, tableHeight:Number ):Rectangle
		{
			var index:int = border.index;
			var widths:Array = _context.determineBorderWidth();
			var spacing:Number = _context.determineCellSpacing() * 2;
			var top:Number = widths[0];
			var right:Number = widths[1];
			var bottom:Number = widths[2];
			var left:Number = widths[3];
			
			var rect:Rectangle = new Rectangle();
			switch( index )
			{
				case 0:
					rect = new Rectangle( 0, 0, left + spacing + right + tableWidth, top );
					break;
				case 1:
					rect = new Rectangle( left + spacing + tableWidth, 0, right, top + spacing + bottom + tableHeight );
					break;
				case 2:
					rect = new Rectangle( 0, top + spacing + tableHeight, left + spacing + right + tableWidth, bottom );
					break;
				case 3:
					rect = new Rectangle( 0, 0, left, top + spacing + bottom + tableHeight );
					break;
			}
			return rect;
		}
		
		/**
		 * @private 
		 * 
		 * Determines the appropriate color value for the border leg based on style.
		 * @param leg BorderLeg
		 * @return uint
		 */
		protected function computeBorderColor( leg:TableBorderLeg ):uint
		{
			switch( leg.index )
			{
				case 0:
				case 3:
					leg.color = ( leg.style == BorderStyleEnum.OUTSET ) ? applyAlpha(leg.color) : leg.color;
					break;
				case 1:
				case 2:
					leg.color = ( leg.style == BorderStyleEnum.INSET ) ? applyAlpha(leg.color) : leg.color;
					break;
			}
			return leg.color;
		}
		
		/**
		 * @private 
		 * 
		 * Determines the appropriate color values for the border leg based on RIDGE or GROOVED style.
		 * @param leg BorderLeg
		 * @return uint
		 */
		protected function computeBorderColors( leg:TableBorderLeg ):Array /* uint[] */
		{
			var colors:Array = [];
			switch( leg.index )
			{
				case 0:
				case 3:
					colors.push( ( leg.style == BorderStyleEnum.GROOVE ) ? leg.color : applyAlpha(leg.color) );
					colors.push( ( leg.style == BorderStyleEnum.GROOVE ) ? applyAlpha(leg.color) : leg.color );
					break;
				case 1:
				case 2:
					colors.push( ( leg.style == BorderStyleEnum.RIDGE ) ? leg.color : applyAlpha(leg.color) );
					colors.push( ( leg.style == BorderStyleEnum.RIDGE ) ? applyAlpha(leg.color) : leg.color );
					break;
			}
			return colors;
		}
		
		/**
		 * @private
		 * 
		 * Computes new value of color based on alpha determined from style. 
		 * @param to uint
		 * @param alpha Number
		 * @return uint
		 */
		protected function applyAlpha( to:uint, alpha:Number = 0.5 ):uint
		{
			var r:uint = to >>> 16 & 0xff;
			var g:uint = to >>> 8 & 0xff;
			var b:uint = to & 0x000000ff;
			
			var ca:Number = Math.max( 0, Math.min( 1.0, alpha ) );
			var rr:uint = ca * 0xff + ca * r;
			var rg:uint = ca * 0xff + ca * g;
			var rb:uint = ca * 0xff + ca * b;
			
			return new uint( (rr << 16) | (rg << 8) | rb );
		}
		
		/**
		 * @private
		 * 
		 * Draws an evenly dotted dashed line as the border.
		 * @param border TableBorderLeg
		 * @param direction uint The axis on which the leg resides.
		 * @param rect Rectangle
		 */
		protected function drawDottedLine( border:TableBorderLeg, direction:int, rect:Rectangle ):void
		{
			var widths:Array = _context.determineBorderWidth();
			var width:Number = widths[border.index];
		
			var xpos:Number = rect.x;
			var ypos:Number = rect.y;
			var amount:int;
			var space:Number;
			var i:int;
			var xoffset:Number = width / 2;
			var yoffset:Number = width / 2;
			_targetDisplay.graphics.beginFill( computeBorderColor( border ) );
			if( direction == TableBorderRenderer.DIRECTION_HORIZONTAL )
			{	
				amount = ( ( rect.width - rect.x ) / ( width ) ) * 0.5;
				space = ( ( rect.width - rect.x ) - ( amount * width ) ) / ( amount - 1 );
				for( i = 0; i < amount; i++ )
				{
					_targetDisplay.graphics.drawCircle( xpos + xoffset, ypos + yoffset, width / 2 );
					xpos += width + space;
				}
			}
			else
			{
				amount = ( ( rect.height - rect.y ) / ( width ) ) * 0.5;
				space = ( ( rect.height - rect.y ) - ( amount * width ) ) / ( amount - 1 );
				for( i = 0; i < amount; i++ )
				{
					_targetDisplay.graphics.drawCircle( xpos + xoffset, ypos + yoffset, width / 2 );
					ypos += width + space;
				}
			}
			_targetDisplay.graphics.endFill();
		}
		
		/**
		 * @private
		 * 
		 * Draws an evenly spaced dashed line as the border.
		 * @param border TableBorderLeg
		 * @param direction uint The axis on which the leg resides.
		 * @param rect Rectangle
		 */
		protected function drawDashedLine( border:TableBorderLeg, direction:uint, rect:Rectangle ):void
		{
			var widths:Array = _context.determineBorderWidth();
			var width:Number = widths[border.index];
			var length:Number = ( direction == TableBorderRenderer.DIRECTION_HORIZONTAL ) ? width * 2 : width;
			var depth:Number = ( direction == TableBorderRenderer.DIRECTION_HORIZONTAL ) ? width : width * 2;
			var xpos:Number = rect.x;
			var ypos:Number = rect.y;
			
			var amount:int;
			var space:Number;
			var i:int;
			_targetDisplay.graphics.beginFill( computeBorderColor( border ) );
			if( direction == TableBorderRenderer.DIRECTION_HORIZONTAL )
			{
				amount = ( ( rect.width - rect.x ) / length ) * 0.5;
				space = ( ( rect.width - rect.x ) - ( amount * length ) ) / ( amount - 1 );
				for( i = 0; i < amount; i++ )
				{
					_targetDisplay.graphics.drawRect( xpos, ypos, length, depth );
					xpos += length + space;
				}
			}
			else
			{
				amount = ( ( rect.height - rect.y ) / depth ) * 0.5;
				space = ( ( rect.height - rect.y ) - ( amount * depth ) ) / ( amount - 1 );
				for( i = 0; i < amount; i++ )
				{
					_targetDisplay.graphics.drawRect( xpos, ypos, length, depth );
					ypos += depth + space;
				}
			}
			_targetDisplay.graphics.endFill();
		}
		
		/**
		 * @private
		 * 
		 * Draws an evenly spaced double line as the border.
		 * @param border TableBorderLeg
		 * @param direction uint The axis on which the leg resides.
		 * @param rect Rectangle
		 */
		protected function drawDoubleLine( border:TableBorderLeg, direction:uint, rect:Rectangle ):void
		{
			// If less than 2, it is rendered solid.
			_targetDisplay.graphics.beginFill( computeBorderColor( border ) );
			if( width < 2 ) 
			{
				_targetDisplay.graphics.drawRect( rect.x, rect.y, rect.width, rect.height );
			}
			else
			{
				var width:Number;
				if( direction == TableBorderRenderer.DIRECTION_HORIZONTAL )
				{
					width = rect.height / 3;
					_targetDisplay.graphics.drawRect( rect.x, rect.y, rect.width, width);
					_targetDisplay.graphics.drawRect( rect.x, rect.y + ( width * 2 ), rect.width, width );
				}
				else
				{
					width = rect.width / 3;
					_targetDisplay.graphics.drawRect( rect.x, rect.y, width, rect.height );
					_targetDisplay.graphics.drawRect( rect.x + ( width * 2 ), rect.y, width, rect.height );
				}
			}
			_targetDisplay.graphics.endFill();
		}
		
		/**
		 * @private
		 * 
		 * Draws border with angles for styles INSET, OUTSET and SOLID. 
		 * @param border TableBorderLeg
		 * @param tableWidth Number
		 * @param tableHeight Number
		 */
		protected function drawAngledBorder( border:TableBorderLeg, tableWidth:Number, tableHeight:Number ):void
		{
			var pts:Vector.<Point> = composePoints( border, tableWidth, tableHeight );
			var point:Point = pts.shift();
			_targetDisplay.graphics.beginFill( computeBorderColor( border ) );
			_targetDisplay.graphics.moveTo( point.x, point.y );
			while( pts.length > 0 )
			{
				point = pts.shift();
				_targetDisplay.graphics.lineTo( point.x, point.y );
			}
			_targetDisplay.graphics.endFill();
		}
		
		/**
		 * @private
		 * 
		 * Draws a border with stacked angels for styles RIDGE and GROOVE.
		 * @param border TableBorderLeg
		 * @param style String
		 * @param tableWidth Number
		 * @param tableHeight Number
		 */
		protected function drawStackedAngledBorder( border:TableBorderLeg, tableWidth:Number, tableHeight:Number ):void
		{
			var stack:Array = composeStackedPoints( border, tableWidth, tableHeight ); /* Vector.<Point>[] */
			var colors:Array = computeBorderColors( border );
			var pts:Vector.<Point>;
			
			while( stack.length > 0 )
			{
				pts = stack.shift() as Vector.<Point>;
				var point:Point = pts.shift();
				_targetDisplay.graphics.beginFill( colors.shift() );
				_targetDisplay.graphics.moveTo( point.x, point.y );
				while( pts.length > 0 )
				{
					point = pts.shift();
					_targetDisplay.graphics.lineTo( point.x, point.y );
				}
				_targetDisplay.graphics.endFill();
			}
		}
		
		/**
		 * @private
		 * 
		 * Draws a border based on rectangular area for styles DOTTED, DASHED and DOUBLE. 
		 * @param border TableBorderLeg
		 * @param style String
		 * @param tableWidth Number
		 * @param tableHeight Number
		 */
		protected function drawStraightBorder( border:TableBorderLeg, tableWidth:Number, tableHeight:Number ):void
		{
			var rect:Rectangle = composeRectangle( border, tableWidth, tableHeight );
			var direction:uint = ( border.index % 2 == 0 ) ? TableBorderRenderer.DIRECTION_HORIZONTAL : TableBorderRenderer.DIRECTION_VERTICAL;
			switch( border.style )
			{
				case BorderStyleEnum.DOTTED:
					drawDottedLine( border, direction, rect );
					break;
				case BorderStyleEnum.DASHED:
					drawDashedLine( border, direction, rect );
					break;
				case BorderStyleEnum.DOUBLE:
					drawDoubleLine( border, direction, rect );
					break;
			}
		}
		
		/**
		 * Renders a border on the target display baed on TableBorderLeg model and dimensions of the table. 
		 * @param border TableBorderLeg
		 * @param tableWidth Number
		 * @param tableHeight Number
		 */
		public function drawBorder( border:TableBorderLeg, tableWidth:Number, tableHeight:Number ):void
		{
			if( !isBorderDrawable( border ) ) return;
			
			var borderStyle:String = border.style;
			switch( borderStyle )
			{
				case BorderStyleEnum.INSET:
				case BorderStyleEnum.OUTSET:
				case BorderStyleEnum.SOLID:
					drawAngledBorder( border, tableWidth, tableHeight );
					break;
				case BorderStyleEnum.DOTTED:
				case BorderStyleEnum.DASHED:
				case BorderStyleEnum.DOUBLE:
					drawStraightBorder( border, tableWidth, tableHeight );
					break;
				case BorderStyleEnum.RIDGE:
				case BorderStyleEnum.GROOVE:
					drawStackedAngledBorder( border, tableWidth, tableHeight );
					break;
			}
		}
	}
}