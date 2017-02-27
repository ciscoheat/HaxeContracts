package haxecontracts;

import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.ExprTools;
using Lambda;

#if macro

@:enum private class ContractLevel {
	public static var disabled = 0;
	public static var preconditions = 1;
	public static var all = 2;
}

// A map for the invariant Exprs and their description (null = no description specified)
private typedef Invariants = Map<Expr, Expr>;

class ContractBuilder
{
	@macro public static function build() : Array<Field>
	{
		contractLevel = 
			if (Context.defined("nocontracts") || Context.defined("no-contracts") || Context.defined("contracts-disabled"))
				ContractLevel.disabled
			else if (Context.defined("contracts-preconditions-only") || Context.defined("contracts-only-preconditions"))
				ContractLevel.preconditions
			else
				ContractLevel.all;
				
		importStaticKeywords = !Context.defined("no-contracts-imports") && !Context.defined("contracts-no-imports");
				
		return new ContractBuilder().buildContracts();
	}
	
	public static function objectRefToThis(objectRef : Expr) : Expr {
		return if(objectRef.expr.equals(EConst(CIdent("null")))) {
			try {
				Context.typeof(macro this);
				macro this;
			} catch (e : Dynamic) {
				objectRef;
			}
		} else objectRef;		
	}	
	
	public static var contractLevel(default, null) : Int;
	public static var importStaticKeywords(default, null) : Bool;
	
	private static function getFunction(field : Field)
	{		
		return switch(field.kind)
		{
			case FFun(f): f;
			case _: null;
		}
	}
	
	private var invariants : Invariants;
	
	private function new() {
		invariants = new Invariants();
	}

