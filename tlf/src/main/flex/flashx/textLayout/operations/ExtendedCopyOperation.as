package flashx.textLayout.operations
{
	import flashx.textLayout.edit.ExtendedTextClipboard;
	import flashx.textLayout.edit.ExtendedTextScrap;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.edit.TextScrap;
	import flashx.textLayout.edit.helpers.SelectionHelper;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.list.ListElementX;
	import flashx.textLayout.elements.list.ListItemElementX;
	import flashx.textLayout.tlf_internal;
	
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
			{
				var scrap:TextScrap = ExtendedTextScrap.createExtendedTextScrap( textFlow, originalSelectionState );
				
				if( scrap )
					_extendedClipboard.setContents(scrap);
			}
			return true;
		}
	}
}