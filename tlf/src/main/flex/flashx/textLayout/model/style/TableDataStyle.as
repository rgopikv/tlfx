package flashx.textLayout.model.style
{
	public class TableDataStyle extends TableStyle
	{
		public function TableDataStyle( border:* = undefined, padding:* = undefined )
		{
			super( border, padding );
		}
		
		override protected function getDefaultBorderStyle():String
		{
			_defaultBorderStyle = TableBorderStyleEnum.INSET;
			return _defaultBorderStyle;
		}
	}
}