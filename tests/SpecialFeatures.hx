package;

import haxecontracts.*;

class SpecialFeatures implements HaxeContracts
{
	public function new() { }

	public function test(x : Int) {
		requires(x > 10);
		return x + 1;
	}
}