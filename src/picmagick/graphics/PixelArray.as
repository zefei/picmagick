package picmagick.graphics
{
	import flash.utils.ByteArray;
	
	// utility class to access pixel info in BitmapData.getPixels()
	public class PixelArray
	{
		private var _bytes:ByteArray; // reference to ByteArray returned from BitmapData.getPixels()
		private var _width:int; // BitmapData width
		private var _height:int; // BitmapData height
		
		public function PixelArray(bytes:ByteArray, width:int, height:int)
		{
			_bytes = bytes;
			_width = width;
			_height = height;
		}
		
		// reference to ByteArray returned from BitmapData.getPixels()
		public function get bytes():ByteArray {
			return _bytes;
		}
		
		// BitmapData width
		public function get width():int {
			return _width;
		}
		
		// BitmapData height
		public function get height():int {
			return _height;
		}
		
		// get Alpha value at (x, y)
		public function a(x:int, y:int):int {
			return _bytes[(y * _width + x) * 4];
		}
		
		// get Red value at (x, y)
		public function r(x:int, y:int):int {
			return _bytes[(y * _width + x) * 4 + 1];
		}
		
		// get Green value at (x, y)
		public function g(x:int, y:int):int {
			return _bytes[(y * _width + x) * 4 + 2];
		}
		
		// get Blue value at (x, y)
		public function b(x:int, y:int):int {
			return _bytes[(y * _width + x) * 4 + 3];
		}
		
		// set Alpha value at (x, y)
		public function sa(x:int, y:int, value:int):void {
			_bytes[(y * _width + x) * 4] = value;
		}
		
		// set Red value at (x, y)
		public function sr(x:int, y:int, value:int):void {
			_bytes[(y * _width + x) * 4 + 1] = value;
		}
		
		// set Green value at (x, y)
		public function sg(x:int, y:int, value:int):void {
			_bytes[(y * _width + x) * 4 + 2] = value;
		}
		
		// set Blue value at (x, y)
		public function sb(x:int, y:int, value:int):void {
			_bytes[(y * _width + x) * 4 + 3] = value;
		}
	}
}