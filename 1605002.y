%{

#include<bits/stdc++.h>
#include "symboltable.h"

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
FILE *myLog, *myError;
extern int line_count;
string r2d2;
vector<SymbolInfo*> dlist, pslist;
vector<string> plist, alist;

SymbolTable *table;

void printRule(string s)
{
	printf("At line %d, %s found\n", line_count, s.c_str());
}

void logP(string rule, string text)
{
	fprintf(myLog, "At line no: %d %s\n\n%s\n\n", line_count, rule.c_str(), text.c_str());
}

void errorP(string vul)
{
	fprintf(myError, "Error at Line %d: %s\n\n", line_count, vul.c_str());
}

void yyerror(char *s)
{
	//write your code
	printf("%s\n", s);
}

%}

%define api.value.type { SymbolInfo* }
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%token IF  FOR WHILE
%token INT FLOAT DOUBLE CHAR
%token RETURN VOID MAIN PRINTLN
%token ADDOP MULOP ASSIGNOP RELOP LOGICOP
%token NOT
%token SEMICOLON COMMA LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD INCOP DECOP
%token CONST_INT CONST_FLOAT ID
//%start func_declaration

%%

start: program
	{
		//write your code in this block in all the similar blocks below
	}
	;

program: program unit
		 {
			 $$ = new SymbolInfo($1->name+"\n"+$2->name, "");
			 logP("program : program unit", $$->name);
		 }
	| unit
	  {
		  $$ = new SymbolInfo($1->name, "");
		  logP("program : unit", $$->name);
	  }
	;
	
unit: var_declaration
	  {
		  $$ = new SymbolInfo($1->name, "");
		  logP("unit : var_declaration", $$->name);
	  }
     | func_declaration
	   {
		   $$ = new SymbolInfo($1->name, "");
		   logP("unit : func_declaration", $$->name);
	   }
     | func_definition
	   {
		   $$ = new SymbolInfo($1->name, "");
		   logP("unit : func_definition", $$->name);
	   }
     ;
     
func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
				  {
					  SymbolInfo *cur = table->lookup($2->name);
					  if(cur)
					  {
						  if(cur->IDType != "function")
						  	  errorP(cur->name + " redeclared as different type of symbol");
					  	  else if(plist != cur->prms)
						  	  errorP("Conflicting types for " + cur->name);
					  }
					  else
					  {
						  table->insertNode($2->name, "ID", $1->name, "function", plist);
						  
					  }

					  $$ = new SymbolInfo($1->name+" "+$2->name+"("+$4->name+");", "");
					  logP("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON", $$->name);
					  plist.clear();
					  pslist.clear();

					  //table->fprint(myLog);
				  }
		| type_specifier ID LPAREN RPAREN SEMICOLON
		  {
			  SymbolInfo *cur = table->lookup($2->name);
			  if(cur)
			  {
				  if(cur->IDType != "function")
					  errorP(cur->name + " redeclared as different type of symbol");
				  else if(plist != cur->prms)
					  errorP("Conflicting types for " + cur->name);
			  }
			  else
			  {
				  table->insertNode($2->name, "ID", $1->name, "function", plist);
			  }

			  $$ = new SymbolInfo($1->name+" "+$2->name+"();", "");
			  logP("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON", $$->name);
			  plist.clear();
			  pslist.clear();
		  }
		;
		 
func_definition: type_specifier ID LPAREN parameter_list RPAREN
				 {
					SymbolInfo *cur = table->lookup($2->name);
					  if(cur)
					  {
						  printf("%d\n", cur->isDefined);
						  if(cur->IDType != "function")
						  	  errorP(cur->name + " redeclared as different type of symbol");
					  	  else if(plist != cur->prms)
						  	  errorP("Conflicting types for " + cur->name);
						  else if(cur->isDefined)
						  	  errorP("Redefinition of "+cur->name);
						  else cur->isDefined = true;
					  }
					  else
					  {
						  table->insertNode($2->name, "ID", $1->name, "function", plist, true);
						  
					  }
				 } compound_statement
				{
					  $$ = new SymbolInfo($1->name+" "+$2->name+"("+$4->name+")"+$7->name, "");
					  logP("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement", $$->name);
					  plist.clear();
					  pslist.clear();
				}
		| type_specifier ID LPAREN RPAREN
		{
			SymbolInfo *cur = table->lookup($2->name);
			if(cur)
			{
				if(cur->IDType != "function")
					errorP(cur->name + " redeclared as different type of symbol");
				else if(plist != cur->prms)
					errorP("Conflicting types for " + cur->name);
				else if(cur->isDefined)
					errorP("Redefinition of "+cur->name);
				else cur->isDefined = true;
			}
			else
			{
				table->insertNode($2->name, "ID", $1->name, "function", plist, true);
				
			}
		} compound_statement
		{
			$$ = new SymbolInfo($1->name+" "+$2->name+"()"+$6->name, "");
			logP("func_definition : type_specifier ID LPAREN RPAREN compound_statement", $$->name);
			plist.clear();
			pslist.clear();
		}
 		;				


