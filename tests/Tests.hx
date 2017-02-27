import haxecontracts.ContractException;
import haxecontracts.HaxeContracts;
import haxecontracts.example.Rational;

import haxecontracts.Contract.assert;

using buddy.Should;

class Tests extends buddy.SingleSuite {
    public function new() {
        // A test suite:
        describe("HaxeContracts", {
			
			describe("Testing a Rational number class", {
				var rational : Rational;
	
				beforeEach({
					rational = new Rational(12, 6);
				});
	
				it("should create a rational number properly", {
					rational.toFloat().should().beCloseTo(2, 0);
				});
	
				it("should be able to set the denominator of the rational number", {
					rational.denominator = 3;
					rational.toFloat().should.beCloseTo(4, 0);
				});
	
				it("should throw a ContractException when setting the denominator to zero", {
					(function() rational.denominator = 0).should().throwType(ContractException);				
				});
				
				it("should throw a ContractException when creating a rational number where the denominator to zero", {
					(function() new Rational(12, 0)).should().throwType(ContractException);
				});
			});
			
			it("should be able to import the static Contract functions", {
				(function() new SpecialFeatures().test(0)).should().throwType(ContractException);
				new SpecialFeatures().test(11).should.be(12);
			});
			
			it("should have a useful collection of data in the ContractException", {
				var exception = (function() new SpecialFeatures(true).test(11)).should().throwType(ContractException);
				
				exception.arguments.length.should.be(1);
				exception.arguments[0].should.be(11);
				
				exception.object.failEnsures.should.be(true);
				exception.message.should.contain("result > x");
				exception.pos.className.should.be("SpecialFeatures");
				exception.callStack.should.not.be(null);
			});
			
			it("should be able to hold invariants.", {
				(function() new SpecialFeatures().fail()).should().throwType(ContractException);
			});
			
			it("should test invariants in methods returning Void", {
				(function() new SpecialFeatures().returnVoidTest()).should().throwType(ContractException);
			});
			
			it("should test original arguments with Contract.old", {
				var o = new SpecialFeatures(); 
				var anon = { name: "test" };
				
				o.testingOld(10, anon).should.be(11);
				anon.name.should.be("Something else");
				
				(function() o.testingOldWithVoid()).should.not.throwAnything();
			});
			
			// PHP can't catch fatal errors, so things like date.getHours() doesn't work if date is null.
			// CPP crashes on null access.
			#if (!php && !cpp)
			it("should guard against exceptions in contract conditions", {
				(function() new SpecialFeatures().testingNullRef(null)).should.throwType(ContractException);
			});
			#end
        });
    }
}