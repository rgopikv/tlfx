package flashx.textLayout.model.table
{
	/**
	 * ITabelDecorationContext is an extension of ITableBaseDecorationContext to expose properties and methods related to the parenting Table. 
	 * @author toddanderson
	 */
	public interface ITableDecorationContext extends ITableBaseDecorationContext
	{
		/**
		 * Returns the cummulative height based on top and bottom border widths. 
		 * @return Number
		 */
		function getComputedHeightOfBorders():Number;
		/**
		 * Returns the cummulative width based on left and right border widths. 
		 * @return Number
		 */
		function getComputedWidthOfBorders():Number
		/**
		 * Returns the detemrine bordr width array for display based on attributes and styles. 
		 * @return Array
		 */
		function determineBorderWidth():Array;
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