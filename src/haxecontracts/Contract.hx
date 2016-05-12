package haxecontracts;
#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.ExprTools;
import haxe.PosInfos;
#end

class Contract
{
	private static var implementationError = 
		"A class calling haxecontracts.Contract must implement haxecontracts.HaxeContracts";
	
	/**
	 * Specifies a requirement (precondition). Executed at the beginning of the method.
	 * @param	condition Expression that must be true for the contract to hold.
	 * @param	message Optional message that will be displayed if condition fails.
	 */
	public static function requires(condition : Bool, message = "Contract precondition failed.") : Void
	{
		throw implementationError;
	}
	
	/**
	 * Ensures a final condition (postcondition). Executed right before the method returns.
	 * @param	condition Expression that must be true for the contract to hold
	 * @param	message Optional message that will be displayed if condition fails.
	 */
	public static function ensures(condition : Bool, message = "Contract postcondition failed.") : Void
	{
		throw implementationError;
	}

	/**
	 * A condition that must hold throughout the object's lifetime. Executed right before every public method returns, 
	 * including public properties with accessor methods. Can only be used in methods marked with @invariant.
	 * @param	condition Expression that must be true for the contract to hold
	 * @param	message Optional message that will be displayed if condition fails.
	 */
	public static function invariant(condition : Bool, message = "Contract invariant failed.") : Void
	{
		throw implementationError;
	}

	/**
	 * Refers to the return value of the method. Can only be used in postconditions (ensures).
	 */
	public static var result(get, never) : Dynamic;
	
	private static function get_result() : Dynamic 
	{
		throw implementationError;
		return false;
	}

	/**
	 * Refers to the original value of a current method parameter. Can only be used in postconditions (ensures).
	 */
	public static function old(a : Dynamic) : Dynamic
	{
		throw "Contract.old can only be called within Contract.ensures";
		return false;
	}

	/**
	 * A general assertion that can be placed anywhere in the code. For contract assertions, use requires or ensures.
	 * @param	condition Expression that must evaluate to true.
	 * @param	message Optional message that will be displayed if condition fails.
	 * @param	objectRef Optional object that caused the assert violation.
	 */
	macro public static function assert(condition : ExprOf<Bool>, ?message : Expr, ?objectRef : Expr)
	{
		var objectRef = ContractBuilder.objectRefToThis(objectRef);
		
		message.expr = switch message.expr {
			case EConst(CIdent("null")):
				EConst(CString('Assertion failed for: [' + ExprTools.toString(condition) + ']'));
			case _:
				message.expr;
		};
		
		return macro if (!$condition) throw new haxecontracts.ContractException($message, $objectRef);
	}	
}