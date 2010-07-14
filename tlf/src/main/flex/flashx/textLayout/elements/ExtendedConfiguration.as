package flashx.textLayout.elements
{
	import flash.text.engine.FontWeight;
	import flash.text.engine.Kerning;
	import flash.text.engine.RenderingMode;
	
	import flashx.textLayout.formats.BaselineShift;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextAlign;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormatValueHolder;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.DimensionTokenUtil;

	use namespace tlf_internal;
	
	public class ExtendedConfiguration extends Configuration
	{
		protected var _defaultTableFormat:ITextLayoutFormat;
		protected var _defaultTableHeaderFormat:ITextLayoutFormat;
		protected var _defaultHeaderFormat:ITextLayoutFormat;
		
		public function ExtendedConfiguration(initializeWithDefaults:Boolean=true)
		{
			super(initializeWithDefaults);
			
			if( initializeWithDefaults ) 
				initialize();
		}
		
		protected function initialize():void
		{
			var format:TextLayoutFormatValueHolder = new TextLayoutFormatValueHolder();
			_defaultTableFormat = format;
			
			var thFormat:TextLayoutFormatValueHolder = new TextLayoutFormatValueHolder();
			thFormat.fontWeight = FontWeight.BOLD;
			thFormat.textAlign = TextAlign.CENTER;
			_defaultTableHeaderFormat = thFormat;
			
			var hFormat:TextLayoutFormatValueHolder = new TextLayoutFormatValueHolder();
			hFormat.fontWeight = FontWeight.BOLD;
			hFormat.fontSize = DimensionTokenUtil.convertPointToPixel( 14 );
			hFormat.lineHeight = ( hFormat.fontSize ) * 1.2;
			_defaultHeaderFormat = hFormat;
		}
		
		override public function clone():Configuration
		{
			var exConfig:Configuration = new ExtendedConfiguration( false );
			// must copy all values
			exConfig.defaultLinkActiveFormat = defaultLinkActiveFormat;
			exConfig.defaultLinkHoverFormat = defaultLinkHoverFormat;
			exConfig.defaultLinkNormalFormat = defaultLinkNormalFormat;
			exConfig.textFlowInitialFormat = textFlowInitialFormat;
			exConfig.focusedSelectionFormat = focusedSelectionFormat;
			exConfig.unfocusedSelectionFormat = unfocusedSelectionFormat;
			exConfig.inactiveSelectionFormat = inactiveSelectionFormat;
			
			exConfig.manageTabKey = manageTabKey;
			exConfig.manageEnterKey = manageEnterKey;
			exConfig.overflowPolicy = overflowPolicy;
			exConfig.enableAccessibility = enableAccessibility;
			exConfig.releaseLineCreationData = releaseLineCreationData;
			
			exConfig.scrollDragDelay = scrollDragDelay;
			exConfig.scrollDragPixels = scrollDragPixels;
			exConfig.scrollPagePercentage = scrollPagePercentage;
			exConfig.scrollMouseWheelMultiplier = scrollMouseWheelMultiplier;
			
			exConfig.flowComposerClass = flowComposerClass;
			exConfig.inlineGraphicResolverFunction = inlineGraphicResolverFunction;
			
			( exConfig as ExtendedConfiguration ).defaultTableFormat = _defaultTableFormat;
			( exConfig as ExtendedConfiguration ).defaultTableHeaderFormat = _defaultTableHeaderFormat;
			( exConfig as ExtendedConfiguration ).defaultHeaderFormat = _defaultHeaderFormat;
			return exConfig; 
		}
		
		public function get defaultTableFormat():ITextLayoutFormat
		{
			return _defaultTableFormat;
		}
		public function set defaultTableFormat( value:ITextLayoutFormat ):void
		{
			_defaultTableFormat = value;
		}
		
		public function get defaultTableHeaderFormat():ITextLayoutFormat
		{
			return _defaultTableHeaderFormat;
		}
		public function set defaultTableHeaderFormat( value:ITextLayoutFormat ):void
		{
			_defaultTableHeaderFormat = value;
		}

		public function get defaultHeaderFormat():ITextLayoutFormat
		{
			return _defaultHeaderFormat;
		}
		public function set defaultHeaderFormat(value:ITextLayoutFormat):void
		{
			_defaultHeaderFormat = value;
		}

	}
}