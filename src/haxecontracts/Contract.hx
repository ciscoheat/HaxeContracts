package haxecontracts;
import haxe.PosInfos;

class Contract
{
	private static var implementationError = 
	"A class calling haxecontracts.Contract must implement haxecontracts.HaxeContracts";
	
	public static function requires(condition : Bool, requirement = "") : Void
	{
		throw implementationError;
	}
	
	public static function ensures(condition : Bool, requirement = "") : Void
	{
		throw implementationError;
	}

	public static function invariant(condition : Bool, requirement = "") : Void
	{
		throw implementationError;
	}

	public static var result(get, never) : Dynamic;
	
	private static function get_result() : Dynamic 
	{
		throw implementationError;
		return false;
	}
	
	public static function assert(condition : Bool, requirement = "Contract.assert failed", ?p : PosInfos) : Void
	{
		if(!condition) throw new ContractException(Std.string(p), requirement);
	}
}