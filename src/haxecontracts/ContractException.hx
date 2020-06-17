package haxecontracts;
import haxe.CallStack;
import haxe.PosInfos;

class ContractException
{
	public var message(default, null) : String;
	public var object(default, null) : Null<Dynamic>;
	public var arguments(default, null) : Null<Array<Dynamic>>;
	public var pos(default, null) : Null<PosInfos>;
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
		var posMsg = if(pos == null) "" else '${pos.fileName}:${pos.lineNumber}';

		return message + 
			' ($posMsg$innerEx) ' + 
			Std.string(arguments == null ? "" : arguments) + 
			(object != null ? " " + Std.string(object) : "");
	}
}