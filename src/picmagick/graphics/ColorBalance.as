package picmagick.graphics
{
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	
	// white balance utility
	public class ColorBalance
	{
		private static const CLIPPING:Number = 0.001; // clipping range for shadow and highlight
		
		// (color temperature, green component) to sRGB
		public static function t2rgb(temperature:Number, green:Number):Array {
			var xD:Number, yD:Number;
			
			if (temperature > 12000) temperature = 12000;
			if (temperature <= 4000) xD = 0.27475e9/(temperature*temperature*temperature) - 0.98598e6/(temperature*temperature) + 1.17444e3/temperature + 0.145986;
			else if (temperature <= 7000) xD = -4.6070e9/(temperature*temperature*temperature) + 2.9678e6/(temperature*temperature) + 0.09911e3/temperature + 0.244063;
			else xD = -2.0064e9/(temperature*temperature*temperature) + 1.9018e6/(temperature*temperature) + 0.24748e3/temperature + 0.237040;
			yD = -3 * xD * xD + 2.87 * xD - 0.275;
			
			var x:Number = xD / yD;
			var y:Number = 1;
			var z:Number = (1 - xD - yD) / yD;
			var r:Number = 3.24071 * x - 1.53726 * y - 0.498571 * z;
			var g:Number = -0.969258 * x + 1.87599 * y + 0.0415557 * z;
			var b:Number = 0.0556352 * x - 0.203996 * y + 1.05707 * z;
			
			g = g / (green + 0.000001);
			var l:Number = 0.299 * r + 0.587 * g + 0.114 * b;
			r /= l;
			g /= l;
			b /= l;
			
			return [r, g, b];
		}
		
		// sRGB to [color temperature, green component]
		public static function rgb2t(r:Number, g:Number, b:Number):Array {
			var temperature:Number;
			var green:Number = 1;
			var tmin:Number = 2000;
			var tmax:Number = 12000;
			var br:Number = b / r;
			var rgb:Array;
			
			for (temperature = (tmin + tmax) / 2; tmax - tmin > 10; temperature = (tmin + tmax) / 2) {
				rgb = t2rgb(temperature, green);
				if (rgb[2] / rgb[0] > br) tmax = temperature;
				else tmin = temperature;
			}
			
			green = (rgb[1] / rgb[0]) / (g / r);
			return [temperature, green];
		}
		
		// hex to RGB
		public static function int2rgb(color:int):Array {
			var r:int = color >> 16;
			var g:int = (color & 0x00FF00) >> 8;
			var b:int = color & 0x0000FF;
			return [r, g, b];
		}
		
		// RGB to hex
		public static function rgb2int(r:int, g:int, b:int):int {
			return (r << 16) + (g << 8) + b;
		}
		
		// finding white point by averaging highlights (with clipping pre-applied)
		public static function whitePoint(bmd:BitmapData):Array {
			var bytes:ByteArray = bmd.getPixels(bmd.rect);
			var clipping:int = bmd.width * bmd.height * CLIPPING;
			var luma:Array = new Array(256);
			var lumaWhite:int, rWhite:Number, gWhite:Number, bWhite:Number;
			var i:int, t:int, count:int;
			
			for (i = 0; i < 256; i++) luma[i] = 0;
			for (i = 0; i < bmd.width * bmd.height * 4; i += 4) {
				bytes[i] = Math.round(0.299 * bytes[i + 1] + 0.587 * bytes[i + 2] + 0.114 * bytes[i + 3]);
				luma[bytes[i]]++;
			}
			
			t = 0;
			for (i = 255; i >= 0; i--) {
				if (t + luma[i] > clipping) {
					lumaWhite = i;
					break;
				}
				else t += luma[i];
			}
			
			count = 0;
			rWhite = 0;
			gWhite = 0;
			bWhite = 0;
			for (i = 0; i < bmd.width * bmd.height * 4; i += 4) {
				if (bytes[i] == lumaWhite) {
					count++;
					rWhite += bytes[i + 1];
					gWhite += bytes[i + 2];
					bWhite += bytes[i + 3];
				}
			}
			
			rWhite /= count;
			gWhite /= count;
			bWhite /= count;
			return [rWhite, gWhite, bWhite];
		}
	}
}