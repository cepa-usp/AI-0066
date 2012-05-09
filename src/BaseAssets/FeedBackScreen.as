package BaseAssets
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	/**
	 * ...
	 * @author Alexandre
	 */
	public class FeedBackScreen extends MovieClip
	{
		public var okCancelMode:Boolean = false;
		
		public function FeedBackScreen() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			this.x = stage.stageWidth / 2;
			this.y = stage.stageHeight / 2;
			
			//this.closeButton.addEventListener(MouseEvent.CLICK, closeScreen);
			//stage.addEventListener(KeyboardEvent.KEY_UP, escCloseScreen);
			
			this.gotoAndStop("END");
		}
		
		private function escCloseScreen(e:KeyboardEvent):void 
		{
			if (e.keyCode ==  Keyboard.ESCAPE) {
				if (this.currentFrame == 1) closeScreen(null);
			}
		}
		
		private function closeScreen(e:MouseEvent):void 
		{
			this.play();
			dispatchEvent(new Event(Event.CLOSE, true));
		}
		
		private function closeScreenOK(e:MouseEvent):void 
		{
			this.play();
			dispatchEvent(new Event("OK", true));
		}
		
		private function openScreen():void
		{
			this.gotoAndStop("BEGIN");
			
			if (okCancelMode) {
				closeButton.x = -125;
				cancelButton.x = 125;
				cancelButton.visible = true;
				closeButton.visible = true;
				
				cancelButton.addEventListener(MouseEvent.CLICK, closeScreen, false, 0, true);
				closeButton.addEventListener(MouseEvent.CLICK, closeScreenOK, false, 0, true);
			}else {
				closeButton.x = 0;
				cancelButton.visible = false;
				closeButton.visible = true;
				closeButton.addEventListener(MouseEvent.CLICK, closeScreen, false, 0, true);
			}
		}
		
		public function setText(texto:String):void
		{
			openScreen();
			this.texto.text = texto;
		}
		
	}

}