package flashx.textLayout.elements.list
{
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;
	
	public class ListPaddingElement extends ParagraphElement
	{
		public function ListPaddingElement()
		{
			super();
			var span:SpanElement = new SpanElement();
			span.text = ' ';
			addChild(span);
		}
		
		tlf_internal override function ensureTerminatorAfterReplace(oldLastLeaf:FlowLeafElement):void
		{
			//	Nothing here in order to ensure that no extra spaces are added between lines
		}
	}
}