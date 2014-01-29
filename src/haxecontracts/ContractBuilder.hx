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
	
	public function execute() : Array<Field>
	{
		var fields = Context.getBuildFields();
		var outputFields = [];
		
		var invariantMethod : Field;
		
		for(field in fields)
		{
			var f = getFunction(field);
			if (f == null) 
			{
				outputFields.push(field);
				continue;
			}
					
			new FunctionRewriter(f).execute();
			outputFields.push(field);
		}
		
		return outputFields;
	}
}

private class FunctionRewriter
{
	var f : Function;
	var start : Bool;
	var firstBlock : Bool;
	var ensures : Array<Expr>;
	
	public function new(f : Function)
	{
		this.f = f;
	}

	private function rebind(f)
	{
		start = true;
		firstBlock = true;
		ensures = [];
		this.f = f;
	}
	
	public function execute()
	{
		if (f.expr != null)
		{
			switch(f.expr.expr)
			{
				case EBlock(exprs):
					rebind(f);
					for (e in exprs) 
						rewriteRequires(e);
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
	
	private function requiresBlock(a : Expr, b : Expr) : ExprDef
	{
		var e = macro if(!$a) throw new haxecontracts.ContractException($b);
		return e.expr;
	}

	private function ensuresBlock(e : Expr) : ExprDef
	{
		var copy = ensures.copy();
		copy.push(e);
		
		return EBlock(copy);
	}
	
	private function rewriteRequires(e : Expr) : Void
	{		
		switch(e.expr)
		{
			case EReturn(r):
				start = false;
				e.expr = EReturn({expr: ensuresBlock(r), pos: r.pos});
				return;
				
			case _:
		}
		
		switch(e)
		{
			case macro haxecontracts.Contract.requires($a), macro Contract.requires($a):
				test(e);
				e.expr = requiresBlock(a, macro "");

			case macro haxecontracts.Contract.requires($a, $b), macro Contract.requires($a, $b):
				test(e);
				e.expr = requiresBlock(a, b);
				
			case macro haxecontracts.Contract.ensures($a), macro Contract.ensures($a):
				test(e);
				ensures.push({expr: requiresBlock(a, macro ""), pos: e.pos});
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
