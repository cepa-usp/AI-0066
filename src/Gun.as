package
{
	import flash.display.MovieClip;
	
	public class Gun extends MovieClip
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