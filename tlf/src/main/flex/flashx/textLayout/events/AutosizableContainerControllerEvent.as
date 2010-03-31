package flashx.textLayout.events
{
	import flash.events.Event;
	
	import flashx.textLayout.container.AutosizableContainerController;
	
	/**
	 * AutosizableContainerControllerEvent is an event corresponding to the resize of an autosizable container controller. 
	 * @author toddanderson
	 */
	public class AutosizableContainerControllerEvent extends Event
	{
		public var width:Number;
		public var height:Number;
		public var oldWidth:Number;
		public var oldHeight:Number;
		public var controller:AutosizableContainerController;
		public static const RESIZE_COMPLETE:String = "resizeComplete";
		/**
		 * Constructor. 
		 * @param type String
		 * @param controller AutosizableContainerController The dispatching instance.
		 * @param offset Number The offset in height after a resize operation.
		 */
		public function AutosizableContainerControllerEvent( type:String, controller:AutosizableContainerController, width:Number, height:Number, oldWidth:Number, oldHeight:Number )
		{
			super( type );
			this.controller = controller;
			this.width = width;
			this.height = height;
			this.oldWidth = oldWidth;
			this.oldHeight = oldHeight;
		}
		
		/**
		 * @inherit
		 */
		override public function clone():Event
		{
			return new AutosizableContainerControllerEvent( type, controller, width, height, oldWidth, oldHeight );
		}
	}
}