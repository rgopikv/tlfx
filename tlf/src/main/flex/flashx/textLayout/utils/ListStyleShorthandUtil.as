package flashx.textLayout.utils
{
	import flashx.textLayout.model.style.ListStyleEnum;
	import flashx.textLayout.model.style.ListStyleShorthand;
	
	public class ListStyleShorthandUtil
	{
		private static function indexOfTypeUnit( units:Array ):int
		{
			var i:int;
			var typeList:Array = ListStyleEnum.getAllTypes();
			for( i = 0; i < units.length; i++ )
			{
				if( typeList.indexOf( units[i] ) != -1 )
					return i;
			}
			return -1;
		}
		
		private static function indexOfImageUnit( units:Array ):int
		{
			var i:int;
			var value:String;
			var regex:RegExp = /(\w)*\.(jp(e)?g|gif|png)\b/ig;
			for( i = 0; i < units.length; i++ )
			{
				value = units[i].toString();
				if( regex.test( value ) )
					return i;
			}
			return -1;
		}
		
		private static function indexOfPositionUnit( units:Array ):int
		{
			var i:int;
			var positionList:Array = ListStyleEnum.getPositions();
			for( i = 0; i < units.length; i++ )
			{
				if( positionList.indexOf( units[i] ) != -1 )
					return i;
			}
			return -1;
		}
		
		public static function deserializeShorthand( value:* ):ListStyleShorthand
		{
			if( !value ) return null;
			
			var type:*;
			var image:*;
			var position:*;
			
			var units:Array = value.toString().split( " " );
			var tIndex:int = ListStyleShorthandUtil.indexOfTypeUnit( units );
			if( tIndex >= 0 )
			{
				type = units[tIndex];
				units.splice( tIndex, 1 );
			}
			var pIndex:int = ListStyleShorthandUtil.indexOfPositionUnit( units );
			if( pIndex >= 0 )
			{
				position = units[pIndex];
				units.splice( pIndex, 1 );	
			}
			var iIndex:int = ListStyleShorthandUtil.indexOfImageUnit( units );
			if( iIndex >= 0 )
			{
				image = units[iIndex];
				units.splice( iIndex, 1 );
			}
			return new ListStyleShorthand( type, image, position );
		}
	}
}