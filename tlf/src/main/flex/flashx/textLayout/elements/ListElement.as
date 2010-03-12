package flashx.textLayout.elements
{
	import flashx.textLayout.tlf_internal;

	use namespace tlf_internal;
	
	public class ListElement extends DivElement implements IListElement
	{
		public static const NONE:String 		= 	'none';
		public static const ORDERED:String		=	'ordered';
		public static const UNORDERED:String	=	'unordered';
		
		private var _mode:String;
		
		public function get numListElements():int 
		{
			var count:int;
			
			for (var i:int = 0; i < numChildren; i++)
			{
				if (getChildAt(i) is ListItemElement)
				{
					var child:ListItemElement = ListItemElement(getChildAt(i));
					if (!child.first && !child.last)
					{
						count++;
					}
				}
			}
			
			return count;
		}
		
		public function get numElements():int 
		{
			var count:int;
			
			for (var i:int = 0; i < numChildren; i++)
			{
				if (getChildAt(i) is ListItemElement)
				{
					var child:ListItemElement = ListItemElement(getChildAt(i));
					if (!child.first && !child.last)
					{
						count++;
					}
				}
				else
				{
					count++;
				}
			}
			
			return count;
		}
		
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
		
		public function updateList():void 
		{
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:FlowElement = getChildAt(i);
				
				if (child is ListElement)
				{
					(child as ListElement).updateList();
				}
			}
			
			updateFirst();
			updateLast();
			updateNumbers();
			updateIndent();
		}
		
		/**
		 * Reset all the current list item numbers.
		 */
		private function updateNumbers():void 
		{			
			var adj:int;
			var firstItem:FlowElement = getChildAt(0);

			if (firstItem is ListItemElement)
			{
				adj = 1;
			}
			
			var i:int = numChildren;
			while ( --i > -1 )
			{
				if (getChildAt(i) is ListItemElement)
				{
					( getChildAt(i) as ListItemElement ).number = i + adj;
				}
			}
		}
		
		private function updateIndent():void 
		{
			var indent:int = 0;
			var indentSet:Boolean = false;
			
			for (var i:int = 0; i < numChildren; i++)
			{
				var item:FlowElement = getChildAt(i);
				
				if (item is ListItemElement)
				{
					if (!ListItemElement(item).first && !indentSet)
					{
						indentSet = true;
						indent = ListItemElement(item).paragraphStartIndent;
					}
					else
					{
						ListItemElement(item).paragraphStartIndent = indent;
					}
				}
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
			
			if (first)
			{
				super.removeChildAt(0);
			}
			
			if (!(parent is ListElement))
			{				
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
			
			if (!(parent is ListElement))
			{	
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
			else
			{
				if (last)
				{
					super.removeChildAt(getChildIndex(last));
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
		}
		public function get mode():String
		{
			return _mode;
		}
		
		
		
		//	Necessary in order to be able to add children
		override tlf_internal function canOwnFlowElement(elem:FlowElement) : Boolean
		{
			return elem is ListItemElement || elem is ListElement || elem is ParagraphElement;
		}
		
		//	Necessary for instantiation
		override protected function get abstract() : Boolean
		{
			return false;
		}
	}
}