package com.imagination.todo.model.filter;
import msignal.Signal.Signal0;
import openfl.net.SharedObject;

/**
 * ...
 * @author P.J.Shand
 */
@:rtti
@:keepSub
class FilterModel 
{
	public static var FILTER_ALL:String = "All";
	public static var FILTER_ACTIVE:String = "Active";
	public static var FILTER_COMPLETED:String = "Completed";
	
	private var _value:String = FilterModel.FILTER_ALL;
	public var value(get, set):String;
	public var change = new Signal0();
	
	private var sharedObject:SharedObject;
	
	public function new() 
	{
		sharedObject = SharedObject.getLocal("FilterModel");
		var savedValue:String = Reflect.getProperty(sharedObject.data, "savedValue");
		if (savedValue != null) {
			this.value = savedValue;
		}
	}
	
	private function get_value():String 
	{
		return _value;
	}
	
	private function set_value(v:String):String 
	{
		if (_value == v) return v;
		_value = v;
		change.dispatch();
		sharedObject.setProperty("savedValue", value);
		sharedObject.flush();
		return v;
	}
}