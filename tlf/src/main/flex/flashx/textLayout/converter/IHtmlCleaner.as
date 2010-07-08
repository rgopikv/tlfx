package flashx.textLayout.converter
{
	public interface IHtmlCleaner
	{
		function clean( html:String ):String;
		function cleanAsync( callback:Function, html:String ):void;
	}
}