package picmagick.graphics
{
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	
	public class Blend
	{
		// softlight blend mode
		// applying softlight with image's low-passed, inverted, grayscale version is a naive (fast) way to do local contrast enhancement
		public static function softlight(bmd:BitmapData, lum:BitmapData):void {
			var a:ByteArray = bmd.getPixels(bmd.rect);
			var b:ByteArray = lum.getPixels(lum.rect);
			var c:int;
			var ai:Number, bi:Number;
			
			for (var i:int = 0; i < bmd.width * bmd.height * 4; i++) {
				if (i % 4 == 0) continue;
				c = (a[i] * b[i]) >> 8;
				a[i] = c + ((a[i] * (255 - (((255 - a[i]) * (255 - b[i])) >> 8) - c)) >> 8);
			}
			
			a.position = 0;
			lum.setPixels(lum.rect, a);
		}
	}
}