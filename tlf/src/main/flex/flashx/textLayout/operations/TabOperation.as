package flashx.textLayout.operations
{
	import flash.events.KeyboardEvent;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.container.AutosizableContainerController;
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.converter.IHTMLExporter;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.edit.EditManager;
	import flashx.textLayout.edit.ExtendedEditManager;
	import flashx.textLayout.edit.ParaEdit;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.edit.helpers.SelectionHelper;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.list.ListElementX;
	import flashx.textLayout.elements.list.ListItemElementX;
	import flashx.textLayout.elements.list.ListPaddingElement;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.ListUtil;
	
	use namespace tlf_internal;
	
	/**
	 * The TabOperation is a subclass that tabs text.
	 * 
	 * @author dominickaccattato
	 * 
	 */
	public class TabOperation extends FlowTextOperation
	{
		private var interactionManager:ExtendedEditManager;
				
		protected var selectedLists:Array = new Array();
		private var event:KeyboardEvent;
								
		/**
		 * 
		 * @param operationState
		 * @param interactionManager
		 * @param importer
		 * @param exporter
		 * 
		 */
		public function TabOperation( operationState:SelectionState, interactionManager:ExtendedEditManager, event:KeyboardEvent, importer:IHTMLImporter, exporter:IHTMLExporter )
		{
			super( operationState );
			
			// Set the interaction manager so that we can reference it while deleting lists.
			this.interactionManager = interactionManager;
			this.event = event;
		}
				
		/**
		 * doOperation is called by ExtendedEditManager.
		 * 
		 * @return 
		 * 
		 */
		public override function doOperation():Boolean	{
			var items:Array = SelectionHelper.getSelectedListItems( textFlow, true );
			var lists:Array = SelectionHelper.getSelectedLists( textFlow );
			
			var startItem:ListItemElementX;
			var endItem:ListItemElementX;
			
			var startElement:FlowElement;
			var endElement:FlowElement;
			
			var p:ParagraphElement;
			
			var item:ListItemElementX;
			var prevItem:ListItemElementX;
			var nextItem:ListItemElementX;
			
			var nextElement:FlowElement;
			
			var list:ListElementX;
			var endList:ListElementX;
			
			var start:int;
			var end:int;
			
			var deleteFrom:int;
			var deleteTo:int;
			
			var i:int;
			var j:int;
			
			var tl:int;
			
			var node:XML;
			
			var transferItems:Vector.<ListItemElementX> = new Vector.<ListItemElementX>();
			var transferChildren:Vector.<FlowElement> = new Vector.<FlowElement>();			
			
			if ( items.length > 0 )
			{
				for each ( item in items )
				{
					list = item.parent as ListElementX;
					
					//	Get the item with the previous indent (if possible)
					prevItem = getLastIndentedListItem(item);
					
					if ( event.shiftKey )
					{
						//	Update children with > indent
						for ( i = list.getChildIndex(item)+1; i < list.numChildren; i++ )
						{
							startItem = list.getChildAt(i) as ListItemElementX;
							if ( startItem )
							{
								if ( startItem.indent > item.indent )
								{
									endItem = getLastIndentedListItem(startItem, item);
									if ( endItem && endItem.mode != startItem.mode && Math.max(0, startItem.indent-24) <= endItem.indent )
										startItem.mode = endItem.mode;
									startItem.indent = Math.max(0, startItem.indent-24);
								}
								else
									break;
							}
							else
								break;
						}
						
						if ( prevItem )
						{
							//	Only change mode if prevItem.mode differs and if the change will make it the same (or less [SHOULD NEVER HAPPEN]) indent as prevItem
							if ( prevItem.mode != item.mode && Math.max(0, item.indent-24) <= prevItem.indent )
								item.mode = prevItem.mode;
							item.indent = Math.max(0, item.indent-24);
						}
						else
							item.indent = Math.max(0, item.indent-24);
					}
					else
					{
						//	Update children with > indent
						for ( i = list.getChildIndex(item)+1; i < list.numChildren; i++ )
						{
							startItem = list.getChildAt(i) as ListItemElementX;
							if ( startItem )
							{
								if ( startItem.indent > item.indent )
									startItem.indent = Math.min(240, startItem.indent+24);
								else
									break;
							}
							else
								break;
						}
						
						item.indent = Math.min(240, item.indent+24);
					}
				}
				
				for each ( list in lists )
				list.update();
				
				textFlow.flowComposer.updateAllControllers();
				return true;
			}
			else
			{
				if (textFlow.configuration.manageTabKey) 
				{
					var em:EditManager = interactionManager as EditManager;
					EditManager.overwriteMode ? em.overwriteText(String.fromCharCode(event.charCode)) : em.insertText(String.fromCharCode(event.charCode));
					//event.preventDefault();
				}

				return true;
			}
			
			return true;	
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */
		public override function undo():SelectionState
		{
			/*
			if( _listModeChange )
			{
			undoListModeChange();
			}
			else if( _listModeCreateOnTextFlow )
			{
			removeListFromTextFlow( _listCreatedOnTextFlow );
			}*/
			return originalSelectionState; 
		}
		
		private function getLastIndentedListItem( start:ListItemElementX, ignore:ListItemElementX = null ):ListItemElementX
		{
			var list:ListElementX = start.parent as ListElementX;
			
			if ( list )
			{
				for ( var i:int = list.getChildIndex(start)-1; i > -1; i-- )
				{
					var item:ListItemElementX = list.getChildAt(i) as ListItemElementX;
					if ( item && item.indent < start.indent && item != ignore )
						return item;
				}
			}
			return null;
		}
		
		// [TA] 07-27-2010 :: See comment on FlowOperation.
		override public function get affectsFlowStructure():Boolean
		{
			return true;
		}
		// [END TA]
	}
}