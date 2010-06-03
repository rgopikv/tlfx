package flashx.textLayout.model.style
{
	public interface IBorderStyle extends IBoxModelUnitStyle
	{
		/**
		 * Returns the computed style based on supplied values and default values. 
		 * @return IBorderStyle
		 */
		function getComputedStyle( forceNew:Boolean = false ):IBorderStyle;
		
		function computeBorderWidthBasedOnStyle( style:String, presetValue:Number ):Number;
		function computeBorderStyleBasedOnWidth( width:int, presetStyle:String ):String
		
		function get borderBottomWidth():*;
		function set borderBottomWidth(value:*):void;
		function get borderTopWidth():*;
		function set borderTopWidth(value:*):void;
		function get borderRightWidth():*;
		function set borderRightWidth(value:*):void;
		function get borderLeftWidth():*;
		function set borderLeftWidth(value:*):void;
		function get borderWidth():*;
		function set borderWidth(value:*):void;
		function get borderBottomStyle():*;
		function set borderBottomStyle(value:*):void;
		function get borderTopStyle():*;
		function set borderTopStyle(value:*):void;
		function get borderRightStyle():*;
		function set borderRightStyle(value:*):void;
		function get borderLeftStyle():*;
		function set borderLeftStyle(value:*):void;
		function get borderStyle():*;
		function set borderStyle(value:*):void;
		function get borderBottomColor():*;
		function set borderBottomColor(value:*):void;
		function get borderTopColor():*;
		function set borderTopColor(value:*):void;
		function get borderRightColor():*;
		function set borderRightColor(value:*):void;
		function get borderLeftColor():*;
		function set borderLeftColor(value:*):void;
		function get borderColor():*;
		function set borderColor(value:*):void;
		function get borderBottom():*;
		function set borderBottom(value:*):void;
		function get borderTop():*;
		function set borderTop(value:*):void;
		function get borderRight():*;
		function set borderRight(value:*):void;
		function get borderLeft():*;
		function set borderLeft(value:*):void;
		function get border():*;
		function set border(value:*):void;
	}
}