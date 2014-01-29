package haxecontracts;

/**
 * ...
 * @author ciscoheat
 */
class ContractException
{
	public var message(default, null) : String;

	public function new(message = "") 
	{
		this.message = message;
	}	
}