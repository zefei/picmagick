package picmagick.display {
	
	import flash.display.Bitmap;
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.ui.Mouse;
	
	// simple cursor manager to show normal, hand, move, resize, color picker, brush cursors
	public class CursorManager {
		private static var _cursor:Sprite;
		private static var _currentCursor:String;
		private static var _brushSize:Number;
		
		[Embed(source="images/hand.png")]
		private static var HandCursor:Class;
		
		[Embed(source="images/move.png")]
		private static var MoveCursor:Class;
		
		[Embed(source="images/resize_ew.png")]
		private static var ResizeEWCursor:Class;
		
		[Embed(source="images/resize_nesw.png")]
		private static var ResizeNESWCursor:Class;
		
		[Embed(source="images/resize_ns.png")]
		private static var ResizeNSCursor:Class;
		
		[Embed(source="images/resize_nwse.png")]
		private static var ResizeNWSECursor:Class;
		
		[Embed(source="images/color_picker.png")]
		private static var ColorPickerCursor:Class;
		
		public static function init(stage:Stage):void {
			_cursor = new Sprite();
			_cursor.mouseEnabled = false;
			_cursor.visible = false;
			_currentCursor = CursorType.NULL;
			stage.addChild(_cursor);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove, true);
		}
		
		// get current cursor type
		public static function get cursor():String {
			return _currentCursor;
		}
		
		// set current cursor type
		public static function set cursor(c:String):void {
			if (c == _currentCursor) return;
			if (c == CursorType.NULL) {
				Mouse.show();
				_cursor.visible = false;
			} else {
				_cursor.blendMode = BlendMode.NORMAL;
				switch (c) {
					case CursorType.HAND: drawCursor(HandCursor, -8, -8); break;
					case CursorType.MOVE: drawCursor(MoveCursor, -15, -15); break;
					case CursorType.RESIZE_EW: drawCursor(ResizeEWCursor, -15, -15); break;
					case CursorType.RESIZE_NESW: drawCursor(ResizeNESWCursor, -15, -15); break;
					case CursorType.RESIZE_NS: drawCursor(ResizeNSCursor, -15, -15); break;
					case CursorType.RESIZE_NWSE: drawCursor(ResizeNWSECursor, -15, -15); break;
					case CursorType.COLOR_PICKER: drawCursor(ColorPickerCursor, -1, -17); break;
					case CursorType.CIRCLE:
						_cursor.blendMode = BlendMode.INVERT;
						drawCircleCursor();
					break;
				}
				Mouse.hide();
				_cursor.visible = true;
			}
			_currentCursor = c;
		}
		
		// get brush size for brush cursor
		public static function get brushSize():Number {
			return _brushSize;
		}
		
		// set brush size for brush cursor
		public static function set brushSize(b:Number):void {
			_brushSize = b;
			if (_currentCursor == CursorType.CIRCLE) drawCircleCursor();
		}
		
		// mouse event handler
		private static function mouseMove(event:MouseEvent):void {
			_cursor.x = event.stageX;
			_cursor.y = event.stageY;
		}
		
		// draw cursor according to current context
		private static function drawCursor(Cursor:Class, x:int, y:int):void {
			var cursorBmp:Bitmap = new Cursor();
			var m:Matrix = new Matrix(1, 0, 0, 1, x, y);
			with (_cursor.graphics) {
				clear();
				beginBitmapFill(cursorBmp.bitmapData, m);
				drawRect(x, y, cursorBmp.width - 1, cursorBmp.height - 1);
				endFill();
			}
		}
		
		// draw brush cursor
		private static function drawCircleCursor():void {
			with (_cursor.graphics) {
				clear();
				lineStyle(1);
				drawEllipse(-_brushSize / 2, -_brushSize / 2, _brushSize, _brushSize);
			}
		}
	}
}