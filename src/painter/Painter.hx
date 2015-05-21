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
	
	public inline static function defaultPalette() : Array<Int> {
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
	
	public static function pointsToSegments(p0 : Array<Array<Int>>) {
		var r0 = new Array<Array<Int>>();
		var i0 = 0;
		while (i0 < p0.length) {
			var from = p0[i0]; var to = p0[(i0 + 1) % p0.length];
			r0.push([from[0],from[1],to[0],to[1]]);
			i0 += 1;
		}
		return r0;
	}
	
	public static function pointsToSegmentsUnlooped(p0 : Array<Array<Int>>) {
		var r0 = new Array<Array<Int>>();
		var i0 = 0;
		while (i0 < p0.length - 1) {
			var from = p0[i0]; var to = p0[(i0 + 1) % p0.length];
			r0.push([from[0],from[1],to[0],to[1]]);
			i0 += 1;
		}
		return r0;
	}
	
	public static inline function distance(x : Float, y : Float) {
		return Math.sqrt((x + y) * (x + y));
	}
	public static inline function distanceSqr(x : Float, y : Float) {
		return ((x + y) * (x + y));
	}
	public static inline function ellipse(x0 : Float, x1 : Float, y0 : Float, y1 : Float) {
		var rx = Math.abs(x0 - x1);
		var ry = Math.abs(y0 - y1);
		var r = distance(rx, ry); /* radius */
		var c = 2 * Math.PI * r; /* circumference */
		
		/* draw one quad with trig, then copy so that pattern is consistent */
		var pts = new Array<Array<Int>>();
		for (i0 in 0...Math.ceil(c/4)) {
			var a = i0 / c * Math.PI * 2; /* angle in radians */
			var y = Math.round((Math.sin(a) * ry));
			var x = Math.round((Math.cos(a) * rx));
			pts.push([x, y]);
		}
		var quad = pts.length;
		for (i0 in 0...quad) { var i1 = quad - i0 - 1; pts.push([-pts[i1][0], pts[i1][1]]); }
		for (i0 in 0...quad) { var i1 = quad - i0 - 1; pts.push([-pts[i0][0], -pts[i0][1]]); }
		for (i0 in 0...quad) { var i1 = quad - i0 - 1; pts.push([pts[i1][0], -pts[i1][1]]); }
		for (t0 in pts) { t0[0] += Std.int(x0); t0[1] += Std.int(y0); }
		return pts;
	}
	
	public inline static function defaultPrograms() : Array<PaintProgram> {
		return [
			function(p0 : Painter, s0 : PaintState) { /* freehand */
				if (s0.button[0]) {
					p0.drawLine(p0.result, Std.int(p0.paint.x), Std.int(p0.paint.y), 
						Std.int(s0.x), Std.int(s0.y), p0.paint.color);
					p0.paint.x = s0.x; p0.paint.y = s0.y;
				}
				return !s0.button[0];
			},
			function(p0 : Painter, s0 : PaintState) { /* line */
				var target : PaintResult;
				if (s0.button[0]) target = p0.preview; else target = p0.result;
				p0.preview.clear();
				p0.drawLine(target, Std.int(p0.paint.x), Std.int(p0.paint.y), 
					Std.int(s0.x), Std.int(s0.y), p0.paint.color);
				return !s0.button[0];
			},			
			function(p0 : Painter, s0 : PaintState) { /* rectangle */
				var target : PaintResult;
				if (s0.button[0]) target = p0.preview; else target = p0.result;
				var x0 = Std.int(p0.paint.x);
				var x1 = Std.int(s0.x);
				var y0 = Std.int(p0.paint.y);
				var y1 = Std.int(s0.y);
				p0.preview.clear();
				for (c0 in pointsToSegments([[x0, y0], [x0, y1], [x1, y1], [x1, y0]])) {
					p0.drawLine(target, c0[0], c0[1], c0[2], c0[3], p0.paint.color);
				}
				return !s0.button[0];
			},
			function(p0 : Painter, s0 : PaintState) { /* circle */
				var target : PaintResult;
				if (s0.button[0]) target = p0.preview; else target = p0.result;
				p0.preview.clear();
				var r = distance(s0.x - p0.paint.x, s0.y - p0.paint.y); /* unify the x/y differentials */
				for (c0 in pointsToSegments(ellipse(p0.paint.x, p0.paint.x + r, p0.paint.y, p0.paint.y + r))) {
					p0.drawLine(target, c0[0], c0[1], c0[2], c0[3], p0.paint.color);
				}
				return !s0.button[0];
			},
			function(p0 : Painter, s0 : PaintState) { /* ellipse */
				var target : PaintResult;
				if (s0.button[0]) target = p0.preview; else target = p0.result;
				p0.preview.clear();
				for (c0 in pointsToSegments(ellipse(p0.paint.x, s0.x, p0.paint.y, s0.y))) {
					p0.drawLine(target, c0[0], c0[1], c0[2], c0[3], p0.paint.color);
				}
				return !s0.button[0];
			},
			function(p0 : Painter, s0 : PaintState) : Bool { /* flood fill */
				if (!s0.button[0]) {
					p0.canvas.floodFill(Std.int(s0.x), Std.int(s0.y), p0.paint.color);
					p0.sync_canvas = true;
				}
				return !s0.button[0];
			},
			function(p0 : Painter, s0 : PaintState) : Bool { /* dijkstra flood */
				if (!s0.button[0]) {
					var df = p0.canvas.dijkstraFlood(Std.int(s0.x), Std.int(s0.y));
					for (i0 in 0...df.canvas.d.length) {
						df.canvas.d[i0] = 0xFF000000 | df.canvas.d[i0] | (df.canvas.d[i0] << 8) | (df.canvas.d[i0] << 16);
					}
					p0.canvas.blit(df.canvas, 0, 0);
					p0.sync_canvas = true;
				}
				return !s0.button[0];
			},
			function(p0 : Painter, s0 : PaintState) : Bool { /* dijkstra path */
				var target : PaintResult;
				p0.preview.clear();
				if (s0.button[0]) {
					p0.drawLine(p0.preview, Std.int(p0.paint.x), Std.int(p0.paint.y), 
						Std.int(s0.x), Std.int(s0.y), p0.paint.color);
				} else {
					var df = p0.canvas.dijkstraFlood(Std.int(s0.x), Std.int(s0.y));
					var dp = df.canvas.dijkstraPath4(Std.int(p0.paint.x), Std.int(p0.paint.y));
					for (c0 in 0...dp.length) {
						var xr = dp.data[c0 * 3]; var yr = dp.data[c0 * 3 + 1];
						for (v0 in 0...p0.paint.brush.length)
							p0.result.push(xr + p0.paint.brush.data[v0*3], yr + p0.paint.brush.data[v0*3 + 1], p0.paint.color);
					}
				}
				return !s0.button[0];
			},
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
		if (state.button[0]) {
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
