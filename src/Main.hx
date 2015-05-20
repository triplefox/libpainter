package;

import painter.Painter;
import painter.PaintState;
import painter.PaintResult;
import painter.PaintProgram;

import openfl.events.MouseEvent;
import openfl.events.KeyboardEvent;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.Lib;

class Main extends Sprite 
{

	public var editscreen : Bitmap;
	public var previewscreen : Bitmap;
	public var edittarget : Sprite;
	public var state : PaintState;
	public var painter : Painter;
	public var palette : Array<UInt>;
	public var program : Array<PaintProgram>;
	public var selected_color : Int;
	public var selected_brush : Int;
	public var selected_program : Int;
	public var brush : Array<PaintResult>;
	
	public function new() 
	{
		super();
		
		brush = Painter.defaultBrushes();
		palette = Painter.defaultPalette();
		program = Painter.defaultPrograms();
		
		editscreen = new Bitmap(new BitmapData(256, 256, false, 0x888888));
		previewscreen = new Bitmap(new BitmapData(256, 256, true, 0));
		edittarget = new Sprite();
		
		painter = new Painter();
		state = new PaintState();
		state.clear();
		selected_color = 0;
		selected_brush = 0;
		selected_program = 0;
		
		program = program.concat([
			function(p0 : Painter, s0 : PaintState) : Bool { /* flood fill */
				if (!s0.button_down) {
					editscreen.bitmapData.floodFill(s0.x, s0.y, p0.paint.color);
				}
				return !s0.button_down;
			},
			function(p0 : Painter, s0 : PaintState) : Bool { /* copy/paste */
				p0.preview.clear();
				if (s0.button_down && p0.paint.tooldata == null) { /* 1. picking end point */
					p0.drawLine(p0.preview, p0.paint.x, p0.paint.y, p0.paint.x, s0.y, 
						p0.paint.color);				
					p0.drawLine(p0.preview, p0.paint.x, p0.paint.y, s0.x, p0.paint.y, 
						p0.paint.color);
					p0.drawLine(p0.preview, p0.paint.x, s0.y, s0.x, s0.y, 
						p0.paint.color);
					p0.drawLine(p0.preview, s0.x, p0.paint.y, s0.x, s0.y, 
						p0.paint.color);
					return false;
				}
				else if (!s0.button_down && p0.paint.tooldata == null) { /* 2. selection chosen */
					var x0 = s0.x; var x1 = p0.paint.x; if (x0 > p0.paint.x) { x0 = p0.paint.x; x1 = s0.x; }
					var y0 = s0.y; var y1 = p0.paint.y; if (y0 > p0.paint.y) { y0 = p0.paint.y; y1 = s0.y; }
					if (x1 - x0 < 1 || y1 - y0 < 1) return true; /* too small */
					var td = new BitmapData(x1-x0, y1-y0, false, 0); p0.paint.tooldata = {click:false, data:td};
					td.copyPixels(editscreen.bitmapData, new Rectangle(x0, y0, x1-x0, y1-y0), new Point(0., 0.));
					return false;
				}
				else if (s0.button_down && p0.paint.tooldata != null && !p0.paint.tooldata.click) { /* 3. waiting for selection release */
					previewscreen.bitmapData.fillRect(previewscreen.bitmapData.rect, 0);
					previewscreen.bitmapData.copyPixels(p0.paint.tooldata.data, p0.paint.tooldata.data.rect, new Point(s0.x, s0.y));
					return false;
				}
				else if (!s0.button_down && p0.paint.tooldata != null) { /* 4. picking paste point */
					previewscreen.bitmapData.fillRect(previewscreen.bitmapData.rect, 0);
					previewscreen.bitmapData.copyPixels(p0.paint.tooldata.data, p0.paint.tooldata.data.rect, new Point(s0.x, s0.y));
					p0.paint.tooldata.click = true;
					return false;
				}
				else if (s0.button_down && p0.paint.tooldata != null && p0.paint.tooldata.click) { /* 5. paste point chosen */
					editscreen.bitmapData.copyPixels(p0.paint.tooldata.data, p0.paint.tooldata.data.rect, new Point(s0.x, s0.y));
					//p0.paint = null; /* this shouldn't be necessary, but it is? */
					return true;
				}
				else { return true; } /* should never get here */
			}
		]);
		
		/* copy/paste... the way we'd do this is to have some brush generated and...inserted into the state. 
		   i.e. we shouldn't have a palette. We shouldn't have a color, either.
		*/
		
		edittarget.addEventListener(MouseEvent.MOUSE_DOWN, onMouse);
		edittarget.addEventListener(MouseEvent.MOUSE_UP, onMouse);
		edittarget.addEventListener(MouseEvent.MOUSE_MOVE, onMouse);
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, onKey);
		this.addChild(edittarget);
		edittarget.addChild(editscreen);
		edittarget.addChild(previewscreen);
		
	}

	public function onMouse(evt : MouseEvent) {
		/* populate state of new tool program */
		state.x = Std.int(evt.localX);
		state.y = Std.int(evt.localY);
		state.button_down = evt.buttonDown;
		state.color = palette[selected_color];
		state.brush = brush[selected_brush];
		state.program = program[selected_program];
		/* update and draw result or preview */
		if (painter.updateMouse(state))
			previewscreen.bitmapData.fillRect(previewscreen.bitmapData.rect, 0);
		for (i0 in 0...painter.result.length) {
			editscreen.bitmapData.setPixel(
				painter.result.data[i0 * 3],
				painter.result.data[i0 * 3 + 1],
				painter.result.data[i0 * 3 + 2]);
		}
		if (painter.preview.length > 0) {
			previewscreen.bitmapData.fillRect(previewscreen.bitmapData.rect, 0);
			for (i0 in 0...painter.preview.length) {
				previewscreen.bitmapData.setPixel32(
					painter.preview.data[i0 * 3],
					painter.preview.data[i0 * 3 + 1],
					painter.preview.data[i0 * 3 + 2] | 0xFF000000);
			}
		}
	}
	
	public function onKey(evt : KeyboardEvent) {
		
		if (evt.type == KeyboardEvent.KEY_DOWN) {
			switch(evt.keyCode)
			{
				case 49: // 1
					selected_program = (selected_program + 1) % program.length;
				case 50: // 2
					selected_brush = (selected_brush + 1) % brush.length;
				case 51: // 3
					selected_color = (selected_color + 1) % palette.length;
			}
		}
		
	}
	
}
