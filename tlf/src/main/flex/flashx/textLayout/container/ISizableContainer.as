package flashx.textLayout.container
{
	import flash.events.IEventDispatcher;

	/**
	 * ISizableContainer is an interface for custom controller containers that are used as displays for ContainerController.
	 * They can report back size and position properties as they relate to runtime changes in the container controller.
	 * @author toddanderson
	 */
	public interface ISizableContainer extends IEventDispatcher
	{
		function get actualHeight():Number;
		
		function get x():Number;
		function set x( value:Number ):void;
		function get y():Number;
		function set y( value:Number ):void;
		function get width():Number;
		function set width( value:Number ):void;
		function get height():Number;
		function set height( value:Number ):void;
	}
}