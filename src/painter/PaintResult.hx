package painter;

import haxe.ds.Vector;

class PaintResult {
	public var data : Vector<Int>;
	public var length : Int;
	public function new() { data = new Vector(3); length = 0; }
	public function clear(?and_buffer = false) {
		length = 0; if (and_buffer) data = new Vector(3);
	}
	public inline function push(x : Int, y : Int, color : UInt) {
		/* Double buffer size if needed */
		while (data.length <= length * 3) {
			var nd = new Vector(data.length * 2);
			for (i0 in 0...data.length) { nd[i0] = data[i0]; }
			data = nd;
		}
		/* push */
		data[length * 3] = x;
		data[length * 3 + 1] = y;
		data[length * 3 + 2] = color;
		length += 1;
	}
	public static function fromPairs(pairs : Array<Array<Int>>, color : UInt) {
		var pr = new PaintResult();
		for (p in pairs) pr.push(p[0], p[1], color);
		return pr;
	}
	public static function fromTriplets(triplets : Array<Array<Int>>) {
		var pr = new PaintResult();
		for (p in triplets) pr.push(p[0], p[1], p[2]);
		return pr;
	}
	public function copy() : PaintResult {
		var r = new PaintResult(); 
		r.data = new Vector(data.length);
		Vector.blit(data, 0, r.data, 0, r.data.length);
		r.length = length; 
		return r;
	}
	public function toString() {
		return [for (i0 in 0...length) data[i0]];
	}
}
