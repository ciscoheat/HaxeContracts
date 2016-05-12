
class SpecialFeatures implements haxecontracts.HaxeContracts
{
	var failEnsures : Bool;
	var alwaysTrue : Bool;
	
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
	
	@invariant function invariants() {
		invariant(alwaysTrue == true);
	}
}