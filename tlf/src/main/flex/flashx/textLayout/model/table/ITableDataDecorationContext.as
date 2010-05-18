package flashx.textLayout.model.table
{
	import flashx.textLayout.container.table.ICellContainer;

	/**
	 * ITableDataDecorationContext is a context model representing display properties for a table cell. 
	 * @author toddanderson
	 */
	public interface ITableDataDecorationContext extends ITableDecorationContext
	{
		/**
		 * Determines the padding along border to apply to each cell. 
		 * @return Array
		 */
		function determinePadding():Array;
		
		/**
		 * Returns the specified padding for the left side of the cell. 
		 * @return Number
		 */
		function getLeftPadding():Number;
		/**
		 * Returns the specified padding for the right side of the cell. 
		 * @return Number
		 */
		function getRightPadding():Number;
		/**
		 * Returns the sepcified padding for the top of the cell. 
		 * @return Number
		 */
		function getTopPadding():Number;
		/**
		 * Returns the specified padding for the bottom of the cell. 
		 * @return Number
		 */
		function getBottomPadding():Number;
		
		/**
		 * Returns the cummulative width of the left and right padding. 
		 * @return Number
		 */
		function getComputedWidthOfPadding():Number;
		/**
		 * Returns the cummulative height of the top and bottom padding. 
		 * @return Number
		 */
		function getComputedHeightOfPadding():Number;
		
		/**
		 * Returns the cummulative width of the left and right padding and left and right borders. 
		 * @return Number
		 */
		function getComputedWidthOfPaddingAndBorders():Number;
		/**
		 * Returns the cummulative height of the top and bottom padding and top and bottom borders. 
		 * @return Number
		 */
		function getComputedHeightOfPaddingAndBorders():Number;
		
		function getDefinedWidth():Number;
		function getDefinedHeight():Number;
		
		function getAllotedWidth( cell:ICellContainer ):Number;
		function getAllotedHeight( cell:ICellContainer ):Number;
	}
}