package haxecontracts.example;
import haxecontracts.Contract;

class Main
{
	static function main()
	{
		#if sys
		Sys.println("");
		trace("Press a key to create the Rational number 12/6.");
		Sys.getChar(false);
		#else
		trace("Creating the Rational number 12/6:");
		#end

		var r = new Rational(12, 6);
		trace(r.toFloat() + " (" + r + ")");

		trace("Setting the denominator to 3:");
		r.denominator = 3;
		trace(r.toFloat() + " (" + r + ")");

		#if sys
		trace("Press a key to create a Rational number where the denominator is zero.");
		Sys.getChar(false);
		#else
		trace("Creating a Rational number where the denominator is zero:");
		#end

		var r2 = new Rational(12, 0);
		trace(r2.toFloat());
	}
}
