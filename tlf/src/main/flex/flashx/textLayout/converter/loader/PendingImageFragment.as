package flashx.textLayout.converter.loader
{
	import flashx.textLayout.utils.FragmentAttributeUtil;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;

	/**
	 * PendingImageFragment is a begind the scenes loader for images related to <img /> tag.
	 * Images are loaded and dimnesion properties are set to the images on fragments that do not have those attributes.
	 * This is needed in order to properly preprocess the table layout. 
	 * @author toddanderson
	 */
	public class PendingImageFragment extends EventDispatcher
	{
		protected var fragment:XML;
		protected var source:String;
		protected var loader:Loader;
		
		/**
		 * Constructor.
		 *  
		 * @param fragment The target <img /> fragment.
		 */
		public function PendingImageFragment( fragment:XML )
		{
			this.fragment = fragment;
			source = fragment.@source;
			
			// Create loader and assign listeners.
			loader = new Loader();
			addListeners();
		}
		
		/**
		 * @priavte 
		 * 
		 * Assigns handlers for Loader instance.
		 */
		protected function addListeners():void
		{
			loader.contentLoaderInfo.addEventListener( Event.COMPLETE, handleComplete, false, 0, true );
			loader.contentLoaderInfo.addEventListener( ProgressEvent.PROGRESS, handleProgress, false, 0, true );
			loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, handleError, false, 0, true );
		}
		
		/**
		 * @private
		 *  
		 * Removes handlers on Loader instance.
		 */
		protected function removeListeners():void
		{
			loader.contentLoaderInfo.removeEventListener( Event.COMPLETE, handleComplete, false );
			loader.contentLoaderInfo.removeEventListener( ProgressEvent.PROGRESS, handleProgress, false );
			loader.contentLoaderInfo.removeEventListener( IOErrorEvent.IO_ERROR, handleError, false );
		}
		
		/**
		 * @private
		 * 
		 * Event handler for complete load of image. 
		 * @param evt Event
		 */
		protected function handleComplete( evt:Event ):void
		{
			var content:DisplayObject = ( evt.target as LoaderInfo ).content;
			// Only apply to properties that weren't set before.
			if( !FragmentAttributeUtil.exists( fragment, "width" ) ) 	fragment.@width = content.width;
		 	if( !FragmentAttributeUtil.exists( fragment, "height" ) )	fragment.@height = content.height;
			
			// remove listeners.
			removeListeners();
			// redispatch.
			dispatchEvent( evt.clone() );
		}
		
		/**
		 * @private
		 * 
		 * Event handler for progress of image download. 
		 * @param evt ProgressEvent
		 */
		protected function handleProgress( evt:ProgressEvent ):void
		{
			dispatchEvent( evt.clone() );
		}
		
		/**
		 * @private
		 * 
		 * Event handler for load of image. Fail silently. 
		 * @param evt Event
		 */
		protected function handleError( evt:Event ):void
		{
			// remove listeners.
			removeListeners();
			// redispatch.
			dispatchEvent( evt.clone() );
		}
		
		/**
		 * Instruct to begin loading the image.
		 */
		public function load():void
		{
			loader.load( new URLRequest( source ) );
		}
	}
}