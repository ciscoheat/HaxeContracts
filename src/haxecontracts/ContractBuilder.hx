package haxecontracts;

import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.ExprTools;

#if macro

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

	private function findInvariants(fields : Array<Field>) : Array<Expr>
	{
		var func : ExprDef;
		// Find the invariant first
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
		
		if (invariantMethod == null) return [];
		
		var invariants = [];
		switch(func)
		{
			case EBlock(exprs):
				for (e in exprs)
				{
					switch(e)
					{
						case macro haxecontracts.Contract.invariant($a), macro Contract.invariant($a):
							invariants.push(a);
						case _:
							Context.error("The invariant method can only contain Contract.invariant calls.", e.pos);
					}
				}
				
			case _:
				Context.error("The invariant method must have a function body.", invariantMethod.pos);
		}
		
		return invariants;
	}
	
	private function isPublic(f : Field) : Bool
	{
		return Lambda.exists(f.access, function(a) { return a == Access.APublic; } );
	}
	
	private function findFields(fields : Array<Field>) : Array<Field>
	{
		var output = [];
		var accessors = [];
		var fieldNames = new Map<String, Field>();
		
		for (f in fields)
		{			
			switch(f.kind)
			{
				case FProp(getter, setter, _, _):
					if (getter == "get")
						accessors.push("get_" + f.name);
					if (setter == "set")
						accessors.push("set_" + f.name);
						
				case FFun(_):
					if (isPublic(f))
						output.push(f);
					else
						fieldNames.set(f.name, f);
						
				case _:
			}
		}
	
		for (a in accessors)
			output.push(fieldNames.get(a));
				
		return output;
	}
	
	private var invariantMethod : Field;
	
	public function execute() : Array<Field>
	{
		var fields = Context.getBuildFields();
		var outputFields = [];
		var invariants = findInvariants(fields);
				
		for(field in findFields(fields))
		{
			var f = getFunction(field);
			if (f != null)
			{
				// The constructor has no invariants. This makes it simpler
				// to use Contract.invariant statements, not having to worry about
				// "this" in the constructor.
				new FunctionRewriter(f, field.name == "new" ? [] : invariants).execute();
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
	var invariants : Array<Expr>;
	var returns : Bool;
	
	public function new(f : Function, invariants : Array<Expr>)
	{
		rebind(f, invariants);
	}

	private function rebind(f, invariants)
	{
		start = true;
		firstBlock = true;
		returns = false;
		ensures = [];
		this.f = f;
		this.invariants = invariants;
	}
	
	public function execute()
	{
		if (f.expr != null)
		{
			switch(f.expr.expr)
			{
				case EBlock(exprs):
					rebind(f, invariants);
					for (e in exprs) 
						rewriteRequires(e);
						
					if (!returns && (invariants.length > 0 || ensures.length > 0))
					{
						for (e in ensures)
							exprs.push(e);
							
						for (e in invariants)
							exprs.push(e);
					}
				case _:
					// Ignore functions without a body
			}
		}
	}
	
	private function test(e : Expr)
	{
		if (!start) 
			Context.error("Contract checks can only be made in the beginning of a method.", e.pos);
	}
	
	private function requiresBlockStr(a : Expr, message : String) : ExprDef
	{
		var e = macro if(!$a) throw new haxecontracts.ContractException($v{message});
		return e.expr;
	}

	private function requiresBlock(a : Expr, b : Expr) : ExprDef
	{
		var e = macro if(!$a) throw new haxecontracts.ContractException($b);
		return e.expr;
	}

	private function ensuresBlock(e : Expr) : ExprDef
	{
		var copy = [];
		for (i in invariants)
		{
			copy.push({expr: requiresBlockStr(i, Std.string(e.pos)), pos: e.pos});
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
				if (ensures.length > 0 || invariants.length > 0)
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
