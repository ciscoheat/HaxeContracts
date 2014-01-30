package haxecontracts.example;

class Main 
{
	static function main() 
	{
		Sys.println("");
		Sys.println("Press a key to create a Rational number 12/6.");
		Sys.getChar(false);
		
		var r = new Rational(12, 6);
		trace(r.toFloat());
		
		Sys.println("Press a key to create a Rational where the enumerator is zero.");
		Sys.getChar(false);
		
		var r2 = new Rational(12, 0);
		trace(r2.toFloat());
	}	
}
