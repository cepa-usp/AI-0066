package {
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	
	public class ExtendedMovieClip extends MovieClip implements IEventDispatcher {
		
		private var _maskFocus:Boolean;
		private var maskFocusEnabled:Boolean;
		
		/**
		 * Cria um MovieClip com a função extra de apresentar o filme de trás para frente (método <source>reversePlay</source>).
		 */
		public function ExtendedMovieClip () : void {
			maskFocus = false;
		}
		
		/**
		 * Apresenta o filme de trás para frente
		 */
		public function reversePlay () : void {
			addEventListener(Event.ENTER_FRAME, onEnterFrameEvent);
		}
		
		/**
		 * Pára o filme em execução.
		 */
		/*
		 * Foi necessário sobrescrever o método original para remover o observador de eventos responsável por apresentar o filme de trás para frente.
		 */
		override public function stop () : void {
			super.stop();
			removeEventListener(Event.ENTER_FRAME, onEnterFrameEvent);
		}
		
		/*
		 * Posiciona o cursor no frame anterior (ou no último, se o atual for o primeiro)
		 */
		private function onEnterFrameEvent (event:Event) : void {
			if (currentFrame > 1) gotoAndStop(currentFrame - 1);
			else gotoAndStop(totalFrames)
		}
		
		public function set maskFocus (focus:Boolean) : void {
			_maskFocus = focus;
			maskFocusEnabled = _maskFocus && mask != null;
			
			if (maskFocusEnabled) {
				this.x = super.x;
				this.y = super.y;
				this.width = super.width;
				this.height = super.height;
			}
		}
		
		public function get maskFocus () : Boolean {
			return _maskFocus;
		}
		
		override public function set mask (mask:DisplayObject) : void {
			super.mask = mask;
			maskFocusEnabled = _maskFocus && mask != null;
			
			if (maskFocusEnabled) {
				this.x = super.x;
				this.y = super.y;
				this.width = super.width;
				this.height = super.height;
			}
		}
		
		override public function set x (x:Number) : void {
			super.x = x - (maskFocusEnabled ? (mask.getBounds(this).x + mask.getBounds(this).width / 2) * scaleX : 0);
		}
		
		override public function get x () : Number {			
			return super.x + (maskFocusEnabled ? (mask.getBounds(this).x + mask.getBounds(this).width / 2) * scaleX : 0);
		}
		
		override public function set y (y:Number) : void {
			super.y = y - (maskFocusEnabled ? (mask.getBounds(this).y + mask.getBounds(this).height / 2) * scaleY : 0);
		}
		
		override public function get y () : Number {
			return super.y + (maskFocusEnabled ? (mask.getBounds(this).y + mask.getBounds(this).height / 2) * scaleY : 0);
		}
		
		override public function set width (width:Number) : void {
			if (maskFocusEnabled) {
				var tmp:Number = this.x;
				scaleX = width / mask.getBounds(this).width;
				this.x = tmp;
			}
			else {
				super.width = width;
			}
		}
		
		override public function get width () : Number {
			return (maskFocusEnabled ? mask.getBounds(this).width * scaleX : super.width);
		}
		
		override public function set height (height:Number) : void {
			if (maskFocusEnabled) {
				var tmp:Number = this.y;
				super.scaleY = height / mask.getBounds(this).height;
				this.y = tmp;
			}
			else {
				super.height = height;
			}
		}
		
		override public function get height () : Number {
			return (maskFocusEnabled ? mask.getBounds(this).height * scaleY : super.height);
		}
	}
}