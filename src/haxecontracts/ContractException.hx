package haxecontracts;
import haxe.macro.Expr.Position;
import haxe.PosInfos;

class ContractException
{
	public var message(default, null) : String;
	public var pos(default, null) : String;

	public function new(pos : String, message = "")
	{
		this.pos = pos;
		this.message = message;
	}
	
	public function toString()
	{
		var end = "[" + pos + "]";
		return message != null && message.length > 0
			? message + " " + end
			: end;
	}
}