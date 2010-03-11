package flashx.textLayout.elements
{
	import flashx.textLayout.tlf_internal;

	use namespace tlf_internal;
	
	public class ListElement extends DivElement implements IListElement
	{
		public static const NONE:String 		= 	'none';
		public static const ORDERED:String		=	'ordered';
		public static const UNORDERED:String	=	'unordered';
		
		//private var groups:Array = [];
		
		private var _mode:String;
		
		public function ListElement()
		{
			super();
			
			_mode = ListElement.NONE;			
		}	
		
		override public function addChild(child:FlowElement) : FlowElement
		{
			var newChild:FlowElement = super.addChild( child ) as FlowElement;
			
			if (child is ListItemElement)
			{
				(child as ListItemElement).mode = _mode;
			}
			
			updateList();
			updateFlow();
			
			//addToGroups(newChild);
			
			return newChild;
		}
		
		override public function addChildAt(index:uint, child:FlowElement) : FlowElement
		{
			var newChild:FlowElement = super.addChildAt(index, child) as FlowElement;
			
			if (child is ListItemElement)
			{
				(child as ListItemElement).mode = _mode;
			}		
			
			updateList();
			updateFlow();
			
			//addToGroups(newChild);
			
			return newChild;
		}
		
		override public function removeChild(child:FlowElement) : FlowElement
		{
			var removedChild:ListItemElement = super.removeChild( child ) as ListItemElement;
			
			updateList();
			updateFlow();
			
			//removeFromGroups(removedChild);
			
			return removedChild;
		}
		
		override public function removeChildAt(index:uint) : FlowElement
		{
			var removedChild:ListItemElement = super.removeChildAt( index ) as ListItemElement;
			
			updateList();
			updateFlow();
			
			//removeFromGroups(removedChild);
			
			return removedChild;
		}
		
		/*private function addToGroups(item:ListItemElement):void 
		{
			var index:int;
			
			if (item.paragraphStartIndent > 0)
			{
				index = item.paragraphStartIndent / 24;
			}			
			else
			{
				index = 0;
			}
			
			if (groups[index] == null)
			{
				groups[index] = [];
			}
			
			(groups[index] as Array).push(item);
		}*/
		
		/*private function removeFromGroups(item:ListItemElement):void 
		{
			for each (var group:Array in groups)
			{
				for (var i:int = 0; i < group.length; i++)
				{
					if (group[i] == item)
					{
						group.splice(i, 1);
						break;
					}
				}
			}
		}*/
		
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
				if (getChildAt(i) is ListItemElement)
				{
					( getChildAt(i) as ListItemElement ).number = i;
				}
			}
		}
		
		/**
		 * Ensures that a list with at least one list item will have a line-height break before it 
		 * by adding an empty list item at the head of the list.
		 */
		private function updateFirst():void 
		{
			if (!(parent is ListElement))
			{
				var first:ListItemElement;
				
				for (var i:int = 0; i < numChildren; i++)
				{
					if (getChildAt(i) is ListItemElement)
					{
						var item:ListItemElement = ListItemElement(getChildAt(i));
						
						if (item.first)
						{
							first = item;
							break;
						}
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
		}
		
		/**
		 * Ensures a list with at least one list item will have a line-height break after it
		 * by adding an empty list item at the tail of the list.
		 */
		private function updateLast():void
		{					
			if (!(parent is ListElement))
			{
				var last:ListItemElement;
				
				for (var i:int = 0; i < numChildren; i++)
				{
					if (getChildAt(i) is ListItemElement)
					{
						var item:ListItemElement = ListItemElement(getChildAt(i));
		
						if (item.last)
						{
							last = item;
							break;
						}
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
			if ( value == ListElement.ORDERED || value == ListElement.UNORDERED || value == ListElement.NONE )
			{
				_mode = value;
				var i:int = numChildren;
				while ( --i > -1 )
				{
					if (getChildAt(i) is ListItemElement)
					{
						( getChildAt(i) as ListItemElement ).mode = _mode;
					}
				}
				updateFlow();
			}
			else
				return;
			
			trace("ListElement mode set to : " + _mode + " " + value);
		}
		public function get mode():String
		{
			return _mode;
		}
		
		
		
		//	Necessary in order to be able to add children
		override tlf_internal function canOwnFlowElement(elem:FlowElement) : Boolean
		{
			return elem is ListItemElement || elem is ListElement;
		}
		
		//	Necessary for instantiation
		override protected function get abstract() : Boolean
		{
			return false;
		}
	}
}