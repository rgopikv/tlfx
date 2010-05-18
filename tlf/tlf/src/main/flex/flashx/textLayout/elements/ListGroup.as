package flashx.textLayout.elements
{
	public class ListGroup
	{
		public var id:int = -1;
		
		public var indent:int = -1;
		
		public var startIndex:int;
		
		public var listItems:Array = [];
		
		public var listMode:String = "";
		
		public var parent:ListGroup;
		
		public function toString():String 
		{
			return "ListGroup[start: " + startIndex + ", indent: " + indent + ", items: " + listItems + "]";
		}
	}
}