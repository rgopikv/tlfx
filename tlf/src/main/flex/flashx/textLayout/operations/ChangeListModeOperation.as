package flashx.textLayout.operations
{
	import flashx.textLayout.container.AutosizableContainerController;
	import flashx.textLayout.converter.IHTMLExporter;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.edit.helpers.SelectionHelper;
	import flashx.textLayout.elements.BreakElement;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.list.ListElementX;
	import flashx.textLayout.elements.list.ListItemElementX;
	import flashx.textLayout.elements.list.ListItemModeEnum;
	import flashx.textLayout.elements.list.ListPaddingElement;
	import flashx.textLayout.events.TextLayoutEvent;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormatValueHolder;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.NavigationUtil;
	import flashx.textLayout.utils.TextLayoutFormatUtils;
	
	public class ChangeListModeOperation extends FlowTextOperation
	{
		protected var _mode:int;
		protected var _htmlImporter:IHTMLImporter;
		protected var _htmlExporter:IHTMLExporter;
		
		protected var _affectedListItems:Vector.<AffectedListItem>;
		protected var _affectedLists:Array; // ListElementX[];
		protected var _listModeChange:Boolean;
		
		protected var _listModeCreateOnTextFlow:Boolean;
		protected var _listCreatedOnTextFlow:ListElementX;
		
		protected var _listModeCreate:Boolean;
		
		public function ChangeListModeOperation( operationState:SelectionState, mode:int, importer:IHTMLImporter, exporter:IHTMLExporter )
		{
			super( operationState );
			_mode = mode;
			
			_htmlImporter = importer;
			_htmlExporter = exporter;
		}
		
		// [TA] 06-30-2010 :: Replaced assigning computed format of paragraph to using smart algo to find all cascading styles. 
		//						This was needed as styles were not update on list items because the had a filled format that couldn't be overriding with inline or external styles.
		protected function getCascadingFormatForElement( element:FlowElement ):ITextLayoutFormat
		{
			var format:ITextLayoutFormat = element.format ? element.format : null;//new TextLayoutFormat();
			var parent:FlowElement = element.parent;
			while( !(parent is TextFlow) )
			{
				format = TextLayoutFormatUtils.mergeFormats( parent.format, format );
				parent = parent.parent;
			}
			return format;
		}
		// [END TA]
		
		/**
		 * @private
		 * 
		 * Do operation on just changing the mode of a currently created list element. 
		 * @param items Array Array of ListItemElementX
		 * @param lists Array Array of ListElementX
		 * @param mode int
		 */
		protected function changeListModeOnAlreadyCreatedList( items:Array, lists:Array, mode:int ):ListElementX
		{
			var item:ListItemElementX;
			var list:ListElementX;
			
			_listModeChange = true;
			_affectedListItems = new Vector.<AffectedListItem>();
			_affectedLists = lists;
			//	Switch mode of all items selected
			for each ( item in items )
			{
				_affectedListItems.push( new AffectedListItem( item ) );
				// [TA] 06-30-2010 :: Change to invoke mode change through parenting list in order to track markup change of item for external styling.
				var parentList:ListElementX = item.parent as ListElementX;
				
				//	[KK]	Stop list from being updated every time an item is added/removed
				parentList.pendingUpdate = true;
				//	[END KK]
				
				parentList.changeListModeOnListItem( item, ( mode == ListItemModeEnum.ORDERED ) ? mode : ListItemModeEnum.UNORDERED );
				// [END TA]
			}
			
			//	Update all lists selected
			for each ( list in lists )
			{
				list.pendingUpdate = false;
				list.update();
			}
				
			return list;
		}
		
		/**
		 * @private
		 * 
		 * Undo operation of strictly changing mode of list already created on text flow.
		 */
		protected function undoListModeChange():void
		{
			var list:ListElementX;	
			var affectedItem:AffectedListItem;
			
			while( _affectedListItems.length > 0 )
			{
				affectedItem = _affectedListItems.shift();
				affectedItem.element.mode = affectedItem.previousMode;
			}
			
			while( _affectedLists.length > 0 )
			{
				list = _affectedLists.shift();
				list.update();
			}
		}
		
		/**
		 * @private
		 * 
		 * Do operation on creation of new list directly on TextFlow instance. 
		 * @param textFlow TextFlow
		 * @param paragraphs Array Array of ParagraphElements to convert to list items.
		 * @param index int
		 */
		protected function addListDirectlyToTextFlow( tf:TextFlow, spans:Array /* SpanElement[] */, index:int ):ListElementX//paragraphs:Array /* ParagraphElement[] */, index:int ):ListElementX
		{
//			var firstParagraph:ParagraphElement = paragraphs[0];
			var span:SpanElement = spans[0] as SpanElement;
			
			var list:ListElementX = new ListElementX();
			
			//	[KK]	Mark lists as pending update so they don't update too many times
			list.pendingUpdate = true;
			//	[END KK]
			
//			addParagraphElementsAsItemsToList( paragraphs, list );
			addSpanElementsAsItemsToList( spans, list );
			
			_listModeCreateOnTextFlow = true;
			_listCreatedOnTextFlow = list;
			
//			var node:XML = _htmlExporter.getSimpleMarkupModelForElement( list );
//			_htmlImporter.importStyleHelper.assignInlineStyle( node, list );
//			_htmlImporter.importStyleHelper.apply();
			
			// Weed out empty items
			for ( var i:int = list.numChildren-1; i > -1; i-- )
			{
				if ( list.getChildAt(i) is ListItemElementX )
				{
					var item:ListItemElementX = list.getChildAt(i) as ListItemElementX;
					if ( item.modifiedTextLength == 0 )
						list.removeChildAt(i);
				}
			}
			
			//	[KK]	Mark list as not pending update, so that it will actually update
			list.pendingUpdate = false;
			//	[END KK]
			
			//	Update in case any items were removed
			list.update();
			
			return tf.addChildAt( index, list ) as ListElementX;
		}
		
		
		protected function addSpanElementsAsItemsToList( spans:Array /* SpanElement[] */, list:ListElementX ):void
		{
			//	Make sure the list doesn't update prematurely
			list.pendingUpdate = true;
			
			var br:BreakElement;
			var cascadeFormat:ITextLayoutFormat;
			var i:int;
			var j:int;
			var item:ListItemElementX;
			var resetItem:Boolean = true;
			var span:SpanElement;
			var undefinedFormat:ITextLayoutFormat = new TextLayoutFormat();
			
			for ( i = spans.length-1; i > -1; i-- )
			{
				span = spans[i] as SpanElement;
				
				if ( span )
				{
					if (resetItem)
					{
						item = new ListItemElementX();
						try {
							cascadeFormat = getCascadingFormatForElement( span );
						} catch ( e:* ) {
							//	Nothing
						}
						item.format = cascadeFormat ? cascadeFormat : undefinedFormat;
						cascadeFormat = null;
						item.indent = int(span.paragraphStartIndent) > 0 ? int( 24 * (span.paragraphStartIndent % 24) ) : 0;
						item.mode = _mode;
						resetItem = false;
					}
					
					if ( span is BreakElement )
					{
						br = span as BreakElement;
						
						span = new SpanElement();
						try {
							cascadeFormat = getCascadingFormatForElement( br );
						} catch ( e:* ) {
							//	Nothing
						}
						span.format = cascadeFormat ? cascadeFormat : undefinedFormat;
						cascadeFormat = null;
						span.text = br.text.replace(/[\u2028\n\r\u2029]/g, '');
						
						br.parent.removeChild(br);
						
						if ( span.text.match( /\w/g ).length > 0 )
						{
							item.addChildAt(0, span);
						}
						resetItem = true;
					}
					else if ( span is SpanElement )
					{
						if ( span.parent is LinkElement )
						{
							var link:LinkElement = span.parent as LinkElement;
							testLinkChildren:for ( j = link.numChildren-1; j > -1; j-- )
							{
								if ( link.getChildAt(j) is SpanElement )
								{
									if ( link.getChildAt(j) is SpanElement )
									{
										if ((link.getChildAt(j) as SpanElement).text.match( /\w/g ).length > 0 )
										{
											if ( item.getChildIndex( link ) < 0 )
												item.addChildAt(0, link);
											break testLinkChildren;
										}
									}
									else
									{
										if ( item.getChildIndex( link ) < 0 )
											item.addChildAt(0, link);
										break testLinkChildren;
									}
								}
							}
						}
						else if ( span.text.match( /\w/g ).length > 0 )
						{
							if ( item.getChildIndex( span ) < 0 )
								item.addChildAt(0, span);
						}
					}
					else
					{
						if ( item.getChildIndex( span ) < 0 )
							item.addChildAt(0, span);
					}
					
					if ( list.getChildIndex(item) < 0 )
						list.addChildAt(0, item);
				}
			}
			
			//	[FORMATING]
			formatListItemsOnList( list );
			//	[FORMATING]
			//	[KK] Apply all styling
			addListItemsToStyleHelper( list );
			
			//	Okay list to update
			list.pendingUpdate = false;
			
			//	Update
			list.update();
		}
		
		/**
		 * @private
		 * 
		 * Removes paragraph elements from their parent and adds them as list items to the list. 
		 * @param paragraphs Array An Array of ParagraphElement
		 * @param list ListElementX
		 */
		protected function addParagraphElementsAsItemsToList( paragraphs:Array /*ParagraphElement[] */, list:ListElementX ):void
		{
			//	[KK]	Mark list as pending update
			list.pendingUpdate = true;
			//	[END KK]
			
			var i:int;
			var j:int;
			var p:ParagraphElement;
			var item:ListItemElementX;
			var pchild:FlowElement;
			var node:XML;
			var cascadeFormat:ITextLayoutFormat;
			var undefinedFormat:ITextLayoutFormat = new TextLayoutFormat();
			for ( i = paragraphs.length-1; i > -1; i-- )
			{
				item = new ListItemElementX();
				p = paragraphs[i] as ParagraphElement;
				cascadeFormat = getCascadingFormatForElement( p );
				item.format = cascadeFormat;
				item.mode = _mode;
				if ( p && !(p is ListItemElementX) )
				{
					item.indent = int(p.paragraphStartIndent) > 0 ? int( 24 * (p.paragraphStartIndent % 24) ) : 0;
					//	TODO:	Find out why formatting appears correct before conversion in RTE, but no format has been set	-	KK (06/10/2010)
					for ( j = p.numChildren-1; j > -1; j-- )
					{
						pchild = p.getChildAt(j);
						// Merge format withoverwrite from child format on top of cascaded paragraph format.
						if( pchild.format != null )
						{
							if( cascadeFormat != null )
								cascadeFormat = TextLayoutFormatUtils.overwrite( cascadeFormat, pchild.format );
							else
								cascadeFormat = pchild.format;
						}
						//	Break on break element
						if ( pchild is BreakElement )
						{
							//	If item already exists, add it to the list
							if ( item.numChildren > 1 )
							{
								list.addChildAt( 0, item );
							}
							
							var prevIndent:int = item.indent;
							
							item = new ListItemElementX();
							
							item.mode = _mode;
							item.format = cascadeFormat;
							item.indent = prevIndent;
							item.text = (pchild as BreakElement).text.replace(/[\u2028\n\r\u2029]/g, '');
							
							p.removeChildAt(j);
							
							list.addChildAt( 0, item );
							
							//	Reset the item for the next time through
							item = new ListItemElementX();
							item.format = cascadeFormat;
							item.mode = _mode;
							item.indent = prevIndent;
							
							trace( "Is valid cascade format: " + TextLayoutFormat.isEqual( cascadeFormat, undefinedFormat ) ); 
							
							continue;
						}
						//	Prevent adding blank list items by ensuring that they have either word characters or a TLF element
						else if ( pchild is SpanElement )
						{
							if ( (pchild as SpanElement).text.match( /\w/g ).length > 0 )
								item.addChildAt(0, p.removeChildAt(j));
						}
						else if ( pchild is LinkElement )
						{
							testLinkChildren:for ( var k:int = 0; k < (pchild as LinkElement).numChildren; k++ )
							{
								if ( (pchild as LinkElement).getChildAt(k) is SpanElement )
								{
									if ( ((pchild as LinkElement).getChildAt(k) as SpanElement).text.match( /\w/g ).length > 0 )
									{
										item.addChildAt(0, p.removeChildAt(j));
										break testLinkChildren;
									}
								}
							}
						}
						else
							item.addChildAt(0, p.removeChildAt(j));
					}
				}
				
				if (item.numChildren < 1)
					continue;
				
				list.addChildAt( 0, item );
				p.parent.removeChild(p);
			}
			
			//	[FORMATING]
			formatListItemsOnList( list );
			//	[FORMATING]
			//	[KK] Apply all styling
			addListItemsToStyleHelper( list );
			
			//	[KK]	Mark list as not pending update
			list.pendingUpdate = false;
			//	[END KK]
			
			list.update();
		}
		
		/**
		 * @private
		 * 
		 * Go through each new list item and transfer the format from its first child to the actual list item if exists. 
		 * @param list ListElementX
		 */
		protected function formatListItemsOnList( list:ListElementX ):void
		{
			var i:int;
			var listItem:ListItemElementX;
			var leaf:FlowElement;
			var listItems:Array = list.listItems;
			// Used to decipher the format to transfer to the list item if available.
			var transferFormat:ITextLayoutFormat;
			var isTransferFormatUndefined:Boolean;
			var undefinedFormat:ITextLayoutFormat = new TextLayoutFormat();
			for( i = 0; i < listItems.length; i++ )
			{
				listItem = listItems[i] as ListItemElementX;
				leaf = listItem.nonListRelatedContent[0];
				transferFormat = null;
				if( leaf is SpanElement )
				{
					transferFormat = ( leaf ) ? leaf.format : null;
					isTransferFormatUndefined = TextLayoutFormat.isEqual( transferFormat, undefinedFormat ); 
					// If no format from first child, so grab the cascading format.
					if( !isTransferFormatUndefined )
					{
						listItem.format = transferFormat;
					}
				}
			}
		}
		
		protected function addListItemsToStyleHelper( list:ListElementX ):void
		{
			var listItems:Array = list.listItems;
			var length:int = listItems.length;
			var i:int;
			var node:XML;
			var listItem:ListItemElementX;
			for( i = 0; i < length; i++ )
			{
				listItem = listItems[i] as ListItemElementX;
				node = _htmlExporter.getSimpleMarkupModelForElement( listItem );
				_htmlImporter.importStyleHelper.assignInlineStyle( node, listItem );
			}
			node = _htmlExporter.getSimpleMarkupModelForElement( list );
			_htmlImporter.importStyleHelper.assignInlineStyle( node, list );
			_htmlImporter.importStyleHelper.apply();
		}
		
		/**
		 * @private
		 * 
		 * Undo of operation of creating a list element from selected paragraph elements directly on the TextFlow 
		 * @param list ListElementX The previously cerated ListElementX element from the do operation.
		 */
		protected function removeListFromTextFlow( list:ListElementX ):void
		{
			var parent:FlowGroupElement = list.parent;
			var tf:TextFlow;
			while( !( parent is TextFlow ) && parent != null )
			{
				parent = parent.parent;
			}
			
			if( !parent || !( parent is TextFlow ) ) return;
			
			tf = parent as TextFlow;
			var listIndex:int = tf.getChildIndex( list );
			tf.removeChild( list );
			
			var items:Array = [];
			var listItems:Array = list.listItems;
			while( listItems.length > 0 )
			{
				items.push( list.removeChild( listItems.shift() ) );
			}
			returnListItemsAsParagraphElements( parent, items, listIndex, (items[0] as ListItemElementX).format );
		}
		
		/**
		 * @private
		 * 
		 * Converts list item elements to paragraph elements and adds them to the flow. 
		 * @param listItems
		 * @param index
		 * 
		 */
		protected function returnListItemsAsParagraphElements( group:FlowGroupElement, listItems:Array /*ListItemElementX[]*/, index:int, formatToPass:ITextLayoutFormat = null ):Array
		{
			var returnedElements:Array = []; // FlowElement[]
			var listItem:ListItemElementX;
			var listItemChildren:Array;
			var listItemChild:FlowElement;
			
			var p:ParagraphElement = new ParagraphElement();
			var format:ITextLayoutFormat;
			if ( listItems.length > 0 )
			{
				//	[KK]	Commented out because it wasn't in newest revision, ask Todd about it
//				p.format = new TextLayoutFormat( formatToPass );
				p.original = true;
				p.paragraphStartIndent = Math.max(0, (listItems[0] as ListItemElementX).indent-24);
				
				while ( listItems.length > 0 )
				{
					listItem = listItems.shift() as ListItemElementX;
					if ( !listItem )
						continue;
					
					format = ( listItem.format ) ? listItem.format : new TextLayoutFormat();
					listItemChildren = listItem.nonListRelatedContent;
					while ( listItemChildren.length > 0 )
					{
						listItemChild = listItemChildren.shift();
						format = ( listItemChild.format ) ? TextLayoutFormatUtils.mergeFormats( format, listItemChild.format, ["paragraphStartIndent"] ) : format;
						limitIndentFormatOnReturn( listItem, format );
						listItemChild.format = format;
						p.addChild( listItemChild );
					}
					
					p.addChild( new BreakElement() );
				}
				
				returnedElements.push(p);
				
				return returnedElements;
			}
			else
				return [];
		}
		
		/**
		 * Runs check on indent of list item and corrects the paragraphStartIndent format value based on the list item. If it is 0, it is flipped to undefined.
		 * @param listItem ListItemElementX
		 * @param format ITextLayoutFormat
		 */
		protected function limitIndentFormatOnReturn( listItem:ListItemElementX, format:ITextLayoutFormat ):void
		{
			if( format.paragraphStartIndent && format is TextLayoutFormat )
			{
				( format as TextLayoutFormat ).paragraphStartIndent -= listItem.indent;
				if( ( format as TextLayoutFormat ).paragraphStartIndent <= 0 )
				{
					( format as TextLayoutFormat ).paragraphStartIndent = undefined;
				}
			}
			else if( format.paragraphStartIndent && format is TextLayoutFormatValueHolder )
			{
				( format as TextLayoutFormatValueHolder ).paragraphStartIndent -= listItem.indent;
				if( ( format as TextLayoutFormatValueHolder ).paragraphStartIndent <= 0 )
				{
					( format as TextLayoutFormatValueHolder ).paragraphStartIndent = undefined;
				}
			}
		}
		
		/**
		 * @private
		 * 
		 * Do operation to Split parents at selection and inserts a list onto the TextFlow. 
		 * @param parent FlowGroupElement The first level parent of selection at paragraph to start splitting.
		 * @param paragraphs Array An Array of ParagraphElement
		 */
		protected function splitAndAddListToTextFlow( groupParent:FlowGroupElement, spans:Array /* SpanElement[] */ ):ListElementX//paragraphs:Array /*ParagraphElement[]*/ ):ListElementX
		{
			var list:ListElementX;
			
			// First find the first level parenting div.
			while( !(groupParent is DivElement ) )
			{
				groupParent = groupParent.parent;
			}
			// First top level div from paragraph. Divs can be in Divs so split on traverse up.
			var parent:FlowGroupElement;
			parent = groupParent;
			if( (parent is DivElement) )
			{
//				var firstParagraph:ParagraphElement = paragraphs[0] as ParagraphElement;
				var firstSpan:SpanElement = spans[0] as SpanElement;
				var lastSpan:SpanElement = spans[spans.length-1] as SpanElement;
				var index:int = parent.getChildIndex( firstSpan.parent );//firstParagraph );
				var lastIdx:int = lastSpan.parent.getChildIndex( lastSpan );
				//	Will go through this loop at least once
				//	Splits the div at the specified index (starting at the ParagraphElement)
				while ( !(parent is TextFlow) )
				{
					var parentPara:ParagraphElement = firstSpan.parent as ParagraphElement;
					
					if(spans.length < firstSpan.parent.mxmlChildren.length) {
						var newPara:ParagraphElement = splitParaInTwo( parentPara, lastIdx);
					
						var newDiv:DivElement = splitDivInTwo( parent as DivElement, index );
						//	Get the index of the current DivElement from it's parent
						index = newDiv.parent.getChildIndex(newDiv);
					} else {
						index = parent.parent.getChildIndex(parent);
					}
					//	Assign the DivElement's parent to be the prnt variable
					parent = parent.parent;
				}
				
				//	Add the list at the end resulting prnt var (TextFlow) at the end resulting index (DivElement on TextFlow) + 1
				var tf:TextFlow = parent as TextFlow;
				if( tf != null )
				{
					list = addListDirectlyToTextFlow( tf, spans, index );//paragraphs, index + 1 );
					
//					//	[KK]	Attempt to remove last (empty) paragraph added through the creation process
//					var lastItem:ListItemElementX;
//					var idx:int = list.numChildren;
//					while ( !lastItem || !(lastItem is ListItemElementX) )
//					{
//						idx--;
//						if ( idx < 0 )
//							break;
//						lastItem = list.getChildAt(idx) as ListItemElementX;
//					}
//					
//					if ( lastItem )
//					{
//						idx = lastItem.numChildren;
//						while (--idx > -1)
//						{
//							var child:FlowElement = lastItem.getChildAt(idx);
//							
//							if ( child is SpanElement )
//							{
//								//	[KK]	Remove the last character as it is an unnecessary line break added from who knows where
//								(child as SpanElement).text = (child as SpanElement).text.substring(0, (child as SpanElement).text.length-1);
//								break;
//							}
//						}
//					}
				}
			}
			
			return list;
		}
		
		/**
		 * @private
		 * 
		 * Converts elements from a list to non-list items and adds them to the flow. 
		 * @param list ListElementX
		 */
		protected function returnElementsFromSingleList( list:ListElementX, items:Array /*ListItemEleementX[]*/ ):Array
		{
			var listItems:Array = []; /*ListItemElementX[]*/
			var returnedElements:Array = []; /*FlowElement[]*/
			var newList:ListElementX;
			var item:ListItemElementX;
			var start:int;
			var end:int;
			var length:int;
			// Grab start index.
			item = items[0] as ListItemElementX;
			start = list.getChildIndex(item);
			// Grab end index.
			item = items[items.length-1] as ListItemElementX;
			end = list.getChildIndex(item);
			length = end - start + 1;
			// Operate on a split of lists.
			var i:int;
			var tmpIdx:int;
			if( length != list.listItems.length ) 
			{
				newList = splitListInTwo( list, start );	
				listItems = removeItemsFromList( newList, 0, length );
				returnedElements = returnListItemsAsParagraphElements( newList.parent, listItems, start, list.format );
				
				tmpIdx = list.parent.getChildIndex(list);
				
				for(var w:int=0; w<returnedElements.length; w++) {
					list.parent.addChildAt(++tmpIdx, returnedElements[w]);
				}
				
				// Update split lists.
				list.update();
				newList.update();
			}
				// Else we are turning the whole list into paragraphs
			else
			{
				textFlow.flowComposer.updateAllControllers();
				listItems = removeItemsFromList( list, 0, length );
			//	textFlow.flowComposer.updateAllControllers();

				tmpIdx = list.parent.getChildIndex(list);
				// get the returned paragraphs
				returnedElements = returnListItemsAsParagraphElements( list.parent, listItems, list.parent.getChildIndex( list ), list.format );
				
				// loop through each paragraph and add to the autosizable container.
				for(w=0; w<returnedElements.length; w++) {
					list.parent.addChildAt(tmpIdx++, returnedElements[w]);
				}

				// we must remove the currnt list or the editor will keep growing unnecessarily 
				list.parent.removeChild( list );
			}
			
			// Apply style and assign managing container controller to returned elements.
//			var node:XML;
//			var element:FlowElement;
//			for( var j:int=0; j<returnedElements.length; j++)
//			{
//				element = returnedElements[j];
//				node = _htmlExporter.getSimpleMarkupModelForElement( element );
//				_htmlImporter.importStyleHelper.assignInlineStyle( node, element );
//			}
			textFlow.flowComposer.updateAllControllers();
//			_htmlImporter.importStyleHelper.apply();
			
			return returnedElements;			
		}
		
		/**
		 * @private
		 * 
		 * Converts list items from lists into flow elements and returns them to the flow. 
		 * @param lists Array An Array of ListElementX
		 * @param items Array An Array of ListItemElementX
		 */
		protected function returnElementsFromMultipleLists( lists:Array /* ListElementX[] */, items:Array /* ListEleemntItemX[] */ ):Array
		{
			var start:int;
			var end:int;
			var length:int;
			var list:ListElementX;
			var startList:ListElementX;
			var endList:ListElementX;
			var listItems:Array = []; // ListItemElementX[]
			var returnedElements:Array = []; // FlowElement[]
			
			var listItemLength:int;
			var removedItemLength:int;
			var i:int;
			var containerController:AutosizableContainerController;
			//	Multiple items
			// Strip from start list and mark returned items.
			startList = (items[0] as ListItemElementX).parent as ListElementX;
			listItemLength = startList.listItems.length;
			
			start = startList.getChildIndex(items[0] as ListItemElementX);
			length = startList.listItems.length;
			
			listItems = removeItemsFromList( startList, start, length );
			removedItemLength = listItems.length;
			returnedElements = returnListItemsAsParagraphElements( startList.parent, listItems, startList.parent.getChildIndex( startList ) + 1, startList.format );
			if( listItemLength == removedItemLength )
			{
				startList.parent.removeChild( startList );	
			}
			
			// Go through any lists caught in the middle.
			for( i = 1; i < lists.length - 1; i++ )
			{
				list = lists[i];
				listItems = removeItemsFromList( list, 0, list.listItems.length );
				returnedElements = returnedElements.concat( returnListItemsAsParagraphElements( list.parent, listItems, list.parent.getChildIndex( list ), list.format ) );
				list.parent.removeChild( list );
			}
			
			// Strip from end list and mark returned items.
			endList = (items[items.length-1] as ListItemElementX).parent as ListElementX;
			listItemLength = endList.listItems.length;
			
			end = endList.getChildIndex(items[items.length-1] as ListItemElementX);
			length = end + 1;
			
			listItems = removeItemsFromList( endList, 0, length );
			removedItemLength = listItems.length;
			returnedElements = returnedElements.concat( returnListItemsAsParagraphElements( endList.parent, listItems, endList.parent.getChildIndex( endList ), endList.format ) );
			if( listItemLength == removedItemLength )
			{
				endList.parent.removeChild( endList );	
			}
			
			startList.update();
			endList.update();
			
			return returnedElements;
		}
		
		/**
		 * @private
		 * 
		 * Removes items from list between start and end index and returns the list of items removed. 
		 * @param list ListElementX
		 * @param startIndex int
		 * @param endIndex int
		 * @return Array
		 */
		protected function removeItemsFromList( list:ListElementX, startIndex:int, endIndex:int ):Array
		{
			var items:Array = []; /* ListItemElementX */
			var i:int;
			for( i = startIndex; i < endIndex; i++ )
			{
				items.push( list.removeChild(list.listItems[0]));
				//items.push( list.getChildAt(list.getChildIndex(list.listItems[startIndex+i])));
			}
			return items;
		}
		
		/**
		 * @private
		 * 
		 * Splits a div into two divs. 
		 * @param div DivElement
		 * @param index index
		 * @return DivElement
		 */
		protected function splitDivInTwo( div:DivElement, index:uint ):DivElement
		{
			var parent:FlowGroupElement = div.parent;
			var divIndex:int = parent.getChildIndex( div );
			var newDiv:DivElement = div.shallowCopy() as DivElement;
			
			//	Take all children from end to index and place in new DivElement
			for ( var i:int = div.numChildren-1; i > index; i-- )//i >= index; i-- )
			{
				newDiv.addChildAt( 0, div.removeChildAt(i) );
			}
			return parent.addChildAt( divIndex + 1, newDiv ) as DivElement;
		}
		
		protected function splitParaInTwo( para:ParagraphElement, index:uint ):ParagraphElement
		{
			var parent:FlowGroupElement = para.parent;
			var paraIndex:int = parent.getChildIndex( para );
			var newPara:ParagraphElement = para.shallowCopy() as ParagraphElement;
			
			//	Take all children from end to index and place in new ParagraphElement
			for ( var i:int = para.numChildren-1; i > index; i-- )//i >= index; i-- )
			{
				newPara.addChildAt( 0, para.removeChildAt(i) );
			}
			
			var retPara:ParagraphElement = parent.addChildAt( paraIndex + 1, newPara ) as ParagraphElement; 
			
			if(retPara.getChildAt(0) is BreakElement) {
				// create a span
				var newSpan:SpanElement = new SpanElement();
				newSpan.format = retPara.getChildAt(0).format;
				newSpan.text = (retPara.getChildAt(0) as BreakElement).text.replace(/[\u2029\u2028\n\r]/g, "");
				retPara.removeChildAt(0);
				retPara.addChildAt(0, newSpan);
			}
			
			return retPara;
		}
		
		protected function splitListInTwo( list:ListElementX, index:uint ):ListElementX
		{
			var parent:FlowGroupElement = list.parent;
			var listIndex:int = parent.getChildIndex( list );
			var newList:ListElementX = list.shallowCopy() as ListElementX;
			
			for( var i:int = list.numChildren - 1; i >= index; i-- )
			{
				newList.addChildAt( 0, list.removeChildAt( i ) );
			}
			
			return parent.addChildAt( listIndex + 1, newList ) as ListElementX;
		}
		
		/** @private */
		public override function doOperation():Boolean
		{
			
			switch(_mode) {
				case ListItemModeEnum.ORDERED:
				case ListItemModeEnum.UNORDERED:

					var selectedListItems:Array = SelectionHelper.getSelectedListItems( textFlow );
					// If there are currently selected list items then we can assume
					// that we are changing an existing list.
					// else we are creating a new list
					if ( selectedListItems.length > 0 )
					{
						// there are selected lists so we change the mode on the 
						// selected lists.
						changeList();
					}
					else
					{
						// there are no selected lists so we create a list
						createList();
					}
					
					break;
				
				case ListItemModeEnum.UNDEFINED:
					// we destroy the currently selected list
					destroyLists();
					break;
				
				default:
					destroyLists();
					break;
				
			}
			
			return true;	
		}
		
		private function createList() : Boolean {
			var selectedListItems:Array = SelectionHelper.getSelectedListItems( textFlow );
			var lists:Array = SelectionHelper.getSelectedLists( textFlow );
			var paragraphs:Array = SelectionHelper.getSelectedParagraphs( textFlow );
			var spans:Array = SelectionHelper.getSelectedElements( textFlow, null, [SpanElement, BreakElement], true );
			
			var item:ListItemElementX;
			var list:ListElementX;
			
			// selection related 
			var absoluteStart:int = 0;
			var absoluteEnd:int = 0;
			var fe1:FlowElement;
			var fe2:FlowElement;
			
			var lastParaFormat:ITextLayoutFormat = getCascadingFormatForElement( paragraphs[paragraphs.length - 1] as ParagraphElement );
			//	Add ListElementX at position of first element
			var p:ParagraphElement = paragraphs[0] as ParagraphElement;
			var prnt:FlowGroupElement = p.parent;
			// Owner is a TextFlow, just add at same position as first ParagraphElement
			if ( prnt is TextFlow )
			{
				list = addListDirectlyToTextFlow( prnt as TextFlow, spans /* [KK] Changed from paragraphs */, prnt.getChildIndex( p ) );
			}
			else
			{
				list = splitAndAddListToTextFlow( prnt, spans );
			}
			
			// we should select the entire list
			absoluteStart = list.getAbsoluteStart();
			absoluteEnd   = list.getAbsoluteStart() + list.textLength-1;
			
			// set the new selection
			var newSS:SelectionState = new SelectionState(textFlow, absoluteStart, absoluteEnd);
			textFlow.interactionManager.setSelectionState(newSS);
			SelectionHelper.cacheSelectedLists(textFlow, absoluteStart, absoluteEnd);
			textFlow.interactionManager.refreshSelection();
			textFlow.flowComposer.updateAllControllers();
			
			return true;
		}
		
		private function changeList() : Boolean {
			var selectedListItems:Array = SelectionHelper.getSelectedListItems( textFlow );
			var lists:Array = SelectionHelper.getSelectedLists( textFlow );
			var paragraphs:Array = SelectionHelper.getSelectedParagraphs( textFlow );
			var spans:Array = SelectionHelper.getSelectedElements( textFlow, null, [SpanElement, BreakElement], true );
			
			var item:ListItemElementX;
			var list:ListElementX;
			
			// selection related 
			var absoluteStart:int = 0;
			var absoluteEnd:int = 0;
			var fe1:FlowElement;
			var fe2:FlowElement;
			
			list = changeListModeOnAlreadyCreatedList( selectedListItems, lists, _mode );
			
			fe1 = selectedListItems[0];
			fe2 = selectedListItems[selectedListItems.length-1];
			
			absoluteStart = fe1.getAbsoluteStart();
			absoluteEnd   = fe2.getAbsoluteStart() + fe2.textLength - 1;
			
			// set the new selection
			var newSS:SelectionState = new SelectionState(textFlow, absoluteStart, absoluteEnd);
			textFlow.interactionManager.setSelectionState(newSS);
			SelectionHelper.cacheSelectedLists(textFlow, absoluteStart, absoluteEnd);
			textFlow.interactionManager.refreshSelection();
			textFlow.flowComposer.updateAllControllers();
			
			return true;
		}
		
		private function destroyLists() : Boolean {
			var selectedListItems:Array = SelectionHelper.getSelectedListItems( textFlow );
			var lists:Array = SelectionHelper.getSelectedLists( textFlow );
			var paragraphs:Array = SelectionHelper.getSelectedParagraphs( textFlow );
			var spans:Array = SelectionHelper.getSelectedElements( textFlow, null, [SpanElement, BreakElement], true );
			
			var item:ListItemElementX;
			var list:ListElementX;
			
			// selection related 
			var absoluteStart:int = 0;
			var absoluteEnd:int = 0;
			var fe1:FlowElement;
			var fe2:FlowElement;
			
			// if there are multiple lists
			// else we are dealing with one list
			if ( lists.length > 1 )
			{
				paragraphs = returnElementsFromMultipleLists( lists, selectedListItems );
			}
			else
			{
				item = selectedListItems[0] as ListItemElementX;
				list = item.parent as ListElementX;
				paragraphs = returnElementsFromSingleList(list , selectedListItems );
			}
			
			if(paragraphs) {
				this.textFlow.flowComposer.updateAllControllers();
				
				// get the first and last flow leaf elements
				fe1 = paragraphs[0];
				fe2 = paragraphs[paragraphs.length-1];
				
				// get the start and end
				absoluteStart = fe1.getAbsoluteStart();
				absoluteEnd   = fe2.getAbsoluteStart() + fe2.textLength;
			}
			
			// set the new selection
			var newSS:SelectionState = new SelectionState(textFlow, absoluteStart, absoluteEnd);
			textFlow.interactionManager.setSelectionState(newSS);
			SelectionHelper.cacheSelectedLists(textFlow, absoluteStart, absoluteEnd);
			textFlow.interactionManager.refreshSelection();
			textFlow.flowComposer.updateAllControllers();
			
			return true;
		}
		
		/** @private */
		public override function undo():SelectionState
		{
			if( _listModeChange )
			{
				undoListModeChange();
			}
			else if( _listModeCreateOnTextFlow )
			{
				removeListFromTextFlow( _listCreatedOnTextFlow );
			}
			return originalSelectionState; 
		}
		
		// [TA] 07-27-2010 :: See comment on FlowOperation.
		override public function get affectsFlowStructure():Boolean
		{
			return true;
		}
		// [END TA]
	}
}

import flashx.textLayout.elements.list.ListItemElementX;
class AffectedListItem
{
	public var element:ListItemElementX;
	public var previousMode:int;
	
	public function AffectedListItem( element:ListItemElementX )
	{
		this.element = element;
		this.previousMode = element.mode;
	}
}