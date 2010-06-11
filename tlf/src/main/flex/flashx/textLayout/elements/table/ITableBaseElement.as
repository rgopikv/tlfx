package flashx.textLayout.elements.table
{
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.style.ITableStyle;
	import flashx.textLayout.model.table.ITableBaseDecorationContext;

	public interface ITableBaseElement
	{
		/**
		 * Returns the decoration context implementation instance. 
		 * @return ITableBaseDecorationContext
		 */
		function getContext():ITableBaseDecorationContext;
		
		/**
		 * Returns the held concrete implmenentation of the ITableStyle instance defined on the context model. 
		 * @return ITableStyle
		 */
		function getContextStyle():ITableStyle;
		
		/**
		 * Returns computed attributes of element and parentin elements. 
		 * @return IAttribute
		 */
		function getComputedAttributes():IAttribute;
		
		/**
		 * Performs any cleanup.
		 */
		function dispose():void;
	}
}