# HaxeContracts - Unit's Bane

A [Design by contract](http://en.wikipedia.org/wiki/Design_by_contract) library for Haxe.

Heavily inspired by [Microsoft Code Contracts](http://research.microsoft.com/en-us/projects/contracts/), with a few code convention changes like camelCase and better use of Haxe's type inference.

## Download and Install
Install via [haxelib](http://haxe.org/doc/haxelib/using_haxelib):
`haxelib install HaxeContracts`

Then add `-lib HaxeContracts` to your hxml or in [FlashDevelop](http://www.flashdevelop.org/).

## Usage

You use contracts while designing your classes, so let's design a `Rational` class that will show how to use the library.

A rational number is quite simple: It is expressed by a quotient: numerator/denominator. The denominator cannot be zero. Lets model a class based on that, and we add the two imports we will use for HaxeContracts:
```actionscript
package;
import haxecontracts.HaxeContracts;
import haxecontracts.Contract;

class Rational implements HaxeContracts {
    public var numerator(default, default) : Int;
    public var denominator(default, default) : Int;

    public function new(int numerator, int denominator) {
        this.numerator = numerator;
        this.denominator = denominator;
    }
    
    public function toFloat() {
        return numerator / denominator;
    }
}
```
There we have the basics, a class implementing `haxecontracts.HaxeContracts`. Now let's consider the important rule: The denominator cannot be zero. Using Contracts, we can enforce this.

When adding a *Contract condition*, which is simply a Boolean statement, it's useful to consider a few things:

- Is this an *invariant* condition? I.e, must it always be true for the entire lifetime of the object?
- Must this condition be true before we enter a method *(precondition)*, or when we return *(postcondition)*?

### Preconditions

Starting with the constructor, the `denominator` parameter cannot be zero, which is a precondition. You add that with the `Contract.requires` method:

```actionscript
public function new(int numerator, int denominator) {
    Contract.requires(denominator != 0);
    
    this.numerator = numerator;
    this.denominator = denominator;
}
```

### Postconditions

That was quite simple, and not much difference from an if-statement that throws an exception, but postconditions gives more insight to the power of Contracts. As you may have noticed the class properties are public, so someone can set the denominator to zero after instantiation. Our job is again to prevent that, enforcing the rule. There is no way of adding Contract conditions to default properties however, so we must use accessors, a `set_denominator` method:
```actionscript
class Rational implements HaxeContracts {
    public var numerator(default, default) : Int;
    public var denominator(default, set) : Int;

    public function new(int numerator, int denominator) {
        Contract.requires(denominator != 0);
        
        this.numerator = numerator;
        this.denominator = denominator;
    }
    
	private function set_denominator(v : Int) {
        Contract.ensures(Contract.result != 0);
        
        return _denominator = v;
    }    
}
```
This is a bit more interesting. We're using `Contract.ensures` to define the postcondition, and also `Contract.result` to test the actual return value. The condition goes on top of the method, as all conditions are, but in reality `Contract.ensures` will be called right before the method returns, checking this time that nobody is breaking the denominator rule.

### Invariants

You may have realized it already, but the denominator rule is actually an invariant. No matter what happens to our `Rational` objects, the denominator cannot be zero. So we can plan for the future and save code at the same time by making an *invariant method:*
```actionscript
@invariant private function objectInvariant() {
    Contract.invariant(this.denominator != 0, "Denominator cannot be zero.");
}
```
A few things to remember here:

1. Mark the method with `@invariant`
1. Call `Contract.invariant` in the same way as the others. (`Contract.result` cannot be used in invariants, naturally.)
1. You must refer to one or more class fields using `this`, otherwise a warning will be issued.

As a bonus we added a text message after the condition. All `Contract` methods have this feature, so you can describe the rules straight away.

### The finished class

```actionscript
package ;
import haxecontracts.HaxeContracts;
import haxecontracts.Contract;

class Rational implements HaxeContracts {
    public var numerator(default, default) : Int;	
    public var denominator(default, set) : Int;

    public function new(numerator : Int, denominator : Int) {
        Contract.requires(denominator != 0);
        
        this.numerator = numerator;
        this.denominator = denominator;
    }
	
	public function toFloat() : Float {
		return numerator / denominator;
	}
	
	private function set_denominator(d : Int) {
		Contract.ensures(Contract.result != 0);
        
        return denominator = d;
    }

    @invariant private function objectInvariant() {
        Contract.invariant(this.denominator != 0, "Denominator cannot be zero");
    }
}
```
(The call to `Contract.requires` in the constructor is redundant because of the invariant, but keeping it to show the syntax.)

### Contract violations

When a condition fails, a `haxecontracts.ContractException` object is created and thrown. It has some useful properties:

- `message` - The error message from the Contract call.
- `object` - A reference to the object where the condition failed.
- `callStack` - A stack trace.

Since it's an exception it can be caught, but be aware: **Don't catch the ContractException for anything but logging purposes!** Jon Skeet [explains it very well](http://stackoverflow.com/a/2640011/70894), but in short, contract violations puts the system in an invalid state, which can become a real mess unless the system shuts down quickly. Catch it high up in the stack, log it somewhere, then rethrow or exit as gracefully as possible.

## Quick API reference

`Contract.requires(condition : Bool, message : String)` - Specifies a requirement (precondition). Executed at the beginning of the method.

`Contract.ensures(condition : Bool, message : String)` - Ensures a final condition (postcondition). Executed right before the method returns.

`Contract.invariant(condition : Bool, message : String)` - A condition that must hold throughout the object's lifetime. Executed right before every public method returns, including public properties with accessor methods.

`Contract.result` - Refers to the return value of the method. Can only be used within `Contract.ensures`.

`Contract.assert(condition : Bool, message : String, objectRef : Dynamic)` - A general assertion that can be placed anywhere in the code.

Any class calling `Contract` must implement `haxecontracts.HaxeContracts` (Except when using only `Contract.assert`).

## Why "Unit's Bane?"

Glad you asked! Since the downsides of TDD are getting [more and more obvious](http://www.sigs.de/download/oop_09/Coplien%20Nmo1.pdf) (pg. 6-9), Design by Contract is an alternative that combined with a system architecture like [DCI](https://github.com/ciscoheat/haxedci-example) could be the end of the test-driven reign. The massive testing focus we see today is mainly a consequence of fundamental limitations in the software architectural model. In testing terms, first we have the Unit level, which quickly becomes a "throw as much input as possible into this class". A little bit tedious, don't you think? (Could be fun for a discrete math-loving nerd, but let's not be navel-gazing. We code mainly for others.)

Actually, if we know the boundaries of the public class interface, in another word the *Contract* of the class, we can let a machine figure out the input variations and test it automatically. Contracts gives us a way. For some promising work in this area, check out [Pex](http://research.microsoft.com/en-us/projects/Pex/) and its interactive testing site, [Pex for fun](http://www.pexforfun.com/).

A much more interesting testing level for system architects is system behavior. Unfortunately in the current software "object" model, behavior is spread out through classes, making it very hard to grasp the polymorphic, abstract mess that "OO code" usually evolves into. Today, system architecture is actually class-oriented rather than object-oriented since we only see the class structure; there is no easy way to reason about object behavior and collaboration. And that's usually where the bugs are... (Yet another design pattern won't simplify either, sorry.)

This elephant in the room has forced programmers to create bloated testing harnesses, often with a deteriorating codebase the same size as the application itself. TDD is a cumbersome, semi-static contract checking that slowly drags the project down. In other words, the time has come for the computer engineers to realize the underlying problem, instead of getting excited over the next slick testing tool. The rest of the world demands it, and unless you program alone in your spare time, the rest of the world probably pays you for doing a good job, in good time.

### Are there any options?

We have to test that everything works, right? Well, apart from good old QA, BDD is gaining ground, which is a step up from TDD. Just make sure that

- Tests are written by someone else than the programmer
- The tests aren't TDD in disguise.

For the first point, it's time to ignore the code and focus on *behavior*. Domain knowledge is more important than code knowledge here, which is the main reason a domain expert or stakeholder should write the tests, of course. But if you are alone on the project or other constraints puts you in the role of "tester", you have to step out of the programmers shoes for a while.

The second point is more obvious. Don't use the nice fluent syntax of a BDD library to write Unit tests. It's also more subtle; the good thing about BDD is that we're taking tests to a higher level. Specifications can be detailed and low-level though, so BDD may not be expressive/convenient enough to cover the whole complexity of the system. We don't want to turn BDD into "throw as much input as possible into this system." TDD in disguise, right?

This is where [DCI](https://github.com/ciscoheat/haxedci-example) makes its entry, as a real solution to the above described problems that we see in many system architectures. We finally get to reason about system behavior in a specific Context. No polymorphism or layers of abstractions, just object collaboration as seen at runtime. And those collaborating objects are protected by their Contract specifications.

Hopefully I made a good enough case for you to consider Contracts a viable alternative to TDD, and DCI a whole new level of architecture. Writing and manipulating an ever-growing series of tests forced me to look for alternatives, maybe it'll be the same for you? Let me know! I'm always available at ciscoheat [AT] gmail [DOT] com.
