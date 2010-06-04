package flashx.textLayout.utils
{
	import flashx.textLayout.model.attribute.Attribute;
	import flashx.textLayout.model.attribute.IAttribute;

	public class AttributeUtil
	{
		/**
		 * Creates a new IAttribute instance based on cascade from default to defined. Because Attributes are loose and don't follow the same rule for all elements,
		 * IAttribute is a dynamic class. As such we have to create an assumed computed merge using deault, child and parent contexts. 
		 * @param defaultAttribute IAttribute
		 * @param childAttribute IAttribute
		 * @param parentAttribute IAttribute
		 * @return IAttribute
		 */
		static public function createFromMerge( defaultAttribute:IAttribute, childAttribute:IAttribute, parentAttribute:IAttribute ):IAttribute
		{
			var attribute:IAttribute = new Attribute();
			var property:String;
			// First fill default.
			for( property in defaultAttribute )
			{
				attribute[property] = defaultAttribute[property];
			}
			// Fill with parent attirbutes.
			for( property in parentAttribute )
			{
				attribute[property] = parentAttribute[property];
			}
			// Overwrite whild child attributes.
			for( property in childAttribute )
			{
				attribute[property] = childAttribute[property];
			}
			return attribute;
		}
	}
}