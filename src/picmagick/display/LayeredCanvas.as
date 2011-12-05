package picmagick.display {
	
	import flash.display.*;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.geom.*;
	
	import mx.managers.ISystemManager;

	// image widget with different predefined layers to help basic editing functions
	public class LayeredCanvas extends Sprite {
		public var systemManager:ISystemManager;
		public var brushMode:String;
		
		private var _base:Sprite;
		private var _bmd:BitmapData;
		private var _selecting:Boolean;
		private var _gray:Shape;
		private var _select:Shape;
		private var _proportion:Number;
		private var _rotating:Boolean;
		private var _grid:Shape;
		private var _gridMask:Shape;
		private var _smoothing:Boolean;
		private var _smooth:Sprite;
		private var _smoothMask:Sprite;
		private var _stroke:Shape;
		private var _colorPicking:Boolean;
		private var _offsetMatrix:Matrix;
		private var _spaceDown:Boolean;
		private var _brushSize:Number;
		private var _actualX:int;
		private var _actualY:int;
		private var _actualWidth:int;
		private var _actualHeight:int;
		private var _selectedArea:Rectangle;
		private var _regPos:int;
		private var _regX:int;
		private var _regY:int;
		
		[Embed(source="images/grid.png")]
		private var GridImage:Class;
		
		public function LayeredCanvas()
		{
			super();
			_base = new Sprite();
			addChild(_base);
			_selecting = false;
			_rotating = false;
			_spaceDown = false;
			_regPos = -1;
			addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		}
		
		// set bitmapData for the image being displayed
		public function set bitmapData(bmd:BitmapData):void {
			_bmd = bmd;
			_actualX = Math.floor(-bmd.width / 2);
			_actualY = Math.floor(-bmd.height / 2);
			_actualWidth = bmd.width;
			_actualHeight = bmd.height;
			with(_base.graphics) {
				clear();
				_offsetMatrix = new Matrix(1, 0, 0, 1, _actualX, _actualY);
				beginBitmapFill(bmd, _offsetMatrix);
				drawRect(_actualX, _actualY, _actualWidth, _actualHeight);
				endFill();
			}
			if (rotating) drawGridMask();
		}
		
		// get image offset matrix
		public function get offsetMatrix():Matrix {
			return _offsetMatrix;
		}
		
		// get size scale coefficient
		public function get scale():Number {
			return _base.scaleX;
		}
		
		// set size scale coefficient
		public function set scale(s:Number):void {
			_base.scaleX = _base.scaleY = s;
			CursorManager.brushSize = _brushSize * scale;
		}
		
		// get width after scaling
		public function get scaledWidth():int {
			return _base.width;
		}
		
		// get height after scaling
		public function get scaledHeight():int {
			return _base.height;
		}
		
		// if widget is under area selecting mode
		public function get selecting():Boolean {
			return _selecting;
		}
		
		// set widget to area selecting mode
		public function set selecting(s:Boolean):void {
			if (s) {
				_selecting = true;
				_selectedArea = null;
				_proportion = 0;
				_gray = new Shape();
				with(_gray.graphics) {
					beginFill(0x555555, 0.5);
					drawRect(_actualX, _actualY, _actualWidth, _actualHeight);
					endFill();
				}
				_gray.visible = false;
				_base.addChild(_gray);
				_select = new Shape();
				_base.addChild(_select);
			} else if (_selecting) {
				_selecting = false;
				_base.removeChild(_gray);
				_base.removeChild(_select);
			}
		}
		
		// set image aspect
		public function set proportion(p:Number):void {
			_proportion = p;
			constrainSelect();
			drawSelect();
		}
		
		// reset selected area
		public function resetSelection():void {
			_selectedArea = null;
			drawSelect();
			with(_gray.graphics) {
				clear();
				beginFill(0x555555, 0.5);
				drawRect(_actualX, _actualY, _actualWidth, _actualHeight);
				endFill();
			}
			drawCursor();
		}
		
		// get selected area
		public function get selection():Rectangle {
			var retRect:Rectangle = _selectedArea.clone();
			retRect.offset(-_actualX, -_actualY);
			return retRect;
		}
		
		// if widget is under rotating mode
		public function get rotating():Boolean {
			return _rotating;
		}
		
		// set widget to rotating mode
		public function set rotating(r:Boolean):void {
			if (r) {
				_rotating = true;
				_grid = new Shape();
				addChild(_grid);
				_gridMask = new Shape();
				_base.addChild(_gridMask);
				_grid.mask = _gridMask;
				drawGrid();
				drawGridMask();
			} else if (_rotating) {
				_rotating = false;
				removeChild(_grid);
				_base.removeChild(_gridMask);
			}
		}
		
		// if widget is under skin smoothing mode
		public function get smoothing():Boolean {
			return _smoothing;
		}
		
		// set widget to skin smoothing mode
		public function set smoothing(s:Boolean):void {
			if (s) {
				_smoothing = true;
				_smooth = new Sprite();
				_smooth.cacheAsBitmap = true;
				_base.addChild(_smooth);
				_smoothMask = new Sprite();
				_smoothMask.cacheAsBitmap = true;
				_smoothMask.blendMode = BlendMode.LAYER;
				_smooth.addChild(_smoothMask);
				_smooth.mask = _smoothMask;
			} else if (_smoothing) {
				_smoothing = false;
				_base.removeChild(_smooth);
			}
		}
		
		// get smoothed overlay cache
		public function get smoothLayer():IBitmapDrawable {
			return _smooth;
		}
		
		// set smoothed overlay cache
		public function set smoothLayer(bmd:IBitmapDrawable):void {
			with(_smooth.graphics) {
				clear();
				beginBitmapFill(bmd, _offsetMatrix);
				drawRect(_actualX, _actualY, _actualWidth, _actualHeight);
				endFill();
			}
		}
		
		// set if smoothed overlay is displayed
		public function set smoothVisible(s:Boolean):void {
			if (_smoothing) _smooth.visible = s;
		}
		
		// if widget is under color picking mode
		public function get colorPicking():Boolean {
			return _colorPicking;
		}
		
		// set widget to color picking mode
		public function set colorPicking(c:Boolean):void {
			_colorPicking = c;
		}
		
		// get coordinates from color picking
		public function get positionPicked():Point {
			return new Point(_regX, _regY);
		}
		
		// if space key is down (widget under moving mode)
		public function get spaceDown():Boolean {
			return _spaceDown;
		}
		
		// set if space key is down (widget under moving mode)
		public function set spaceDown(s:Boolean):void {
			_spaceDown = s;
			drawCursor();
		}
		
		// get brush size for skin smoothing mode
		public function get brushSize():Number {
			return _brushSize;
		}
		
		// set brush size for skin smoothing mode
		public function set brushSize(b:Number):void {
			_brushSize = b;
			CursorManager.brushSize = _brushSize * scale;
		}
		
		// mouse event handler
		private function mouseOut(event:MouseEvent):void {
			if (_regPos == -1) CursorManager.cursor = CursorType.NULL;
		}
		
		// mouse event handler
		private function mouseMove(event:MouseEvent):void {
			drawCursor();
		}
		
		// mouse event handler
		private function mouseDown(event:MouseEvent):void {
			if (_spaceDown) return;
			
			if (_selecting) {
				_regPos = cursorPosition;
				if (_regPos == 0) _selectedArea = new Rectangle(_base.mouseX, _base.mouseY, 0, 0);
				if (_regPos != 3 && _regPos != 6 && _regPos != 9) _regX = _selectedArea.left - _base.mouseX;
				else _regX = _selectedArea.right - _base.mouseX;
				if (_regPos < 7) _regY = _selectedArea.top - _base.mouseY;
				else _regY = _selectedArea.bottom - _base.mouseY;
				systemManager.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveSelect, true);
				systemManager.addEventListener(MouseEvent.MOUSE_UP, mouseUpSelect, true);
			}
			
			if (_smoothing) {
				_regX = _base.mouseX;
				_regY = _base.mouseY;
				_stroke = new Shape();
				_stroke.blendMode = brushMode;
				_smoothMask.addChild(_stroke);
				_stroke.filters = [new BlurFilter(_brushSize / 2, _brushSize / 2, 1)];
				_stroke.graphics.lineStyle(_brushSize / 2, 0, 1, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
				_stroke.graphics.moveTo(_regX, _regY);
				systemManager.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveSmooth, true);
				systemManager.addEventListener(MouseEvent.MOUSE_UP, mouseUpSmooth, true);
			}
			
			if (_colorPicking) {
				_regX = _base.mouseX - _actualX;
				_regY = _base.mouseY - _actualY;
				dispatchEvent(new Event("colorPicked"));
			}
		}
		
		// mouse event handler under area selecting mode
		private function mouseMoveSelect(event:MouseEvent):void {
			event.stopImmediatePropagation();
			
			if (_regPos == 1 || _regPos == 4 || _regPos == 7) _selectedArea.left = _base.mouseX + _regX;
			if (_regPos == 3 || _regPos == 6 || _regPos == 9 || _regPos == 0) _selectedArea.right = _base.mouseX + _regX;
			if (_regPos == 1 || _regPos == 2 || _regPos == 3) _selectedArea.top = _base.mouseY + _regY;
			if (_regPos == 7 || _regPos == 8 || _regPos == 9 || _regPos == 0) _selectedArea.bottom = _base.mouseY + _regY;
			
			preConstrainSelect();
			
			if (_selectedArea.left < _actualX) _selectedArea.left = _actualX;
			if (_selectedArea.left >= _actualX + _actualWidth) _selectedArea.left = _actualX + _actualWidth - 1; 
			if (_selectedArea.top < _actualY) _selectedArea.top = _actualY;
			if (_selectedArea.top >= _actualY + _actualHeight) _selectedArea.top = _actualY + _actualHeight - 1;
			if (_selectedArea.right < _actualX) _selectedArea.right = _actualX;
			if (_selectedArea.right >= _actualX + _actualWidth) _selectedArea.right = _actualX + _actualWidth - 1; 
			if (_selectedArea.bottom < _actualY) _selectedArea.bottom = _actualY;
			if (_selectedArea.bottom >= _actualY + _actualHeight) _selectedArea.bottom = _actualY + _actualHeight - 1;
			
			if (_regPos == 5) {
				_selectedArea.x = _base.mouseX + _regX;
				_selectedArea.y = _base.mouseY + _regY;
				if (_selectedArea.x < _actualX) _selectedArea.x = _actualX;
				if (_selectedArea.y < _actualY) _selectedArea.y = _actualY;
				if (_selectedArea.right >= _actualX + _actualWidth) _selectedArea.x = _actualX + _actualWidth - _selectedArea.width - 1; 
				if (_selectedArea.bottom >= _actualY + _actualHeight) _selectedArea.y = _actualY + _actualHeight - _selectedArea.height - 1;
			}
			
			constrainSelect();
			drawSelect();
		}
		
		// mouse event handler under area selecting mode
		private function mouseUpSelect(event:MouseEvent):void {
			if (_selectedArea.width < 0) {
				_selectedArea.x += _selectedArea.width;
				_selectedArea.width = -_selectedArea.width;
			}
			if (_selectedArea.height < 0) {
				_selectedArea.y += _selectedArea.height;
				_selectedArea.height = -_selectedArea.height;
			}
			if (_selectedArea.width == 0 || _selectedArea.height == 0) _selectedArea = null
			systemManager.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveSelect, true);
			systemManager.removeEventListener(MouseEvent.MOUSE_UP, mouseUpSelect, true);
			drawSelect();
			drawCursor();
			_regPos = -1;
			if (_selectedArea) dispatchEvent(new Event("selectComplete"));
		}
		
		// mouse event handler under skin smoothing mode
		private function mouseMoveSmooth(event:MouseEvent):void {
			var x:int = _base.mouseX;
			var y:int = _base.mouseY;
			if (x >= _actualX && x <= (_actualX + _actualWidth) &&  y >= _actualY && y <= (_actualY + _actualHeight)) {
				_stroke.graphics.lineTo(x, y);
				_regX = x;
				_regY = y;
			}
		}
		
		// mouse event handler under skin smoothing mode
		private function mouseUpSmooth(event:MouseEvent):void {
			event.stopImmediatePropagation();
			
			systemManager.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveSmooth, true);
			systemManager.removeEventListener(MouseEvent.MOUSE_UP, mouseUpSmooth, true);
			drawCursor();
		}
		
		// get mouse relative (9-cell) position with respect to selected area
		private function get cursorPosition():int {
			if (!_selectedArea) return 0;
			var k:int = 15;
			var i:int = 0;
			var x:Number = _base.mouseX;
			var y:Number = _base.mouseY;
			var l:Number = _selectedArea.left;
			var r:Number = _selectedArea.right;
			var t:Number = _selectedArea.top;
			var b:Number = _selectedArea.bottom;
			if (x < l - k) i -= 10;
			else if (x < l + k) i += 1;
			else if (x < r - k) i += 2;
			else if (x < r + k) i += 3;
			else i -= 10;
			if (y < t - k) i -= 10;
			else if (y < t + k) i += 0;
			else if (y < b - k) i += 3;
			else if (y < b + k) i += 6;
			else i -= 10;
			if (i < 0) i = 0;
			return i;
		}
		
		// sgn(n)
		private function sign(n:Number):int {
			if (n >= 0) return 1;
			else return -1;
		}
		
		// prepare for calculating selected area according to aspect
		private function preConstrainSelect():void {
			if (!_selectedArea || _proportion == 0) return;
			switch (_regPos){
				case 2:
					if (Math.abs(_selectedArea.width) < Math.abs(_selectedArea.height)) _selectedArea.left = _selectedArea.right - _selectedArea.height * _proportion;
					else _selectedArea.left = _selectedArea.right - _selectedArea.height / _proportion;
				break;
				case 4:
					if (Math.abs(_selectedArea.height) < Math.abs(_selectedArea.width)) _selectedArea.top = _selectedArea.bottom - _selectedArea.width * _proportion;
					else _selectedArea.top = _selectedArea.bottom - _selectedArea.width / _proportion;
				break;
				case 6:
					if (Math.abs(_selectedArea.height) < Math.abs(_selectedArea.width)) _selectedArea.height = _selectedArea.width * _proportion;
					else _selectedArea.height = _selectedArea.width / _proportion;
				break;
				case 8:
					if (Math.abs(_selectedArea.width) < Math.abs(_selectedArea.height)) _selectedArea.width = _selectedArea.height * _proportion;
					else _selectedArea.width = _selectedArea.height / _proportion;
				break;
			}
		}
		
		// calculate selected area according to aspect
		private function constrainSelect():void {
			if (!_selectedArea || _proportion == 0) return;
			var w:Number = Math.abs(_selectedArea.width);
			var h:Number = Math.abs(_selectedArea.height);
			var x:Number = Math.min(w, h);
			var y:Number = Math.max(w, h);
			if (x > y * _proportion) x = y * _proportion;
			else y = x / _proportion;
			var a:Number = x * sign(_selectedArea.width);
			var b:Number = y * sign(_selectedArea.height);
			var c:Number = y * sign(_selectedArea.width);
			var d:Number = x * sign(_selectedArea.height);
			
			switch (_regPos) {
				case 1:
				case 2:
				case 4:
					if (w < h) {
						_selectedArea.left = _selectedArea.right - a;
						_selectedArea.top = _selectedArea.bottom - b;
					}
					else {
						_selectedArea.left = _selectedArea.right - c;
						_selectedArea.top = _selectedArea.bottom - d;
					}
				break;
				case 3:
					if (w < h) {
						_selectedArea.right = _selectedArea.left + a;
						_selectedArea.top = _selectedArea.bottom - b;
					}
					else {
						_selectedArea.right = _selectedArea.left + c;
						_selectedArea.top = _selectedArea.bottom - d;
					}
				break;
				case 7:
					if (w < h) {
						_selectedArea.left = _selectedArea.right - a;
						_selectedArea.bottom = _selectedArea.top + b;
					}
					else {
						_selectedArea.left = _selectedArea.right - c;
						_selectedArea.bottom = _selectedArea.top + d;
					}
				break;
				case 6:
				case 8:
				case 9:
				case 0:
				case -1:
					if (Math.abs(_selectedArea.width) < Math.abs(_selectedArea.height)) {
						_selectedArea.width = a;
						_selectedArea.height = b;
					}
					else {
						_selectedArea.width = c;
						_selectedArea.height = d;
					}
				break;
			}
		}
		
		// draw predefined layers for area selecting mode
		private function drawSelect():void {
			with (_select.graphics) {
				clear();
				if (!_selectedArea) {
					_gray.visible = false;
					return;
				}
				_gray.visible = true;
				lineStyle(1, 0xFFFFFF, 0.5);
				beginBitmapFill(_bmd, _offsetMatrix);
				drawRect(_selectedArea.x, _selectedArea.y, _selectedArea.width, _selectedArea.height);
				endFill();
			}
		}
		
		// draw predefined layers for rotating mode
		private function drawGrid():void {
			var grid:Bitmap = new GridImage();
			var offset:int = Math.min(_actualX, _actualY) * 2;
			var length:int = Math.max(_actualWidth, _actualHeight) * 2;
			with(_grid.graphics) {
				clear();
				beginBitmapFill(grid.bitmapData);
				drawRect(offset, offset, length, length);
				endFill();
			}
		}
		
		// draw predefined layers for rotating mode
		private function drawGridMask():void {
			with(_gridMask.graphics) {
				clear();
				beginFill(0);
				drawRect(_actualX, _actualY, _actualWidth, _actualHeight);
				endFill();
			}
		}
		
		// draw cursor according to the current context
		private function drawCursor():void {
			var cursor:String;
			
			if (_base.mouseX < _actualX || _base.mouseX > (_actualX + _actualWidth) || 
				_base.mouseY < _actualY || _base.mouseY > (_actualY + _actualHeight) ||
				parent.mouseX < 0 || parent.mouseX > parent.width ||
				parent.mouseY < 0 || parent.mouseY > parent.height)
				cursor = CursorType.NULL;
			else if (_spaceDown) {
				if ((_base.width + 20) > parent.width || (_base.height + 20) > parent.height) cursor = CursorType.HAND;
				else cursor = CursorType.NULL;
			} 
			else if (_selecting) {
				switch (cursorPosition) {
					case 0:
						cursor = CursorType.NULL;
						break;
					case 1:
					case 9:
						cursor = CursorType.RESIZE_NWSE;
						break;
					case 2:
					case 8:
						cursor = CursorType.RESIZE_NS;
						break;
					case 3:
					case 7:
						cursor = CursorType.RESIZE_NESW;
						break;
					case 4:
					case 6:
						cursor = CursorType.RESIZE_EW;
						break;
					case 5:
						cursor = CursorType.MOVE;
						break;
				}
			}
			else if (_smoothing) cursor = CursorType.CIRCLE;
			else if (_colorPicking) cursor = CursorType.COLOR_PICKER;
			else if ((_base.width + 20) > parent.width || (_base.height + 20) > parent.height) cursor = CursorType.HAND;
			else cursor = CursorType.NULL;
			
			CursorManager.cursor = cursor;
		}
	}
}