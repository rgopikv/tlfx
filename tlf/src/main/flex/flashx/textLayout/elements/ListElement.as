package flashx.textLayout.elements
{
	import flashx.textLayout.tlf_internal;

	use namespace tlf_internal;
	
	public class ListElement extends DivElement
	{
		public static const NONE:String 		= 	'none';
		public static const ORDERED:String		=	'ordered';
		public static const UNORDERED:String	=	'unordered';
		
		private var _mode:String;
		
		public function ListElement()
		{
			super();
			
			_mode = ListElement.NONE;			
		}	
		
		override public function addChild(child:FlowElement) : FlowElement
		{
			var newChild:ListItemElement = super.addChild( child ) as ListItemElement;
			
			newChild.mode = mode;
			
			updateList();
			updateFlow();
			
			return newChild;
		}
		
		override public function addChildAt(index:uint, child:FlowElement) : FlowElement
		{
			var newChild:ListItemElement = super.addChildAt(index, child) as ListItemElement;
			
			newChild.mode = mode;		
			
			updateList();
			updateFlow();
			
			return newChild;
		}
		
		override public function removeChild(child:FlowElement) : FlowElement
		{
			var removedChild:ListItemElement = super.removeChild( child ) as ListItemElement;
			
			updateList();
			updateFlow();
			
			return removedChild;
		}
		
		override public function removeChildAt(index:uint) : FlowElement
		{
			var removedChild:ListItemElement = super.removeChildAt( index ) as ListItemElement;
			
			updateList();
			updateFlow();
			
			return removedChild;
		}
		
		private function updateList():void 
		{
			updateFirst();
			updateLast();
			updateNumbers();
		}
		
		/**
		 * Reset all the current list item numbers.
		 */
		private function updateNumbers():void 
		{
			var i:int = numChildren;
			while ( --i > -1 )
			{
				( getChildAt(i) as ListItemElement ).number = i;
			}
		}
		
		/**
		 * Ensures that a list with at least one list item will have a line-height break before it 
		 * by adding an empty list item at the head of the list.
		 */
		private function updateFirst():void 
		{
			var first:ListItemElement;
			
			for (var i:int = 0; i < numChildren; i++)
			{
				var item:ListItemElement = ListItemElement(getChildAt(i));
				
				if (item.first)
				{
					first = item;
					break;
				}
			}
			
			if (numChildren > 0)
			{
				if (!first)
				{
					first = new ListItemElement();
					first.mode = NONE;
					first.text = "";
					first.first = true;
					
					super.addChildAt(0, first);
				}
			}
		}
		
		/**
		 * Ensures a list with at least one list item will have a line-height break after it
		 * by adding an empty list item at the tail of the list.
		 */
		private function updateLast():void
		{					
			var last:ListItemElement;
			
			for (var i:int = 0; i < numChildren; i++)
			{
				var item:ListItemElement = ListItemElement(getChildAt(i));

				if (item.last)
				{
					last = item;
					break;
				}
			}		

			if (numChildren > 1)
			{				
				if (!last)
				{
					last = new ListItemElement();
					last.mode = NONE;
					last.text = "";
					last.last = true;
				}
				else
				{
					super.removeChildAt(getChildIndex(last));
				}
				
				super.addChild(last);	
			}
		}
		
		private function updateFlow():void
		{
			if ( getTextFlow() )
			{
				if ( getTextFlow().flowComposer )
				{
					getTextFlow().flowComposer.updateAllControllers();
				}
			}
		}
		
		public function set mode( value:String ):void
		{
			if ( value == ListElement.ORDERED || value == ListElement.UNORDERED )
			{
				_mode = value;
				var i:int = numChildren;
				while ( --i > -1 )
				{
					( getChildAt(i) as ListItemElement ).mode = _mode;
				}
				updateFlow();
			}
			else
				return;
		}
		public function get mode():String
		{
			return _mode;
		}
		
		
		
		//	Necessary in order to be able to add children
		override tlf_internal function canOwnFlowElement(elem:FlowElement) : Boolean
		{
			return elem is ListItemElement;
		}
		
		//	Necessary for instantiation
		override protected function get abstract() : Boolean
		{
			return false;
		}
	}
}