	private function findInvariants(fields : Array<Field>) : Array<Field>
	{
		var keepFields = new Array<Field>();
		
		// Find the invariant method (metadata @invariant)
		for (field in fields)
		{			
			if (!field.meta.exists(function(m) { return m.name == "invariant" || m.name == "invariants"; } ))
			{
				keepFields.push(field);
			}
			else
			{
				// Skip if no contracts are generated.
				if (contractLevel < ContractLevel.all) continue;
				
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
									invariants.set(a, b);
									
								case macro haxecontracts.Contract.invariant($a), macro Contract.invariant($a):
									invariants.set(a, null);

								case (macro invariant($a, $b)) if (importStaticKeywords):
									invariants.set(a, b);

								case (macro invariant($a)) if (importStaticKeywords):
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
		
	private static function isPublic(f : Field) return f.access.exists(function(a) return a == Access.APublic);
	private static function isStatic(f : Field) return f.access.exists(function(a) return a == Access.AStatic);

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
				case FProp(getter, _, _, _):
					if ((getter == "get" || getter == "set") && isPublic(f) && !isStatic(f))
					{
						// Property getters and setters are ok
						accessors.push(getter + "_" + f.name);
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
		{
			// Test for method existance to prevent a confusing compiler error 
			// which happens when a property accessor is missing.
			if(fieldNames.exists(a))
				output.set(fieldNames.get(a), true);
		}
				
		return output;
	}
		
	public function buildContracts() : Array<Field>
	{
		if (Context.defined("display")) {
			if (!importStaticKeywords) return null;
			
			var fields = Context.getBuildFields();
			for (f in fields) switch f.kind {
				case FFun(f) if(f.expr != null):
					autoComplete(f.expr);
				case _:
			}
			return fields;
		}
		
		var keepFields = findInvariants(Context.getBuildFields());
		var contractFields = findContractFields(keepFields);
		var noInvariants = new Invariants();
				
		// usedFields points to a Bool, signaling if the method is public or not.
		// (property accessors are treated as public)
		for(field in contractFields.keys())	{
			var f = getFunction(field);
			if (f != null && f.expr != null) {
				new FunctionRewriter(f, contractFields.get(field) ? invariants : noInvariants, isStatic(field)).rewrite();
			}					
		}
				
		return keepFields;
	}
	
	function autoComplete(e : Expr) {
		switch e.expr {
			case EDisplay(e2, isCall) if(isCall): switch e2.expr {
				case EConst(CIdent(s)) if(s == "requires" || s == "ensures" || s == "invariant" || s == "old"):
					e2.expr = (macro $p{['haxecontracts', 'Contract', s]}).expr;
				case _:
			}
			case _:
		}
		e.iter(autoComplete);
	}
}

private class FunctionRewriter
{
	var f : Function;
	var start : Expr;
	var ensures : Array<Expr>;
	var invariants : Invariants;
	var returnsValue : Bool;
	var isStatic : Bool;
	
	var hasOld : Array<Expr>;
	var oldExpr : Expr;
	
	public function new(f : Function, invariants : Invariants, isStatic : Bool)
	{
		this.returnsValue = false;
		this.ensures = [];		
		this.f = f;
		this.invariants = invariants;
		this.isStatic = isStatic;

		this.hasOld = [];
		this.oldExpr = {
			expr: EObjectDecl([for (arg in f.args) { field: arg.name, expr: macro $i{arg.name} }]),
			pos: f.expr.pos
		};
	}
	
	public function rewrite()
	{
		if (f.expr == null) return;

		switch(f.expr.expr) {
			case EBlock(exprs):
				this.returnsValue = if(exprs.length == 0) false else exprs[exprs.length - 1].expr.getName() == "EReturn";
				
				for (e in exprs) 
					rewriteRequires(e);
					
				if (ContractBuilder.contractLevel < ContractLevel.all) return;
				
				if (!this.returnsValue && exprs.length > 0) {
					// If method didn't return, apply postconditions to end of method.
					var lastPos = exprs[exprs.length - 1].pos;
					
					for (e in ensures)
						exprs.push(e);
					
					for (e in invariants.keys()) {
						var message = invariants.get(e);
						if(message == null)
							exprs.push(contractBlock(e, "Contract invariant failed", lastPos));
						else
							exprs.push(contractBlockExpr(e, message, lastPos));
					}
				}
				
				var i = 0;
				for (oldExpr in hasOld) {
					var varName = '__contract_old_' + (i++);
					exprs.unshift(macro var $varName = $oldExpr);
				}
			case _:
				// Ignore functions without a body
		}
	}
	
	private function testValidPosition(e : Expr)
	{
		if (start != null) Context.error("Contract checks can only be made in the beginning of a method.", start.pos);
	}
	
	private function contractBlock(condition : Expr, message : String, pos : Position) : Expr
	{
		message += ' for: [${condition.toString()}]';
		var messageExpr = macro $v{message};

		return contractBlockExpr(condition, messageExpr, pos);
	}
	
	private function contractBlockExpr(condition : Expr, messageExpr : Expr, pos : Position) : Expr
	{	
		var thisRef = { expr: EConst(CIdent(isStatic ? "null" : "this")), pos: pos };
		
		// Create an array of identifiers from the method arguments
		var arguments = macro $a{f.args.map(function(a) return macro $i{a.name})};
		
		return macro try if (!($condition)) throw false catch (e : Dynamic)
			@:pos(condition.pos) throw new haxecontracts.ContractException($messageExpr, $thisRef, $arguments, Std.is(e, Bool) ? null : e);
	}

	private function ensuresBlock(returnValue : Expr, pos : Position) : Expr
	{
		var copy = [];
		
		for (i in invariants.keys())
		{
			var message = invariants.get(i);
			if(message == null) {
				copy.push(contractBlock(i, "Contract invariant failed", pos));
			}
			else 
				copy.push(contractBlockExpr(i, message, pos));
		}
		
		if(this.returnsValue)
			copy.push(macro var __contract_output = $returnValue);
		
		for (ensure in ensures) {
			replaceResult(ensure);
			replaceOld(ensure);
			copy.push(ensure);
		}
		
		if(this.returnsValue)
			copy.push(macro __contract_output);
		else if(returnValue != null)
			copy.push(macro return $returnValue);
		else
			copy.push(macro return);
		
		return {expr: EBlock(copy), pos: pos};
	}
	
	// Replace Contract.result with __contract_output
	private function replaceResult(e : Expr)
	{
		switch(e)
		{
			case (macro result) if (ContractBuilder.importStaticKeywords):
				var exp = macro __contract_output;
				e.expr = exp.expr;
			case macro haxecontracts.Contract.result, macro Contract.result:
				var exp = macro __contract_output;
				e.expr = exp.expr;
			case _:
				e.iter(replaceResult);
		}
	}

	private function replaceOld(e : Expr)
	{
		function setOldExpr(a : Expr) {
			var varName = '__contract_old_' + this.hasOld.length;
			
			e.expr = EConst(CIdent(varName));
			this.hasOld.push(a);
		}
		
		switch(e) {
			case (macro old($a)) if (ContractBuilder.importStaticKeywords):
				setOldExpr(a);
				
			case macro haxecontracts.Contract.old($a), macro Contract.old($a):
				setOldExpr(a);
				
			case _:
				e.iter(replaceOld);
		}
	}

	private function testIfNotOld(e : Expr)
	{
		var error = "Contract.old can only be called within Contract.ensures";
		
		switch(e) {
			case (macro old($a)) if (ContractBuilder.importStaticKeywords):
				Context.error(error, e.pos);
				
			case macro haxecontracts.Contract.old($a), macro Contract.old($a):
				Context.error(error, e.pos);
				
			case _:
				e.iter(testIfNotOld);
		}
	}

	private function rewriteRequires(e : Expr) : Void
	{
		// This can be defined before the actual Contract rewrite because it's not allowed
		// to return before a Contract definition.
		if (ContractBuilder.contractLevel == ContractLevel.all) switch e.expr {
			case EFunction(_, _): 
				// Skip inner functions, they should not have the invariants appended.
				return;
			
			case EReturn(r):
				start = e;
				
				if (ensures.length > 0 || !invariants.empty()) {
					if (returnsValue) e.expr = EReturn(ensuresBlock(r, e.pos));
					else e.expr = ensuresBlock(r, e.pos).expr;
				}
				return;
				
			case _:
		}
		
		var emptyDef = EConst(CIdent("null"));
		
		if(ContractBuilder.importStaticKeywords) switch(e) {
			case macro requires($a): e.expr = (macro Contract.requires($a)).expr;
			case macro requires($a, $b): e.expr = (macro Contract.requires($a, $b)).expr;
			case macro ensures($a): e.expr = (macro Contract.ensures($a)).expr;
			case macro ensures($a, $b): e.expr = (macro Contract.ensures($a, $b)).expr;
			case macro invariant($a): e.expr = (macro Contract.invariant($a)).expr;
			case macro invariant($a, $b): e.expr = (macro Contract.invariant($a, $b)).expr;
			case _:
		}
		
		switch(e)
		{
			case macro haxecontracts.Contract.requires($a), macro Contract.requires($a):
				testValidPosition(e);
				testIfNotOld(a);
				if (ContractBuilder.contractLevel < ContractLevel.preconditions)
					e.expr = emptyDef;
				else {
					e.expr = contractBlock(a, 'Contract precondition failed', e.pos).expr;
				}

			case macro haxecontracts.Contract.requires($a, $b), macro Contract.requires($a, $b):
				testValidPosition(e);
				testIfNotOld(a);
				testIfNotOld(b);
				if (ContractBuilder.contractLevel < ContractLevel.preconditions)
					e.expr = emptyDef;
				else
					e.expr = contractBlockExpr(a, b, e.pos).expr;
				
			case macro haxecontracts.Contract.ensures($a), macro Contract.ensures($a):
				testValidPosition(e);
				
				if (ContractBuilder.contractLevel == ContractLevel.all)
					ensures.push( { expr: contractBlock(a, 'Contract postcondition failed', e.pos).expr, pos: e.pos } );

				e.expr = emptyDef;

			case macro haxecontracts.Contract.ensures($a, $b), macro Contract.ensures($a, $b):
				testValidPosition(e);
				
				if (ContractBuilder.contractLevel == ContractLevel.all)
					ensures.push( { expr: contractBlockExpr(a, b, e.pos).expr, pos: e.pos } );
					
				e.expr = emptyDef;

			case macro haxecontracts.Contract.invariant($a, $b), macro Contract.invariant($a, $b):
				testIfNotOld(a);
				testIfNotOld(b);
				Context.error("Contract.invariant calls are only allowed in methods marked with @invariant.", e.pos);
				
			case macro haxecontracts.Contract.invariant($a), macro Contract.invariant($a):
				testIfNotOld(a);
				Context.error("Contract.invariant calls are only allowed in methods marked with @invariant.", e.pos);

			case _:
				switch(e.expr) {
					case EVars(_): // defining a var before contracts is ok to prevent macro conflicts.
					case _:
						start = e;
						e.iter(rewriteRequires);
				}
		}
	}
}

#end
