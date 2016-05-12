# HaxeContracts - Unit's Bane

A [Design by contract](http://en.wikipedia.org/wiki/Design_by_contract) library for Haxe.

Heavily inspired by [Microsoft Code Contracts](http://research.microsoft.com/en-us/projects/contracts/), with a few code convention changes like camelCase and better use of Haxe's type inference.

And of course everything contract-related in software started with [Eiffel](https://en.wikipedia.org/wiki/Eiffel_(programming_language)) and [Design by contract](https://en.wikipedia.org/wiki/Design_by_contract) by Bertrand Meyer. Thank you!

## Download and Install

Install via [haxelib](http://haxe.org/doc/haxelib/using_haxelib): `haxelib install HaxeContracts` (Note the UpperCased characters)

Then add `-lib HaxeContracts` in your hxml.

## Usage & Tutorial

You use contracts while designing your classes, so let's design a `Rational` class as a tutorial how to use the library.

A rational number is quite simple: It is expressed by a quotient: numerator/denominator. The denominator cannot be zero. Lets model a class based on that, and we'll add the two imports required for HaxeContracts:

```haxe
package;
import haxecontracts.*;

class Rational implements HaxeContracts {
    public var numerator(default, default) : Int;
    public var denominator(default, default) : Int;

    public function new(numerator : Int, denominator : Int) {
        this.numerator = numerator;
        this.denominator = denominator;
    }
    
    public function toFloat() {
        return numerator / denominator;
    }
}
```
There we have the basics, a class implementing `haxecontracts.HaxeContracts`. Now let's consider the important rule: The denominator cannot be zero. Using Contracts, we can enforce this.

When adding a *Contract condition*, which is simply a Boolean statement, the first step is usually to consider a few things:

- Is this an *invariant* condition? I.e, must it always be true for the entire lifetime of the object?
- Must this condition be true before we enter a method *(precondition)*, or when we return *(postcondition)*?

### Preconditions

Starting with the constructor, the `denominator` parameter cannot be zero, which is a precondition. You add that with the `Contract.requires` method:

```haxe
public function new(numerator : Int, denominator : Int) {
    Contract.requires(denominator != 0);
    
    this.numerator = numerator;
    this.denominator = denominator;
}
```

### Postconditions

That was quite simple, and not so much difference from an if-statement that throws an exception. Postconditions however gives more insight to the power of Contracts. As you may have noticed the class properties are public, so someone can set the denominator to zero after instantiation. Setting aside how "correct" that is, our job is again to enforce the rule. There is no way of adding Contract conditions to default properties however, so we must use accessors, a `set_denominator` method:

```haxe
class Rational implements HaxeContracts {
    public var numerator(default, default) : Int;
    public var denominator(default, set) : Int;

    public function new(numerator : Int, denominator : Int) {
        Contract.requires(denominator != 0);
        
        this.numerator = numerator;
        this.denominator = denominator;
    }
    
    private function set_denominator(v : Int) {
        Contract.ensures(Contract.result != 0);
        
        return denominator = v;
    }    
}
```
This is more interesting. We're using `Contract.ensures` to define the postcondition, and also `Contract.result` to test the actual return value. The condition goes on top of the method, as all conditions are, but in reality `Contract.ensures` will be called right before the method returns, checking this time that nobody is breaking the denominator rule.

### Invariants

You may have realized it already, but the denominator rule is actually an invariant. No matter what happens to our `Rational` objects, the denominator cannot be zero. So we can plan for the future and save code at the same time by making an *invariant method:*

```haxe
@invariants function invariants() {
    Contract.invariant(denominator != 0, "Denominator cannot be zero.");
}
```

All invariant conditions will be tested as postconditions to every public method, and public properties with get/set accessor methods.

Two things to remember for the invariant method:

1. Mark it with `@invariants` (the method name can be anything)
1. Call `Contract.invariant` in the same way as pre/postconditions. (`Contract.result` cannot be used in invariants, naturally.)

As a bonus we added a text message after the condition. All `Contract` methods have this feature, so you can describe the rules straight away.

(Note: For technical reasons the `toString` method is excluded from invariants.)

### Old

`Contract.old` is used to test if the original method arguments conforms to some condition. It can only be used within `Contract.ensures`. A common usage is to test if some counter has been increased, for example:

```haxe
public function counter(i : Int) : Int {
    Contract.ensures(Contract.old(i) == Contract.result - 1);
    return i + 1;
}
```

### The finished class

A final touch: It's possible to skip the static `Contract` class name, keeping only the method calls.

This essentially reserves the words `requires`, `ensures`, `invariant`, `old` and `result` in a class implementing `HaxeContracts`. It's quite convenient when you've memorized the API, but if you don't like "magic methods", or this creates a problem with existing method names or variables, you can disable it. See the "Compilation flags" section further below for instructions how to do that.

Here's our completed Rational class:

```haxe
import haxecontracts.*;

class Rational implements HaxeContracts {
    public var numerator(default, default) : Int;   
    public var denominator(default, set) : Int;

    public function new(numerator : Int, denominator : Int) {
        requires(denominator != 0);
        
        this.numerator = numerator;
        this.denominator = denominator;
    }
    
    public function toFloat() : Float {
        return numerator / denominator;
    }
    
    private function set_denominator(d : Int) {
        ensures(result != 0);
        
        return denominator = d;
    }

    @invariants function invariants() {
        invariant(denominator != 0, "Denominator cannot be zero");
    }
}
```

(The calls to `requires` and `ensures` are redundant because of the invariant in this simple example, but keeping them to show the syntax.)

## Contract violations

When a condition fails, a `haxecontracts.ContractException` object is created and thrown. It has some useful properties:

- `message` - The error message from the Contract call.
- `object` - A reference to the object where the condition failed.
- `callStack` - A stack trace.

Since it's an exception it can be caught, but be aware: **Don't catch the ContractException for anything but logging purposes!** Jon Skeet [explains it very well](http://stackoverflow.com/a/2640011/70894), but in short, contract violations puts the system in an invalid state, which can propagate to other parts of the system unless it shuts down quickly. Catch it high up in the stack, log it somewhere, then rethrow or exit as gracefully as possible.

## Quick API reference

`Contract.requires(condition : Bool, ?message : String)` <br>
Specifies a requirement (precondition). Executed at the beginning of the method.
<hr>

`Contract.ensures(condition : Bool, ?message : String)` <br>
Ensures a final condition (postcondition). Executed right before the method returns.
<hr>

`Contract.invariant(condition : Bool, ?message : String)` <br>
A condition that must hold throughout the object's lifetime. Executed right before every public method returns, including public properties with accessor methods.
<hr>

`Contract.result` <br>
Refers to the return value of the method. Can only be used within `Contract.ensures`.
<hr>

`Contract.old(arg : Dynamic)` <br>
Refers to the original value of the current method argument `arg`. Can only be used within `Contract.ensures`.
<hr>

`Contract.assert(condition : Bool, ?message : String, ?objectRef : Dynamic)` <br>
A general assertion that can be placed anywhere in the code.
<hr>

### Imports and implements

Any class calling `haxecontracts.Contract` must implement `haxecontracts.HaxeContracts`, except when using only `Contract.assert`.

All API methods except `Contract.assert` can be used without the static `Contract` class. If this creates a problem with existing method names or variables, see below for how to disable it.

If you want to use `assert` in the same way, just import it normally: `import haxecontracts.Contract.assert;`.

### Compilation flags

Flag (-D) | Effect
--- | ---
contracts-disabled | Disables the whole Contract code generation
contracts-preconditions-only | Disables Contract code generation, except for preconditions (on method entry)
contracts-no-imports | If the Contract method names conflicts with existing fields or variables, this flag disables it, and you must use the static `Contract` class explicitly.

Please note that disabling contracts as above doesn't affect the `Contract.assert` method. It's a general assertion, not a contract bound to an object or method.

## Why "Unit's Bane?"

Glad you asked! Since the downsides of TDD and unit testing are getting [more](http://www.rbcs-us.com/documents/Why-Most-Unit-Testing-is-Waste.pdf) and [more](http://www.rbcs-us.com/documents/Segue.pdf) obvious, Design by Contract is an alternative that combined with a system architecture like [DCI](https://github.com/ciscoheat/haxedci-example) and higher-level testing could be the end of the test-driven reign. The massive testing focus we see today is mostly a consequence of fundamental limitations in the software architectural model.

In testing terms, we have the unit level, which quickly becomes a "throw as much input as possible into this method". A bit tedious, don't you think? (Could be fun for a discrete math-loving nerd, but let's not be navel-gazing. We code mainly for others.) Also, since the tests frequently only concerns single methods we're not far from stepping back from OO to plain old procedural thinking (Pascal, Fortran).

Machines can handle this level much better. If we know the boundaries of the public class interface, in another word the *Contract* of the class, we can let a program figure out the input variations and test it automatically. Contracts gives us a way. For some promising work in this area, check out [Pex](http://research.microsoft.com/en-us/projects/Pex/) and its interactive testing site, [Pex for fun](http://www.pexforfun.com/).

A much more interesting testing level for system architects is system behavior, since the interesting stuff (for users and stakeholders) happens *between* objects. Unfortunately in the current software "object" model, behavior is spread out through classes, making it very hard to grasp the polymorphic, abstract mess that "OO code" usually evolves into. System architecture today is actually class-oriented rather than object-oriented, since we only see the class structure; there is no easy way to reason about object behavior and collaboration. And that's usually where the bugs are... (Yet another design pattern won't simplify either, sorry.)

This elephant in the room has forced programmers to create bloated testing harnesses, often with a deteriorating codebase the same size as the application itself. Unit testing is a cumbersome, semi-static contract checking that slowly drags the project down. 

In other words, the time has come for computer engineers to realize the underlying problem, instead of getting excited over the next slick testing tool. The rest of the world demands it, and unless you program alone in your spare time, the rest of the world probably pays you for doing a good job, in good time.

### Are there any options?

We have to test that things work, right? Apart from good old QA, usually performed through [exploratory testing](https://en.wikipedia.org/wiki/Exploratory_testing), [BDD](https://en.wikipedia.org/wiki/Behavior-driven_development) is gaining ground, which is a step up from TDD. Just make sure that

- Tests are written by someone else than the programmer
- The tests aren't TDD in disguise.

For the first point, it's needed because tests usually becomes a self-fulfilling prophecy. If the programmer writes the tests they *will* pass, or he/she will make it so. Secondly, it's important to ignore the code and focus on *behavior*. Domain knowledge is more important than code knowledge here, which is the main reason a domain expert or stakeholder should write the tests. But if you are alone on the project or other constraints puts you in the role of "tester", you have to step out of the programmers shoes for a while.

The second point is more obvious. Don't use the nice fluent syntax of a BDD library to write unit tests. It's also more subtle; the good thing about BDD is that we're taking tests to a higher level. Specifications can be detailed and low-level though, so BDD may not be expressive/convenient enough to cover the whole complexity of the system. We don't want to turn BDD into "throw as much input as possible into this system." Unit testing in disguise, right?

This is where [DCI](https://github.com/ciscoheat/haxedci-example) makes its entry, as a real solution to the above described problems that we see in many system architectures. We finally get to reason about system behavior in a specific Context. No polymorphism or layers of abstractions, just object collaboration as seen at runtime. (And those collaborating objects are protected by their Contract specifications!)

Hopefully I made a good enough case for you to consider Contracts and BDD a viable alternative to TDD and most unit testing, and DCI a whole new level of architecture. Writing and manipulating an ever-growing series of tests forced me to look for alternatives, maybe it'll be the same for you? Let me know! I'm always available at ciscoheat [AT] gmail [DOT] com.

## More Design by Contract information

- https://www.eiffel.org/doc/eiffel/ET%3A%20Design%20by%20Contract%20%28tm%29%2C%20Assertions%20and%20Exceptions
- https://www.eiffel.com/values/design-by-contract/introduction/
- http://c2.com/cgi/wiki?DesignByContract
- http://www.minddriven.de/index.php/technology/dot-net/code-contracts/comparison-of-dbc-and-tdd-part-1
- http://research.microsoft.com/en-us/projects/contracts/
