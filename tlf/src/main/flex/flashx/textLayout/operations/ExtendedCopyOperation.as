package flashx.textLayout.operations
{
	import flashx.textLayout.edit.ExtendedTextClipboard;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.edit.TextScrap;
	
	public class ExtendedCopyOperation extends CopyOperation
	{
		protected var _extendedClipboard:ExtendedTextClipboard;
		
		public function ExtendedCopyOperation(operationState:SelectionState, extendedClipboard:ExtendedTextClipboard )
		{
			super(operationState);
			_extendedClipboard = extendedClipboard;
		}
		
		public override function doOperation():Boolean
		{
			if (originalSelectionState.activePosition != originalSelectionState.anchorPosition)
				_extendedClipboard.setContents(TextScrap.createTextScrap(originalSelectionState));
			return true;
		}
	}
}