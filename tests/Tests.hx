import haxecontracts.ContractException;
import haxecontracts.example.Rational;

import haxecontracts.Contract.assert;

using buddy.Should;

class Tests extends buddy.SingleSuite {
    public function new() {
        // A test suite:
        describe("Using Buddy", {
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
			
			it("should be able to import the static Contract functions", {
				(function() new SpecialFeatures().test(0)).should().throwType(ContractException);
				(function() new SpecialFeatures(true).test(11)).should().throwType(ContractException);
				new SpecialFeatures().test(11).should.be(12);
			});
			
			it("should be able to hold invariants.", {
				(function() new SpecialFeatures().fail()).should().throwType(ContractException);
			});			
        });
    }
}