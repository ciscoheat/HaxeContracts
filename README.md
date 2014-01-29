# HaxeContracts - Unit's Bane

A [Design by contract](http://en.wikipedia.org/wiki/Design_by_contract) library for Haxe.

Heavily inspired by [Microsoft Code Contracts](http://research.microsoft.com/en-us/projects/contracts/), with a few code convention changes like camelCase and better use of Haxe's type inference.

## Proof-of-concept
```actionscript
package;
using haxecontracts.Contract;

class Rational implements HaxeContracts {
    var numerator : Int;
    var _denominator : Int;

    public var denominator(get, null);

    public function new(int numerator, int denominator) {
        // requires is like a normal assertion.
        Contract.requires(denominator != 0);
        
        this.numerator = numerator;
        this.denominator = denominator;
    }
    
    private function get_denominator() {
        // ensures will be tested before a method returns.
        Contract.ensures(Contract.result != 0, "Result cannot be zero");
        return _denominator;
    }
    
    // Invariants will we injected in the end of every public method (except the constructor) 
    // and in accessor methods.
    @invariant private function objectInvariant() {
        Contract.invariant(denominator != 0);
    }
}
```

The above class will be transformed into:
```actionscript
package;

class Rational implements HaxeContracts {
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
            if(!(this.denominator != 0)) throw new haxecontracts.ContractException();
            var __contract_output = _denominator; // Return statement
            if(!(__contract_output != 0)) throw new haxecontracts.ContractException("Result cannot be zero");
            __contract_output;
        }
    }
}
```
## Unit's Bane?
Glad you asked! Since the downsides of TDD are getting [more and more obvious](http://www.sigs.de/download/oop_09/Coplien%20Nmo1.pdf) (pg. 6-9), Design by Contract is an alternative that combined with a system architecture like [DCI](https://github.com/ciscoheat/haxedci-example) could be the end of the massive test-driven reign. Testing today is mainly a consequence of lack of Context in the code. Behavior is spread out through classes, making it very hard to grasp the polymorphic mess that todays so-called "OO code" quickly evolves into. It is rather class-oriented than object-oriented, since there is no easy way to reason about object behavior at runtime. And that's where the bugs are... 

This invisible elephant of a problem has forced programmers to create bloated, cumbersome testing harnesses, often with a codebase the same size as the application itself. But the time has come for the computer engineers to realize the underlying problem, instead of getting excited over the next slick testing tool. The rest of the world demands it, and unless you program completely alone in your spare time, the rest of the world probably pays you for being productive.

BDD is gaining ground, which is surely a step up from TDD. Just take notice that

- Tests should be written by someone else than the programmer
- The tests aren't TDD in disguise.

