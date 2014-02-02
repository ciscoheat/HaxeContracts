package haxecontracts.example;
import haxecontracts.Contract;

class Main 
{
	static function main() 
	{
		Sys.println("");
		Sys.println("Press a key to create the Rational number 12/6.");
		Sys.getChar(false);
		
		var r = new Rational(12, 6);
		trace(r.toFloat() + " (" + r + ")");
		
		Sys.println("Press a key to create a Rational number where the denominator is zero.");
		Sys.getChar(false);
		
		var r2 = new Rational(12, 0);
		trace(r2.toFloat());
	}	
}
