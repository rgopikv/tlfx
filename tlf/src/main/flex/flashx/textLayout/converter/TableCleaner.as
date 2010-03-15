package flashx.textLayout.converter
{
	import flashx.textLayout.converter.loader.PendingImageFragment;
	import flashx.textLayout.converter.loader.PendingImageQueue;
	import flashx.textLayout.events.TagParserCleanCompleteEvent;
	import flashx.textLayout.events.TagParserCleanProgressEvent;
	import flashx.textLayout.utils.FragmentAttributeUtil;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.ProgressEvent;
	
	[Event(name="cleanProgress", type="flashx.textLayout.events.TagParserCleanProgressEvent")]
	[Event(name="cleanComplete", type="flashx.textLayout.events.TagParserCleanCompleteEvent")]
	/**
	 * TableCleaner performs any preparsing operations needed to reliable parse a Table. This currently includes preloading images and updating their attibutes. 
	 * @author toddanderson
	 */
	public class TableCleaner extends EventDispatcher implements ITagCleaner
	{
		protected var queue:PendingImageQueue;
		protected var cleanXML:XML;
		
		protected var originalTotal:int;
		
		/**
		 * Constructor.
		 */
		public function TableCleaner() 
		{
			queue = new PendingImageQueue();
			queue.addEventListener( ProgressEvent.PROGRESS, handlePendingItemProgress, false, 0, true );
			queue.addEventListener( Event.COMPLETE, handlePendingQueueComplete, false, 0, true );
		}
		
		/**
		 * @private
		 * 
		 * Event handler for progress of one item in queue. 
		 * @param evt ProgressEvent
		 */
		protected function handlePendingItemProgress( evt:ProgressEvent ):void
		{
			var message:String = "Loading " + ( originalTotal - queue.length() ) + " of " + originalTotal;
			var percent:Number = ( evt.bytesLoaded / evt.bytesTotal ) * 100;
			dispatchEvent( new TagParserCleanProgressEvent( message, percent ) );
		}
		
		/**
		 * @private
		 * 
		 * Event handler for completion and emptying of queue. 
		 * @param evt Event
		 */
		protected function handlePendingQueueComplete( evt:Event ):void
		{
			dispatchEvent( new TagParserCleanCompleteEvent( cleanXML ) );
		}
		
		/**
		 * Cleans the supplied table fragment to prepare for proper parsing. 
		 * @param fragment String
		 */
		public function clean( fragment:String ):void
		{
			try
			{
				XML.ignoreComments = true;
				XML.ignoreWhitespace = true;
				XML.prettyPrinting = false;
				XML.prettyIndent = 0;
				cleanXML = XML( fragment );
				
				// run through <img /> tags and drop into queue.
				var imageList:XMLList = cleanXML..img;
				var imgFragment:XML;
				for( var i:int = 0; i < imageList.length(); i++ )
				{
					imgFragment = imageList[i] as XML;
					var imgSource:String = imgFragment.@src;
					if ( imgSource.length > 0 )
					{
						delete imgFragment.@src;
						imgFragment.@source = "http://www.newviewnetworks.com/nvnhome/imageProxy.cfm?imageURL=" + imgSource;
					}
					// only send it to queue if dimensions aren't set.
					if( !FragmentAttributeUtil.exists( imgFragment, "width" ) || !FragmentAttributeUtil.exists( imgFragment, "height" ) )
					{
						queue.addImage( new PendingImageFragment( imgFragment ) );
					}
				}
				// Store original length for notification.
				originalTotal = queue.length();
				// Start the queue.
				queue.load();
			}
			catch( e:Error )
			{
				// fail silently.
				trace( e.message );
			}
		}
		
		/**
		 * Performs any necessary clean up instructions.
		 */
		public function dismantle():void
		{
			queue.removeEventListener( ProgressEvent.PROGRESS, handlePendingItemProgress, false );
			queue.removeEventListener( Event.COMPLETE, handlePendingQueueComplete, false );
			queue = null;
		}
	}
}