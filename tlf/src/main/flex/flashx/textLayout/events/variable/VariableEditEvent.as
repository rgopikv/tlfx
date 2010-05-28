package flashx.textLayout.events.variable
{
	import flash.events.Event;
	
	import flashx.textLayout.elements.IVarElement;
	
	public class VariableEditEvent extends Event
	{
		public var element:IVarElement;
		public static const EDIT_CHANGE:String = "editChange";
		public static const EDIT_VARIABLE:String = "editVariable";
		
		public function VariableEditEvent( type:String, element:IVarElement )
		{
			super( type, true );
			this.element = element;
		}
	}
}