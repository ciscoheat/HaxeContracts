import haxecontracts.Contract;

class SpecialFeatures implements haxecontracts.HaxeContracts
{
	var failEnsures : Bool;
	var alwaysTrue : Bool;
	var positionInMethod : Int = 0;
	
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
		
		a++;
		b.name = "Something else";
		
		Contract.assert(b.name != null);
		
		return a;
	}
	
	public function testingNullRef(d : Date) {
		requires(d.getHours() > 20);
	}
	
	@invariant function invariants() {
		invariant(alwaysTrue == true);
		invariant(positionInMethod == 0);
	}
}