parameter_list: parameter_list COMMA type_specifier ID
				{
					plist.push_back($3->name);
					$4->IDType = "variable";
					$4->returnType = $3->name;
					pslist.push_back($4);

					$$ = new SymbolInfo($1->name+", "+$3->name+" "+$4->name, "");
					logP("parameter_list : parameter_list COMMA type_specifier ID", $$->name);
				}
		| parameter_list COMMA type_specifier
		{
			plist.push_back($3->name);
			SymbolInfo *tmp = new SymbolInfo("", "ID");
			tmp->IDType = "variable";
			tmp->returnType = $3->name;
			pslist.push_back(tmp);

			$$ = new SymbolInfo($1->name+", "+$3->name, "");
			logP("parameter_list : parameter_list COMMA type_specifier", $$->name);
		}
 		| type_specifier ID
		{
			plist.push_back($1->name);
			$2->IDType = "variable";
			$2->returnType = $1->name;
			pslist.push_back($2);

			$$ = new SymbolInfo($1->name+" "+$2->name, "");
			logP("parameter_list : type_specifier ID", $$->name);
		}
		| type_specifier
		{
			plist.push_back($1->name);
			SymbolInfo *tmp = new SymbolInfo("", "ID");
			tmp->IDType = "variable";
			tmp->returnType = $1->name;
			pslist.push_back(tmp);

			$$ = new SymbolInfo($1->name, "");
			logP("parameter_list : type_specifier", $$->name);
		}
 		;

 		
compound_statement: LCURL
					{
						table->enterNew(myLog);

						for(SymbolInfo *si: pslist)
						{
							if(si->name == "") errorP("Parameter name omitted");
							else
							{
								SymbolInfo *cur = table->curScope->lookup(si->name);
								if(cur) errorP("Redefintion of parameter "+si->name);
								table->insertNode(si->name, si->typ, si->returnType, si->IDType);
							}
						}
					} statements RCURL
					{
						table->fprint(myLog);
						$$ = new SymbolInfo("{\n"+$3->name+"\n}", "");
						table->exitPrev(myLog);
					}
 		    | LCURL
			{
				table->enterNew(myLog);

				for(SymbolInfo *si: pslist)
				{
					if(si->name == "") errorP("Parameter name omitted");
					else
					{
						SymbolInfo *cur = table->curScope->lookup(si->name);
						if(cur) errorP("Redefintion of parameter "+si->name);
						table->insertNode(si->name, si->typ, si->returnType, si->IDType);
					}
				}
			} RCURL
			{
				table->fprint(myLog);
				$$ = new SymbolInfo("{}", "");
				table->exitPrev(myLog);
			}
 		    ;
 		    
var_declaration: type_specifier declaration_list SEMICOLON
				 {
					 $$ = new SymbolInfo($1->name + " " + $2->name+";", "");
					 for(SymbolInfo *si: dlist)
					 {
						 SymbolInfo *cur = table->curScope->lookup(si->name);
						 si->returnType = $1->name;

						 if(cur) errorP("Redeclaration of "+si->name);
						 else
						 {
						 	table->insertNode(si->name, si->typ, si->returnType, si->IDType);
						 }
					 }

					 logP("var_declaration: type_specifier declaration_list SEMICOLON", $$->name);
					 dlist.clear();
				 }
 		 ;
 		 
type_specifier: INT
				{
					$$ = new SymbolInfo("int", "");
					logP("type_specifier: INT", $$->name);
				}
 		| FLOAT
		{
			$$ = new SymbolInfo("float", "");
			logP("type_specifier: FLOAT", $$->name);
		}
 		| VOID
		{
			$$ = new SymbolInfo("void", "");
			logP("type_specifier: VOID", $$->name);
		}
 		;
 		
