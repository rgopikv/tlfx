package flashx.textLayout.events
{
	import flash.events.Event;
	
	public class UpdateEvent extends Event
	{
		public static const UPDATE:String = 'update';
		
		public function UpdateEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}