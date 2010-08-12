package flashx.textLayout.elements.list
{
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.container.AutosizableContainerController;
	import flashx.textLayout.converter.IHTMLExporter;
	import flashx.textLayout.edit.helpers.SelectionHelper;
	import flashx.textLayout.elements.ContainerFormattedElement;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.ListElement;
	import flashx.textLayout.elements.ListItemElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.events.ModelChange;
	import flashx.textLayout.events.list.ListElementEvent;
	import flashx.textLayout.format.IExportStyleHelper;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.ListUtil;
	
	use namespace tlf_internal;
	
	public class ListElementX extends DivElement
	{
		protected var _pendingChildElements:Vector.<PendingNotifyingElement>;
		protected var _pendingUpdate:Boolean;
		
		private var _paddingItems:Vector.<ListPaddingElement>;
		
		public function ListElementX()
		{
			super();
			_pendingChildElements = new Vector.<PendingNotifyingElement>();
			_pendingUpdate = false;
		//	paragraphSpaceAfter = 100;
			
			/*_paddingItems = new Vector.<ListPaddingElement>();
			_paddingItems.push( new ListPaddingElement(), new ListPaddingElement() );*/
		}
						
		// [TA] 06-30-2010 :: Override of replace children to notify clients of change to list. ATM the most accurate way to track a change to children in list
		//						which is needed to properly track list item elements of the text flow for external CSS styling purposes.
		override public function replaceChildren(beginChildIndex:int, endChildIndex:int, ...rest):void
		{
			// Go thorough those being marked as removed and either notify clients of removal or mark for pending once the list is added to the flow.
			var i:int;
			var len:int = endChildIndex - beginChildIndex;
			var child:ListItemElementX;
			var flow:TextFlow = getTextFlow();
			for( i = 0; i < len; i++ )
			{
				child = getChildAt( i ) as ListItemElementX;
				if( child )
				{
					if( flow )
					{
						notifyOfElementChange( child, PendingNotifyingElement.ACTION_REMOVE );
					}
					else
					{
						_pendingChildElements.push( new PendingNotifyingElement( child, PendingNotifyingElement.ACTION_REMOVE ) );
					}
				}
			}
			// Go through the children being add and either notify clients of add or mark as pending once list is added to flow.
			var obj:Object;
			for each( obj in rest)
			{
				child = obj as ListItemElementX;
				if( child ) 
				{
					if( flow )
					{
						notifyOfElementChange( child, PendingNotifyingElement.ACTION_ADD );
					}
					else
					{
						_pendingChildElements.push( new PendingNotifyingElement( child, PendingNotifyingElement.ACTION_ADD ) );
					}
				}
			}
			
			//	[KK]	Was throwing an error on select all + delete because normalizeRange attempts to fill this with a paragraph element
			var canOwnAll:Boolean = true;
			for each ( var o:* in rest )
			{
				if (o is FlowElement)
				{
					if ( !canOwnFlowElement(o as FlowElement) )
					{
						canOwnAll = false;
						break;
					}
				}
				else
				{
					canOwnAll = false;
					break;
				}
			}
			
			if ( canOwnAll )
				super.replaceChildren( beginChildIndex, endChildIndex, rest );
			else
				super.replaceChildren( beginChildIndex, endChildIndex, [] );
		}
		// [END TA]
		
		// [TA] 06-30-2010 :: Override to track this instance being added to the flow in order to notify client of children that require references for external CSS styling.
		tlf_internal override function modelChanged(changeType:String, changeStart:int, changeLen:int, needNormalize:Boolean = true, bumpGeneration:Boolean = true):void
		{
			super.modelChanged( changeType, changeStart, changeLen, needNormalize, bumpGeneration );
			switch( changeType )
			{
				case ModelChange.ELEMENT_ADDED:
					notifyOfChildElementsChange( _pendingChildElements );
					break;
			}
		}
		// [END TA]
		
		// [TA] 06-30-2010 :: Added to notify clients of change in list items. Used to track list item elements on flow for external css styling.
		protected function notifyOfElementChange( child:ListItemElementX, action:uint ):void
		{
			var flow:TextFlow = getTextFlow();
			if( flow )
			{
				flow.dispatchEvent( new ListElementEvent( ( action == PendingNotifyingElement.ACTION_ADD ) ? ListElementEvent.ITEM_ADDED : ListElementEvent.ITEM_REMOVED, child, this ) );
			}
		}
		protected function notifyOfChildElementsChange( elements:Vector.<PendingNotifyingElement> ):void
		{
			var requiresUpdate:Boolean = elements.length > 0;
			var element:PendingNotifyingElement;
			while( elements.length > 0 )
			{
				element = elements.shift();
				notifyOfElementChange( element.element, element.action );
			}
		}
		// [END TA]
		
		/*public function removePadding():void
		{
			attemptRemoveChild( _paddingItems[0] );
			attemptRemoveChild( _paddingItems[1] );
		}*/
		
		/*public function correctPadding():void
		{
			removePadding();
			
			// if there is a list directly above the list we do not 
			// want to add padding above
			var listElem:ListElementX = this.getPreviousSibling() as ListElementX;
			
			// if the previous item is not a ListElementX then we can add the padding.
			/*if(!listElem) {
				super.addChildAt( 0, _paddingItems[0] );
			}*/
			
			//super.addChild( _paddingItems[1] );
			
		/*}*/
				
		protected function attemptRemoveChild( child:FlowElement ):Boolean
		{
			try {
				removeChild( child );
				return true;
			} catch ( e:* ) {
				//	Fail silently
				return false;
			}
			return false;
		}
		
		// [TA] 06-30-2010 :: Added to notify clients in change of list mode in order to track proper external css styling. Mode is used to construct corrsponding node used to recognize styles.
		public function changeListModeOnListItem( item:ListItemElementX, mode:int ):void
		{
			item.mode = mode;
			notifyOfElementChange( item, PendingNotifyingElement.ACTION_REMOVE );
			notifyOfElementChange( item, PendingNotifyingElement.ACTION_ADD );
		}
		// [END TA]
		
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
		
		public function close():void {
			var textFlow:TextFlow = this.getTextFlow();
			
			if(textFlow) {
				var paragraphs:Array = SelectionHelper.getSelectedParagraphs( textFlow );
				
				var newPara:ParagraphElement = new ParagraphElement();
				newPara.format = (paragraphs[0] as ParagraphElement).computedFormat;
				
				var paraElem:ParagraphElement = new ParagraphElement();
				var listIdx:int = textFlow.getChildIndex(this);
				
				textFlow.addChildAt(++listIdx, paraElem);
			}
			
		}
		
		public function update():void
		{
			if ( numChildren > 0 && !pendingUpdate )
			{
				ensureIndentation();
				
				correctParagraphSpacing();
			}
		}
		
		private function correctParagraphSpacing() : void {
			
			// we loop through the ListItems so that there paragraph spacing is correct
			for(var i:int=0; i<= listItems.length-2; i++) {
				var item:ListItemElementX = listItems[i] as ListItemElementX;
				item.paragraphSpaceAfter = 0;
			}
			
			
			// get font size of last leaf
			var lastItem:ListItemElementX = listItems[listItems.length-1] as ListItemElementX;
			if(lastItem.fontSize != undefined) {
				lastItem.paragraphSpaceAfter = lastItem.fontSize;
			} else {
				lastItem.paragraphSpaceAfter = 16;
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
					var itemIndent:int = Math.max(item.indent-24, 0);
					var ind:int;
					
					if ( prevItem )
					{
						var prevItemIndent:int = Math.max(prevItem.indent-24, 0);
						//	Non matching indents
						if ( uint(itemIndent) != uint(prevItemIndent) )
						{
							//	Should hold Vector for this grouping already
							if ( groups.length > uint(itemIndent/24) )
							{
								group = groups[uint(itemIndent/24)];
								
								//	If group holds items to test against
								if ( group.length > 0 )
								{
									groupItem = group[group.length-1];
									
									//	Matching modes
									if ( groupItem.mode == item.mode )
										groups[uint(itemIndent/24)].push(item);
									//	Non matching modes
									else
									{
										//	Holds at least one more grouping above the current, test for similarity
										if ( groups.length > uint(itemIndent/24)+1 )
										{
											group = groups[uint(itemIndent/24)+1];
											
											//	If group holds items to test against
											if ( group.length > 0 )
											{
												groupItem = group[group.length-1];
												
												//	Matching modes
												if ( groupItem.mode == item.mode )
													groups[uint(itemIndent/24)+1].push(item);
												//	Non matching modes, must splice in new Vector
												else
												{
													//	Splice in AFTER original Vector
													//	[KK]
													//	-	Start at index you want to inject into
													//	-	Delete whatever is at that pointer
													//	-	Inject new Vector and then the clone of what was at that pointer
													groups.splice( uint(itemIndent/24)+1, 1, new Vector.<ListItemElementX>(), group );
													groups[uint(itemIndent/24)+1].push( item );
												}
											}
											//	No items to test, add item
											else
												groups[uint(itemIndent/24)+1].push(item);
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
									groups[uint(itemIndent/24)].push(item);
							}
							//	No Vector yet exists
							else
							{
								if ( uint(itemIndent) > uint(prevItemIndent) )
									ind = uint(itemIndent-prevItemIndent)/24;
								else
									ind = uint(itemIndent/24)-(groups.length-1);
								
								while ( ind > 0 )
								{
									groups.push( new Vector.<ListItemElementX>() );
									ind--;
								}
								
								groups[uint(itemIndent/24)].push(item);
							}
						}
						//	Non matching modes
						else if ( item.mode != prevItem.mode )
						{
							//	[KK]	OFFENDING LINE IS IF STATEMENT******************************
							
							//	+1 becase we want to insert it in the next group
							if ( groups.length > uint(itemIndent/24)+1 )
							{
								groups[uint(itemIndent/24)].push(item);//+1].push(item);
							}
							else
							{
								if (groups.length > uint(itemIndent/24)+1 )
								{
									//	[KK]
									//	-	Start at index you want to inject into
									//	-	Delete whatever is at that pointer
									//	-	Inject new Vector and then the clone of what was at that pointer
									groups.splice( uint(itemIndent/24)+1, 1, new Vector.<ListItemElementX>(), group );
									groups[uint(itemIndent/24)+2].push(item);
								}
								else
								{
									ind = (uint(itemIndent/24)+1)-(groups.length-1);
									
									while ( ind > 0 )
									{
										groups.push( new Vector.<ListItemElementX>() );
										ind--;
									}
									
									groups[uint(itemIndent/24)+1].push(item);
								}
							}
						}
						//	Same group
						else
						{
							group = groups[uint(itemIndent/24)];
							
							//	If group holds items to test against
							if ( group.length > 0 )
							{
								groupItem = group[group.length-1];
								
								//	Matching modes
								if ( groupItem.mode == item.mode )
									groups[uint(itemIndent/24)].push(item);
								//	Non matching modes
								else
								{
									//	Holds at least one more grouping above the current, test for similarity
									if ( groups.length > uint(itemIndent/24)+1 )
									{
										group = groups[uint(itemIndent/24)+1];
										
										//	If group holds items to test against
										if ( group.length > 0 )
										{
											groupItem = group[group.length-1];
											
											//	Matching modes
											if ( groupItem.mode == item.mode )
												groups[uint(itemIndent/24)+1].push(item);
											//	Non matching modes, must splice in new Vector
											else
											{
												//	Splice in AFTER original Vector
												if ( groups.length > uint(itemIndent/24)+2 )
													groups[uint(itemIndent/24)+2].push( item );
												else
												{
													//	[KK]
													//	-	Start at index you want to inject into
													//	-	Delete whatever is at that pointer
													//	-	Inject new Vector and then the clone of what was at that pointer
													groups.splice( uint(itemIndent/24)+1, 1, new Vector.<ListItemElementX>(), group );
													groups[uint(itemIndent/24)+2].push(item);
												}
											}
										}
										//	No items to test, add item
										else
											groups[uint(itemIndent/24)+1].push(item);
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
								groups[uint(itemIndent/24)].push(item);
						}
					}
					else
					{
						//	First item. Create Vector to hold it and push it into that Vector.
						ind = uint( itemIndent / 24 );
						while ( ind > -1 )
						{
							groups.push( new Vector.<ListItemElementX>() );
							ind--;
						}
						groups[groups.length-1].push( item );
					}
					
					prevItem = item;
				}
				
				//	[KK]	This pending flag is important, without it lists will recursively update giving bad results
				pendingUpdate = true;
				for ( i = 0; i < groups.length; i++ )
				{
					group = groups[i];
					for ( var j:int = 0; j < group.length; j++ )
					{
						item = group[j];
						item.indent = Math.min( 240, Math.max( item.indent, i*24+24 ) );
						item.number = j+1;
						item.update();
					}
				}
				pendingUpdate = false;
			}
		}
		
		// [TA] 06-30-2010 :: Added argument for IExportStyleHelper instance. Proper implementation needed for export and strip of styles from applied and explicit formatting.
		// [TA] 07-12-2010 :: ADDED IHTMLExport argument to properly export child elements from list item element.
		public function export( exporter:IHTMLExporter, styleExporter:IExportStyleHelper ):String
		{
		// [END TA]
			var xmlStr:String = '';
			
			var items:Array = listItems;
			
			if ( items.length == 0 )
				return null;
			
			var prevItem:ListItemElementX;
			
			var appendChild:int;
			
			var listNode:XML;
			var itemParentNode:XML;
			var wrapXML:XML;
			
			for ( var i:int = 0; i < items.length; i++ )
			{
				var item:ListItemElementX = items[i] as ListItemElementX;
				var itemIndent:int = Math.max( 0, item.indent-24 );
				// If we have a previous item, we ned to either append or start nesting.
				if ( prevItem )
				{
					var ind:int;
					var prevItemIndent:int = Math.max( 0, prevItem.indent-24 );
					if ( itemIndent > prevItemIndent )
					{
						ind = itemIndent - 24;
						var origParent:XML = item.getParentingNodeCopy();
						if( ind == prevItemIndent ) wrapXML = origParent;
						else
						{
							var wrapParent:XML = origParent;
							while ( ind > prevItemIndent )
							{
								xmlStr = item.mode == ListItemModeEnum.UNORDERED ? 'ul' : 'ol';
								wrapXML = <{xmlStr}/>
								wrapXML.appendChild(wrapParent);
								wrapParent = wrapXML;
								ind -= 24;
							}
						}
						itemParentNode.appendChild( wrapXML );
						itemParentNode = origParent;
					}
					else if ( itemIndent < prevItemIndent )
					{
						ind = prevItemIndent;
						while ( ind > itemIndent )
						{
							itemParentNode = itemParentNode.parent();
							ind -= 24;
						}
					}
					else if ( item.mode != prevItem.mode )
					{
						var newNode:XML = item.getParentingNodeCopy();
						itemParentNode.appendChild( newNode );
						itemParentNode = newNode;
					}
				}
				else
				{
					// Start off with the parenting node for the item.
					itemParentNode = item.getParentingNodeCopy();
					// Copy for nesting if needed.
					listNode = itemParentNode;
					ind = itemIndent;
					// Nest if needed.
					while (ind > 0)
					{
						xmlStr = item.mode == ListItemModeEnum.UNORDERED ? 'ul' : 'ol';
						wrapXML = <{xmlStr}/>;
						wrapXML.appendChild( listNode );
						listNode = wrapXML;
						ind-=24;
					}
				}
				
				var itemXML:XML = item.export( exporter, styleExporter );
				if( itemXML ) itemParentNode.appendChild( itemXML );
				
				prevItem = item;
			}
			
			xmlStr = listNode.toXMLString();
			xmlStr = xmlStr.replace( /\n/ig, '' );
			
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
		
		// [TA] 07-26-2010 :: Factory method for creating an empty div container to be used during paste operations within TextFlowEdit.
		//						The way that paste works in TextflowEdit is to add the paste content temporarily to the end of the target container.
		//						Since we are pasting into a list item element, the container is a list element. Technically, due to the override of canOwnFlowElement()
		//							the operation in TextflowEdit could not add a temp div to finish the paste operation. 
		//							As such this is a quick access factort method to create that container legally.
		tlf_internal function getTemporaryPasteContainer():ContainerFormattedElement
		{
			if( mxmlChildren == null ) mxmlChildren = [];
			
			var div:DivElement = new DivElement();
			var p:ParagraphElement = new ParagraphElement();
			p.replaceChildren( 0, 0, new SpanElement() );
			div.replaceChildren( 0, 0, p );
			mxmlChildren[numChildren] = div;
			return div;
		}
		// [END TA]
		
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
		
		public function set pendingUpdate( value:Boolean ):void
		{
			_pendingUpdate = value;
		}
		public function get pendingUpdate():Boolean
		{
			return _pendingUpdate;
		}
	}
}

import flashx.textLayout.elements.list.ListItemElementX;
class PendingNotifyingElement
{
	public var element:ListItemElementX;
	public var action:uint;
	
	public static const ACTION_ADD:int = 0;
	public static const ACTION_REMOVE:int = 1;
	
	public function PendingNotifyingElement( element:ListItemElementX, action:uint )
	{
		this.element = element;
		this.action = action;
	}
}