declaration_list: declaration_list COMMA ID
			{
				$3->IDType = "variable";
				dlist.push_back($3);
				$$ = new SymbolInfo($1->name+", "+$3->name, "");
				logP("declaration_list : declaration_list COMMA ID", $$->name);
			}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
		    {
				$3->IDType = "array";
				dlist.push_back($3);
				$$ = new SymbolInfo($1->name+", "+$3->name+"["+$5->name+"]", "");
				logP("declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD", $$->name);
			}
 		  | ID
			{	
				$1->IDType = "variable";
				dlist.push_back($1);
				$$ = new SymbolInfo($1->name, "");
				logP("declaration_list : ID", $$->name);
			}
 		  | ID LTHIRD CONST_INT RTHIRD
		    {
				$1->IDType = "array";
				dlist.push_back($1);
				$$ = new SymbolInfo($1->name+"["+$3->name+"]", "");
				logP("declaration_list : ID LTHIRD CONST_INT RTHIRD", $$->name);
			}
 		  ;
 		  
statements: statement
		{
			$$ = new SymbolInfo($1->name, "");
			logP("statements : statement", $$->name);
		}
	   | statements statement
	    {
		    $$ = new SymbolInfo($1->name+"\n"+$2->name, "");
			logP("statements : statements statement", $$->name);
	    }
	   ;
	   
statement: var_declaration
		{
			$$ = new SymbolInfo($1->name, "");
			logP("statement : var_declaration", $$->name);
		}
	  | expression_statement
	    {
			$$ = new SymbolInfo($1->name, "");
			logP("statement : expression_statement", $$->name);
		}
	  | compound_statement
	    {
			$$ = new SymbolInfo($1->name, "");
			logP("statement : compound_statement", $$->name);
		}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	    {
			$$ = new SymbolInfo("for("+$3->name+" "+$4->name+" "+$5->name+")\n"+$7->name, "");
			logP("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement", $$->name);
		}
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	    {
			$$ = new SymbolInfo("if("+$3->name+")\n"+$5->name, "");
			logP("statement : IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE", $$->name);
		}
	  | IF LPAREN expression RPAREN statement ELSE statement
	    {
			$$ = new SymbolInfo("if("+$3->name+")\n"+$5->name+"\nelse\n"+$7->name, "");
			logP("statement : IF LPAREN expression RPAREN statement ELSE statement", $$->name);
		}
	  | WHILE LPAREN expression RPAREN statement
	    {
			$$ = new SymbolInfo("while("+$3->name+")\n"+$5->name, "");
			logP("statement : WHILE LPAREN expression RPAREN statement", $$->name);
		}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	    {
			SymbolInfo *cur = table->lookup($3->name);
			if(!cur)
			{
				errorP($3->name+" undeclared");
			}
			$$ = new SymbolInfo("println("+$3->name+");", "");
			logP("statement : PRINTLN LPAREN ID RPAREN SEMICOLON", $$->name);
		}
	  | RETURN expression SEMICOLON
	    {
			$$ = new SymbolInfo("return "+$2->name+";", "");
			logP("statement : RETURN expression SEMICOLON", $$->name);
		}
	  ;
	  
expression_statement: SEMICOLON	
				{
					$$ = new SymbolInfo(";", "");
					logP("expression_statement : SEMICOLON", $$->name);
				}		
			| expression SEMICOLON 
				{
					$$ = new SymbolInfo($1->name+";", "");
					logP("expression_statement : expression SEMICOLON", $$->name);
				}		
			;
	  
variable: ID
		{
			SymbolInfo *cur = table->lookup($1->name);
			if(!cur)
			{
				errorP($1->name+" undeclared");
				$$ = new SymbolInfo($1->name, "");
			}
			else if(cur->IDType != "variable")
			{
				errorP(cur->name+" is not a variable");
				$$ = new SymbolInfo($1->name, "");
			}
			else $$ = new SymbolInfo($1->name, "", cur->returnType);

			logP("variable : ID", $$->name);
		}
	 | ID LTHIRD expression RTHIRD
	 	{
			SymbolInfo *cur = table->lookup($1->name);
			if(!cur)
			{
				errorP($1->name+" undeclared");
				$$ = new SymbolInfo($1->name+"["+$3->name+"]", "");
			}
			else if(cur->IDType != "array")
			{
				errorP(cur->name+" is not a variable");
				$$ = new SymbolInfo($1->name+"["+$3->name+"]", "");
			}
			else
			{
				if($3->returnType != "int") errorP("Array index not integer");
				$$ = new SymbolInfo($1->name+"["+$3->name+"]", "", cur->returnType);
			}

			logP("variable : ID LTHIRD expression RTHIRD", $$->name);
		}
	 ;
	 
