package com.asc.jsCommunicate
{
	import flash.utils.Dictionary;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	public class JSCommunicator
	{
		private static var _instance:JSCommunicator;
		
		private var jsInterface:JSExternalInterface;
		//List for callback functions
		private var callbackFns:Dictionary;
		
		public static function getInstance():JSCommunicator
		{
			return _instance || (_instance = new JSCommunicator());
		}
		
		public function JSCommunicator()
		{
			jsInterface = new JSExternalInterface();
			
			init();
		}
		
		/**
		 * 用于SWF公开的notify接口，允许页面通过notify接口的第一个参数type映射调用到SWF内部的方法
		 * e.g.:
		 * 		addFnsToCallbackHeap(oneObject; [{"pausePlayer":"pause"},{"pause":"pause"}])
		 * 		swf.notify('pausePlayer', [p1, p2, ...])  --->  oneObject.pause(p1, p2, ...)
		 * 		swf.notify('pause', [p1, p2, ...])  --->  oneObject.pause(p1, p2, ...)
		 * @param thisObj		调用对象
		 * @param mappingArr	映射关系
		 * @example addFnsToCallbackHeap(oneObject; [{"pausePlayer":"pause"},{"pause":"pause"}])
		 *
		 */
		private function addFnsToCallbackHeap(thisObj:Object, fnNameArr:Array):void
		{
			if (!fnNameArr || 0 >= fnNameArr.length || null == thisObj)
				return;
			
			for (var i:int = 0; i < fnNameArr.length; i++)
			{
				var obj:Object = fnNameArr[i];
				for (var a:String in obj)
				{
					callbackFns[a] = {'thisObj': thisObj, 'fnName': obj[a]};
				}
			}
		}
		
		/**
		 * The function will be registered as the available ActionScript function to container(Here is JavaScript Container).
		 * Currently it will be added into the heap and waiting for registration.
		 * @param thisObj          This object of the function
		 * @param fName            {"pausePlayer":"pause"}  pausePlayer页面使用，pause为thisObject的方法
		 */
		private function addToCallbackHeap(thisObj:Object, fnName:Object):void
		{
			for (var a:String in fnName)
			{
				callbackFns[a] = {'thisObj': thisObj, 'fnName': fnName[a]};
			}
		}
		
		/**
		 * Remove the function from the callback functions' heap.
		 * Do this remove action before the registration is valuable.
		 * @param fName            页面使用名
		 */
		private function removeFromCallbackHeap(fnName:String):void
		{
			callbackFns[fnName] = null;
			delete callbackFns[fnName];
		}
		
		private function init():void
		{
			reset();
		}
		
		//*****************
		// js call as
		//*****************
		private function notifyHlr(eventName:String, params:Array = null):*
		{
			//trace(eventName, "params: " + params);
			if (null == params)
				params = [];
			if (null != callbackFns[eventName])
				return applyCallbackFn(eventName, params);
			else
				return null;
		}
		
		private function applyCallbackFn(eventName:String, params:Array):*
		{
			var obj:Object = callbackFns[eventName];
			if (!obj.hasOwnProperty('thisObj') || !obj.hasOwnProperty('fnName'))
				return;
			
			var thisObj:Object = obj['thisObj'];
			if (null == thisObj)
				return null;
			
			var fn:Function = thisObj[obj['fnName']];
			if (null == fn)
				return null;
			
			return fn.apply(thisObj, params);
		}
		
		private function destroyDict(dict:Dictionary):void
		{
			if (dict)
			{
				for (var key:*in dict)
				{
					dict[key] = null;
					delete dict[key];
				}
			}
		}
		
		//*****************
		//模拟JS监听AS3事件
		//*****************
		private var listenerDict:Dictionary;
		private var listenerCallbackAdded:Boolean;
		
		private function initJSEventListener():void
		{
			if (!listenerCallbackAdded)
			{
				listenerCallbackAdded = true;
				jsInterface.addCallback(JSCommuncatorConstant.ADD_EVENT_LISTENER, addEventListenerHlr, true);
				jsInterface.addCallback(JSCommuncatorConstant.REMOVE_EVENT_LISTENER, removeEventListenerHlr, true);
			}
		}
		
		private function get enableJsEventDisPatcher():Boolean
		{
			return listenerCallbackAdded;
		}
		
		private function addEventListenerHlr(maptype:String, listener:String):void
		{
			var type:String = maptype; //EventConstant[maptype]; //todo: EventConstant
			if (!type)
				return;
			
			listenerDict[type] = listener;
		}
		
		private function removeEventListenerHlr(type:String, listener:String):void
		{
			listenerDict[type] = null;
			delete listenerDict[type];
		}
		
		public function add(thisObj:Object, option:*):void
		{
			if (option is Array)
			{
				addFnsToCallbackHeap(thisObj, option);
			}
			else if (option is Object)
			{
				addToCallbackHeap(thisObj, option);
			}
		}
		
		public function remove(name:String):void
		{
			removeFromCallbackHeap(name);
		}
		
		public function dispatcher(eventType:String, ... params):void
		{
			var listener:String = listenerDict[eventType];
			if (listener)
				jsInterface.call(listener, params);
		}
		
		public function reset():void
		{
			if (jsInterface)
			{
				jsInterface.reset();
			}
			listenerCallbackAdded = false;
			
			destroyDict(listenerDict);
			listenerDict = new Dictionary();
			destroyDict(callbackFns);
			callbackFns = new Dictionary();
			
			jsInterface.addCallback(JSCommuncatorConstant.JS_NOTIFY_AS, notifyHlr, true);
			initJSEventListener();
		}
		
		public function destroy():void
		{
			if (jsInterface)
			{
				jsInterface.destroy();
				jsInterface = null;
			}
			destroyDict(listenerDict);
			destroyDict(callbackFns);
		}
	}
}