package haxecontracts;
import haxe.CallStack;
import haxe.PosInfos;

class ContractException
{
	public var message(default, null) : String;
	public var object(default, null) : Dynamic;
	public var pos(default, null) : PosInfos;
	public var callStack(default, null) : Array<StackItem>;

	public function new(message = "", object : Dynamic = null, ?p : PosInfos)
	{
		this.message = message;
		this.object = object;
		this.pos = p;
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
		return message + " (" + (pos.fileName + ":" + pos.lineNumber) + ")" + (object != null ? " " + Std.string(object) : "");
	}
}