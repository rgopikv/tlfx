package flashx.textLayout.operations
{
	import flashx.textLayout.converter.IHTMLExporter;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.edit.SelectionState;
	
	public class ExtendedInsertFlowLeafElementOperation extends InsertFlowLeafElementOperation
	{
		protected var _htmlImporter:IHTMLImporter;
		protected var _htmlExporter:IHTMLExporter;
		
		public function ExtendedInsertFlowLeafElementOperation( operationState:SelectionState, htmlImporter:IHTMLImporter, htmlExporter:IHTMLExporter, text:String, elementClass:String )
		{
			super(operationState, text, elementClass);
			_htmlImporter = htmlImporter;
			_htmlExporter = htmlExporter;
		}
		
		override public function doOperation():Boolean
		{
			var success:Boolean = super.doOperation();
			
			var node:XML = _htmlExporter.getSimpleMarkupModelForElement( _createdElement );
			_htmlImporter.importStyleHelper.assignInlineStyle( node, _createdElement );
			_htmlImporter.importStyleHelper.apply();
			return success;
		}
	}
}