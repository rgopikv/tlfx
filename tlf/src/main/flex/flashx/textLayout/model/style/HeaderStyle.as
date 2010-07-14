package flashx.textLayout.model.style
{
	import flashx.textLayout.utils.DimensionTokenUtil;

	public class HeaderStyle implements IHeaderStyle
	{
		protected var _lineHeight:*;
		
		public function HeaderStyle() {}
		
		public function getComputedLineHeight( fontSizeValue:* ):Number
		{
			if( _lineHeight ) return DimensionTokenUtil.normalize( _lineHeight );
			
			return DimensionTokenUtil.normalize( fontSizeValue ) * 1.8;
		}
		
		public function isUndefined( property:String ):Boolean
		{
			return ( this[property] ) ? false : true;
		}
		
		public function undefineStyleProperty( property:String ):void
		{
			this[property] = undefined;
		}
		
		public function get lineHeight():*
		{
			return _lineHeight;
		}
		public function set lineHeight(value:*):void
		{
			_lineHeight = value;
		}
	}
}