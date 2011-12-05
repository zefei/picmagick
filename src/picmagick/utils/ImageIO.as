package picmagick.utils {
	import cmodule.as3_jpeg_wrapper.CLibInit;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.utils.*;
	
	// utility class to load/save image (JPEG/PNG) files
	public class ImageIO {
		public static var as3_jpeg_wrapper:Object = (new CLibInit).init(); // JPEG encoder, imported from as3_jpeg_wrapper.swc
		
		private var _imageLoaded:Function; // callback function after image is loaded, takes one parameter BitmapData
		private var _imageSaved:Function; // callback function after image is saved, takes no parameters
		private var _ioError:Function; // callback function after io error occurs, takes no parameter
		private var _imageDimLimit:int = 2048; // image dimension limit, default to 2048 x 2048
		private var _filename:String; // current image filename
		
		public function ImageIO(imageLoaded:Function, imageSaved:Function, ioError:Function) {
			_imageLoaded = imageLoaded;
			_imageSaved = imageSaved;
			_ioError = ioError;
		}
		
		// set image dimension limit (dim x dim), default to 2048 x 2048
		public function set imageDimLimit(dim:int):void {
			_imageDimLimit = dim;
		}
		
		// load image, _imageLoaded(BitmapData) will be called after completion
		public function loadImage():void {
			var fileRef:FileReference = new FileReference()
			var fileTypes:FileFilter = new FileFilter("Photo File (*.jpg, *.jpeg, *.png)", "*.jpg; *.jpeg; *.png;");
			fileRef.addEventListener(Event.SELECT, function (event:Event):void { fileRef.load(); });
			fileRef.addEventListener(Event.COMPLETE, fileLoaded);
			fileRef.addEventListener(IOErrorEvent.IO_ERROR, function (event:Event):void { _ioError(); });
			fileRef.browse([fileTypes]);
		}
		
		// save image from BitmapData, _imageSaved() will be called after completion
		public function saveImage(bitmapData:BitmapData):void {
			var bytes:ByteArray = as3_jpeg_wrapper.write_jpeg_file(bitmapData.getPixels(new Rectangle(0, 0, bitmapData.width, bitmapData.height)), 
				bitmapData.width, bitmapData.height, 3, 2, 90);	
			var fileRef:FileReference = new FileReference();
			fileRef.addEventListener(Event.COMPLETE, fileSaved);
			fileRef.save(bytes, _filename);
		}
		
		// (event handler) file is selected
		private function fileLoaded(event:Event):void {
			var fileRef:FileReference = event.target as FileReference;
			_filename = rename(fileRef.name);
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function (event:Event):void { _ioError(); });
			loader.loadBytes(fileRef.data)
		}
		
		// (event handler) file is loaded
		private function imageLoaded(event:Event):void {
			var loaderInfo:LoaderInfo = event.target as LoaderInfo;
			var bitmapData:BitmapData = (loaderInfo.content as Bitmap).bitmapData;
			_imageLoaded(resize(bitmapData, _imageDimLimit));
		}
		
		// (event handler) file is saved
		private function fileSaved(event:Event):void {
			var fileRef:FileReference = event.target as FileReference;
			_filename = rename(fileRef.name);
			_imageSaved()
		}
		
		// reduce image size to dim x dim, keeping aspect
		private function resize(input:BitmapData, dim:int):BitmapData {
			var w:int;
			var h:int;
			if (input.width > input.height) {
				if (input.width > dim) {
					w = dim;
					h = dim / input.width * input.height;
				} else {
					w = input.width;
					h = input.height;
				}
			} else {
				if (input.height > dim) {
					w = dim / input.height * input.width;
					h = dim;
				} else {
					w = input.width;
					h = input.height;
				}
			}
			
			var ret:BitmapData = new BitmapData(w, h);
			var s:Number = w / input.width;
			var matrix:Matrix = new Matrix();
			matrix.scale(s, s);
			ret.draw(input, matrix);
			return ret;
		}
		
		// rename filename to *.jpg
		private function rename(filename:String):String {
			var ret:String = filename.replace(/\.(jpg|jpeg|png)$/i, ".jpg");
			if (!ret.match(/\.jpg$/)) ret = ret + ".jpg";
			return ret;
		}
	}
}