expression: logic_expression
		{
			$$ = new SymbolInfo($1->name, "", $1->returnType);
			logP("expression : logic_expression", $$->name);
		}
	   | variable ASSIGNOP logic_expression
	   {
		   if($1->returnType != "" && $1->returnType != $3->returnType)
		   		errorP("Oparands don't match in type");
			
			$$ = new SymbolInfo($1->name+" = "+$3->name, "", $1->returnType);
			logP("expression : variable ASSIGNOP logic_expression", $$->name);
	   }
	   ;
			
logic_expression: rel_expression
			{
				$$ = new SymbolInfo($1->name, "", $1->returnType);
				logP("logic_expression: rel_expression", $$->name);
			}	
		 | rel_expression LOGICOP rel_expression 
		 	{
				if($1->returnType == "void" || $3->returnType == "void")
				{
					errorP("void in expression");
					$$ = new SymbolInfo($1->name+" "+$2->name+" "+$3->name, "");
				}
				else
				{
					$$ = new SymbolInfo($1->name+" "+$2->name+" "+$3->name, "", "int");
				}

				logP("logic_expression : rel_expression LOGICOP rel_expression", $$->name);
			}
		 ;
			
rel_expression: simple_expression 
			{
				$$ = new SymbolInfo($1->name, "", $1->returnType);
				logP("rel_expression: simple_expression", $$->name);
			}
		| simple_expression RELOP simple_expression
			{
				if($1->returnType == "void" || $3->returnType == "void")
				{
					errorP("void in expression");
					$$ = new SymbolInfo($1->name+" "+$2->name+" "+$3->name, "");
				}
				else
				{
					$$ = new SymbolInfo($1->name+" "+$2->name+" "+$3->name, "", "int");
				}

				logP("rel_expression: simple_expression RELOP simple_expression", $$->name);
			}
		;
				
simple_expression: term
				{
					$$ = new SymbolInfo($1->name, "", $1->returnType);
					logP("simple_expression: term", $$->name);
				}
		  | simple_expression ADDOP term
		  		{
					if($1->returnType == "" || $3->returnType == "")
					{
						$$ = new SymbolInfo($1->name, "");
					}
					else
					{
						if($1->returnType == "void" || $3->returnType == "void")
						{
							$$ = new SymbolInfo($1->name+" "+$2->name+" "+$3->name, "");
							errorP("void in expression");
						}
						else
						{
							string nrt = "int";
							if($1->returnType == "float" || $3->returnType == "float") nrt = "float";

							$$ = new SymbolInfo($1->name+" "+$2->name+" "+$3->name, "", nrt);
						}
					}

					logP("simple_expression: simple_expression ADDOP term", $$->name);
				} 
		  ;
					
term:	unary_expression
	{
		$$ = new SymbolInfo($1->name, "", $1->returnType);
		logP("term : unary_expression", $$->name);
	}
     |  term MULOP unary_expression
	{
		if($1->returnType == "" || $3->returnType == "")
		{
			$$ = new SymbolInfo($1->name, "");
		}
		else
		{
			if($1->returnType == "void" || $3->returnType == "void")
			{
				$$ = new SymbolInfo($1->name+" "+$2->name+" "+$3->name, "");
				errorP("void in expression");
			}
			else if($2->name == "%" && ($1->returnType != "int" || $3->returnType != "int"))
			{
				$$ = new SymbolInfo($1->name+" "+$2->name+" "+$3->name, "");
				errorP("non-integer operand of modulus operator");
			}
			else
			{
				string nrt = "int";
				if($1->returnType == "float" || $3->returnType == "float") nrt = "float";

				$$ = new SymbolInfo($1->name+" "+$2->name+" "+$3->name, "", nrt);
			}
		}

		logP("term : term MULOP unary_expression", $$->name);
	}
     ;

