package painter;
import haxe.ds.Vector;

class VectorCanvas {
	
	public var d : Vector<Int>;
	public var w : Int;
	public var h : Int;
	
	public function new() {
	}
	
	public function init(width : Int, height : Int) {
		this.w = width; this.h = height;
		this.d = new Vector<Int>(w * h);
	}
	public function clear(v : Int) {
		for ( i0 in 0...d.length) d[i0] = v;
	}
	public function copy() {
		var r = new VectorCanvas(); r.w = w; r.h = h; Vector.blit(d, 0, r.d, 0, d.length); return r;
	}
	
	public inline function xIdx(idx : Int) { return idx % w; }
	public inline function yIdx(idx : Int) { return Std.int(idx / h); }
	public inline function getIdx(x : Int, y : Int) { return w*y + x; }
	public inline function rawget(x : Int, y : Int) { return d[w*y + x]; }
	public inline function get(x : Int, y : Int) { if (x >= 0 && x < w && y >= 0 && y < h) return d[w * y + x]; else return d[0]; }
	public inline function setIdx(idx : Int, v : Int) { d[idx] = v; }
	public inline function rawset(x : Int, y : Int, v : Int) { d[w*y + x] = v; }
	public inline function set(x : Int, y : Int, v : Int) { if (x >= 0 && x < w && y >= 0 && y < h) d[w*y + x] = v; }
	
	public inline function slice(x : Int, y : Int, w : Int, h : Int) : VectorCanvas {
		if (w < 1 || h < 1) return null;
		var result = new VectorCanvas(); result.init(w, h);
		for (i0 in 0...h) {
			for (i1 in 0...w) {
				result.set(i1, i0, get(i1 + x, i0 + y));
			}
		}
		return result;
	}
	
	public inline function blit(src : VectorCanvas, x : Int, y : Int, ?w : Int=0, ?h : Int=0) : Void {
		if (w == 0) w = src.w; if (h == 0) h = src.h;
		if (w > src.w) w = src.w; if (h > src.h) h = src.h;
		for (i0 in 0...h) {
			for (i1 in 0...w) {
				set(i1 + x, i0 + y, src.get(i1, i0));
			}
		}
	}
	
	public inline function floodFill(x : Int, y : Int, v : Int) : PaintResult {
		var queue = new Array<Int>();
		var paints = new PaintResult();
		var seed = get(x, y);
		if (seed == v) return paints;
		queue.push(getIdx(x, y));
		while (queue.length > 0) {
			var node = queue.shift();
			var y = yIdx(node); var yi = y * w;
			var wx = xIdx(node);
			var ex = wx;
			while (wx >= 0 && d[wx + yi] == seed) wx -= 1;
			while (ex < w && d[ex + yi] == seed) ex += 1;
			wx += 1;
			for (i0 in wx...ex) {
				paints.push(i0, y, v);
				set(i0, y, v);
				if (y - 1 >= 0 && d[i0 + yi - w] == seed) queue.push(getIdx(i0, y - 1));
				if (y + 1 < h && d[i0 + yi + w] == seed) queue.push(getIdx(i0, y + 1));
			}
		}
		return paints;
	}
	
}