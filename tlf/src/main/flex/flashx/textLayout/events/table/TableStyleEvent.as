package flashx.textLayout.events.table
{
	import flash.events.Event;

	public class TableStyleEvent extends Event
	{
		public static const STYLE_CHANGED:String = "styleChanged";
		
		public function TableStyleEvent()
		{
			super( TableStyleEvent.STYLE_CHANGED );
		}
	}
}