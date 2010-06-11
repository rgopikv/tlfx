package flashx.textLayout.model.table
{
	import flash.geom.Point;

	public class TableBorderLeg
	{
		public var index:int;
		public var thickness:Number;
		public var color:uint;
		public var style:String;
		public var points:Vector.<Point>;
		public function TableBorderLeg( index:int, thickness:Number, color:uint, style:String, points:Vector.<Point> = null )
		{
			this.index = index;
			this.thickness = thickness;
			this.color = color;
			this.style = style;
			this.points = points;
		}
	}
}