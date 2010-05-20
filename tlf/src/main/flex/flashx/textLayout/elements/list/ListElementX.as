package flashx.textLayout.elements.list
{
	import flash.events.Event;
	import flash.text.engine.GroupElement;
	
	import flashx.textLayout.elements.BreakElement;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.events.StatusChangeEvent;
	import flashx.textLayout.events.UpdateEvent;
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
				
				i = -1;
				while (++i < prevChildren.length)
				{
					( prevChildren[i] as ListItemElementX ).number = i+1;
					super.addChild(prevChildren[i]);
				}
				
				update();
				
				return child;
			}
			return null;
		}
		
		public function update():void
		{
			if ( numChildren > 0 )
			{
				for ( var i:int = numChildren-1; i > -1; i-- )
				{
					if ( getChildAt(i) is ListPaddingElement )
						removeChildAt(i);
				}
				
				var items:Array = listItems;
				
				//	Start on 1 because 0 is ParagraphElement
				var prevItem:ListItemElementX;
				var numbers:Vector.<int> = new Vector.<int>();
				
				for ( i = 0; i < items.length; i++ )
				{
					var item:ListItemElementX = items[i] as ListItemElementX;
					
					//	2nd item and beyond
					if ( prevItem )
					{
						var indent:int;
						//	Nested
						if ( item.indent > prevItem.indent )
						{
							indent = item.indent;
							while ( indent > prevItem.indent )
							{
								numbers.push(1);
								indent = Math.max( indent-24, 0 );//-= 24;
								if ( indent == 0 )
									break;
							}
						}
						else if ( item.indent < prevItem.indent )
						{
							indent = prevItem.indent;
							while ( indent > item.indent )
							{
								numbers.pop();
								indent = Math.max( indent-24, 0 );//-= 24;
								if ( indent == 0 )
									break;
							}
						}
						//	New list
						else if ( item.mode != prevItem.mode )
						{
							numbers[numbers.length-1] = 1;
						}
					}
					else
						numbers.push(1);
					
					if ( numbers.length == 0 )
						numbers.push(1);
					
					item.number = numbers[numbers.length-1] ? numbers[numbers.length-1] : 0;
					item.update();
					
					numbers[numbers.length-1]++;
					
					prevItem = item;
				}
				
				ensureIndentation();
				
				addChildAt(0, padding);
				addChildAt(numChildren, padding);
			}
			
			if ( getTextFlow() )
				getTextFlow().flowComposer.updateAllControllers();
		}
		
		protected function ensureIndentation():void
		{
			var items:Array = listItems;
			if ( items.length > 0 )
			{
				var groups:Array = [[]];
				var prevItem:ListItemElementX;
				
				for ( var i:int = 0; i < items.length; i++ )
				{
					var item:ListItemElementX = items[i] as ListItemElementX;
					var ind:int;
					
					if ( prevItem )
					{
						if ( item.indent > prevItem.indent )
						{
							ind = (item.indent-prevItem.indent)/24;
							
							//	Ensure that all slots are filled
							while ( ind > 0 )
							{
								groups.push([]);
								ind--;
							}
							
							(groups[groups.length-1] as Array).push(item);
						}
						else if ( item.indent < prevItem.indent )
							(groups[item.indent/24] as Array).push(item);
						else if ( item.mode != prevItem.mode )
						{
							groups.push([]);
							(groups[groups.length-1] as Array).push(item);
						}
						else
							(groups[item.indent/24] as Array).push(item);
					}
					else
						(groups[0] as Array).push(item);
					
					prevItem = item;
				}
				
				for ( i = 0; i < groups.length; i++ )
				{
					var group:Array = groups[i] as Array;
					for ( var j:int = 0; j < group.length; j++ )
					{
						item = group[j] as ListItemElementX;
						item.indent = Math.min( 240, Math.max( item.indent, i*24 ) );
					}
				}
			}
		}
		
		public function export():XML
		{
			var xml:XML;
			var xmlStr:String = '';
			
			var items:Array = listItems;
			
			if ( items.length == 0 )
				return null;
			
			var prevItem:ListItemElementX;
			
			var appendChild:int;
			
			XML.prettyPrinting = false;
			XML.ignoreWhitespace = false;
			
			for ( var i:int = 0; i < items.length; i++ )
			{
				var item:ListItemElementX = items[i] as ListItemElementX;
				
				if ( prevItem )
				{
					var ind:int;
					if ( item.indent > prevItem.indent )
					{
						ind = item.indent;
						while ( ind > prevItem.indent )
						{
							xmlStr += item.mode == ListItemElementX.UNORDERED ? '<ul>' : '<ol>';
							ind -= 24;
						}
					}
					else if ( item.indent < prevItem.indent )
					{
						ind = prevItem.indent;
						
						var lastList:String = prevItem.mode == ListItemElementX.UNORDERED ? '<ul>' : '<ol>';
						var lastListIndex:int = xmlStr.lastIndexOf(lastList);
						while ( ind > item.indent )
						{
							xmlStr += lastList == '<ul>' ? '</ul>' : '</ol>';
							ind -= 24;
							
							var lastOL:int = xmlStr.substring(0, lastListIndex).lastIndexOf('<ol>', lastListIndex);
							var lastUL:int = xmlStr.substring(0, lastListIndex).lastIndexOf('<ul>', lastListIndex);
							
							if ( lastOL > lastUL )
							{
								lastList = '<ol>';
								lastListIndex = lastOL;
							}
							else if ( lastUL > lastOL )
							{
								lastList = '<ul>';
								lastListIndex = lastUL;
							}
							else
							{
								//	BROKEN!
							}
						}
					}
					else if ( item.mode != prevItem.mode )
					{
						xmlStr += item.mode == ListItemElementX.UNORDERED ? '<ul>' : '<ol>';
					}
				}
				else
					xmlStr += item.mode == ListItemElementX.UNORDERED ? '<ul>' : '<ol>';
				
				var itemXML:XML = item.export();
				xmlStr += itemXML ? itemXML.toXMLString() : '';
				
				prevItem = item;
			}
			
			xmlStr = xmlStr.replace( /\n/ig, '' );
			xmlStr += ( items[0] as ListItemElementX ).mode == ListItemElementX.UNORDERED ? '</ul>' : '</ol>';
			
			//	Ensure that everything is properly closed
			xmlStr = cleanExport( xmlStr );
			
			xml = new XML( xmlStr );
			
			XML.prettyPrinting = true;
			
			return xml;
		}
		
		protected function cleanExport( value:String ):String
		{
			var returnValue:String = value;
			var lastOpen:String = returnValue.substr(1, 2);
			var lastClose:String;
			
			var openTags:Vector.<String> = new Vector.<String>();
			
			openTags.push( lastOpen );
			
			for ( var i:int = 4; i < returnValue.length; i++ )
			{
				if ( i < 4 )
					break;
				
				var char:String = returnValue.charAt(i);
				
				if ( char == '<' )
				{
					var nextChar:String = returnValue.charAt(i+1);
					if ( nextChar == '/' )
					{
						//	Closing tag
						var closeTagName:String = returnValue.charAt(i+2) + returnValue.charAt(i+3);
						if ( closeTagName == 'ol' || closeTagName == 'ul' )
						{
							if ( closeTagName != lastOpen )
							{
								returnValue = returnValue.substring(0, i) + '</' + lastOpen + '>' + returnValue.substring(i);
								i+=5;	//	For injection
							}
							
							openTags.pop();
							lastOpen = openTags.length > 0 ? openTags[openTags.length-1] : '';
						}
						
						i = returnValue.indexOf('<', i+1)-1;
					}
					else if ( nextChar == 'o' || nextChar == 'u' )
					{
						//	Opening tag
						var openTagName:String = nextChar + 'l';
						openTags.push( openTagName );
						lastOpen = openTagName;
						i+=3;	//	For tag
					}
					else
					{
						i = returnValue.indexOf('<', i+1)-1;
					}
				}
				
				if ( lastOpen == '' )
					break;
			}
			
			return returnValue;
		}
		
		
		
		tlf_internal override function canOwnFlowElement(elem:FlowElement):Boolean
		{
			return elem is ListItemElementX || elem is ListPaddingElement;
		}
		
		
		
		public function get padding():ListPaddingElement
		{
			return new ListPaddingElement();
		}
		
		public function get listItems():Array
		{
			var items:Array = [];
			for ( var i:int = 0; i < numChildren; i++ )
			{
				if ( getChildAt(i) is ListItemElementX )
					items.push( getChildAt(i) );
			}
			return items;
		}
	}
}