package flashx.textLayout.elements
{
	import flashx.textLayout.tlf_internal;
	
	use namespace tlf_internal;
	
	public class ExtendedLinkElement extends LinkElement
	{
		public function ExtendedLinkElement()
		{
			super();
		}
		
		/**
		 * The purpose of creating this class is to solve the future implementation problem of LinkElement being able to accept at least one other LinkElement
		 * as HTML allows.
		 * 
		 * This implementation hasn't yet been elected to be developed, but it may be in the future.
		 */		
		
		override tlf_internal function canOwnFlowElement(elem:FlowElement) : Boolean
		{
			return elem is SpanElement;
		}
	}
}