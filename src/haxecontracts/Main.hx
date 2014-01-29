package haxecontracts;

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
		
		var r = new Rational(1, 1);
		trace(r.denominator);		
	}	
}
