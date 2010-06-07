package flashx.textLayout.model.style
{
	dynamic public class TableDataStyle extends TableStyle
	{
		public function TableDataStyle( border:* = undefined, padding:* = undefined )
		{
			super( border, padding );
		}
		
		override protected function getDefaultBorderStyle():String
		{
			_defaultBorderStyle = BorderStyleEnum.INSET;
			return _defaultBorderStyle;
		}
	}
}