package picmagick.display {
	
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.ui.Keyboard;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	
	// image widget containing a LayeredCanvas instance, which can be moved by mouse
	public class DraggableCanvas extends UIComponent {
		public var draggable:Boolean; // if current mode allows dragging
		public var spaceDown:Boolean; // if space key is down (dragging is enforced)
		
		private var _canvas:LayeredCanvas; // underlying LayeredCanvas instance
		private var _mask:Shape; // displayable area mask
		private var _centerX:int; // image center
		private var _centerY:int; // image center
		
		public function DraggableCanvas() {
			super();
			draggable = true;
			spaceDown = false;
			_canvas =  new LayeredCanvas();
			_canvas.filters = [new DropShadowFilter(4, 45, 0, 1, 4, 4, 1, 3)];
			mask = _mask = new Shape();
			_centerX = _centerY = 0;
			addChild(_canvas);
			addChild(_mask);
			addEventListener(FlexEvent.CREATION_COMPLETE, creationComplete);
			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			addEventListener(ResizeEvent.RESIZE, resize);
		}
		
		// get the LayeredCanvas instance
		public function get layers():LayeredCanvas {
			return _canvas;
		}
		
		// set bitmapData for the image being displayed
		public function set bitmapData(bmd:BitmapData):void {
			_canvas.bitmapData = bmd;
		}
		
		// get size scale coefficient
		public function get scale():Number {
			return _canvas.scale;
		}
		
		// set size scale coefficient
		public function set scale(s:Number):void {
			_canvas.scale = s;
			fixCenter();
		}
		
		// re-center the image
		public function resetPosition():void {
			_centerX = _centerY = 0;
			_canvas.x = width / 2;
			_canvas.y = height / 2;
		}
		
		// init
		private function creationComplete(event:FlexEvent):void {
			_canvas.systemManager = systemManager;
		}
		
		
		// init
		private function addedToStage(event:Event):void {
			CursorManager.init(stage);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
		}
		
		// mouse event handler
		private function mouseDown(event:MouseEvent):void {
			if (((_canvas.scaledWidth + 20) > width || (_canvas.scaledHeight + 20) > height) && (draggable || spaceDown)) {
				systemManager.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove, true);
				systemManager.addEventListener(MouseEvent.MOUSE_UP, mouseUp, true);
				_canvas.startDrag();
			}
		}
		
		// mouse event handler
		private function mouseMove(event:MouseEvent):void {
			fixCenter(true);
		}
		
		// mouse event handler
		private function mouseUp(event:MouseEvent):void {
			systemManager.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove, true);
			systemManager.removeEventListener(MouseEvent.MOUSE_UP, mouseUp, true);
			_canvas.stopDrag();
		}
		
		// mouse event handler
		private function resize(event:ResizeEvent):void {
			with(_mask.graphics) {
				clear();
				beginFill(0);
				drawRect(0, 0, width, height);
				endFill();
			}
			fixCenter();
		}
		
		// re-position image when context changed
		private function fixCenter(moving:Boolean = false):void {
			if (!moving) {
				_canvas.x = width / 2 + _centerX * scale;
				_canvas.y = height / 2 + _centerY * scale;
			}
			
			if ((_canvas.scaledWidth + 20) <= width) {
				_canvas.x = width / 2;
			} else {
				if ((_canvas.x - _canvas.scaledWidth / 2 - 10) > 0 ) _canvas.x = _canvas.scaledWidth / 2 + 10;
				if ((_canvas.x + _canvas.scaledWidth / 2 + 10) < width ) _canvas.x = width - _canvas.scaledWidth / 2 - 10;
			}
			
			if ((_canvas.scaledHeight + 20) <= height) {
				_canvas.y = height / 2;
			} else {
				if ((_canvas.y - _canvas.scaledHeight / 2 - 10) > 0 ) _canvas.y = _canvas.scaledHeight / 2 + 10;
				if ((_canvas.y + _canvas.scaledHeight / 2 + 10) < height ) _canvas.y = height - _canvas.scaledHeight / 2 - 10;
			}
			
			_centerX = (_canvas.x - width / 2) / scale;
			_centerY = (_canvas.y - height / 2) / scale;
		}
		
		// get key status, so that when SPACE is pressed, mouse events are only used to move the image
		private function keyDown(event:KeyboardEvent):void {
			if (event.keyCode == Keyboard.SPACE) _canvas.spaceDown = spaceDown = true;
		}
		
		// get key status, so that when SPACE is pressed, mouse events are only used to move the image
		private function keyUp(event:KeyboardEvent):void {
			if (event.keyCode == Keyboard.SPACE) _canvas.spaceDown = spaceDown = false;
		}
	}
}