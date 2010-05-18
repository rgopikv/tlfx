package flashx.textLayout.events
{
	import flash.events.Event;
	
	import flashx.textLayout.container.AutosizableContainerController;
	
	/**
	 * AutosizableContainerControllerEvent is an event corresponding to the resize of an autosizable container controller. 
	 * @author toddanderson
	 */
	public class AutosizableContainerEvent extends Event
	{
		public var newHeight:Number;
		public var oldHeight:Number;
		public static const RESIZE_COMPLETE:String = "resizeComplete";
		/**
		 * Constructor. 
		 * @param type String
		 * @param controller AutosizableContainerController The dispatching instance.
		 * @param offset Number The offset in height after a resize operation.
		 */
		public function AutosizableContainerEvent( type:String, newHeight:Number, oldHeight:Number )
		{
			super( type );
			this.newHeight = newHeight;
			this.oldHeight = oldHeight;
		}
		
		/**
		 * @inherit
		 */
		override public function clone():Event
		{
			return new AutosizableContainerEvent( type, newHeight, oldHeight );
		}
	}
}