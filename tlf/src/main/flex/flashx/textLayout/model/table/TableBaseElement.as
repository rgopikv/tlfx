package flashx.textLayout.model.table
{
	import flash.events.EventDispatcher;
	import flashx.textLayout.model.attribute.IAttribute;

	/**
	 * TableElement is the base class for all models making up a table. 
	 * @author toddanderson
	 * 
	 */
	public class TableBaseElement extends EventDispatcher
	{
		public var attributes:IAttribute;
		
		public function TableBaseElement() 
		{
			setDefaultAttributes();
		}
		
		/**
		 * @private
		 * 
		 * Creates default IAttributes implementation.
		 */
		protected function setDefaultAttributes():void
		{
			// abtract.
		}
	}
}