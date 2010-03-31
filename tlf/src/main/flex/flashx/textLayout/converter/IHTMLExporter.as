package flashx.textLayout.converter
{
	public interface IHTMLExporter
	{
		function exportElementsToFragment( node:XML, elements:Array ):void;
	}
}