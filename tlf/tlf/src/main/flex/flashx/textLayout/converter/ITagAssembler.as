package flashx.textLayout.converter
{
	/**
	 * ITagAssembler converts a fragment model into a valid HTML markup. 
	 * @author toddanderson
	 */
	public interface ITagAssembler
	{
		/**
		 * Creates fragment based on supplied data. 
		 * @param value * The data to convert into a fragment.
		 * @return String
		 */
		function createFragment( value:* ):String;
	}
}