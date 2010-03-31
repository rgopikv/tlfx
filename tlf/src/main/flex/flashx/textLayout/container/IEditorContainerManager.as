package flashx.textLayout.container
{
	import flash.display.DisplayObjectContainer;
	import flash.events.IEventDispatcher;
	
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.elements.TextFlow;

	/**
	 * IEditorContainerManager is an interface for composing container controllers and their corresponding displays based on a TextFlow. 
	 * @author toddanderson
	 */
	public interface IEditorContainerManager extends IEventDispatcher
	{
		/**
		 * Composes container controllers and their corresponding displays based on elements of the TextFlow.
		 * @param textFlow TextFlow 
		 * @param elements Array Array of FlowElement
		 * @param initalFlowIndex The index at which to start adding controllers to the flow.
		 */
		function composeContainers( textFlow:TextFlow, elements:Array /*FlowElement[]*/, initialFlowIndex:int = 0 ):void;
		/**
		 * Returns a list of ContainerController instances created based on TextFlow. 
		 * @return Vector.<ContainerController>
		 */
		function getContainerControllers():Vector.<ContainerController>;
		
		function get contentWidth():Number;
		function get contentHeight():Number;
		
		function get targetDisplay():DisplayObjectContainer;
		function set targetDisplay( value:DisplayObjectContainer ):void;
		
		function get padding():int;
		function set padding( value:int ):void;
		
		function get imageProxy():String;
		function set imageProxy( value:String ):void;
		
		function get width():Number;
		function set width( value:Number ):void;
		function get height():Number;
		function set height( value:Number ):void;
	}
}