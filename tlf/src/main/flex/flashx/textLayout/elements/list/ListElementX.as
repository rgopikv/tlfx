package flashx.textLayout.elements.list
{
	import flashx.textLayout.elements.BreakElement;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;
	
	public class ListElementX extends DivElement
	{
		public function ListElementX()
		{
			super();
		}
		
		
		
		public override function addChild(child:FlowElement):FlowElement
		{
			var i:int = numChildren;
			var prevChildren:Array = [];
			while (--i > -1)
			{
				var c:FlowElement = getChildAt(i);
				if ( c is ListItemElementX )
					prevChildren.push( getChildAt(i) )
				removeChildAt(i);
			}
			
			prevChildren.reverse();
			
			if ( child is ListItemElementX )
			{
				prevChildren.push( child );
				
				super.addChild( padding );
				i = -1;
				while (++i < prevChildren.length)
				{
					( prevChildren[i] as ListItemElementX ).number = i+1;
					super.addChild(prevChildren[i]);
				}
				super.addChild( padding );
				
				update();
				
				return child;
			}
			return null;
		}
		
		public function update():void
		{
			//	Clean up all paragraphs EXCEPT first and last
			for ( var i:int = numChildren-2; i > 0; i-- )
			{
				if ( !(getChildAt(i) is ListItemElementX) )
					removeChildAt(i);
			}
			
			var items:Array = listItems;
			
			//	Start on 1 because 0 is ParagraphElement
			var prevItem:ListItemElementX;
			
			for ( i = 0; i < items.length; i++ )
			{
				var item:ListItemElementX = items[i] as ListItemElementX;
				
				//	2nd item and beyond
				if ( prevItem )
				{
					//	New list
					if ( item.mode != prevItem.mode )
					{
						item.number = 1;
						
						if ( item.mode == ListItemElementX.ORDERED )
//						if ( !( getChildAt( getChildIndex( item ) - 1 ) is ListItemElementX ) )
						{
							addChildAt( getChildIndex( item ), padding );
							addChildAt( getChildIndex( item )+1, padding );
						}
					}
					else if ( prevItem.mode == ListItemElementX.ORDERED )
						item.number = prevItem.number+1;
					else
						item.number = 1;
				}
				else
					item.number = 1;
				
				prevItem = item;
			}
		}
		
//		public function export():XML
//		{
//			var xml:XML = new XML();
//			var mode:String;
//			var indent:int;
//			
//			if ( numChildren == 0 )
//				return null;
//			
//			mode = ( getChildAt(0) as ListItemElementX ).mode;
//			indent = int( ( getChildAt(0) as ListItemElementX ).paragraphStartIndent );
//			
//			if ( mode == ListItemElementX.UNORDERED )
//				xml = <ul/>;
//			else
//				xml = <ol/>;
//			
//			for ( var i:int = 0; i < numChildren; i++ )
//			{
//				var item:ListItemElementX = getChildAt(i) as ListItemElementX;
//				
//				if ( item.mode != mode )
//				{
//					//	Start new list
//					var newList:XML = item.mode == ListItemElementX.UNORDERED ? <ul/> : <ol/>;
//					if ( int( item.paragraphStartIndent ) > indent )
//					{
//						
//					}
//					else if ( int( item.paragraphStartIndent ) < indent )
//					{
//						
//					}
//					else
//					{
//						if ( xml.parent() )
//							xml = xml.parent().appendChild( newList );
//						//	if not, needs to be able to add & concatenate a list after itself
//					}
//				}
//				else if ( int( item.paragraphStartIndent ) > indent )
//				{
//					//	Nest
//					
//				}
//				else if ( int( item.paragraphStartIndent ) < indent )
//				{
//					//	End nesting
//					xml = xml.parent();
//				}
//				
//				//	Add new item to current list
//				xml.appendChild( item.export() );
//			}
//			
//			return xml;
//		}
		
		
		
		tlf_internal override function canOwnFlowElement(elem:FlowElement):Boolean
		{
			return elem is ListItemElementX || elem is ParagraphElement;
		}
		
		
		
		public function get padding():ParagraphElement
		{
			var p:ParagraphElement = new ParagraphElement();
			var span:SpanElement = new SpanElement();
			span.text = '';
			p.addChild( span );
			return p;
		}
		
		public function get listItems():Array
		{
			var items:Array = [];
			for ( var i:int = 1; i < numChildren-1; i++ )
			{
				if ( getChildAt(i) is ListItemElementX )
					items.push( getChildAt(i) );
			}
			return items;
		}
	}
}