import haxecontracts.Contract;

class SpecialFeatures implements haxecontracts.HaxeContracts
{
	var failEnsures : Bool;
	var alwaysTrue : Bool;
	var positionInMethod : Int = 0;
	var toggleState : Bool = false; // testingOld
	
	public function new(failEnsures = false) {
		this.failEnsures = failEnsures;
		this.alwaysTrue = true;
	}

	public function test(x : Int) {
		requires(x > 10);
		ensures(result > x);
		
		return failEnsures ? x : x + 1;
	}
	
	public function fail() {
		alwaysTrue = false;
	}
	
	public function returnVoidTest() : Void {
		requires(positionInMethod == 0);
		if (positionInMethod > 0) return;
		positionInMethod = 2;
	}
	
	public function testingOld(a : Int, b : {name: String}) {
		ensures(old(a) == result-1);
		Contract.ensures(Contract.old(b) == b);
		
		Contract.ensures(Contract.old(this.toggleState) != toggleState);
		Contract.ensures(Contract.old(toggleState) != this.toggleState);
		Contract.ensures(Contract.old(this.toggleState) != this.toggleState);
		Contract.ensures(Contract.old(toggleState) != toggleState);

		Contract.ensures(Contract.result == old(a + 1));
		
		a++;
		b.name = "Something else";
		toggleState = !toggleState;
		
		Contract.assert(b.name != null);
		
		return a;
	}
	
	public function testingOldWithVoid() : Void {
		Contract.ensures(Contract.old(toggleState) != toggleState);
		toggleState = !toggleState;
	}
	
	public function testingNullRef(d : Date) {
		requires(d.getHours() > 20);
	}
	
	@invariant function invariants() {
		invariant(alwaysTrue == true);
		invariant(positionInMethod == 0);
	}
}