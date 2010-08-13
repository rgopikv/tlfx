package flashx.textLayout.converter
{
	import flashx.textLayout.elements.table.TableElement;
	import flashx.textLayout.elements.table.TableRowElement;
	import flashx.textLayout.model.attribute.TableAttribute;
	import flashx.textLayout.model.style.ITableStyle;
	import flashx.textLayout.model.table.ITableBaseDecorationContext;
	import flashx.textLayout.model.table.Table;
	import flashx.textLayout.model.table.TableRow;
	import flashx.textLayout.utils.DimensionTokenUtil;
	import flashx.textLayout.utils.FragmentAttributeUtil;
	import flashx.textLayout.utils.StyleAttributeUtil;
	
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
		
		/**
		 * @private
		 * 
		 * Transfers any necessary stripped atributes to the styles. 
		 * @param tableElement TableElement
		 */
		protected function transferAttributesToStyles( tableElement:TableElement ):void
		{
			var context:ITableBaseDecorationContext = tableElement.getDecorationContext();
			var attributes:Object = context.attributes;
			var styles:Object = context.style;
			if( !attributes.isUndefined( TableAttribute.WIDTH ) )
			{
				delete attributes[TableAttribute.WIDTH];
			}
		}
		
		/**
		 * @private
		 * 
		 * Update the widht dimension on the explicit styles in order to be exported properly with dimnesions. 
		 * @param tableElement TableElement
		 * @param width Number
		 */
		protected function affixTableWidthDimension( tableElement:TableElement, width:Number ):void
		{
			var explicitStyles:Object = StyleAttributeUtil.getExplicitStyle( tableElement );
			if( explicitStyles == null ) 
			{
				StyleAttributeUtil.setExplicitStyle( tableElement, {} );
				explicitStyles = StyleAttributeUtil.getExplicitStyle( tableElement );
			}
			if( !isNaN(width) && explicitStyles )
			{
				explicitStyles["width"] = DimensionTokenUtil.exportAsPixel( width );
			}
		}
		
		/**
		 * Creates a valid <table /> based on supplied data which is assumed as a Table.
		 * @param value * A Table instance.
		 * @return String
		 */
		public function createFragment( value:* ):String
		{
			var settings:Object = XML.settings();
			XML.ignoreWhitespace = true;
			XML.prettyPrinting = false;
			var fragment:XML = <table />;
			var tableElement:TableElement = value as TableElement;
			var table:Table = tableElement.getTableModel();
			transferAttributesToStyles( tableElement );
			FragmentAttributeUtil.assignAttributes( fragment, table.context.getDefinedAttributes() );
			StyleAttributeUtil.assembleTableBaseStyles( fragment, tableElement );
			affixTableWidthDimension( tableElement, table.getComputedWidth() );
			
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
			var payload:String = fragment.toXMLString();
			XML.setSettings( settings );
			return payload;
		}
	}
}