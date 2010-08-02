package flashx.textLayout.operations
{
	import flashx.textLayout.edit.ParaEdit;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.edit.helpers.SelectionHelper;
	import flashx.textLayout.elements.list.ListItemElementX;
	import flashx.textLayout.formats.ITextLayoutFormat;
	
	public class ExtendedApplyFormatOperation extends ApplyFormatOperation
	{
		protected var searchIndex:int;
		protected var fullySelectedListItems:Array; /* ListItemElementX[] */
		
		public function ExtendedApplyFormatOperation(operationState:SelectionState, leafFormat:ITextLayoutFormat, paragraphFormat:ITextLayoutFormat, containerFormat:ITextLayoutFormat=null)
		{
			super(operationState, leafFormat, paragraphFormat, containerFormat);
			fullySelectedListItems = SelectionHelper.cachedListItems;
		}
		
		protected function findSelectedListItem( startIndex:int, endIndex:int, fromArray:Array /* ListItemElementX[] */ ):ListItemElementX
		{
			var item:ListItemElementX = fromArray[searchIndex];
			// Try to find if this item has children at positions.
			var abStart:int = item.getAbsoluteStart();
			var abEnd:int = abStart + item.textLength;
			if( startIndex >= abStart && abEnd >= endIndex )
			{
				return item;	
			}
			return null;	
		}
		
		protected function limitApplyFormatOfListItems( listItems:Array ):void
		{
			// If we have selected list items that are not fully selected, inspect if they have their symbol as part of the selection.
			//	If so, we cannot style just the symbol. Sumbols are only style when the whole list is selected.
			//	As such, roll back on the formatting for the symbol.
			var foundListItem:ListItemElementX;
			var startIndex:int;
			var endIndex:int;
			var styleObj:Object;
			searchIndex = 0;
			if( listItems && listItems.length > 0 )
			{
				for each(styleObj in undoLeafArray)
				{
					foundListItem = findSelectedListItem( styleObj.begIdx, styleObj.endIdx, listItems );
					if( foundListItem ) 
					{
						var seperatorLength:int = foundListItem.seperatorLength;
						startIndex = foundListItem.getAbsoluteStart();
						if( styleObj.begIdx == startIndex && styleObj.endIdx == ( startIndex + seperatorLength ) )
						{
							ParaEdit.setTextStyleChange( textFlow, styleObj.begIdx, styleObj.endIdx, styleObj.style );
						}	
						// Up index for finding next item.
						searchIndex++;
						// If we have reached the end of slots for fully selected list items, break out and continue.
						if( searchIndex > listItems.length - 1 ) break;
					}
				}
			}
		}
		
		override protected function doInternal():SelectionState
		{
			var newState:SelectionState = super.doInternal();
			// Grab selected items. It is possible to have a not fully selected item, but the list item be selected up to symbol.
			// In which case we have to go through and undo any possibly formatted symbols.
			// Formatting symbols is only viable when a whole list item is selected.
			var selectedListItems:Array = SelectionHelper.getSelectedListItems( textFlow ).slice();
			
			// If we aren't concerned with list items, check for partial selected list items and return right away.
			if( fullySelectedListItems == null || fullySelectedListItems.length == 0 )
			{
				limitApplyFormatOfListItems( selectedListItems );
				return newState;	
			}
			
			// Strip out the fully selected ones, as we will handle those specially
			var indexOfDupe:int;
			for( var i:int = 0; i < fullySelectedListItems.length; i++ )
			{
				indexOfDupe = selectedListItems.indexOf( fullySelectedListItems[i] );
				if( indexOfDupe > -1 )
				{
					selectedListItems.splice( indexOfDupe, 1 );
				}
			}
			
			var styleObj:Object;
			var foundListItem:ListItemElementX;
			var selectedListItem:ListItemElementX;
			var startIndex:int;
			var endIndex:int;
			searchIndex = 0;
			if( fullySelectedListItems && fullySelectedListItems.length > 0 )
			{
				// Undo character format changes if they are part of he selected list items.
				for each(styleObj in undoLeafArray)
				{
					foundListItem = findSelectedListItem( styleObj.begIdx, styleObj.endIdx, fullySelectedListItems );
					if( foundListItem ) 
					{
						if( selectedListItem != foundListItem )
						{
							selectedListItem = foundListItem;
							startIndex = selectedListItem.getAbsoluteStart();
							endIndex = startIndex + selectedListItem.textLength - 1;
							// Find format at position for leaf, apply to the list item.
							// First pass it along to undo cache.
							if( undoParagraphArray == null ) undoParagraphArray = [];
							ParaEdit.cacheParagraphStyleInformation( textFlow, startIndex, endIndex, undoParagraphArray);
							// Then apply it to the list item which is a paragraph.
							ParaEdit.applyParagraphStyleChange( textFlow, startIndex, endIndex, leafFormat, null );
						}
						// If beg and end fall within a selected list item, undo formatting, and transpose the new formatting from the span to the list item.
						// Undo.
						// Don't need to undo, exporter should handle it.
//						ParaEdit.setTextStyleChange( textFlow, styleObj.begIdx, styleObj.endIdx, styleObj.style );
						
						// Up index for finding next item.
						searchIndex++;
						// If we have reached the end of slots for fully selected list items, break out and continue.
						if( searchIndex > fullySelectedListItems.length - 1 ) break;	
					}
				}
			}
			// Run check on partial selected list items.
			limitApplyFormatOfListItems( selectedListItems );
			
			return newState;
		}
	}
}