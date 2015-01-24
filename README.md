# js-communicate
AS-JS的交互通讯模块，提供了JS中模拟AS3事件监听处理方式用于取代AS直接调页面接口。  
使用该库将为SWF提供三个接口给JS来调用：  
1、notify，用于JS调AS中的接口  
2、addEventListener，用于模拟事件监听  
3、removeEventListener，用于模拟事件监听  

## Usage 使用
###Actionscript 3
```actionscript
//AS3
//配置callback
JSCommunicator.getInstance().add(this, {"swfIsReady": "swfIsReady"});
JSCommunicator.getInstance().add(this, [{"abc": "booo"}, {"booo": "booo"}]);
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
	console.log("this swf is ready? " + (isReady?"yes":"false"));
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

