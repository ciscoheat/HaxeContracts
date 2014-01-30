package haxecontracts;

import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.ExprTools;

#if macro

// A map for the Expr and its message (null = use pos)
private typedef Invariants = Map<Expr, Expr>;

class ContractBuilder
{
	@macro public static function build() : Array<Field>
	{
		return new ContractBuilder().execute();
	}
	
	static function getFunction(field : Field)
	{		
		return switch(field.kind)
		{
			case FFun(f): f;
			case _: null;
		}
	}
	
	private function new()
	{
		
	}

	private function findInvariants(fields : Array<Field>) : Invariants
	{
		var func : ExprDef;
		
		// Find the invariant method first, if it exists
		for (field in fields)
		{
			//if (Lambda.exists(field.meta, function(m) { return m.name == "trace"; } )) trace(field);
			
			if (Lambda.exists(field.meta, function(m) { return m.name == "invariant"; } ))
			{
				switch(field.kind)
				{
					case FFun(f): func = f.expr.expr;
					case _: Context.error("The invariant field must be a method.", field.pos);						
				}
				
				if (invariantMethod != null)
					Context.error("There can only be one invariant method definition per class.", field.pos);
					
				invariantMethod = field;
			}
		}
		
		var invariants = new Invariants();
		if (invariantMethod == null) return invariants;
		
		switch(func)
		{
			// Extract the invariant conditions from the method.
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
							Context.error("The invariant method can only contain Contract.invariant calls.", e.pos);
					}
				}
				
			case _:
				Context.error("The invariant method must have a function body.", invariantMethod.pos);
		}
		
		return invariants;
	}
	
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
	
	private function isPublic(f : Field) : Bool
	{
		return Lambda.exists(f.access, function(a) { return a == Access.APublic; } );
	}
	
	// Find fields that can contain Contract expressions.
	private function findFields(fields : Array<Field>) : Map<Field, Bool>
	{
		var output = new Map<Field, Bool>();
		var fieldNames = new Map<String, Field>();
		var accessors = [];
		
		for (f in fields)
		{
			if (f == invariantMethod) continue;
			
			switch(f.kind)
			{
				case FProp(getter, setter, _, _):
					if (isPublic(f))
					{
						// Property accessors methods are ok
						if (getter == "get")
							accessors.push("get_" + f.name);
						if (setter == "set")
							accessors.push("set_" + f.name);
					}
						
				case FFun(_):
					// Public methods are ok
					if (isPublic(f))
						output.set(f, true);
					else
						output.set(f, false);
						fieldNames.set(f.name, f);
						
				case _:
			}
		}
	
		// Set accessors to ok here, now when we know their names.
		for (a in accessors)
			output.set(fieldNames.get(a), true);
				
		return output;
	}
	
	private var invariantMethod : Field;
	
	public function execute() : Array<Field>
	{
		var fields = Context.getBuildFields();
		var invariants = findInvariants(fields);
		var usedFields = findFields(fields);
				
		// usedFields points to a Bool, whether it's allowed or not with Contract expressions there.
		for(field in usedFields.keys())
		{
			var f = getFunction(field);
			if (f != null)
			{
				new FunctionRewriter(f, invariants, usedFields.get(field)).execute();
			}					
		}
				
		if (invariantMethod != null)
			fields.remove(invariantMethod);

		return fields;
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
	var allowed : Bool;
	
	public function new(f : Function, invariants : Invariants, allowed : Bool)
	{
		rebind(f, invariants, allowed);
	}

	private function rebind(f, invariants, allowed)
	{
		start = true;
		firstBlock = true;
		returns = false;
		ensures = [];
		
		this.f = f;
		this.invariants = invariants;
		this.allowed = allowed;
	}
	
	public function execute()
	{
		if (f.expr != null)
		{
			switch(f.expr.expr)
			{
				case EBlock(exprs):
					rebind(f, invariants, allowed);
					for (e in exprs) 
						rewriteRequires(e);
						
					if (!returns && (!Lambda.empty(invariants) || ensures.length > 0))
					{
						var lastPos = exprs[exprs.length - 1].pos;
						
						for (e in ensures)
							exprs.push({expr: requiresBlockStr(e, Std.string(lastPos)), pos: lastPos});
							
						for (e in invariants.keys())
						{
							var message = invariants.get(e);
							if(message == null)
								exprs.push( { expr: requiresBlockStr(e, Std.string(lastPos)), pos: lastPos } );
							else
								exprs.push( { expr: requiresBlock(e, message), pos: lastPos } );
						}
					}
				case _:
					// Ignore functions without a body
			}
		}
	}
	
	private function test(e : Expr)
	{
		if (!allowed)
			Context.error("Contract checks can only be made in public methods or property accessors.", e.pos);
			
		if (!start) 
			Context.error("Contract checks can only be made in the beginning of a method.", e.pos);
	}
	
	private function requiresBlockStr(a : Expr, message : String) : ExprDef
	{
		var e = macro if (!$a) throw new haxecontracts.ContractException($v{message});
		return e.expr;
	}

	private function requiresBlock(a : Expr, b : Expr) : ExprDef
	{
		var e = macro if (!$a) throw new haxecontracts.ContractException($b);
		return e.expr;
	}

	private function ensuresBlock(e : Expr) : ExprDef
	{
		var copy = [];
		for (i in invariants.keys())
		{
			var message = invariants.get(i);
			if(message == null)
				copy.push({expr: requiresBlockStr(i, Std.string(e.pos)), pos: e.pos});
			else 
				copy.push({expr: requiresBlock(i, message), pos: e.pos});
		}
		
		copy.push(macro var __contract_output = $e);
		for (ensure in ensures)
		{
			replaceResult(ensure);
			copy.push(ensure);
		}
		copy.push(macro return __contract_output);
				
		return EBlock(copy);
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
		switch(e.expr)
		{
			case EReturn(r):
				start = false;
				returns = true;
				if (ensures.length > 0 || !Lambda.empty(invariants))
				{
					e.expr = EReturn( { expr: ensuresBlock(r), pos: r.pos } );
				}
				return;
				
			case _:
		}
		
		switch(e)
		{
			case macro haxecontracts.Contract.requires($a), macro Contract.requires($a):
				test(e);
				e.expr = requiresBlockStr(a, Std.string(a.pos));

			case macro haxecontracts.Contract.requires($a, $b), macro Contract.requires($a, $b):
				test(e);
				e.expr = requiresBlock(a, b);
				
			case macro haxecontracts.Contract.ensures($a), macro Contract.ensures($a):
				test(e);
				ensures.push({expr: requiresBlockStr(a, Std.string(a.pos)), pos: e.pos});
				e.expr = EBlock([]);

			case macro haxecontracts.Contract.ensures($a, $b), macro Contract.ensures($a, $b):
				test(e);
				ensures.push({expr: requiresBlock(a, b), pos: e.pos});
				e.expr = EBlock([]);
								
			case _: 
				start = false;
				e.iter(rewriteRequires);
		}
	}
}

#end
