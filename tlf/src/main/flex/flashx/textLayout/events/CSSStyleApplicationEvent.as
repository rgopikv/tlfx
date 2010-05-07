package flashx.textLayout.events
{
	import flash.events.Event;
	
	import flashx.textLayout.elements.FlowElement;
	
	public class CSSStyleApplicationEvent extends Event
	{
		public var element:FlowElement;
		public static const STYLE_COMPLETE:String = "styleComplete";
		public function CSSStyleApplicationEvent( element:FlowElement )
		{
			super( CSSStyleApplicationEvent.STYLE_COMPLETE );
			this.element = element;
		}
		
		override public function clone():Event
		{
			return new CSSStyleApplicationEvent( element );
		}
	}
}