unary_expression: ADDOP unary_expression
				{
					if($2->returnType == "void") 
					{
						$$ = new SymbolInfo($1->name+$2->name, "");
						errorP("void in expression");
					}
					else $$ = new SymbolInfo($1->name+$2->name, "", $2->returnType);
					
					logP("unary_expression : ADDOP unary_expression", $$->name);
				}
		 | NOT unary_expression
		 		{
					if($2->returnType == "void")
					{
						$$ = new SymbolInfo($1->name+$2->name, "");
						errorP("void in expression");
					}
					else if($2->returnType != "" && $2->returnType != "int")
					{
						$$ = new SymbolInfo($1->name+$2->name, "");
						errorP("operand of NOT not integer");
					}
					else $$ = new SymbolInfo($1->name+$2->name, "", $2->returnType);

					logP("unary_expression : NOT unary_expression", $$->name);
				}
		 | factor 
		 		{
					$$ = new SymbolInfo($1->name, "", $1->returnType);
					logP("unary_expression : factor", $$->name);
				}
		 ;
	
factor: variable
		{
			$$ = new SymbolInfo($1->name, "", $1->returnType);
			logP("factor : variable", $$->name);
		}
	| ID LPAREN argument_list RPAREN
		{
			SymbolInfo *cur = table->lookup($1->name);
			if(!cur)
			{
				errorP("Undefined reference to "+$1->name);
				$$ = new SymbolInfo($1->name+"("+$3->name+")", "");
			}
			else if(cur->IDType != "function")
			{
				errorP($1->name+" is not a function");
				$$ = new SymbolInfo($1->name+"("+$3->name+")", "");
			}
			else if(cur->prms != $3->arms)
			{
				errorP("Function argument list does not match in type");
				$$ = new SymbolInfo($1->name+"("+$3->name+")", "", cur->returnType);
			}
			else $$ = new SymbolInfo($1->name+"("+$3->name+")", "", cur->returnType);

			logP("factor : ID LPAREN argument_list RPAREN", $$->name);
		}
	| LPAREN expression RPAREN
		{
			if($2->returnType == "void")
			{
				$$ = new SymbolInfo("("+$2->name+")", "");
				errorP("void in expression");
			}
			else
			{
				$$ = new SymbolInfo("("+$2->name+")", "", $2->returnType);
			}

			logP("factor : CONST_INT", $$->name);
		}
	| CONST_INT
		{
			$$ = new SymbolInfo($1->name, "", "int");
			logP("factor : LPAREN expression RPAREN", $$->name);
		}
	| CONST_FLOAT
		{
			$$ = new SymbolInfo($1->name, "", "float");
			logP("factor : CONST_FLOAT", $$->name);
		}
	| variable INCOP
		{
			$$ = new SymbolInfo($1->name+"++", "", $1->returnType);
			logP("factor : variable INCOP", $$->name);
		} 
	| variable DECOP
		{
			$$ = new SymbolInfo($1->name+"--", "", $1->returnType);
			logP("factor : variable DECOP", $$->name);
		}
	;
	
argument_list: arguments
			{
				$$ = new SymbolInfo($1->name, "");
				$$->arms = $1->arms;
				logP("argument_list : arguments", $$->name);
			}
			  |
			{
				$$ = new SymbolInfo("", "");
				logP("argument_list : ", $$->name);
			}
			  ;
	
arguments: arguments COMMA logic_expression
		{
			if($3->returnType == "void") errorP("void in expression");
			$$ = new SymbolInfo($1->name+", "+$3->name, "");
			$$->arms = $1->arms;
			$$->arms.push_back($3->returnType);
			logP("arguments : arguments COMMA logic_expression", $$->name);
		}
	      | logic_expression
		{
			if($1->returnType == "void") errorP("void in expression");
			$$ = new SymbolInfo($1->name, "");
			$$->arms.push_back($1->returnType);
			logP("arguments : logic_expression", $$->name);
		}
	      ;
 

%%
int main(int argc,char *argv[])
{
	FILE *fp;

	table = new SymbolTable(10);

	if((fp = fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	myLog = fopen("log.txt", "w");
	myError = fopen("error.txt", "w");

	/*fp2= fopen(argv[2],"w");
	fclose(fp2);
	fp3= fopen(argv[3],"w");
	fclose(fp3);
	
	fp2= fopen(argv[2],"a");
	fp3= fopen(argv[3],"a");*/
	

	yyin=fp;
	yyparse();
	

	//fclose(fp2);
	//fclose(fp3);
	
	return 0;
}
