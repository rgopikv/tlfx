package flashx.textLayout.elements
{
	import flashx.textLayout.tlf_internal;

	use namespace tlf_internal;
	
	public class ListElement extends DivElement implements IListElement
	{
		public static const NONE:String 		= 	'none';
		public static const ORDERED:String		=	'ordered';
		public static const UNORDERED:String	=	'unordered';
		
		private var _groups:ListGroup;
		
		public function get groups():ListGroup 
		{
			return _groups;
		}
		
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
		
		public function get listElements():Array 
		{
			var listElements:Array = [];
			
			for (var i:int = 0; i < numChildren; i++)
			{
				var item:FlowElement = FlowElement(getChildAt(i));
				
				if (item is ListItemElement)
				{
					if (!ListItemElement(item).first && !ListItemElement(item).last)
					{
						listElements.push(item);
					}
				}
			}
			
			return listElements;
		}
		
		public function ListElement()
		{
			super();
			
			_mode = ListElement.NONE;			
		}	
		
		override public function addChild(child:FlowElement) : FlowElement
		{
			var newChild:FlowElement = super.addChild( child ) as FlowElement;
			
			updateList();
			updateFlow();
			
			return newChild;
		}
		
		override public function addChildAt(index:uint, child:FlowElement) : FlowElement
		{
			var newChild:FlowElement = super.addChildAt(index, child) as FlowElement;
				
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
			updateFirst();
			updateLast();
			updateGroups();
			updateNumbers(_groups);
		}
		
		/**
		 * Reset all the current list item numbers.
		 */
		private function updateNumbers(group:ListGroup):void 
		{		
			var count:int = 1;
			
			for each (var item:* in group.listItems)
			{
				if (item is ListItemElement)
				{
					ListItemElement(item).number = count++;
				}
				
				if (item is ListGroup)
				{
					updateNumbers(ListGroup(item));
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
		
		public function updateGroups():void 
		{			
			_groups = new ListGroup();
			var group:ListGroup = _groups;
			group.startIndex = 0;
			group.indent = 0;
			group.listMode = baseMode;
			
			var previousElement:ListItemElement;
						
			var i:int;
			for each (var li:ListItemElement in listElements)
			{
				if (li.paragraphStartIndent != group.indent ||
					li.mode != group.listMode)
				{
					var newGroup:ListGroup;
					
					if (li.paragraphStartIndent != group.indent)
					{
						while (li.paragraphStartIndent > group.indent)
						{			
							newGroup = new ListGroup();
							newGroup.startIndex = i;
							newGroup.listMode = li.mode;
							newGroup.indent = group.indent + 24;
							
							group.listItems.push(newGroup);
							
							newGroup.parent = group;
							group = newGroup;
						}
												
						while (li.paragraphStartIndent < group.indent)
						{
							group = group.parent;
						}
					}
					else
					{
						newGroup = new ListGroup();
						newGroup.startIndex = i;
						newGroup.listMode = li.mode;
						newGroup.indent = li.paragraphStartIndent;
						
						if (group.parent)
						{
							group.parent.listItems.push(newGroup);
							newGroup.parent = group.parent;
						}
						else
						{
							group.listItems.push(newGroup);
						}
						
						group = newGroup;
					}
				}			
				
				group.listItems.push(li);

				i++;
				
				li.previousItem = previousElement;
				previousElement = li;
			}
		}
		
		private function get baseMode():String 
		{
			for each (var li:ListItemElement in listElements)
			{
				if (li.paragraphStartIndent == 0)
				{
					return li.mode;
				}
			}
			
			return UNORDERED;
		}
	}
}