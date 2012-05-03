package
{
	import flash.display.Sprite;
	
	public class Gun extends Sprite
	{
		public function Gun ()
		{
			
		}
		
		public function set aim (active:Boolean) : void
		{
			laser.visible = active;
		}
	}
}