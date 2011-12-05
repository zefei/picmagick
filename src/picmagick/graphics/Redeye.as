package picmagick.graphics
{
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	import flash.geom.*;

	// utility class to fix red eye
	public class Redeye
	{
		private static const MIN_RED_VAL:int = 40;
		
		private static var region:Rectangle;
		private static var regionOfInterest:Array;
		private static var spreadablePixels:Array;
		private static var blobPixelCount:int;
		private static var blobTopLeft:Point;
		private static var blobBottomRight:Point;
		private static var maxSize:int;
		private static var blobID:int;
		private static var blob:Rectangle;
		
		// fixing ONE red eye within Rectangle
		public static function fix(bmd:BitmapData, rect:Rectangle):void {
			var bytes:ByteArray = bmd.getPixels(rect);
			var pixels:PixelArray = new PixelArray(bytes, rect.width, rect.height);
			
			findRegionOfInterest(pixels);
			if (region) {
				region.x += rect.x;
				region.y += rect.y;
			}
			else return;
			
			var bytesp:ByteArray = bmd.getPixels(region);
			var pixelsp:PixelArray = new PixelArray(bytesp, region.width, region.height);
			findBlobs(pixelsp);
			
			region.x -= rect.x;
			region.y -= rect.y;
			if (blobID != -1) {
				blob.x += region.x;
				blob.y += region.y;
				desaturateBlob(pixels);
			}
			else desaturateAll(pixels);
			bytes.position = 0;
			bmd.setPixels(rect, bytes);
		}
		
		private static function findRegionOfInterest(pixels:PixelArray):void {
			var topLeft:Point = new Point(-1, -1);
			var bottomRight:Point = new Point(-1, -1);
			
			for (var y:int = 0; y < pixels.height; y++) {
				for (var x:int = 0; x < pixels.width; x++) {
					if (pixels.r(x,y) > 2 * pixels.g(x,y) && pixels.r(x,y) > MIN_RED_VAL) {
						if (topLeft.x == -1) {
							topLeft.x = bottomRight.x = x;
							topLeft.y = bottomRight.y = y;
						}
						
						if (x < topLeft.x) topLeft.x = x;
						if (y < topLeft.y) topLeft.x = y;
						if (x > bottomRight.x) bottomRight.x = x;
						if (y > bottomRight.y) bottomRight.y = y;
					}
				}
			}
			
			if (topLeft.x == -1) region = null;
			else region = new Rectangle(topLeft.x, topLeft.y, bottomRight.x - topLeft.x + 1, bottomRight.y - topLeft.y + 1); 
		}
		
		private static function pushPixel(x:int, y:int, id:int):void {
			if (x < 0 || y < 0 || x >= region.width || y >= region.height || regionOfInterest[y * region.width + x] != 1) return;
			regionOfInterest[y * region.width + x] = id;
			spreadablePixels.push(new Point(x, y));
			blobPixelCount++;
			if (x < blobTopLeft.x) blobTopLeft.x = x;
			if (y < blobTopLeft.y) blobTopLeft.y = y;
			if (x > blobBottomRight.x) blobBottomRight.x = x;
			if (y > blobBottomRight.y) blobBottomRight.y = y;
		}
		
		private static function updateBlob(id:int):void {
			var size:int = blobPixelCount;
			var ratio:Number = (blobBottomRight.x - blobTopLeft.x + 1) / (blobBottomRight.y - blobTopLeft.y + 1);
			if (ratio > 0.75 && ratio < 2 && size > 10 && size > maxSize) {
				maxSize = size
				blobID = id;
				blob = new Rectangle(blobTopLeft.x, blobTopLeft.y, blobBottomRight.x - blobTopLeft.x + 1, blobBottomRight.y - blobTopLeft.y + 1);
			}
		}
		
		private static function findBlobs(pixels:PixelArray):void {
			var w:int = pixels.width;
			var h:int = pixels.height;
			var x:int, y:int, i:int, j:int;
			
			regionOfInterest = new Array(w * h);
			spreadablePixels = [];
			maxSize = 0;
			blobID = -1;
			blob = null;
			
			for (y = 0; y < h; y++) {
				for (x = 0; x < w; x++) {
					if (pixels.r(x,y) > 2 * pixels.g(x,y) && pixels.r(x,y) > MIN_RED_VAL) regionOfInterest[y * w + x] = 1;
					else regionOfInterest[y * w + x] = 0;
				}
			}
			
			var nextValidID:int = 2;
			for (y = 0; y < h; y++) {
				for (x = 0; x < w; x++) {
					if (regionOfInterest[y * w + x] != 1) continue;
					blobPixelCount = 1;
					blobTopLeft = new Point(x, y);
					blobBottomRight = new Point(x, y);
					pushPixel(x, y, nextValidID);
					
					while (spreadablePixels.length > 0) {
						var point:Point = spreadablePixels.pop();
						for (i = point.x - 1; i <= point.x + 1; i++)
							for (j = point.y - 1; j <= point.y + 1; j++)
								if (i != point.x || j != point.y) pushPixel(i, j, nextValidID);
					}
					
					updateBlob(nextValidID);
					nextValidID++;
				}
			}
		}
		
		private static function IDedPixel(x:int, y:int):Boolean {
			if (x < region.left || y < region.top || x >= region.right || y >= region.bottom) return false;
			var i:int = (y - region.y) * region.width + (x - region.x);
			return (regionOfInterest[i] == blobID);
		}
		
		private static function desaturateAlpha(x:int, y:int):Number {
			if (IDedPixel(x, y)) return 1;
			
			var n:int = 0;
			for (var i:int = x - 2; i <= x + 2; i++)
				for (var j:int = y - 2; j <= y + 2; j++)
					if (IDedPixel(i, j)) n++;
			return Math.min(n / 10, 1);
		}
		
		private static function desaturateBlob(pixels:PixelArray):void {
			for (var y:int = Math.max(blob.top - 2, 0); y < Math.min(blob.bottom + 2, pixels.height); y++)
				for (var x:int = Math.max(blob.left - 2, 0); x < Math.min(blob.right + 2, pixels.width); x++) {
					var alpha:Number = desaturateAlpha(x, y);
					if (alpha > 0) pixels.sr(x,y, alpha * (0.05 * pixels.r(x,y) + 0.6 * pixels.g(x,y) + 0.3 * pixels.b(x,y)) + (1 - alpha) * pixels.r(x,y));
				}
		}
		
		private static function desaturateAll(pixels:PixelArray):void {
			for (var y:int = 0; y < pixels.height; y++)
				for (var x:int = 0; x < pixels.width; x++)
					if (pixels.r(x,y) > 2 * pixels.g(x,y)) pixels.sr(x,y, 0.05 * pixels.r(x,y) + 0.6 * pixels.g(x,y) + 0.3 * pixels.b(x,y));
		}
	}
}