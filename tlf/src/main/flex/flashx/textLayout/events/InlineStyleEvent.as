package flashx.textLayout.events
{
	import flash.events.Event;
	
	public class InlineStyleEvent extends Event
	{
		public var oldStyle:*;
		public var newStyle:*;
		public static const APPLIED_STYLE_CHANGE:String = "appliedStyleChange";
		public static const EXPLICIT_STYLE_CHANGE:String = "explicitStyleChange";
		
		public function InlineStyleEvent( type:String, oldStyle:*, newStyle:* )
		{
			super( type );
			this.oldStyle = oldStyle;
			this.newStyle = newStyle;
		}
	}
}