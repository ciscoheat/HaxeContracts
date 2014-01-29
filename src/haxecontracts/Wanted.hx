package haxecontracts;

class Wanted {
    var numerator : Int;
    var _denominator : Int;

    public var denominator(get, null) : Int;

    public function new(numerator : Int, denominator : Int) {
        if(!(denominator != 0)) throw new haxecontracts.ContractException();
        
        this.numerator = numerator;
        this._denominator = denominator;
    }
    
    private function get_denominator() {
        return {
            if(!(this.denominator != 0)) throw new haxecontracts.ContractException(); // Invariant
            var __contract_output = _denominator; // Return statement
            if(!(__contract_output != 0)) throw new haxecontracts.ContractException("Result cannot be zero");
            __contract_output;
        }
    }
}