package haxecontracts;

import neko.Lib;

/**
 * ...
 * @author ciscoheat
 */

class Main 
{
	
	static function main() 
	{
		var w = new haxecontracts.Wanted(1, 1);
		trace(w.denominator);
		
		var r = new Rational(1, 0);
		trace(r.denominator);
		trace(r.test());
	}
	
}