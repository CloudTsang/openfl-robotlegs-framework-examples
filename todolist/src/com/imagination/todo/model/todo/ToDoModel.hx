package com.imagination.todo.model.todo;

import com.imagination.delay.Delay;
import com.imagination.todo.model.todo.items.ToDoItem;
import msignal.Signal.Signal1;
import openfl.net.SharedObject;

/**
 * ...
 * @author P.J.Shand
 */
@:rtti
@:keepSub
class ToDoModel
{
	private var items = new Array<ToDoItem>();
	public var onNewItem = new Signal1<ToDoItem>();
	public var onRemoveItem = new Signal1<ToDoItem>();
	public var onUpdateItem = new Signal1<ToDoItem>();
	public var numberOfItems(get, null):Int;
	public var numberOfCompletedItems(get, null):Int;
	public var numberOfRemainingItems(get, null):Int;
	
	private var sharedObject:SharedObject;
	
	public function new() 
	{
		#if flash
		untyped __global__["flash.net.registerClassAlias"]("ToDoItem", com.imagination.todo.model.todo.items.ToDoItem);
		#end
		
		sharedObject = SharedObject.getLocal("ToDoItems");
		var savedItems:Array<ToDoItem> = Reflect.getProperty(sharedObject.data, "savedItems");
		if (savedItems != null) {
			Delay.nextFrame(AddSavedItems, [savedItems]);
		}
	}
	
	private function AddSavedItems(savedItems:Array<ToDoItem>):Void
	{
		trace("savedItems.length = " + savedItems.length);
		for (i in 0...savedItems.length) 
		{
			addItem(savedItems[i]);
		}
	}
	
	public function addItem(toDoItem:ToDoItem):Void
	{
		items.push(toDoItem);
		onNewItem.dispatch(toDoItem);
		saveData();
	}
	
	public function updateItem(toDoItem:ToDoItem):Void
	{
		var i = items.length - 1;
		while (i >= 0) 
		{
			if (items[i] == toDoItem) {
				onUpdateItem.dispatch(toDoItem);
			}
			i--;
		}
		saveData();
	}
	
	public function removeItem(toDoItem:ToDoItem):Void
	{
		var i = items.length - 1;
		while (i >= 0) 
		{
			if (items[i] == toDoItem) {
				var _toDoItem = items[i];
				items.splice(i, 1);
				onRemoveItem.dispatch(_toDoItem);
			}
			i--;
		}
		saveData();
	}
	
	public function clearComplete():Void
	{
		var i = items.length - 1;
		while (i >= 0) 
		{
			if (items[i].done) {
				var _toDoItem = items[i];
				items.splice(i, 1);
				onRemoveItem.dispatch(_toDoItem);
			}
			i--;
		}
		saveData();
	}
	
	private function saveData():Void
	{
		sharedObject.setProperty("savedItems", items);
		sharedObject.flush();
	}
	
	private function get_numberOfItems():Int 
	{
		return items.length;
	}
	
	private function get_numberOfCompletedItems():Int 
	{
		var value:Int = 0;
		for (i in 0...items.length) 
		{
			if (items[i].done) value++;
		}
		return value;
	}
	
	private function get_numberOfRemainingItems():Int 
	{
		var value:Int = 0;
		for (i in 0...items.length) 
		{
			if (items[i].done == false) value++;
		}
		return value;
	}
}