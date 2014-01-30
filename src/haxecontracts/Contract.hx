package haxecontracts;
import haxe.PosInfos;

class Contract
{
	private static var implementationError = 
	"A class calling haxecontracts.Contract must implement haxecontracts.HaxeContracts";
	
	/**
	 * Specifies a requirement (precondition). Executed at the beginning of the method.
	 * @param	condition Expression that must be true for the contract to hold.
	 * @param	message Optional message that will be displayed if condition fails.
	 */
	public static function requires(condition : Bool, message = "") : Void
	{
		throw implementationError;
	}
	
	/**
	 * Ensures a final condition (postcondition). Executed right before the method returns.
	 * @param	condition Expression that must be true for the contract to hold
	 * @param	message Optional message that will be displayed if condition fails.
	 */
	public static function ensures(condition : Bool, message = "") : Void
	{
		throw implementationError;
	}

	/**
	 * A condition that must hold throughout the object's lifetime. Executed right before every public method returns, including public properties with accessor methods.
	 * @param	condition Expression that must be true for the contract to hold
	 * @param	message Optional message that will be displayed if condition fails.
	 */
	public static function invariant(condition : Bool, message = "") : Void
	{
		throw implementationError;
	}

	/**
	 * Refers to the return value of the method. Can only be used in postconditions.
	 */
	public static var result(get, never) : Dynamic;
	
	private static function get_result() : Dynamic 
	{
		throw implementationError;
		return false;
	}
	
	/**
	 * A general assertion that can be placed anywhere in the code. For contract assertions, use requires or ensures.
	 * @param	condition Expression that must evaluate to true.
	 * @param	message Optional message that will be displayed if condition fails.
	 * @param	?p Automatic position information.
	 */
	public static function assert(condition : Bool, message = "Assert failed", ?p : PosInfos) : Void
	{
		if(!condition) throw new ContractException(Std.string(p), message);
	}
}