package haxecontracts.example;
import haxecontracts.HaxeContracts;
import haxecontracts.Contract;

class Rational implements HaxeContracts
{
	public var numerator(default, default) : Int;
    public var denominator(default, set) : Int;

    public function new(numerator : Int, denominator : Int)
	{
		Contract.requires(denominator != 0, "Denominator cannot be zero.");
		
        this.numerator = numerator;
        this.denominator = denominator;
    }

	public function toFloat() : Float
	{
		return numerator / denominator;
	}

	public function toString() : String
	{
		return numerator + "/" + denominator;
	}

	private function set_denominator(d : Int)
	{
		Contract.ensures(Contract.result != 0, "Denominator cannot be zero.");
        return denominator = d;
    }

    // Invariants will we injected at the end of every public method and in accessor methods.
    @invariant function invariants()
	{
        Contract.invariant(denominator != 0, "Denominator cannot be zero.");
    }
}