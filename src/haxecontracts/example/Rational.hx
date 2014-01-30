package haxecontracts.example;
import haxecontracts.HaxeContracts;

class Rational implements HaxeContracts
{
    var _denominator : Int;

	public var numerator(default, null) : Int;
    public var denominator(get, null) : Int;

    public function new(numerator : Int, denominator : Int) 
	{
        this.numerator = numerator;
        this._denominator = denominator;
    }
	
	public function toFloat() : Float
	{
		return numerator / denominator;
	}
	
    private function get_denominator() 
	{
        return _denominator;
    }

    // Invariants will we injected at the end of every public method and in accessor methods.
    @invariant private function objectInvariant() 
	{
        Contract.invariant(this.denominator != 0, "Denominator is zero");
    }
}