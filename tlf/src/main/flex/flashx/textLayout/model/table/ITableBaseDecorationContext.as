package flashx.textLayout.model.table
{
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.style.ITableStyle;

	/**
	 * ITableBaseDecorationContext is a base interface that exposes properties and methods related to styling and attributes that make up the dsiaply model of table elements. 
	 * @author toddanderson
	 */
	public interface ITableBaseDecorationContext
	{
		/**
		 * Modifies the attbributes based on the overlay object of key/value pairs. 
		 * @param overlay Object
		 */
		function modifyAttributes( overlay:Object ):void;
		
		function getDefinedAttributes():IAttribute;
		function getDefaultAttributes():IAttribute;
		function getFormattableAttributes():IAttribute;
		
		/**
		 * Merges the held ITableStyle instance with the overlay style.
		 * @param overlay ITableStyle
		 */
		function mergeStyle( overlay:ITableStyle ):void;
		
		/**
		 * Accessor/Modifier for the IAttribute instance. 
		 * @return IAttribute
		 */
		function get attributes():IAttribute;
		function set attributes( value:IAttribute ):void;
		/**
		 * Accessor/Modifier for the ITableStyle instance. 
		 * @return ITableStyle
		 */
		function get style():ITableStyle;
		function set style( value:ITableStyle ):void;
	}
}