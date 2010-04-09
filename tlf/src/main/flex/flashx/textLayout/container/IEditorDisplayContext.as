package flashx.textLayout.container
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.IEventDispatcher;
	
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.container.ISizableContainer;
	import flashx.textLayout.elements.table.TableElement;

	public interface IEditorDisplayContext extends IEventDispatcher
	{
		function addContainer( container:ISizableContainer ):void;
		function addContainerAt( container:ISizableContainer, index:int ):void;
		function removeContainer( container:ISizableContainer ):void;
		function removeContainerAt( index:int ):ISizableContainer;
		function getContainerIndex( container:ISizableContainer ):int;
		function getContainerAt( index:int ):ISizableContainer;
		function getContainerLength():int;
		function containsContainer( container:ISizableContainer ):Boolean;
		
		function clean():void;
		function updateDisplay():void;
		function updateContainerOffsetFromIndex( offset:Number, index:int ):void;
		function updateContainerOffsetFromContainer( container:ISizableContainer, index:int ):void;
		function get targetDisplay():DisplayObjectContainer;
		
		function showAlert( message:String ):void;
	}
}