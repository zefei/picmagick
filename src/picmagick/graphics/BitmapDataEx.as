package picmagick.graphics
{
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.filters.*;
	import flash.geom.*;

	// utility class to call image editing functions
	public class BitmapDataEx
	{
		private const BEZIER_STEP:int = 10; // sampling rate for bezier curves
		
		private var bmd:BitmapData; // bitmapData instance
		private var tempBmd:BitmapData; // temporary variable
		private var highBmd:BitmapData; // temporary variable
		private var lowBmd:BitmapData; // temporary variable
		
		// constructor from existing BitmapData, either referencing or cloning the BitmapData instance
		public function BitmapDataEx(bitmap_data:BitmapData, clone:Boolean = false)
		{
			if (clone) bmd = bitmap_data.clone();
			else bmd = bitmap_data;
		}
		
		// set (reference) BitmapData
		public function set bitmapData(bitmap_data:BitmapData):void {
			bmd = bitmap_data;
		}
		
		// get BitmapData
		public function get bitmapData():BitmapData {
			return bmd;
		}
		
		// cropping to Rectangle
		public function crop(rect:Rectangle):BitmapData {
			var retBmd:BitmapData = new BitmapData(rect.width, rect.height);
			retBmd.copyPixels(bmd, rect, new Point(0, 0));
			return retBmd;
		}
		
		// rotating in radians
		public function rotate(angle:Number):BitmapData {
			var a:Number = Math.max(bmd.width, bmd.height);
			var b:Number = Math.min(bmd.width, bmd.height);
			var ratio:Number = b / Math.cos(Math.atan(a / b) - Math.abs(angle) * Math.PI / 180) / Math.sqrt(a * a + b * b);
			var matrix:Matrix = new Matrix();
			var retBmd:BitmapData;
			if (Math.abs(angle) <= 45) retBmd = new BitmapData(Math.round(bmd.width * ratio), Math.round(bmd.height * ratio));
			else retBmd = new BitmapData(bmd.height, bmd.width);
			matrix.translate(-(bmd.width / 2.0), -(bmd.height / 2.0));
			matrix.rotate(angle * Math.PI / 180);
			matrix.translate(retBmd.width / 2.0, retBmd.height / 2.0);
			retBmd.draw(bmd, matrix, null, null, null, true);
			return retBmd;
		}
		
		// fixing ONE red eye within Rectangle
		public function redeye(rect:Rectangle):BitmapData {
			var retBmd:BitmapData = bmd.clone();
			Redeye.fix(retBmd, rect);
			return retBmd;
		}
		
		// smoothing by an approximated Gaussian kernal
		public function smooth(radius:Number):BitmapData {
			var coarseBlur:BlurFilter = new BlurFilter(radius * 3, radius * 3, 3);
			var fineBlur:BlurFilter = new BlurFilter(radius, radius, 3);
			
			tempBmd = new BitmapData(bmd.width, bmd.height);
			tempBmd.applyFilter(bmd, bmd.rect, new Point(0, 0), coarseBlur);
			lowBmd = new BitmapData(bmd.width, bmd.height);
			lowBmd.applyFilter(bmd, bmd.rect, new Point(0, 0), fineBlur);
			
			highBmd = tempBmd.clone();
			highBmd.draw(lowBmd, null, null, BlendMode.SUBTRACT);
			lowBmd.draw(tempBmd, null, null, BlendMode.SUBTRACT);
			
			var retBmd:BitmapData = bmd.clone();
			var colorTransform:ColorTransform = new ColorTransform(2, 2, 2);
			retBmd.draw(highBmd, null, colorTransform, BlendMode.ADD);
			retBmd.draw(lowBmd, null, colorTransform, BlendMode.SUBTRACT);
			return retBmd;
		}
		
		// fast color mapping by a set of coefficients for each color (mainly used for contrast adjustment)
		public function scaleColor(scaleR:Number, scaleG:Number, scaleB:Number):BitmapData {
			var retBmd:BitmapData = new BitmapData(bmd.width, bmd.height);
			var redArray:Array = new Array(256);
			var greenArray:Array = new Array(256);
			var blueArray:Array = new Array(256);
			var i:int, t:int;
			
			for (i = 0; i < 256; i++) {
				t = Math.round(Math.min(i * scaleR, 255));
				redArray[i] = t << 16;
				
				t = Math.round(Math.min(i * scaleG, 255));
				greenArray[i] = t << 8;
				
				t = Math.round(Math.min(i * scaleB, 255));
				blueArray[i] = t;
			}
			
			retBmd.paletteMap(bmd, bmd.rect, new Point(0, 0), redArray, greenArray, blueArray);
			return retBmd;
		}
		
		// preparing color enhancement
		public function preEnhance():void {
			tempBmd = new BitmapData(bmd.width, bmd.height);
			var blurFilter:BlurFilter = new BlurFilter(4, 4, 3);
			tempBmd.applyFilter(bmd, bmd.rect, new Point(0, 0), blurFilter);
			
			var matrix:Array = [-0.299, -0.587, -0.114, 0, 255, -0.299, -0.587, -0.114, 0, 255, -0.299, -0.587, -0.114, 0, 255, 0, 0, 0, 1, 0];
			var luminanceFilter:ColorMatrixFilter = new ColorMatrixFilter(matrix);
			tempBmd.applyFilter(tempBmd, tempBmd.rect, new Point(0, 0), luminanceFilter);
			
			Blend.softlight(bmd, tempBmd);
			
			highBmd = tempBmd.clone();
			highBmd.draw(bmd, null, null, BlendMode.SUBTRACT);
			
			lowBmd = bmd.clone();
			lowBmd.draw(tempBmd, null, null, BlendMode.SUBTRACT);
		}
		
		// color enhancement by (shadow removal, highlight removal, brightness, contrast)
		public function enhance(s:Number, h:Number, b:Number, c:Number):BitmapData {
			s = s / 50;
			h = h / 50;
			b /= 100;
			c /= 100;
			
			var shadowColorTransform:ColorTransform = new ColorTransform(s, s, s);
			var highlightColorTransform:ColorTransform = new ColorTransform(h, h, h);
			var retBmd:BitmapData = bmd.clone();
			retBmd.draw(highBmd, null, shadowColorTransform, BlendMode.ADD);
			retBmd.draw(lowBmd, null, highlightColorTransform, BlendMode.SUBTRACT);
			
			var contrastArray:Array = new Array(256);
			var redArray:Array = new Array(256);
			var greenArray:Array = new Array(256);
			var blueArray:Array = new Array(256);
			var i:Number, j:int, x:int, y:int, x0:int, y0:int;
			
			contrastArray[0] = x0 = y0 = 0;
			for (i = 1 / BEZIER_STEP; i <= 1; i += 1 / BEZIER_STEP) {
				x = Math.round((1.5 * i * (1 - i) * (1 - i) * (1 + c) + 1.5 * i * i * (1 - i) * (1 - c) + i * i * i) * 255);
				y = Math.round((1.5 * i * (1 - i) * (1 - i) * (1 - c) + 1.5 * i * i * (1 - i) * (1 + c) + i * i * i) * 255);
				if (x == x0) continue;
				for (j = x0 + 1; j <= x; j++) contrastArray[j] = Math.round((y - y0) * (j - x0) / (x - x0) + y0);
				x0 = x;
				y0 = y;
			}
			
			redArray[0] = greenArray[0] = blueArray[0] = x0 = y0 = 0;
			for (i = 1 / BEZIER_STEP; i <= 1; i += 1 / BEZIER_STEP) {
				x = Math.round((i * (1 - i) * (1 - b) + i * i) * 255);
				y = Math.round((i * (1 - i) * (1 + b) + i * i) * 255);
				if (x == x0) continue;
				for (j = x0 + 1; j <= x; j++) {
					blueArray[j] = contrastArray[Math.round((y - y0) * (j - x0) / (x - x0) + y0)]; 
					greenArray[j] = blueArray[j] << 8;
					redArray[j] = blueArray[j] << 16;
				}
				x0 = x;
				y0 = y;
			}
			
			retBmd.paletteMap(retBmd, retBmd.rect, new Point(0, 0), redArray, greenArray, blueArray);
			return retBmd;
		}
		
		// preparing for sharpening
		public function preSharpen():void {
			tempBmd = new BitmapData(bmd.width, bmd.height);
			var blurFilter:BlurFilter = new BlurFilter(4, 4, 3);
			tempBmd.applyFilter(bmd, bmd.rect, new Point(0, 0), blurFilter);
			
			highBmd = bmd.clone();
			highBmd.draw(tempBmd, null, null, BlendMode.SUBTRACT);
			
			lowBmd = tempBmd.clone();
			lowBmd.draw(bmd, null, null, BlendMode.SUBTRACT);
		}
		
		// sharpening by (strength)
		public function sharpen(s:Number):BitmapData {
			s = s / 20 + 1;
			var colorTransform:ColorTransform = new ColorTransform(s, s, s);
			var retBmd:BitmapData = tempBmd.clone();
			retBmd.draw(highBmd, null, colorTransform, BlendMode.ADD);
			retBmd.draw(lowBmd, null, colorTransform, BlendMode.SUBTRACT);
			return retBmd;
		}
		
		// softening by (strength, blur radius)
		public function soften(s:Number, r:Number):BitmapData {
			s *= 2.56;
			var blurFilter:BlurFilter = new BlurFilter(r, r, 3);
			var retBmd:BitmapData = new BitmapData(bmd.width, bmd.height);
			retBmd.applyFilter(bmd, bmd.rect, new Point(0, 0), blurFilter);
			retBmd.merge(bmd, bmd.rect, new Point(0, 0), 256 - s, 256 - s, 256 - s, 0);
			return retBmd;
		}

		// applying sepia tone
		public function sepia():BitmapData {
			var matrix:Array = [0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0];
			var sepiaFilter:ColorMatrixFilter = new ColorMatrixFilter(matrix);
			var retBmd:BitmapData = new BitmapData(bmd.width, bmd.height);
			retBmd.applyFilter(bmd, bmd.rect, new Point(0, 0), sepiaFilter);
			return retBmd;
		}
		
		// applying graw scale tone
		public function grayscale():BitmapData {
			var matrix:Array = [0.299, 0.587, 0.114, 0, 0, 0.299, 0.587, 0.114, 0, 0, 0.299, 0.587, 0.114, 0, 0, 0, 0, 0, 1, 0];
			var grayscaleFilter:ColorMatrixFilter = new ColorMatrixFilter(matrix);
			var retBmd:BitmapData = new BitmapData(bmd.width, bmd.height);
			retBmd.applyFilter(bmd, bmd.rect, new Point(0, 0), grayscaleFilter);
			return retBmd;
		}
		
		// glowing by (intensity, blur radius)
		public function glow(i:Number, r:Number):BitmapData {
			i *= 2.56;
			var blurFilter:BlurFilter = new BlurFilter(r, r, 3);
			var retBmd:BitmapData = new BitmapData(bmd.width, bmd.height);
			retBmd.applyFilter(bmd, bmd.rect, new Point(0, 0), blurFilter);
			retBmd.draw(bmd, null, null, BlendMode.LIGHTEN);
			retBmd.merge(bmd, bmd.rect, new Point(0, 0), 256 - i, 256 - i, 256 - i, 0);
			return retBmd;
		}
	}
}