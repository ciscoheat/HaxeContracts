package haxecontracts;
import haxe.CallStack;
import haxe.PosInfos;

class ContractException
{
	public var message(default, null) : String;
	public var object(default, null) : Dynamic;
	public var arguments(default, null) : Array<Dynamic>;
	public var pos(default, null) : PosInfos;
	public var callStack(default, null) : Array<StackItem>;
	public var innerException(default, null) : Null<Dynamic>;

	public function new(message = "", object : Dynamic = null, arguments : Array<Dynamic> = null, ?innerException : Dynamic, ?p : PosInfos)
	{
		this.message = message;
		this.object = object;
		this.arguments = arguments == null ? [] : arguments;
		this.pos = p;
		this.callStack = [];
		this.innerException = innerException;
		
		for (s in CallStack.callStack()) switch s {
			case FilePos(_, file, _) if (file != "haxecontracts/ContractException.hx"):
				callStack.push(s);
			case _:
		}
	}
	
	public function toString()
	{
		var innerEx = innerException == null ? "" : ': ' + Std.string(innerException);
		return message + 
			' (${pos.fileName}:${pos.lineNumber}$innerEx) ' + 
			Std.string(arguments) + 
			(object != null ? " " + Std.string(object) : "");
	}
}