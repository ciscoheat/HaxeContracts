package haxecontracts;

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
}