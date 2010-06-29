package flashx.textLayout.elements.list
{
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.ListItemElement;
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
				
				addChildAt(0, new ListPaddingElement());
				super.addChild(new ListPaddingElement());
				
//				if ( getTextFlow() )
//					getTextFlow().flowComposer.updateAllControllers();
			}
		}
		
		protected function ensureIndentation():void
		{
			var items:Array = listItems;
			var groups:Vector.<Vector.<ListItemElementX>> = new Vector.<Vector.<ListItemElementX>>();;
			var group:Vector.<ListItemElementX>;
			var prevItem:ListItemElementX;
			var groupItem:ListItemElementX;
			if ( items.length > 0 )
			{
				for ( var i:int = 0; i < items.length; i++ )
				{
					var item:ListItemElementX = items[i] as ListItemElementX;
					var ind:int;
					
					if ( prevItem )
					{
						//	Non matching indents
						if ( uint(item.indent) != uint(prevItem.indent) )
						{
							//	Should hold Vector for this grouping already
							if ( groups.length > uint(item.indent/24) )
							{
								group = groups[uint(item.indent/24)];
								
								//	If group holds items to test against
								if ( group.length > 0 )
								{
									groupItem = group[group.length-1];
									
									//	Matching modes
									if ( groupItem.mode == item.mode )
										groups[uint(item.indent/24)].push(item);
									//	Non matching modes
									else
									{
										//	Holds at least one more grouping above the current, test for similarity
										if ( groups.length > uint(item.indent/24)+1 )
										{
											group = groups[uint(item.indent/24)+1];
											
											//	If group holds items to test against
											if ( group.length > 0 )
											{
												groupItem = group[group.length-1];
												
												//	Matching modes
												if ( groupItem.mode == item.mode )
													groups[uint(item.indent/24)+1].push(item);
												//	Non matching modes, must splice in new Vector
												else
												{
													//	Splice in AFTER original Vector
													groups.splice( uint(item.indent/24), 0, new Vector.<ListItemElementX>() );
													groups[uint(item.indent/24)+1].push( item );
												}
											}
											//	No items to test, add item
											else
												groups[uint(item.indent/24)+1].push(item);
										}
										//	Does not hold any more groupings, add new
										else
										{
											groups.push( new Vector.<ListItemElementX>() );
											groups[groups.length-1].push( item );
										}
									}
								}
								//	No items to test against, add item
								else
									groups[uint(item.indent/24)].push(item);
							}
							//	No Vector yet exists
							else
							{
								if ( uint(item.indent) > uint(prevItem.indent) )
									ind = uint(item.indent-prevItem.indent)/24;
								else
									ind = uint(item.indent/24)-(groups.length-1);
								
								while ( ind > 0 )
								{
									groups.push( new Vector.<ListItemElementX>() );
									ind--;
								}
								
								groups[uint(item.indent/24)].push(item);
							}
						}
						//	Non matching modes
						else if ( item.mode != prevItem.mode )
						{
							//	+1 becase we want to insert it in the next group
							if ( groups.length > uint(item.indent/24)+1 )
								groups[uint(item.indent/24)+1].push(item);
							else
							{
								if ( groups.length > (uint(item.indent/24)+1) )
								{
									groups.splice( uint(item.indent/24)+1, 0, groups[uint(item.indent/24)+1], new Vector.<ListItemElementX>() );
									groups[uint(item.indent/24)+2].push(item);
								}
								else if ( groups.length == (uint(item.indent/24)+1) )
								{
									groups.push( new Vector.<ListItemElementX>() );
									groups[groups.length-1].push(item);
								}
								else
								{
									trace( '[KK] {' + getQualifiedClassName(this) + '} :: Could not add new Vector.<ListItemElementX>() to groups in ListElementX, ' + this + '.' );
									continue;
								}
							}
						}
						//	Same group
						else
						{
							group = groups[uint(item.indent/24)];
							
							//	If group holds items to test against
							if ( group.length > 0 )
							{
								groupItem = group[group.length-1];
								
								//	Matching modes
								if ( groupItem.mode == item.mode )
									groups[uint(item.indent/24)].push(item);
								//	Non matching modes
								else
								{
									//	Holds at least one more grouping above the current, test for similarity
									if ( groups.length > uint(item.indent/24)+1 )
									{
										group = groups[uint(item.indent/24)+1];
										
										//	If group holds items to test against
										if ( group.length > 0 )
										{
											groupItem = group[group.length-1];
											
											//	Matching modes
											if ( groupItem.mode == item.mode )
												groups[uint(item.indent/24)+1].push(item);
											//	Non matching modes, must splice in new Vector
											else
											{
												//	Splice in AFTER original Vector
												if ( groups.length > uint(item.indent/24)+2 )
													groups[uint(item.indent/24)+2].push( item );
												else
												{
													groups.splice( uint(item.indent/24)+1, 0, groups[uint(item.indent/24)+1], new Vector.<ListItemElementX>() );
													groups[uint(item.indent/24)+2].push(item);
												}
											}
										}
										//	No items to test, add item
										else
											groups[uint(item.indent/24)+1].push(item);
									}
									//	Does not hold any more groupings, add new
									else
									{
										groups.push( new Vector.<ListItemElementX>() );
										groups[groups.length-1].push( item );
									}
								}
							}
							//	No items to test against, add item
							else
								groups[uint(item.indent/24)].push(item);
						}
					}
					else
					{
						//	First item. Create Vector to hold it and push it into that Vector.
						ind = uint( item.indent / 24 );
						while ( ind > -1 )
						{
							groups.push( new Vector.<ListItemElementX>() );
							ind--;
						}
						groups[groups.length-1].push( item );
					}
					
					prevItem = item;
				}
				
				for ( i = 0; i < groups.length; i++ )
				{
					group = groups[i];
					for ( var j:int = 0; j < group.length; j++ )
					{
						item = group[j];
						item.indent = Math.min( 240, Math.max( item.indent, i*24 ) );
					}
				}
			}
		}
		
		public function export():String
		{
			var xmlStr:String = '';
			
			var items:Array = listItems;
			
			if ( items.length == 0 )
				return null;
			
			var prevItem:ListItemElementX;
			
			var appendChild:int;
			
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
							xmlStr += item.mode == ListItemModeEnum.UNORDERED ? '<ul>' : '<ol>';
							ind -= 24;
						}
					}
					else if ( item.indent < prevItem.indent )
					{
						ind = prevItem.indent;
						
						var lastList:String = prevItem.mode == ListItemModeEnum.UNORDERED ? '<ul>' : '<ol>';
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
								trace( '[KK] {' + getQualifiedClassName(this) + '} :: Exporting of a ListElement encountered a fatal error.' );
							}
						}
					}
					else if ( item.mode != prevItem.mode )
					{
						xmlStr += item.mode == ListItemModeEnum.UNORDERED ? '<ul>' : '<ol>';
					}
				}
				else
				{
					xmlStr += item.mode == ListItemModeEnum.UNORDERED ? '<ul>' : '<ol>';
					ind = item.indent;
					while (ind > 0)
					{
						xmlStr = new String(item.mode == ListItemModeEnum.UNORDERED ? '<ul>' : '<ol>') + xmlStr;
						ind-=24;
					}
				}
				
				var itemXML:XML = item.export();
				xmlStr += itemXML ? itemXML.toXMLString() : '';
				
				prevItem = item;
			}
			
			xmlStr = xmlStr.replace( /\n/ig, '' );
			xmlStr += ( items[0] as ListItemElementX ).mode == ListItemModeEnum.UNORDERED ? '</ul>' : '</ol>';
			
			//	Ensure that everything is properly closed
			xmlStr = cleanExport( xmlStr );
			
			return xmlStr;
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