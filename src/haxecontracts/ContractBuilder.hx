package haxecontracts;

import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.ExprTools;

#if macro

// A map for the invariant Exprs and their description (null = no description specified)
private typedef Invariants = Map<Expr, Expr>;

class ContractBuilder
{
	@macro public static function build() : Array<Field>
	{
		return new ContractBuilder().buildContracts();
	}
	
	private static function getFunction(field : Field)
	{		
		return switch(field.kind)
		{
			case FFun(f): f;
			case _: null;
		}
	}
	
	private var invariants : Invariants;
	
	private function new()
	{
		// Can only be instantiated from the macro.
		invariants = new Invariants();
	}

	private function findInvariants(fields : Array<Field>) : Array<Field>
	{
		var keepFields = new Array<Field>();
		
		// Find the invariant method (metadata @invariant)
		for (field in fields)
		{			
			if (!Lambda.exists(field.meta, function(m) { return m.name == "invariant"; } ))
			{
				keepFields.push(field);
			}
			else
			{
				// Skip if no contracts are generated.
				if (Context.defined("nocontracts")) continue;
				
				var func : ExprDef;

				switch(field.kind)
				{
					case FFun(f): func = f.expr.expr;
					case _: Context.error("The invariant field must be a method.", field.pos);						
				}
				
				switch(func)
				{
					// Extract the invariant conditions from the method.
					// Note that only the expression itself is extracted, so it must be wrapped in an 
					// if-statement or similar to be used propertly.
					case EBlock(exprs):
						for (e in exprs)
						{
							switch(e)
							{
								case macro haxecontracts.Contract.invariant($a, $b), macro Contract.invariant($a, $b):
									#if !nocontractwarnings
									if (!selfRef(a, false))
										Context.warning("An invariant expression doesn't refer to 'this'.", e.pos);
									#end
									invariants.set(a, b);
									
								case macro haxecontracts.Contract.invariant($a), macro Contract.invariant($a):
									#if !nocontractwarnings
									if (!selfRef(a, false))
										Context.warning("An invariant expression doesn't refer to 'this'.", e.pos);
									#end
									invariants.set(a, null);
								case _:
									Context.error("An invariant method can only contain Contract.invariant calls.", e.pos);
							}
						}
						
					case _:
						Context.error("An invariant method must have a function body.", field.pos);
				}
			}
		}
		
		return keepFields;
	}
	
	/**
	 * Test if an expression refers to "this".
	 */
	private function selfRef(e : Expr, output : Bool) : Bool
	{
		switch(e.expr)
		{
			case EConst(c):
				switch(c)
				{
					case CIdent(s): if (s == "this") return true;
					case _: 
				}
			case _:
		}
		
		e.iter(function(e2) { output = selfRef(e2, output); } );
		return output;
	}
	
	private static function isPublic(f : Field) : Bool
	{
		return Lambda.exists(f.access, function(a) { return a == Access.APublic; } );
	}

	private static function isStatic(f : Field) : Bool
	{
		return Lambda.exists(f.access, function(a) { return a == Access.AStatic; } );
	}

	/**
	 * Return a Map of Fields depending on whether they should contain Contract invariants.
	 */
	private function findContractFields(fields : Array<Field>) : Map<Field, Bool>
	{
		var output = new Map<Field, Bool>();
		var fieldNames = new Map<String, Field>();
		var accessors = [];
		
		for (f in fields)
		{
			// Adding invariants to toString seems to create problems with circular references, so it is disabled.
			if (f.name == "toString") continue;
			
			switch(f.kind)
			{
				case FProp(getter, setter, _, _):
					if (isPublic(f) && !isStatic(f))
					{
						// Property accessors methods are ok
						if (getter == "get")
							accessors.push("get_" + f.name);
						if (setter == "set")
							accessors.push("set_" + f.name);
					}
						
				case FFun(_):
					// Public instance methods are ok
					if (isPublic(f) && !isStatic(f))
						output.set(f, true);
					else
						output.set(f, false);
						fieldNames.set(f.name, f);
						
				case _:
			}
		}
	
		// Set accessors to allowed here, now when we know their names.
		for (a in accessors)
			output.set(fieldNames.get(a), true);
				
		return output;
	}
		
	public function buildContracts() : Array<Field>
	{
		var keepFields = findInvariants(Context.getBuildFields());
		var contractFields = findContractFields(keepFields);
		var noInvariants = new Invariants();
				
		// usedFields points to a Bool, signaling if the method is public or not.
		// (property accessors are treated as public)
		for(field in contractFields.keys())
		{
			var f = getFunction(field);
			if (f != null)
			{
				new FunctionRewriter(f, contractFields.get(field) ? invariants : noInvariants, isStatic(field)).rewrite();
			}					
		}
				
		return keepFields;
	}
}

private class FunctionRewriter
{
	var f : Function;
	var start : Bool;
	var firstBlock : Bool;
	var ensures : Array<Expr>;
	var invariants : Invariants;
	var returns : Bool;
	var isStatic : Bool;
	
	public function new(f : Function, invariants : Invariants, isStatic : Bool)
	{
		rebind(f, invariants, isStatic);
	}

