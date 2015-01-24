package
{
	import com.asc.jsCommunicate.JSCommunicator;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.Security;
	
	public class TestJsCommunicate extends Sprite
	{
		
		public function TestJsCommunicate():void
		{
			Security.allowDomain("*");
			Security.allowInsecureDomain("*");
			
			if (stage)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			JSCommunicator.getInstance().add(this, {"swfIsReady": "swfIsReady"});
			JSCommunicator.getInstance().add(this, {"abc": "booo"}, {"booo": "booo"});
			JSCommunicator.getInstance().add(this, [{"setInfo": "info"}, {"info": "info"}]);
		}
		
		public function swfIsReady():Boolean
		{
			return true;
		}
		
		public function booo():void
		{
			trace("AS  BOOOOOOOOOOOOOOOOOOO");
			
			JSCommunicator.getInstance().dispatcher("one", {"hello": "world"});
		}
		
		public function info(a:int, b:int, c:int):void
		{
			trace("AS  Infoooooooooo: ", a, b, c);
			
			JSCommunicator.getInstance().dispatcher("two", {"world": "hello"}, "hello-world");
		}
	}

}