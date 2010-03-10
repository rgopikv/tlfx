package flashx.textLayout.container
{
	import flash.display.Sprite;
	
	/**
	 * AutoSizableControllerContainer is the display Sprite used for a AutosizableContainerController. 
	 * @author toddanderson
	 */
	public class AutosizableControllerContainer extends Sprite implements ISizableContainer
	{
		protected var _controller:AutosizableContainerController;
		
		/**
		 * Constructor.
		 */
		public function AutosizableControllerContainer() { super(); }
		
		/**
		 * Initializes container with a reference to controller. 
		 * @param controller AutosizableContainerController
		 */
		public function initialize( controller:AutosizableContainerController ):void
		{
			_controller = controller;
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
	}
}