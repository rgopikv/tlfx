package flashx.textLayout.model.table
{
	/**
	 * ITabelDecorationContext is an extension of ITableBaseDecorationContext to expose properties and methods related to the parenting Table. 
	 * @author toddanderson
	 */
	public interface ITableDecorationContext extends ITableBaseDecorationContext
	{
		/**
		 * Returns the determined cell spacing for display based on atributes and styles. 
		 * @return Number
		 */
		function determineCellSpacing():Number;
		/**
		 * Returns the determined cell padding for display based on attributes and styles. 
		 * @return Number
		 */
		function determineCellPadding():Number;
	}
}