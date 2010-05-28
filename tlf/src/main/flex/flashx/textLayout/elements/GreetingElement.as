package flashx.textLayout.elements
{
	import flash.events.ContextMenuEvent;
	
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.VarElement;
	import flashx.textLayout.events.variable.GreetingEditEvent;
	
	public class GreetingElement extends VarElement
	{
		public function GreetingElement()
		{
			super();
		}
		
		override protected function handleEditItem(event:ContextMenuEvent):void
		{
			var tf:TextFlow = getTextFlow();
			tf.dispatchEvent( new flashx.textLayout.events.variable.GreetingEditEvent( GreetingEditEvent.EDIT_GREETING, this ) );
		}
		
		override protected function notifyOfChange():void
		{
			var tf:TextFlow = getTextFlow();
			tf.dispatchEvent( new GreetingEditEvent( GreetingEditEvent.EDIT_GREETING_CHANGE, this ) );
		}
	}
}