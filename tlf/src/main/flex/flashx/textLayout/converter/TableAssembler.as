package flashx.textLayout.converter
{
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.elements.table.TableRowElement;
	import flashx.textLayout.model.table.Table;
	import flashx.textLayout.model.table.TableRow;
	import flashx.textLayout.utils.FragmentAttributeUtil;
	
	/**
	 * TableAssembler is an ITagAssembler implementation to convert a model representation of a Table into valid HTML markup. 
	 * @author toddanderson
	 */
	public class TableAssembler implements ITagAssembler
	{
		protected var rowAssembler:ITagAssembler;
		
		/**
		 * Constructor 
		 * @param rowAssembler ITagAssembler An implementation that handles creating a valid fragment of <tr />
		 */
		public function TableAssembler( rowAssembler:ITagAssembler )
		{
			this.rowAssembler = rowAssembler;
		}
		
		/**
		 * @private
		 * 
		 * Filter function to determine if TableRow is considered a header item. 
		 * @param item *
		 * @param index int
		 * @param vector Vector.<TableRow>
		 * @return Boolean
		 */
		protected function itemIsHead( item:*, index:int, vector:Vector.<TableRowElement> ):Boolean
		{
			return ( item as TableRowElement ).isHeader;
		}
		
		/**
		 * @private
		 * 
		 * Filter function to determine if TableRow is considered a body item. 
		 * @param item *
		 * @param index int
		 * @param vector Vector.<TableRow>
		 * @return Boolean
		 */
		protected function itemIsBody( item:*, index:int, vector:Vector.<TableRowElement> ):Boolean
		{
			return ( item as TableRowElement ).isBody;
		}
		
		/**
		 * @private
		 * 
		 * Filter function to determine if TableRow is considered a footer item. 
		 * @param item *
		 * @param index int
		 * @param vector Vector.<TableRow>
		 * @return Boolean
		 */
		protected function itemIsFoot( item:*, index:int, vector:Vector.<TableRowElement> ):Boolean
		{
			return ( item as TableRowElement ).isFooter;
		}
		
		/**
		 * @private
		 * 
		 * Determines is TableRow is part of either a header, body or footer. 
		 * @param row TableRow
		 * @return Boolean
		 */
		protected function isBasicRow( row:TableRowElement ):Boolean
		{
			return !row.isBody && !row.isFooter && !row.isHeader;
		}
		
		// TODO: Apply styles.
		/**
		 * Creates a valid <table /> based on supplied data which is assumed as a Table.
		 * @param value * A Table instance.
		 * @return String
		 */
		public function createFragment( value:* ):String
		{
			var fragment:XML = <table />;
			var tableElement:TableElement = value as TableElement;
			var table:Table = tableElement.getTableModel();
			FragmentAttributeUtil.assignAttributes( fragment, table.context.getStrippedAttributes() );
			
			var tableRows:Vector.<TableRowElement> = tableElement.children();
			var assembledRows:Vector.<TableRowElement> = new Vector.<TableRowElement>();
			// For optional table construction.
			// Turn optional table into standard tr/td
			assembledRows = assembledRows.concat( tableRows.filter( itemIsHead, tableRows ) );
			assembledRows = assembledRows.concat( tableRows.filter( itemIsBody, tableRows ) );
			assembledRows = assembledRows.concat( tableRows.filter( itemIsFoot, tableRows ) );
			var rowList:Vector.<TableRowElement> = new Vector.<TableRowElement>();
			// Run through and add basic rows.
			var i:int;
			var row:TableRowElement;
			for( i = 0; i < tableRows.length; i++ )
			{
				row = tableRows[i] as TableRowElement;
				if( isBasicRow( row ) ) rowList.push( row );
			}
			assembledRows = assembledRows.concat( rowList );
			
			// Append each insertion to the fragment.
			for( i = 0; i < assembledRows.length; i++ )
			{
				fragment.appendChild( XML( rowAssembler.createFragment( assembledRows[i] as TableRowElement ) ) );
			}
			return fragment.toXMLString();
		}
	}
}