	private function rebind(f, invariants, isStatic)
	{
		start = true;
		firstBlock = true;
		returns = false;
		ensures = [];
		
		this.f = f;
		this.invariants = invariants;
		this.isStatic = isStatic;
	}
	
	public function rewrite()
	{
		if (f.expr != null)
		{
			switch(f.expr.expr)
			{
				case EBlock(exprs):
					rebind(f, invariants, isStatic);
					
					for (e in exprs) 
						rewriteRequires(e);
						
					if (Context.defined("nocontracts")) return;
					
					if (!returns && exprs.length > 0)
					{
						// If method didn't return, apply postconditions to end of method.
						var lastPos = exprs[exprs.length - 1].pos;
						
						for (e in ensures)
							exprs.push(e);
						
						for (e in invariants.keys())
						{
							var message = invariants.get(e);
							if(message == null)
								exprs.push(contractBlock(e, "Contract invariant failed.", lastPos));
							else
								exprs.push(contractBlockExpr(e, message, lastPos));
						}						
					}
				case _:
					// Ignore functions without a body
			}
		}
	}
	
	private function testValidPosition(e : Expr)
	{
		if (!start) Context.error("Contract checks can only be made in the beginning of a method.", e.pos);
	}
	
	private function contractBlock(condition : Expr, message : String, pos : Position) : Expr
	{
		var messageExpr = { expr: EConst(CString(message)), pos: pos };
		return contractBlockExpr(condition, messageExpr, pos);
	}
	
	private function contractBlockExpr(condition : Expr, messageExpr : Expr, pos : Position) : Expr
	{	
		var thisRef = { expr: EConst(CIdent(isStatic ? "null" : "this")), pos: pos};
		var e = EIf({expr: EUnop(OpNot, false, condition), pos: pos}, {expr:
			EThrow({
				expr: ENew( {
					name: "ContractException", 
					pack: ["haxecontracts"], 
					params: []
		}, [messageExpr, thisRef]), pos: pos } ), pos: pos}, null);
		
		return {expr: e, pos: pos};
	}

	private function ensuresBlock(e : Expr, pos : Position) : Expr
	{
		var copy = [];
		
		for (i in invariants.keys())
		{
			var message = invariants.get(i);
			if(message == null)
				copy.push(contractBlock(i, "Contract postcondition failed.", pos));
			else 
				copy.push(contractBlockExpr(i, message, pos));
		}
		
		copy.push(macro var __contract_output = $e);
		for (ensure in ensures)
		{
			replaceResult(ensure);
			copy.push(ensure);
		}
		copy.push(macro return __contract_output);
		
		return {expr: EBlock(copy), pos: pos};
	}
	
	// Replace Contract.result with __contract_output
	private function replaceResult(e : Expr)
	{
		switch(e)
		{
			case macro haxecontracts.Contract.result, macro Contract.result:
				var exp = macro __contract_output;
				e.expr = exp.expr;
			case _:
				e.iter(replaceResult);
		}
	}
	
	private function rewriteRequires(e : Expr) : Void
	{
		// This can be defined before the actual Contract rewrite because it's not allowed
		// to return before a Contract definition.
		if (!Context.defined("nocontracts"))
		{
			switch(e.expr)
			{
				case EReturn(r):
					start = false;
					returns = true;
					if (ensures.length > 0 || !Lambda.empty(invariants))
					{
						e.expr = EReturn(ensuresBlock(r, e.pos));
					}
					return;
					
				case _:
			}
		}
		
		var emptyDef = EConst(CIdent("null"));
		
		switch(e)
		{
			case macro haxecontracts.Contract.requires($a), macro Contract.requires($a):
				testValidPosition(e);
				if (Context.defined("nocontracts"))
					e.expr = emptyDef;
				else
					e.expr = contractBlock(a, "Contract precondition failed.", e.pos).expr;

			case macro haxecontracts.Contract.requires($a, $b), macro Contract.requires($a, $b):
				testValidPosition(e);
				if (Context.defined("nocontracts"))
					e.expr = emptyDef;
				else
					e.expr = contractBlockExpr(a, b, e.pos).expr;
				
			case macro haxecontracts.Contract.ensures($a), macro Contract.ensures($a):
				testValidPosition(e);				
				if (!Context.defined("nocontracts"))
					ensures.push( { expr: contractBlock(a, "Contract postcondition failed.", e.pos).expr, pos: e.pos } );

				e.expr = emptyDef;

			case macro haxecontracts.Contract.ensures($a, $b), macro Contract.ensures($a, $b):
				testValidPosition(e);
				if (!Context.defined("nocontracts"))
					ensures.push( { expr: contractBlockExpr(a, b, e.pos).expr, pos: e.pos } );
					
				e.expr = emptyDef;

			case macro haxecontracts.Contract.invariant($a, $b), macro Contract.invariant($a, $b):
				Context.error("Contract.invariant calls are only allowed in methods marked with @invariant.", e.pos);
				
			case macro haxecontracts.Contract.invariant($a), macro Contract.invariant($a):
				Context.error("Contract.invariant calls are only allowed in methods marked with @invariant.", e.pos);

			case _: 
				start = false;
				e.iter(rewriteRequires);
		}
	}
}

#end
