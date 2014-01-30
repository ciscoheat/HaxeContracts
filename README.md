# HaxeContracts - Unit's Bane

A [Design by contract](http://en.wikipedia.org/wiki/Design_by_contract) library for Haxe.

Heavily inspired by [Microsoft Code Contracts](http://research.microsoft.com/en-us/projects/contracts/), with a few code convention changes like camelCase and better use of Haxe's type inference.

## Proof-of-concept

```actionscript
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
        Contract.invariant(this.denominator != 0);
    }
}
```
The above class will be transformed into:
```actionscript
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
            return __contract_output;
        }
    }
}
```

## Unit's Bane?

Glad you asked! Since the downsides of TDD are getting [more and more obvious](http://www.sigs.de/download/oop_09/Coplien%20Nmo1.pdf) (pg. 6-9), Design by Contract is an alternative that combined with a system architecture like [DCI](https://github.com/ciscoheat/haxedci-example) could be the end of the massive test-driven reign. Testing today is mainly a consequence of lack of overview. First we have the Unit level, which is rather contained, and TDD becomes a "throw as much input as possible into this class". Doesn't this sound a little bit tedious? (Could be fun for a discrete math-loving nerd, but let's not be navel-gazing. We code mainly for others.)

What we need to know are the boundaries of the public class interface, in another word the *Contract* of the class. Then we can let a machine figure the input variations and test it automatically. Contracts gives us a way. For some promising work in this area, check out [Pex](http://research.microsoft.com/en-us/projects/Pex/) and have some fun with its interactive testing site, [Pex for fun](http://www.pexforfun.com/).

A more interesting testing area for system architects is system behavior. Unfortunately behavior is spread out through classes, making it very hard to grasp the polymorphic, abstract mess that "OO code" usually evolves into. Today, system architecture is rather class-oriented than object-oriented, since there is no easy way to reason about object behavior and collaboration. And that's usually where the bugs are... (Sorry, another design pattern won't simplify either.)

This invisible elephant of a problem has forced programmers to create bloated testing harnesses, often with a (slowly deteriorating) codebase the same size as the application itself. But the time has come for the computer engineers to realize the underlying problem, instead of getting excited over the next slick testing tool. The rest of the world demands it, and unless you program alone in your spare time, the rest of the world probably pays you for doing a good job, in good time.

In other words, it's time to let go of the manual, cumbersome, semi-static contract checking that TDD is. The computer should do that job, not a poor stressed-out programmer!

### What about options?

Do we have options? Someone has to test that everything works, right? Well, apart from good old QA, BDD is gaining ground, which is a step up from TDD. Just make sure that

- Tests are written by someone else than the programmer
- The tests aren't TDD in disguise.

For the first point, it's time to ignore the code and focus on *behavior*. Domain knowledge is more important than code knowledge here, which is the main reason a domain expert or stakeholder should do the tests, of course. But if you are alone on the project or other constraints puts you in the role of "Tester", you have to step out of the programmers shoes for a while.

The second point is more obvious. Don't use the nice fluent syntax of a BDD library to write Unit tests. It's also more subtle; the good thing about BDD is that it's taking tests to a higher level. Specifications are detailed and low-level though, so BDD may not be expressive/convenient enough to cover the whole complexity of the system. We don't want to turn BDD into "throw as much input as possible into this system." TDD in disguise, right?

This is where [DCI](https://github.com/ciscoheat/haxedci-example) makes its entry, as a real solution to the above described problems that we see in many system architectures. We finally get to reason about system behavior in a specific Context. No polymorphism or layers of abstractions, just object collaboration as seen at runtime. And those collaborating objects are protected by their Contract specifications.

Do we have a winner? :) Time will tell! I hope that I made a good enough case for you to consider this a viable alternative. Maybe you're also exhausted by writing and manipulating an ever-growing series of tests. It forced me to look for alternatives, perhaps it'll be the same for you? Let me know! I'm always available at ciscoheat [AT] gmail [DOT] com.
