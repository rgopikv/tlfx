package flashx.textLayout.container
{
	import flash.display.Sprite;
	
	[Event(name="resizeComplete", type="flashx.textLayout.events.AutosizableContainerEvent")]
	/**
	 * AutoSizableDisplayContainer is the display Sprite used for a AutosizableContainerController. 
	 * @author toddanderson
	 */
	public class AutosizableDisplayContainer extends Sprite implements ISizableContainer
	{
		protected var _controller:AutosizableContainerController;
		
		/**
		 * Constructor.
		 */
		public function AutosizableDisplayContainer() { super(); }
		
		/**
		 * Initializes container with a reference to controller. 
		 * @param controller AutosizableContainerController
		 */
		public function initialize( controller:AutosizableContainerController ):void
		{
			_controller = controller;
		}
		
		/**
		 * Returns reference to the container controller that manages this dispay. 
		 * @return AutosizableContainerController
		 */
		public function get controller():ContainerController
		{
			return _controller;
		}
		/**
		 * Sets reference to the container controller that manages this display. 
		 * @param value ContainerController
		 */
		public function set controller( value:ContainerController ):void
		{
			_controller = value as AutosizableContainerController;
		}
		
		/**
		 * Returns the height defined by AutosizableContainerController. 
		 * @return Number
		 */
		public function get actualHeight():Number
		{
			return _controller.actualHeight;
		}
		
		/**
		 * Returns the ascent associated with the top element content. This is used to shim the container into place. 
		 * @return Number
		 */
		public function get topElementAscent():Number
		{
			return _controller.topElementAscent;
		}
		
		/**
		 * Returns the offset along the y axis supposed after the container, which can be the case wehn stripping paragraphSpaceAfter form the last element. 
		 * @return Number
		 */
		public function get containerSpaceAfter():Number
		{
			return _controller.controllerOffsetAfter;
		}
	}
}