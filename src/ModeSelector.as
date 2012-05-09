package
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class ModeSelector extends Sprite
	{
		public static const MODE_EVAL:String = "EVAL";
		public static const MODE_EXPLORE:String = "EXPLORE";
		
		private var _mode:String;
		private var lastmode:String;
		
		public function ModeSelector ()
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		override public function set visible (visible:Boolean) : void
		{
			super.visible = visible;
			if (visible) lastmode = _mode;
		}
		
		private function init (event:Event = null) : void
		{
			if (distance(handle, mark1) < distance(handle, mark2)) _mode = lastmode = MODE_EXPLORE;
			else _mode = lastmode = MODE_EVAL;
			
			mark1.visible = false;
			mark2.visible = false;
			sensitiveArea.visible = false;
			
			handle.addEventListener(MouseEvent.MOUSE_DOWN, grabHandle);
			board.addEventListener(MouseEvent.MOUSE_UP, releaseHandle);
			//board.addEventListener(MouseEvent.CLICK, select);
			invMode.addEventListener(MouseEvent.CLICK, selectInv);
			evalMode.addEventListener(MouseEvent.CLICK, selectEval);
			
			invMode.buttonMode = true;
			evalMode.buttonMode = true;
			
			okButton.addEventListener(MouseEvent.CLICK, ok);
			cancelButton.addEventListener(MouseEvent.CLICK, cancel);
		}
		
		public function selectInv(e:MouseEvent):void 
		{
			if(_mode != MODE_EXPLORE){
				_mode = MODE_EXPLORE;
				
				handle.x = mark1.x;
				handle.y = mark1.y;
			}
		}
		
		public function selectEval(e:MouseEvent):void 
		{
			if(_mode != MODE_EVAL){
				_mode = MODE_EVAL;
				
				handle.x = mark2.x;
				handle.y = mark2.y;
			}
		}
		
		private function ok (event:Event) : void
		{
			visible = false;
			if (_mode != lastmode) dispatchEvent(new Event(Event.CHANGE));
		}
		
		private function cancel (event:Event) : void
		{
			visible = false;
			
			_mode = lastmode;
			
			if (lastmode == MODE_EXPLORE)
			{
				handle.x = mark1.x;
				handle.y = mark1.y;
			}
			else
			{	
				handle.x = mark2.x;
				handle.y = mark2.y;
			}
		}
		
		private function grabHandle (event:MouseEvent) : void 
		{
			stage.addEventListener(MouseEvent.MOUSE_MOVE, select);
		}
		
		private function select (event:MouseEvent) : void 
		{
			var mouse:Point = new Point(mouseX, mouseY);
			//lastmode = _mode;
			
			if (sensitiveArea.getBounds(this).containsPoint(mouse))
			{	
				if (Point.distance(mouse, new Point(mark1.x, mark1.y)) < Point.distance(mouse, new Point(mark2.x, mark2.y)))
				{
					_mode = MODE_EXPLORE;
					
					handle.x = mark1.x;
					handle.y = mark1.y;
				}
				else
				{
					_mode = MODE_EVAL;
					
					handle.x = mark2.x;
					handle.y = mark2.y;
				}
			}
		}
		
		private function releaseHandle (event:Event) : void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, select);
		}
		
		private function distance (obj1:DisplayObject, obj2:DisplayObject) : Number
		{
			return Math.sqrt(Math.pow(obj2.x - obj1.x, 2) + Math.pow(obj2.y - obj1.y, 2));
		}
	}
}