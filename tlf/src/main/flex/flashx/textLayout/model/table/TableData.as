package flashx.textLayout.model.table
{
	import flashx.textLayout.model.attribute.TableDataAttribute;
	import flashx.textLayout.utils.StyleAttributeUtil;

	/**
	 * TableData represents the model for a single cell within a Table. 
	 * @author toddanderson
	 */
	public class TableData extends TableBaseElement
	{
		public var data:XML;
		public var nextTableData:TableData;
		public var previousTableData:TableData;
		
		public static const CONTENT_PARENT_ID:String = "holder";
		
		/**
		 * Constructor. 
		 * 
		 * @param data XML The straight XML grabbed from the parsed <td /> tag.
		 */
		public function TableData( data:XML )
		{
			super();
			this.data = data;
		}
		
		/**
		 * @inherit
		 */
		override protected function setDefaultAttributes():void
		{
			attributes = TableDataAttribute.getDefaultAttributes();
		}
		
		/**
		 * Returns the text equivilent for the supplied XML data. 
		 * @return String
		 */
		public function get text():String
		{
			return data.text().toString();
		}
		
		/**
		 * Constructs and returns a valid TFL markup fragment representing this data cell.
		 * USeful when inserting and converting elements for the targeted TextFlow. 
		 * @return String
		 */
		public function get content():String
		{
			XML.ignoreWhitespace = true;
			XML.prettyIndent = 0;
			XML.prettyPrinting = false;
			var tlf:XML = <TextFlow xmlns="http://ns.adobe.com/textLayout/2008" />;
			var div:XML = <div id="holder" />;
			var children:XMLList = data.children();
			if( children.length() > 0 )
			{
				var child:XML;
				for( var i:int = 0; i < children.length(); i++ )
				{
					child = children[i];
					div.appendChild( child );	
				}
			}
			else 
			{
				var p:XML = <p />;
				var span:XML = <span></span>
				p.appendChild( span );
				div.appendChild( p );
			}
			tlf.appendChild( div );
			return tlf.toXMLString();
		}
		
		/*
		TODO: For CustomHTMLImporter.
		public function get content():String
		{
			XML.ignoreWhitespace = true;
			XML.prettyIndent = 0;
			XML.prettyPrinting = false;
//			var div:XML = <div/>
			var children:XMLList = data.children();
			var p:XML = children[0];
			if( children.length() > 0 )
			{
//				var child:XML;
//				for( var i:int = 0; i < children.length(); i++ )
//				{
//					child = children[i];
//					div.appendChild( child );	
//				}
			}
			else 
			{
				p = <p />;
				var span:XML = <span></span>
				p.appendChild( span );
//				div.appendChild( p );
				return p.toXMLString();
			}
			return p.toXMLString();
		}
		/**/
		
		/**
		 * Static access to a new Empty TableData instance. 
		 * @param id String The id to assign the new data. Ids are used during recomposition after an alteration to the Table model for the TextFlow.
		 * @return TableData
		 */
		static public function newTableData( id:String = "" ):TableData
		{
			var p:XML = <p id={id}/>;
			var span:XML = <span></span>;
			p.appendChild( span );
			return new TableData( p );
		}
	}
}