package flashx.textLayout.converter.loader
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="progress", type="flash.events.ProgressEvent")]
	/**
	 * PendingImageQueue is a queue loader for PendingImageFragment objects. 
	 * @author toddanderson
	 */
	public class PendingImageQueue extends EventDispatcher
	{
		protected var list:Array;
		protected var running:Boolean;
		protected var currentImage:PendingImageFragment;
		
		/**
		 * Constructor.
		 */
		public function PendingImageQueue()
		{
			list = [];
		}
		
		/**
		 * @private
		 * 
		 * Assigns handlers for currently loading image. 
		 * @param image PendingImageFragment
		 */
		protected function addListeners( image:PendingImageFragment ):void
		{
			image.addEventListener( Event.COMPLETE, handleImageComplete, false, 0, true );
			image.addEventListener( ProgressEvent.PROGRESS, handleImageProgress, false, 0, true );
			image.addEventListener( IOErrorEvent.IO_ERROR, handleImageError, false, 0, true );
		}
		/**
		 * @private
		 * 
		 * Removes handlers for currently loading image. 
		 * @param image PendingImageFragment
		 */
		protected function removeListeners( image:PendingImageFragment ):void
		{
			image.removeEventListener( Event.COMPLETE, handleImageComplete, false );
			image.removeEventListener( ProgressEvent.PROGRESS, handleImageProgress, false );
			image.removeEventListener( IOErrorEvent.IO_ERROR, handleImageError, false );
		}
		
		/**
		 * @private 
		 * 
		 * Loads the next image in the queue. If the queue is empty, notifies listening clients of completion.
		 */
		protected function loadNextImage():void
		{
			// Next in queue.
			if( list.length > 0 )
			{
				running = true;
				currentImage = list.shift();
				addListeners( currentImage );
				currentImage.load();
			}
			else // We have emptied the queue.
			{
				running = false;
				dispatchEvent( new Event( Event.COMPLETE ) );
			}
		}
		
		/**
		 * @private
		 * 
		 * Event handler for completion of load for the image. 
		 * @param evt Event
		 */
		protected function handleImageComplete( evt:Event ):void
		{
			removeListeners( evt.target as PendingImageFragment );
			loadNextImage();
		}
		/**
		 * @private
		 * 
		 * Event handle for download progress of current image. 
		 * @param evt ProgressEvent
		 */
		protected function handleImageProgress( evt:ProgressEvent ):void
		{
			dispatchEvent( evt.clone() );
		}
		/**
		 * @private
		 * 
		 * Event handler for error in load for the image. Fail silently and move on in the queue. 
		 * @param evt Event
		 */
		protected function handleImageError( evt:Event ):void
		{
			removeListeners( evt.target as PendingImageFragment );
			loadNextImage();
		}
		
		/**
		 * Adds an image to the queue for loading. 
		 * @param image PendingImageFragment
		 */
		public function addImage( image:PendingImageFragment ):void
		{
			list.push( image );
		}
		
		/**
		 * Instruct to being loading images in queue.
		 */
		public function load():void
		{
			// if not already running, start it off.
			if( !running )
				loadNextImage();
			// else let it proceed on its way.
		}
		
		/**
		 * Returns the length of the queue. 
		 * @return int
		 */
		public function length():int
		{
			return list.length;
		}
	}
}