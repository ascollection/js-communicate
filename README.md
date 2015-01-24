# js-communicate INTR
AS-JS的交互通讯模块，提供了JS中模拟AS3事件监听处理方式用于取代AS直接调页面接口的方式。  
使用该库将为SWF提供三个接口给JS来调用：  
* **notify，用于JS调AS中的接口**  
>>swf.notify('pausePlayer', [p1, p2, ...])  --->  oneObject.pause(p1, p2, ...)  
* **addEventListener，用于模拟事件监听**  
>>swf.addEventListener("one", "oneHlr");  
>>*one为as中的事件名，oneHlr为页面的方法名*  
* **removeEventListener，用于模拟事件监听**  
>>swf.removeEventListener("one", "oneHlr");  
>>*one为as中的事件名，oneHlr为页面的方法名*  


**Interface 接口**   
```actionscript
/**
 * 为SWF的notify接口添加调用映射配置
 *（key为JS调用notify的消息名，value为SWF中thisObj下的方法名）
 * e.g.:
 *      add(oneObject, [{"pausePlayer":"pause"}, {"pause":"pause"}]);
 *      add(oneObject, {"pausePlayer":"pause"}, {"pause":"pause"});
 *      swf.notify('pausePlayer', [p1, p2, ...])  --->  oneObject.pause(p1, p2, ...)
 *      swf.notify('pause', [p1, p2, ...])        --->  oneObject.pause(p1, p2, ...)
 * @param	thisObj 调用对象
 * @param	...option 映射配置, 支持{}, {},...以及[{}, {}, {}]的数据形式
 */
public function add(thisObj:Object, ... option):void;

/**
 * 根据消息名从SWF的notify接口调用映射配置中移除相应的配置
 * @param	name JS调用notify接口的消息名
 */
public function remove(name:String):void;

/**
 * 抛出JS事件，将根据js是否已注册了该事件，决定是否执行相应的listener
 * @param	eventType   事件名
 * @param	... params  listener方法的参数
 */
public function dispatcher(eventType:String, ... params):void;

/**
 * 重置JS通讯模块
 */
public function reset():void;

/**
 * 析构JS通讯模块
 */
public function destroy():void;
```

## Usage 使用
###Actionscript 3
```actionscript
//AS3
//配置callback
JSCommunicator.getInstance().add(this, {"swfIsReady": "swfIsReady"});
JSCommunicator.getInstance().add(this, {"abc": "booo"}, {"booo": "booo"});
JSCommunicator.getInstance().add(this, [{"setInfo": "info"}, {"info": "info"}]);

//{"swfIsReady": "swfIsReady"}
public function swfIsReady():Boolean
{
	return true;
}

//{"abc": "booo"}, {"booo": "booo"}
public function booo():void
{
	trace("AS  BOOOOOOOOOOOOOOOOOOO");	
	//抛出事件，模拟AS3事件
	JSCommunicator.getInstance().dispatcher("one", { "hello":"world" } );
}

//{"setInfo": "info"}, {"info": "info"}
public function info(a:int, b:int, c:int):void
{
	trace("AS  Infoooooooooo: ", a, b, c);
	//抛出事件，模拟AS3事件
	JSCommunicator.getInstance().dispatcher("two", {"world": "hello"}, "hello-world");
}
```

###Javascript
```javascript
var swf;
var interval = setInterval(checkSwfReady, 50);

//首先检查swf是否存在
function checkSwfReady(){
	console.log("checking!!!");
	swf = document.getElementById("TestJsCommunicate");
	if (!swf || !swf.notify) return;
	
	var isReady = swf.notify("swfIsReady");
	console.log("Is this swf ready? " + (isReady?"yes":"false"));
	if (isReady) {
		if(interval>0)clearInterval(interval);
		//此时SWF已经READY，可以交互了
		//js 注册事件监听
		swf.addEventListener("one", "oneHlr");
		swf.addEventListener("two", "twoHlr");
		//js call as
		swf.notify("abc");
		swf.notify("booo");
		swf.notify("setInfo", [3, 5, 6]);
		swf.notify("info", [9, 5, 6]);
	}
}

function oneHlr(a){
	swf.removeEventListener("one", "oneHlr");
	console.log("js oneHlr", a);
}

function twoHlr(b, c){
	console.log("js twoHlr", b, c);
}
```

## Preview 预览
trace输出  
![](https://raw.githubusercontent.com/ascollection/js-communicate/master/bin/preview/trace.jpg)  
浏览器控制台输出  
![](https://raw.githubusercontent.com/ascollection/js-communicate/master/bin/preview/console.jpg)  

