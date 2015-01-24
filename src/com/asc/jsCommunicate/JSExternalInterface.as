package com.asc.jsCommunicate
{
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	/**
	 * Use ExternalInterface for the interactive between Javascript and ActionScript.
	 */
	public class JSExternalInterface
	{
		
		private const MAX_ITEM_RETRY_COUNT:int = 600; //优化握手成功率
		private const MAX_TOTAL_RETRY_COUNT:int = 600;
		private const RETRY_INTERVAL:int = 100; //unit: ms 
		
		private const LABEL_FN_NAME:String = "LABEL_FN_NAME";
		private const LABEL_FN:String = "LABEL_FN";
		private const LABEL_THIS_OBJECT:String = "LABEL_THIS_OBJECT";
		private const LABEL_CALLBACK_FN:String = "LABEL_CALLBACK_FN";
		private const LABEL_JUDGE_FN:String = "LABEL_JUDGE_FN";
		private const LABEL_PARAMS:String = "LABEL_PARAMS";
		private const LABLE_RETRYABLE_COUNT:String = "LABLE_RETRYABLE_COUNT";
		
		private var callFns:Array = new Array();
		private var callbackFns:Array = new Array();
		
		private var retryTimer:Timer;
		private var curTotalRetryCount:int;
		
		public function JSExternalInterface()
		{
			init();
		}
		
		/**
		 * Register the Actionscript function to be the available function to container.
		 * If failed and needRetry is true, add it into the asynchronous callback list and retry with a time interval.
		 *
		 * @param fnName      function name used for the container to call
		 * @param fn         the closure function will be called
		 * @param needRetry  need retry or not if get error
		 */
		public function addCallback(fnName:String, fn:Function, needRetry:Boolean = false):void
		{
			if (!fnName)
				return;
			
			var fnAdded:Boolean = false;
			try
			{
				if (ExternalInterface.available)
				{
					ExternalInterface.addCallback(fnName, fn);
					fnAdded = true;
				}
			}
			catch (error:Error)
			{
				fnAdded = false;
				trace("[JSExternalInterface] addCallback > catch error > fnName: " + fnName, 0xFF0000);
			}
			finally
			{
				if (needRetry && !fnAdded)
				{
					var callbackFnItem:Dictionary = new Dictionary();
					callbackFnItem[LABEL_FN_NAME] = fnName;
					callbackFnItem[LABEL_FN] = fn;
					callbackFnItem[LABLE_RETRYABLE_COUNT] = MAX_ITEM_RETRY_COUNT;
					callbackFns.push(callbackFnItem);
					
					startTimer();
					
					trace("[JSExternalInterface] addCallback > finally > fnName: " + fnName + " Add this function into callbackFns", 0xFF0000);
				}
			}
		}
		
		/**
		 * Call the available function from swf container and return the value from that available function.
		 * Null will be returned if function name is illegal or fail to call this function.
		 *
		 * @param   fnName           function name
		 * @param   arguments       zero or more parameters will be passed to container
		 * @return  *               return the value from the call of js function
		 */
		public function call(fnName:String, params:Array = null):*
		{
			var result:* = null;
			
			if (!fnName)
				return null;
			
			try
			{
				if (ExternalInterface.available)
				{
					var params:Array = [fnName].concat(params);
					result = ExternalInterface.call.apply(ExternalInterface, params);
				}
			}
			catch (error:Error)
			{
				trace("[JSExternalInterface] call > catch error > fnName: " + fnName, 0xFF0000);
				
				result = error;
			}
			
			return result;
		}
		
		/**
		 * Try doing the asynchronous call.
		 * If failed, add it into the asynchronous call list and retry with a time interval.
		 *
		 * @param thisObj             This object of the function
		 * @param fnName               Name of the function
		 * @param callbackFn          Callback function if the js call success and get true with judge function
		 * @param param               Parameters of the function
		 * @param judgeFn             Function to judge the result from js call
		 */
		public function asynCall(thisObj:Object, fnName:String, params:Array, callbackFn:Function, judgeFn:Function = null):void
		{
			if (!fnName) //!thisObj || !fnName
				return;
			
			var callSuc:Boolean = false;
			
			try
			{
				callSuc = tryAsynCall(thisObj, fnName, callbackFn, params, judgeFn);
			}
			catch (error:Error)
			{
				trace("[JSExternalInterface] asynCall > catch error > fnName: " + fnName, 0xFF0000);
			}
			finally
			{
				if (!callSuc)
				{
					var callFnItem:Dictionary = new Dictionary();
					callFnItem[LABEL_THIS_OBJECT] = thisObj;
					callFnItem[LABEL_FN_NAME] = fnName;
					callFnItem[LABEL_FN] = callbackFn;
					callFnItem[LABEL_PARAMS] = params;
					callFnItem[LABEL_JUDGE_FN] = judgeFn;
					callFnItem[LABLE_RETRYABLE_COUNT] = MAX_ITEM_RETRY_COUNT;
					callFns.push(callFnItem);
					
					if (params.length > 1)
						trace("[JSExternalInterface] asynCall > finally > fnName: " + params[0] + " - " + params[1] + " Add this function into callFns", 0xFF0000);
					else
						trace("[JSExternalInterface] asynCall > finally > fnName: " + params[0] + " Add this function into callFns", 0xFF0000);
					
					startTimer();
				}
			}
		}
		
		/**
		 * Delete call function(s) by their thisObject, function name and parameters.
		 *
		 * @param thisObj    This object of the function
		 * @param fnName      Name of the function
		 * @param param      Parameters of the function
		 */
		public function killAsynCall(thisObj:Object, fnName:String = null, params:Array = null):void
		{
			var item:Dictionary;
			var killable:Boolean;
			
			if (!thisObj)
				return;
			
			for (var i:int = callFns.length - 1; i >= 0; i--)
			{
				item = callFns[i];
				
				if (thisObj !== item[LABEL_THIS_OBJECT])
					continue;
				
				killable = false;
				if (null == fnName)
				{
					killable = true;
				}
				else if (fnName == item[LABEL_FN_NAME])
				{
					if ((null == params) || (0 == params.length))
					{
						killable = true;
					}
					else
					{
						var itemParams:Array = item[LABEL_PARAMS];
						if (itemParams && (itemParams.length == params.length))
						{
							for (var j:int = 0; j < params.length; j++)
							{
								if (params[j] != itemParams[j])
									break;
							}
							killable = (j == params.length);
						}
					}
				}
				
				if (killable)
					deleteItemByIndex(callFns, i);
			}
		}
		
		public function reset():void
		{
			destroy();
			
			curTotalRetryCount = 0;
			callFns = new Array();
			callbackFns = new Array();
		}
		
		public function destroy():void
		{
			clearTimer();
			destroyFnsList(callFns);
			destroyFnsList(callbackFns);
		}
		
		private function init():void
		{
			reset();
		}
		
		/**
		 * Try doing the asynchronous call.
		 * And this function will throw error while doing call function.
		 *
		 * @return        True/False   If the call succeed or not.
		 */
		private function tryAsynCall(thisObj:Object, fnName:String, callbackFn:Function, params:Array = null, judgeFn:Function = null):Boolean
		{
			var callSucc:Boolean = false;
			
			if (ExternalInterface.available)
			{
				var params:Array = [fnName].concat(params);
				var jsResult:* = ExternalInterface.call.apply(ExternalInterface, params);
				if (null == judgeFn)
					callSucc = true;
				else if (null != jsResult)
					callSucc = judgeFn.apply(thisObj, [jsResult]);
				
				if (callSucc && null != callbackFn)
					callbackFn.apply(thisObj, [jsResult]);
			}
			
			return callSucc;
		}
		
		private function retryExternalCall():void
		{
			if ((!callbackFns || 0 == callbackFns.length) && (!callFns || 0 == callFns.length))
			{
				clearTimer();
				return;
			}
			
			//不需要全局的最大重试次数, 每个重试20次即可；
			curTotalRetryCount++;
			
			try
			{
				retryAddCallbackFns();
				retryAsynCallFns();
			}
			catch (e:Error)
			{
				trace("[JSExternalInterface] retryExternalCall ger Error" + e.toString(), 0xFF0000);
			}
		}
		
		/**
		 * Retry the asynchronous call functions and remove it from the asynchronous call list if it success.
		 */
		private function retryAsynCallFns():void
		{
			if (!callFns)
				return;
			
			var len:int = callFns.length;
			if (len <= 0)
				return;
			
			var item:Dictionary;
			for (var i:int = len - 1; i >= 0; i--)
			{
				item = callFns[i];
				
				//在Item不为Null，不管是否抛错，只要callResult为false，都需要重试该Item；抛错且callResult为true不需要重试
				if (item && 0 <= item[LABLE_RETRYABLE_COUNT])
				{
					item[LABLE_RETRYABLE_COUNT]--;
					var callResult:Boolean = false;
					try
					{
						callResult = tryAsynCall(item[LABEL_THIS_OBJECT], item[LABEL_FN_NAME], item[LABEL_FN], item[LABEL_PARAMS], item[LABEL_JUDGE_FN]);
					}
					catch (error:Error)
					{
						callResult = false;
					}
					finally
					{
						if (callResult)
						{
							trace("[JSExternalInterface] Delete " + item[LABEL_FN_NAME]);
							deleteItemByIndex(callFns, i);
							;
						}
					}
				}
				else
				{
					trace("[JSExternalInterface] Delete " + item[LABEL_FN_NAME]);
					deleteItemByIndex(callFns, i);
				}
				
			}
		}
		
		/**
		 * Retry the callback functions and remove it from the callback functions list if it success.
		 */
		private function retryAddCallbackFns():void
		{
			if (!callbackFns)
				return;
			
			var len:int = callbackFns.length;
			if (len <= 0)
				return;
			
			var item:Dictionary;
			for (var i:int = len - 1; i >= 0; i--)
			{
				item = callbackFns[i];
				
				trace("[JSExternalInterface] retryAddCallbackFns:  " + item[LABEL_FN_NAME] + " " + item[LABEL_FN], 0x00FF00);
				
				//在Item不为Null，如果ExternalInterface.available不为True或者抛错时，都需要重试该Item
				if (item && 0 >= item[LABLE_RETRYABLE_COUNT]--)
				{
					var addResult:Boolean = false;
					try
					{
						if (ExternalInterface.available)
						{
							ExternalInterface.addCallback(item[LABEL_FN_NAME], item[LABEL_FN]);
							addResult = true;
						}
					}
					catch (error:Error)
					{
						addResult = false;
					}
					finally
					{
						if (addResult)
						{
							trace("[JSExternalInterface] Delete " + item[LABEL_FN_NAME]);
							deleteItemByIndex(callbackFns, i);
						}
					}
				}
				else
				{
					trace("[JSExternalInterface] Delete " + item[LABEL_FN_NAME]);
					deleteItemByIndex(callbackFns, i);
				}
			}
		}
		
		private function deleteItemByIndex(target:Array, index:int):void
		{
			if (!target || index < 0 || index > target.length)
				return;
			
			trace("[JSExternalInterface] deleteItemByIndex> target: " + target.toString() + " index: " + index, 0xFF0000);
			
			var item:Dictionary = target.splice(index, 1)[0];
			destroyDict(item);
		}
		
		private function startTimer():void
		{
			if (!retryTimer || !retryTimer.hasEventListener(TimerEvent.TIMER))
			{
				clearTimer();
				initTimer();
			}
			
			if (!retryTimer.running)
			{
				retryTimer.start();
			}
		}
		
		private function initTimer():void
		{
			retryTimer = new Timer(RETRY_INTERVAL);
			retryTimer.addEventListener(TimerEvent.TIMER, timerHlr);
		}
		
		private function clearTimer():void
		{
			if (retryTimer)
			{
				retryTimer.removeEventListener(TimerEvent.TIMER, timerHlr);
				retryTimer.stop();
				retryTimer = null;
			}
		}
		
		private function destroyDict(dict:Dictionary):void
		{
			if (dict)
			{
				for (var key:String in dict)
				{
					dict[key] = null;
					delete dict[key];
				}
			}
		}
		
		private function destroyFnsList(target:Array):void
		{
			if (target)
			{
				for (var i:int = target.length - 1; i >= 0; i--)
				{
					destroyDict(target[i]);
				}
				
				target.length = 0;
				target = null;
			}
		}
		
		/////////////////////////////////////////////////////
		/////////        Event Handler         //////////////
		/////////////////////////////////////////////////////
		private function timerHlr(event:TimerEvent):void
		{
			//trace("[JSExternalInterface] curTotalRetryCount = " + curTotalRetryCount, 0xFF0000);
			//if (MAX_TOTAL_RETRY_COUNT < curTotalRetryCount)
			//    clearTimer();
			//else
			retryExternalCall();
		}
	}
}