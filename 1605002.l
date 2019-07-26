%{
#include<bits/stdc++.h>
#include "symboltable.h"
#include "y.tab.h"
#define YYSTYPE SymbolInfo*

using namespace std;

extern SymbolTable *table;
void yyerror(char *);

int line_count=1;
int error=0;


%}



digit [0-9]
letter [A-Za-z]
delim [ \t\r\f\v]
newline \n
ws [delim]+
id (_|{letter})(_|{letter}|{digit})*
integer {digit}+
number {digit}*(\.{digit}+)?(E[+-]?{digit}+)?
ADDOP [+-] 
MULOP [*/%]

%%

{delim}+	{}
{newline} {line_count++;}

"if" {return IF;}
"else" {return ELSE;}
"for" {return FOR;}
"while" {return WHILE;}
"int" {return INT;}
"float" {return FLOAT;}
"double" {return DOUBLE;}
"char" {return CHAR;}
"return" {return RETURN;}
"void" {return VOID;}
"main"	{return MAIN;}
"println"	{return PRINTLN;}

{ADDOP} { 
			SymbolInfo *s= new  SymbolInfo(yytext, "ADDOP");
			yylval = (YYSTYPE)s;
			return ADDOP;
		}



{MULOP}	{
			SymbolInfo *s= new  SymbolInfo(yytext, "MULOP");
			yylval = (YYSTYPE)s;
			return MULOP;
		}


"=" 	{return ASSIGNOP;}

">" |
"<" |
">=" |
"<=" |
"==" |
"!=" {
		SymbolInfo *s= new  SymbolInfo(yytext, "RELOP");
		yylval = (YYSTYPE)s;
		return RELOP;
	}

"&&"	|
"||"	{
			SymbolInfo *s= new  SymbolInfo(yytext, "LOGICOP");
			yylval = (YYSTYPE)s;
			return LOGICOP;
		}
"!"		{	return NOT; }


";" 	{ return SEMICOLON;}
"," 	{return COMMA;}
"(" 	{return LPAREN;}
")" 	{return RPAREN;}
"{" 	{return LCURL;}
"}" 	{return RCURL;}
"[" 	{return LTHIRD;}
"]" 	{return RTHIRD;}
"++" 	{return INCOP;}
"--" 	{return DECOP;}



{integer}	{
				SymbolInfo *s= new  SymbolInfo(yytext, "CONST_INT");
				yylval = (YYSTYPE)s;
				return CONST_INT;
			}
{number} 	{	
				SymbolInfo *s= new  SymbolInfo(yytext, "CONST_FLOAT");
				yylval = (YYSTYPE)s;
				return CONST_FLOAT; 
			}
{id} 		{	 
				SymbolInfo *s= table->lookup(yytext);
				if(s==NULL)
				{					
					s= new SymbolInfo(yytext, "ID");
				}
				yylval = (YYSTYPE)s;
				
				return ID;
			}


%%

int yywrap(void)
{
	return 1;
}





