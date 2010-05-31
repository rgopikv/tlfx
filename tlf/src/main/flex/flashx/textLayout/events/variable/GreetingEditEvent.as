package flashx.textLayout.events.variable
{
	import flash.events.Event;
	
	import flashx.textLayout.elements.GreetingElement;

	public class GreetingEditEvent extends Event
	{
		public var element:GreetingElement;
		public static const EDIT_GREETING_CHANGE:String = "editGreetingChange";
		public static const EDIT_GREETING:String = "editGreeting";
		
		public function GreetingEditEvent( type:String, element:flashx.textLayout.elements.GreetingElement )
		{
			super( type, true );
			this.element = element;
		}
	}
}