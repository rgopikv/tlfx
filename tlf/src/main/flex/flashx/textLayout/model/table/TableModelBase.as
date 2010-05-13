package flashx.textLayout.model.table
{
	import flash.events.EventDispatcher;
	
	import flashx.textLayout.model.attribute.IAttribute;
	import flashx.textLayout.model.style.ITableStyle;

	/**
	 * TableModelBaseis the base class for all models making up a table. 
	 * @author toddanderson
	 */
	public class TableModelBase extends EventDispatcher
	{
		public var context:ITableBaseDecorationContext;
		/**
		 * Contructor. 
		 * Establishes context model for attributes and styles.
		 */
		public function TableModelBase() 
		{
			context = new TableBaseDecorationContext( getDefaultAttributes(), getDefaultStyle() );
		}
		
		/**
		 * Returns the default attributes related to this table model instance. 
		 * @return IAttribute
		 */
		protected function getDefaultAttributes():IAttribute
		{
			// abstract.
			return null;
		}
		
		/**
		 * Returns the default styles related to this table model instance. 
		 * @return ITableStyle
		 */
		protected function getDefaultStyle():ITableStyle
		{
			//abstact.
			return null;
		}
	}
}