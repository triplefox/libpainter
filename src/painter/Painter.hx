package painter;

class Painter {
	
	public var paint : PaintState; /* program state that PaintProgram can retain between frames */
	
	public var result : PaintResult; /* list of points to return to the app this update */
	public var preview : PaintResult; /* list of points to tell the app to preview this update */
	
	public var canvas : VectorCanvas; /* canonical persistent data of the image we're working on */
	
	public var complete : Bool; /* program finished in last update */
	public var sync_canvas : Bool; /* request to sync current canvas state to application */
	
	public inline static function defaultBrushes() : Array <PaintResult> {
		return [PaintResult.fromPairs([[0, 0]], 0xFFFFFFFF), 
			PaintResult.fromPairs([[ -1, 0], [0, -1], [0, 0], [1, 0], [0, 1]], 0xFFFFFFFF),
			PaintResult.fromPairs([[ -1, -1], [ -1, 0], [ -1, 1], [0, -1], [0, 0], [1, 0], [1, -1], [0, 1], [1, 1]], 0xFFFFFFFF),
			];
	}
	
	public inline static function defaultPalette() : Array<UInt> {
		return [
			0xFF000000,
			0xFFFF0000,
			0xFF00FF00,	
			0xFF0000FF,	
			0xFFFFFF00,	
			0xFF00FFFF,	
			0xFFFF00FF
		];
	}
	
	public inline static function defaultPrograms() : Array<PaintProgram> {
		return [
			function(p0 : Painter, s0 : PaintState) { /* freehand */
				if (s0.button_down) {
					p0.drawLine(p0.result, p0.paint.x, p0.paint.y, 
						s0.x, s0.y, p0.paint.color);
					p0.paint.x = s0.x; p0.paint.y = s0.y;
				}
				return !s0.button_down;
			},
			function(p0 : Painter, s0 : PaintState) { /* line */
				var target : PaintResult;
				if (s0.button_down) target = p0.preview; else target = p0.result;
				p0.preview.clear();
				p0.drawLine(target, p0.paint.x, p0.paint.y, 
					s0.x, s0.y, p0.paint.color);
				return !s0.button_down;
			},			
			function(p0 : Painter, s0 : PaintState) { /* rectangle */
				var target : PaintResult;
				if (s0.button_down) target = p0.preview; else target = p0.result;
				p0.preview.clear();
				p0.drawLine(target, p0.paint.x, p0.paint.y, p0.paint.x, s0.y, 
					p0.paint.color);				
				p0.drawLine(target, p0.paint.x, p0.paint.y, s0.x, p0.paint.y, 
					p0.paint.color);
				p0.drawLine(target, p0.paint.x, s0.y, s0.x, s0.y, 
					p0.paint.color);
				p0.drawLine(target, s0.x, p0.paint.y, s0.x, s0.y, 
					p0.paint.color);		
				return !s0.button_down;
			}
		];
	}
	
	public function new() {
		
		paint = null;
		result = new PaintResult();
		preview = new PaintResult();
		complete = false;
		sync_canvas = false;
		
	}
	
	public function drawLine(result : PaintResult, x0 : Int, y0 : Int, x1 : Int, y1 : Int, color : UInt) {
		var dist = Math.ceil(Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0))); /* diagonal distance (rounded up) */
		if (dist < 1) dist = 1;
		for (i0 in 0...dist) { /* draw interpolated dots along diagonal */
			var xr = x0 + Math.round(i0 / dist * (x1 - x0));				
			var yr = y0 + Math.round(i0 / dist * (y1 - y0));
			for (v0 in 0...paint.brush.length)
				result.push(xr + paint.brush.data[v0*3], yr + paint.brush.data[v0*3 + 1], color);
		}
		/* draw last dot */
		for (v0 in 0...paint.brush.length) 
			result.push(x1 + paint.brush.data[v0*3], y1 + paint.brush.data[v0*3 + 1], color);
	}
	
	public function update(state : PaintState) : Void {
		result.clear();
		complete = false;
		sync_canvas = false;
		if (state.button_down) {
			if (paint == null) {
				paint = state.copy();
			}
		}
		if (paint != null) {
			if (paint.program(this, state)) {
				complete = true;
				paint = null;
				preview.clear();
			}
		}
		state.clear();
	}
	
	public function copy() {
		var rp = new Painter();
		rp.canvas = canvas.copy();
		rp.paint = paint.copy();
		rp.preview = preview.copy();
		rp.result = result.copy();
		rp.complete = complete;
		rp.sync_canvas = sync_canvas;
		return rp;
	}
	
}
