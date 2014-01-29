package haxecontracts;

class Rational implements HaxeContracts {
    var numerator : Int;
    var _denominator : Int;

    public var denominator(get, null) : Int;

    public function new(numerator : Int, denominator : Int) {
        Contract.requires(denominator != 0);

        this.numerator = numerator;
        this._denominator = denominator;
    }
	
	public function test() return 123;

    private function get_denominator() {
        Contract.ensures(Contract.result != 0, "Result cannot be zero");
        return _denominator;
    }

    // Invariants will we injected at the end of every public method
    // and in methods that calls Contract.
    @invariant private function objectInvariant() {
        //Contract.invariant(denominator != 0);
    }
}