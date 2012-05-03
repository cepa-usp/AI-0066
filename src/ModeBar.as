package
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	public class ModeBar extends Sprite
	{
		//--------------------------------------------------
		// Membros públicos (interface).
		//--------------------------------------------------
		
		public function ModeBar ()
		{
			_mode = ModeSelector.MODE_EXPLORE;
			buttonMode = true;
			mouseChildren = false;
		}
		
		public function get mode () : String
		{
			return _mode;
		}
		
		//--------------------------------------------------
		// Membros privados.
		//--------------------------------------------------
		
		private var _mode:String;
		
		public function swap (event:MouseEvent = null) : void
		{
			if (_mode == ModeSelector.MODE_EVAL)
			{
				_mode = ModeSelector.MODE_EXPLORE;
				info.text = "Modo de experimentação";
			}
			else if (_mode == ModeSelector.MODE_EXPLORE)
			{
				_mode = ModeSelector.MODE_EVAL;
				info.text = "Modo de avaliação";
			}
		}
	}
}