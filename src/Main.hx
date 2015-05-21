package;

import haxe.ds.Vector;
import painter.Painter;
import painter.PaintState;
import painter.PaintResult;
import painter.PaintProgram;
import painter.VectorCanvas;

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
	public var palette : Array<Int>;
	public var program : Array<PaintProgram>;
	public var selected_color : Int;
	public var selected_brush : Int;
	public var selected_program : Int;
	public var brush : Array<PaintResult>;
	
	/* Right now copy-paste mixes the "preview" mode with the actual canvas ops. Can it be better? */
	/* Implement Dijkstra pathing trace. */
	/* Implement edge tracing on VectorCanvas. */
	/* Implement marching squares. */
	
	public function new() 
	{
		super();
		
		brush = Painter.defaultBrushes();
		palette = Painter.defaultPalette();
		program = Painter.defaultPrograms();
		
		editscreen = new Bitmap(new BitmapData(256, 256, false, 0x888888));
		previewscreen = new Bitmap(new BitmapData(256, 256, true, 0));
		edittarget = new Sprite();
		
		var canvas = new VectorCanvas(); canvas.init(editscreen.bitmapData.width, editscreen.bitmapData.height);
		canvas.clear(0xFF888888); 
		painter = new Painter();
		painter.canvas = canvas;
		state = new PaintState();
		state.clear();
		selected_color = 0;
		selected_brush = 0;
		selected_program = 0;
		
		program = program.concat([
			function(p0 : Painter, s0 : PaintState) : Bool { /* copy/paste */
				p0.preview.clear();
				if (s0.button[0] && p0.paint.tooldata == null) { /* 1. picking end point */
					var x0 = Std.int(p0.paint.x);
					var x1 = Std.int(s0.x);
					var y0 = Std.int(p0.paint.y);
					var y1 = Std.int(s0.y);
					for (c0 in Painter.pointsToSegments([[x0, y0], [x0, y1], [x1, y1], [x1, y0]])) {
						p0.drawLine(p0.preview, c0[0], c0[1], c0[2], c0[3], p0.paint.color);
					}
					return false;
				}
				else if (!s0.button[0] && p0.paint.tooldata == null) { /* 2. selection chosen */
					var x0 = Std.int(s0.x); var x1 = Std.int(p0.paint.x); 
					if (x0 > p0.paint.x) { x0 = Std.int(p0.paint.x); x1 = Std.int(s0.x); }
					var y0 = Std.int(s0.y); var y1 = Std.int(p0.paint.y); 
					if (y0 > p0.paint.y) { y0 = Std.int(p0.paint.y); y1 = Std.int(s0.y); }
					if (x1 - x0 < 1 || y1 - y0 < 1) return true; /* too small */
					var td = canvas.slice(x0, y0, x1 - x0, y1 - y0);
					var td2 = new BitmapData(x1-x0, y1-y0, false, 0); 
					td2.copyPixels(editscreen.bitmapData, new Rectangle(x0, y0, x1-x0, y1-y0), new Point(0., 0.));
					p0.paint.tooldata = {click:false, data:td, preview:td2};
					return false;
				}
				else if (s0.button[0] && p0.paint.tooldata != null && !p0.paint.tooldata.click) { /* 3. waiting for selection release */
					previewscreen.bitmapData.fillRect(previewscreen.bitmapData.rect, 0);
					previewscreen.bitmapData.copyPixels(p0.paint.tooldata.preview, p0.paint.tooldata.preview.rect, new Point(s0.x - p0.paint.tooldata.preview.width/2, s0.y - p0.paint.tooldata.preview.height/2));
					return false;
				}
				else if (!s0.button[0] && p0.paint.tooldata != null) { /* 4. picking paste point */
					previewscreen.bitmapData.fillRect(previewscreen.bitmapData.rect, 0);
					previewscreen.bitmapData.copyPixels(p0.paint.tooldata.preview, p0.paint.tooldata.preview.rect, new Point(s0.x - p0.paint.tooldata.preview.width/2, s0.y - p0.paint.tooldata.preview.height/2));
					p0.paint.tooldata.click = true;
					return false;
				}
				else if (s0.button[0] && p0.paint.tooldata != null && p0.paint.tooldata.click) { /* 5. paste point chosen */
					p0.canvas.blit(p0.paint.tooldata.data, 
						Std.int(s0.x - p0.paint.tooldata.data.w / 2), 
						Std.int(s0.y - p0.paint.tooldata.data.h / 2));
					p0.sync_canvas = true;
					return true;
				}
				else { return true; } /* should never get here */
			}
		]);
		
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
		state.x = evt.localX;
		state.y = evt.localY;
		state.button[0] = evt.buttonDown;
		state.button[1] = evt.ctrlKey;
		state.button[2] = evt.shiftKey;
		state.color = palette[selected_color];
		state.brush = brush[selected_brush];
		state.program = program[selected_program];
		/* update */
		painter.update(state);
		if (painter.complete) /* flush preview */
			previewscreen.bitmapData.fillRect(previewscreen.bitmapData.rect, 0);
		if (painter.result.length > 0) { /* draw some result points */
			var d0 = painter.result.data;
			for (i0 in 0...painter.result.length) {
				var i1 = i0 * 3;
				var x = d0[i1]; var y = d0[i1 + 1]; var v = d0[i1 + 2];
				// set canvas and bitmapData simultaneously
				painter.canvas.set(x, y, v);
				editscreen.bitmapData.setPixel32(x, y, v);
			}
			painter.result.clear();
		}
		if (painter.sync_canvas) { /* rewrite our display with canvas */
			/* because of flash uint type requirements we alloc and copy a new uint vector... */
			var v : Vector<UInt> = new Vector(painter.canvas.d.length);
			for (i0 in 0...v.length) v[i0] = painter.canvas.d[i0];
			editscreen.bitmapData.setVector(editscreen.bitmapData.rect, v.toData());
		}
		if (painter.preview.length > 0) { /* draw some preview points */
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
