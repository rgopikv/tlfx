package flashx.textLayout.model.style
{
	public interface IPaddingStyle extends IBoxModelUnitStyle
	{
		/**
		 * Returns the computed style based on supplied values and default values. 
		 * @return IPaddingStyle
		 */
		function getComputedStyle( forceNew:Boolean = false ):IPaddingStyle;
		/**
		 * Accessor/Modifier for the padding property. 
		 * @param value *
		 */
		function get padding():*;
		function set padding( value:* ):void;
		
		 function get paddingBottom():*;
		 function set paddingBottom(value:*):void;
		 function get paddingTop():*;
		 function set paddingTop(value:*):void;
		 function get paddingRight():*;
		 function set paddingRight(value:*):void;
		 function get paddingLeft():*;
		 function set paddingLeft(value:*):void;
	}
}