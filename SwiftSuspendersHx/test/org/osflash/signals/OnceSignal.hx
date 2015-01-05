package org.osflash.signals;

import flash.errors.IllegalOperationError;
import flash.utils.getQualifiedClassName;

/** 
 * Allows the valueClasses to be set in MXML, e.g.
 * <signals:Signal id="nameChanged">{[String, UInt]}</signals:Signal>
 */
//[DefaultProperty("valueClasses")]	

/**
 * Signal dispatches events to multiple listeners.
 * It is inspired by C# events and delegates, and by
 * <a target="_top" href="http://en.wikipedia.org/wiki/Signals_and_slots">signals and slots</a>
 * in Qt.
 * A Signal adds event dispatching functionality through composition and interfaces,
 * rather than inheriting from a dispatcher.
 * <br/><br/>
 * Project home: <a target="_top" href="http://github.com/robertpenner/as3-signals/">http://github.com/robertpenner/as3-signals/</a>
 */
class OnceSignal implements IOnceSignal
{
	private var _valueClasses:Array<Dynamic>;		// of Class
	private var slots:SlotList = SlotList.NIL;
	
	/**
	 * Creates a Signal instance to dispatch value objects.
	 * @param	valueClasses Any number of class references that enable type checks in dispatch().
	 * For example, new Signal(String, UInt)
	 * would allow: signal.dispatch("the Answer", 42)
	 * but not: signal.dispatch(true, 42.5)
	 * nor: signal.dispatch()
	 *
	 * NOTE: In AS3, subclasses cannot call super.apply(null, valueClasses),
	 * but this constructor has logic to support super(valueClasses).
	 */
	public function OnceSignal(valueClasses:Array<Dynamic>)
	{
		// Cannot use super.apply(null, valueClasses), so allow the subclass to call super(valueClasses).
		//this.valueClasses = (valueClasses.length == 1 && Std.is(valueClasses[0], Array<Dynamic>)) ? valueClasses[0] : valueClasses;
		this.valueClasses = valueClasses;
	}
	
	/**
	 * @inheritDoc
	 * @throws ArgumentError <code>ArgumentError</code>: Invalid valueClasses argument: item at index should be a Class but was not.
	 */
	//[ArrayElementType("Class")]
	public function valueClasses(get, set):Array<Dynamic>
	
	function get_valueClasses():Array<Dynamic> { return _valueClasses; }
	
	function set_valueClasses(value:Array<Dynamic>):Void
	{
		// Clone so the Array<Dynamic> cannot be affected from outside.
		_valueClasses = value ? value.slice() : [];
		
		for (j in 0..._valueClasses.length) 
		{
			var i = _valueClasses.length - 1 - j;
			
		//}
		//for (var i:Int = _valueClasses.length; i--; )
		//{
			if (Std.is(_valueClasses[i], Class) == false)
			{
				throw new ArgumentError('Invalid valueClasses argument: ' +
					'item at index ' + i + ' should be a Class but was:<' +
					_valueClasses[i] + '>.' + getQualifiedClassName(_valueClasses[i]));
			}
		}
	}
	
	/** @inheritDoc */
	public function get numListeners():UInt { return slots.length; }
	
	/**
	 * @inheritDoc
	 * @throws flash.errors.IllegalOperationError <code>IllegalOperationError</code>: You cannot addOnce() then add() the same listener without removing the relationship first.
	 * @throws ArgumentError <code>ArgumentError</code>: Given listener is <code>null</code>.
	 */
	public function addOnce(listener:Function):ISlot
	{
		return registerListener(listener, true);
	}
	
	/** @inheritDoc */
	public function remove(listener:Function):ISlot
	{
		const slot:ISlot = slots.find(listener);
		if (!slot) return null;
		
		slots = slots.filterNot(listener);
		return slot;
	}
	
	/** @inheritDoc */
	public function removeAll():Void
	{
		slots = SlotList.NIL;
	}
	
	/**
	 * @inheritDoc
	 * @throws ArgumentError <code>ArgumentError</code>: Incorrect number of arguments.
	 * @throws ArgumentError <code>ArgumentError</code>: Value object is not an instance of the appropriate valueClasses Class.
	 */
	public function dispatch(...valueObjects):Void
	{
		
		// If valueClasses is empty, value objects are not type-checked. 
		const numValueClasses:Int = _valueClasses.length;
		const numValueObjects:Int = valueObjects.length;

		// Cannot dispatch fewer objects than declared classes.
		if (numValueObjects < numValueClasses)
		{
			throw new ArgumentError('Incorrect number of arguments. '+
				'Expected at least '+numValueClasses+' but received '+
				numValueObjects+'.');
		}
		
		// Cannot dispatch differently typed objects than declared classes.
		for (var i:Int = 0; i < numValueClasses; i++)
		{
			// Optimized for the optimistic case that values are correct.
			if (valueObjects[i] is _valueClasses[i] || valueObjects[i] === null) 
				continue;
				
			throw new ArgumentError('Value object <'+valueObjects[i]
				+'> is not an instance of <'+_valueClasses[i]+'>.');
		}

		// Broadcast to listeners.
		var slotsToProcess:SlotList = slots;
		if(slotsToProcess.nonEmpty)
		{
			while (slotsToProcess.nonEmpty)
			{
				slotsToProcess.head.execute(valueObjects);
				slotsToProcess = slotsToProcess.tail;
			}
		}
	}

	private function registerListener(listener:Function, once:Bool = false):ISlot
	{
		if (registrationPossible(listener, once))
		{
			const newSlot:ISlot = new Slot(listener, this, once);
			slots = slots.prepend(newSlot);
			return newSlot;
		}
		
		return slots.find(listener);
	}

	private function registrationPossible(listener:Function, once:Bool):Bool
	{
		if (!slots.nonEmpty) return true;
		
		const existingSlot:ISlot = slots.find(listener);
		if (!existingSlot) return true;

		if (existingSlot.once != once)
		{
			// If the listener was previously added, definitely don't add it again.
			// But throw an exception if their once values differ.
			throw new IllegalOperationError('You cannot addOnce() then add() the same listener without removing the relationship first.');
		}
		
		return false; // Listener was already registered.
	}
}