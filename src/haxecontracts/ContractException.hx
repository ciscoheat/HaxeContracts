package haxecontracts;
import haxe.CallStack;
import haxe.macro.Expr.Position;
import haxe.PosInfos;

class ContractException
{
	public var message(default, null) : String;
	public var object(default, null) : Dynamic;
	public var callStack(default, null) : Array<StackItem>;

	public function new(message = "", object : Dynamic = null)
	{
		this.message = message;
		this.object = object;
		this.callStack = [];
		
		for (s in CallStack.callStack())
		{
			switch(s)
			{
				case FilePos(_, file, _):
					if (file == "haxecontracts/ContractException.hx") continue;
				case _:
			}
			
			callStack.push(s);
		}
	}
	
	public function toString()
	{
		return message + " (" + Std.string(object) + ")";
	}
}