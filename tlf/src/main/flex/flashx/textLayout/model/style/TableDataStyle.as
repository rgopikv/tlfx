package flashx.textLayout.model.style
{
	public class TableDataStyle extends TableStyle
	{
		public function TableDataStyle(borderStyle:Array=null, borderWidth:Array=null, borderColor:Array=null, borderSpacing:Number=Number.NaN, borderCollapse:String=null)
		{
			super(borderStyle, borderWidth, borderColor, borderSpacing, borderCollapse);
		}
		
		/**
		* @inherit
		*/
		override protected function getDefaultBorderStyle():Array
		{
			return [TableBorderStyleEnum.INSET, TableBorderStyleEnum.INSET, TableBorderStyleEnum.INSET, TableBorderStyleEnum.INSET];
		}
	}
}