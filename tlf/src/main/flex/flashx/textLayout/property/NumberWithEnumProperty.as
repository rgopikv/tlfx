////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2008-2009 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
//////////////////////////////////////////////////////////////////////////////////
package flashx.textLayout.property
{
	import flashx.textLayout.debug.assert;
	import flashx.textLayout.formats.FormatValue;
	import flashx.textLayout.tlf_internal;
		
	use namespace tlf_internal;
			
	[ExcludeClass]
	/** A property description with a Number or enumerated string as its value. @private */
	public class NumberWithEnumProperty extends NumberProperty
	{
		private var _range:Object;
		private var _defaultValue:Object;		// could be Number or EnumString value
		
		public function NumberWithEnumProperty(nameValue:String, defaultValue:Object, inherited:Boolean, category:String, minValue:Number, maxValue:Number, ... rest)
		{
			// rest is the list of possible values
			_range = EnumStringProperty.createRange(rest); 
				
			var defaultIsEnum:Boolean = defaultValue is String && _range.hasOwnProperty(defaultValue);
			var numberDefault:Number = defaultIsEnum ? 0 : Number(defaultValue);
			super(nameValue, numberDefault, inherited, category, minValue, maxValue);
			_defaultValue = defaultValue;
		}
		
		/** @private */
		public override function get defaultValue():Object
		{ return _defaultValue; }
		
		/** Returns object whose properties are the legal enum values */
		public function get range():Object
		{
			return Property.shallowCopy(_range); 
		}
		
		/** @private */
		public override function setHelper(currVal:*,newObject:*):*
		{ 
			if (newObject === null)
				newObject = undefined;
			
			if (newObject === undefined)	// range has INHERIT
				return newObject;
				
			return _range.hasOwnProperty(newObject) ? newObject : super.setHelper(currVal,newObject);
		}
		
		/** @private */
		public override function hash(val:Object, seed:uint):uint
		{ 
			CONFIG::debug { assert(!(val is String) || _range.hasOwnProperty(val), "String " + val + " not among possible values for this NumberWithEnumProperty"); }
			var hash:uint = _range[val];
			if (hash != 0)
				return UintProperty.doHash(hash, seed);
			return super.hash(val, seed);
		}
	}
}