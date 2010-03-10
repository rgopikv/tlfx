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
			
			_mode = ListElement.UNORDERED;
			
			
		}
		
		
		
		override public function addChild(child:FlowElement) : FlowElement
		{
			var newChild:ListItemElement = super.addChild( child ) as ListItemElement;
			
			newChild.mode = mode;
			newChild.number = numChildren;
			
			setFirstAndLast();
			update();
			return newChild;
		}
		
		override public function addChildAt(index:uint, child:FlowElement) : FlowElement
		{
			var newChild:ListItemElement = super.addChildAt(index, child) as ListItemElement;
			
			newChild.mode = mode;
			
			//	Reset all current ListItem numbers
			var i:int = numChildren;
			while ( --i > index-1 )
			{
				( getChildAt(i) as ListItemElement ).number = i+1;
			}
			
			setFirstAndLast();
			update();
			return newChild;
		}
		
		override public function removeChild(child:FlowElement) : FlowElement
		{
			var removedChild:ListItemElement = super.removeChild( child ) as ListItemElement;
			setFirstAndLast();
			update();
			return removedChild;
		}
		
		override public function removeChildAt(index:uint) : FlowElement
		{
			var removedChild:ListItemElement = super.removeChildAt( index ) as ListItemElement;
			setFirstAndLast();
			update();
			return removedChild;
		}
		
		
		
		private function setFirstAndLast():void
		{		
			var i:int;
			var item:ListItemElement;
			
			var first:ListItemElement;
			
			for (i = 0; i < numChildren; i++)
			{
				item = ListItemElement(getChildAt(i));
				
				if (item.first)
				{
					first = item;
					break;
				}
			}

			if (first)
			{
				super.removeChild(first);
			}
			
			var last:ListItemElement;
			
			for (i = 0; i < numChildren; i++)
			{
				item = ListItemElement(getChildAt(i));
				if (item.last)
				{
					last = item;
					break;
				}
			}			
			
			if (last)
			{
				super.removeChild(last);
			}
			
			if (numChildren > 0)
			{
				if (!first)
				{
					first = new ListItemElement();
					first.mode = NONE;
					first.text = "";
					first.first = true;
				}
				
				super.addChildAt(0, first);
				
				if (!last)
				{
					last = new ListItemElement();
					last.mode = NONE;
					last.text = "";
					last.last = true;
				}
				
				super.addChild(last);
			}
			else
			{
				//trace("1 or less children - so not adding a 'last' item");
			}
			
			//	Reset all elements to not be first and/or last (no extra breaks)
			/*var i:int = numChildren;
			while ( --i > -1 )
			{
			( getChildAt(i) as ListItemElement ).first = ( getChildAt(i) as ListItemElement ).last = false;
			}*/
			
			//	If there are still children, set the first and last (mimics the breaks of an ordered or unordered list in html)
			/*if ( numChildren > 0 )
			{
				( getChildAt(0) as ListItemElement ).first = true;
				( getChildAt(numChildren - 1) as ListItemElement ).last = true;
			}*/
		}
		
		private function update():void
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
				update();
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