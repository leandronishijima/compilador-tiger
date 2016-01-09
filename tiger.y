%{
#include <stdio.h>
#include "absyn.h"
#include "errormsg.h"

A_exp absyn_root;

void yyerror(char *s){
   EM_error(EM_tokPos, "%s", s);
}

%}


%union {
	int ival;
	char* sval;

	struct A_var_ *A_var;
	struct A_exp_ *A_exp;
	struct A_dec_ *A_dec;
	struct A_ty_ *A_ty;

	struct A_decList_ *A_decList;
	struct A_expList_ *A_expList;
	struct A_field_ *A_field;
	struct A_fieldList_ *A_fieldList;
	struct A_fundec_ *A_fundec;
	struct A_fundecList_ *A_fundecList;
	struct A_namety_ *A_namety;
	struct A_nametyList_ *A_nametyList;
	struct A_efield_ *A_efield;
	struct A_efieldList_ *A_efieldList;

	}

%token <sval> ID STRING
%token <ival> INT
%token COMMA COLON SEMICOLON LPAREN RPAREN LBRACK RBRACK
%token LBRACE RBRACE DOT
%token PLUS MINUS TIMES DIVIDE EQUAL NEQUAL LT LE GT GE
%token AND OR ASSIGN
%token ARRAY IF THEN ELSE WHILE FOR TO DO LET IN END OF
%token BREAK NIL
%token FUNCTION VAR TYPE
%token IMPORT PRIVATE

%type <A_exp> exp ifexp MathExp CompareExp BooleanExp
%type <A_var> lvalue
%type <A_efieldList> recordtail
%type <A_efield> recordfield
%type <A_expList> sequence sequencetail
%type <A_expList> funcParametros parametrosTail
%type <A_decList> decs
%type <A_dec> dec vardec fundec
%type <A_nametyList> typedecs
%type <A_namety> typedec
%type <A_ty> ty
%type <A_fieldList> tyfields comma_tyfields
%type <A_field> tyfield

/* operadores logico */
%left OR
%left AND

/* operadores relacional */
%left EQUAL NEQUAL
%left GT LT GE LE

/* operadores */
%left PLUS MINUS
%left TIMES DIVIDE

%right THEN ELSE

%start program

%%

program: exp		    				{ absyn_root=$1;}
;

exp	:
    NIL                                  		    { $$=A_NilExp(EM_tokPos); }
    | INT						                    { $$=A_IntExp(EM_tokPos, $1); }
    | STRING					                    { $$=A_StringExp(EM_tokPos, $1); }
    | ID LBRACK exp RBRACK OF exp			        { $$=A_ArrayExp(EM_tokPos, S_Symbol($1), $3, $6); }
    | ID LBRACE recordfield recordtail RBRACE	    { $$=A_RecordExp(EM_tokPos, S_Symbol($1), A_EfieldList($3, $4)); }
    | lvalue					                    { $$=A_VarExp(EM_tokPos, $1); }
    | MathExp					                    { $$=$1; }
    | CompareExp					                { $$=$1; }
    | BooleanExp					                { $$=$1; }
    | LPAREN sequence LPAREN			            { $$=A_SeqExp(EM_tokPos, $2); }
    | ID LPAREN funcParametros RPAREN		        { $$=A_CallExp(EM_tokPos, S_Symbol($1), $3); }
    | lvalue ASSIGN exp				                { $$=A_AssignExp(EM_tokPos, $1, $3); }
    | ifexp 					                    { $$=$1; }
    | WHILE exp DO exp				                { $$=A_WhileExp(EM_tokPos, $2, $4); }
    | FOR ID ASSIGN exp TO exp DO exp		        { $$=A_ForExp(EM_tokPos, S_Symbol($2), $4, $6, $8); }
    | BREAK						                    { $$=A_BreakExp(EM_tokPos); }
    | LET decs IN sequence END			            { $$=A_LetExp(EM_tokPos, $2, A_SeqExp(EM_tokPos, $4)); }
;


ifexp :
    IF exp THEN exp				    { $$=A_IfExp(EM_tokPos, $2, $4, NULL); }
    | IF exp THEN exp ELSE exp      { $$=A_IfExp(EM_tokPos, $2, $4, $6); }
;

lvalue :
    ID						{ $$=A_SimpleVar(EM_tokPos, S_Symbol($1));}
   	| ID DOT ID				{ $$=A_FieldVar(EM_tokPos, A_SimpleVar(EM_tokPos, S_Symbol($1)), S_Symbol($3)); }
   	| ID LBRACK exp RBRACK	{ $$=A_SubscriptVar(EM_tokPos, A_SimpleVar(EM_tokPos, S_Symbol($1)), $3); }
;

sequence : exp sequencetail { $$=A_ExpList($1, $2); }
;

sequencetail :
                                        { $$=NULL; }
    | SEMICOLON exp sequencetail	    { $$=A_ExpList($2, $3); }
;

recordfield : ID EQUAL exp				{ $$=A_Efield(S_Symbol($1), $3); }
;

recordtail : 						     { $$=NULL; }
    | COMMA recordfield recordtail		 { $$=A_EfieldList($2, $3); }
;

funcParametros :
                                    { $$=NULL; }
    | exp parametrosTail		    { $$=A_ExpList($1, $2); }
;

parametrosTail :
                                    { $$=NULL; }
	| COMMA exp parametrosTail		{ $$=A_ExpList($2, $3); }
;

MathExp	:
    MINUS exp					    { $$=A_OpExp(EM_tokPos, A_minusOp, A_IntExp(EM_tokPos, 0), $2); }
	| exp PLUS exp					{ $$=A_OpExp(EM_tokPos, A_plusOp, $1, $3); }
	| exp MINUS exp					{ $$=A_OpExp(EM_tokPos, A_minusOp, $1, $3); }
	| exp TIMES exp					{ $$=A_OpExp(EM_tokPos, A_timesOp, $1, $3); }
	| exp DIVIDE exp				{ $$=A_OpExp(EM_tokPos, A_divideOp, $1, $3); }
;

CompareExp :
    exp EQUAL exp				    { $$=A_OpExp(EM_tokPos, A_eqOp, $1, $3); }
	| exp NEQUAL exp				{ $$=A_OpExp(EM_tokPos, A_neqOp, $1, $3); }
	| exp LT exp					{ $$=A_OpExp(EM_tokPos, A_ltOp, $1, $3); }
	| exp LE exp					{ $$=A_OpExp(EM_tokPos, A_leOp, $1, $3); }
	| exp GT exp					{ $$=A_OpExp(EM_tokPos, A_gtOp, $1, $3); }
	| exp GE exp					{ $$=A_OpExp(EM_tokPos, A_geOp, $1, $3); }
;

BooleanExp :
    exp AND exp				        { $$=A_OpExp(EM_tokPos, A_andOp, $1, $3); }
	| exp OR exp					{ $$=A_OpExp(EM_tokPos, A_orOp, $1, $3); }
;

decs :
                                { $$=NULL;}
	| dec decs					{ $$=A_DecList($1, $2);}
;

dec :
    vardec					    { $$=$1; }
	| typedecs 					{ $$=A_TypeDec(EM_tokPos, $1); }
    | fundec 					{ $$=$1; }
;

typedecs:
    typedec					    { $$=A_NametyList($1, NULL);}
	| typedec typedecs			{ $$=A_NametyList($1, $2); }
;

typedec : TYPE ID EQUAL ty		{ $$=A_Namety(S_Symbol($2), $4); }
;

ty 	:
    ID						    { $$=A_NameTy(EM_tokPos, S_Symbol($1)); }
    | LBRACE tyfields RBRACE	{ $$=A_RecordTy(EM_tokPos, $2); }
    | ARRAY OF ID				{ $$=A_ArrayTy(EM_tokPos, S_Symbol($3));}
;

tyfields :
                                { $$=NULL; }
	| tyfield comma_tyfields	{ $$=A_FieldList($1, $2); }
;

tyfield	: ID COLON ID			{ $$=A_Field(EM_tokPos, S_Symbol($1), S_Symbol($3)); }
;

comma_tyfields :
                                    { $$=NULL; }
	| COMMA tyfield comma_tyfields	{ $$=A_FieldList($2, $3); }
;

vardec :
    VAR ID COLON ID ASSIGN exp		{ $$=A_VarDec(EM_tokPos, S_Symbol($2), S_Symbol($4), $6); }
	| VAR ID ASSIGN exp				{ $$=A_VarDec(EM_tokPos, S_Symbol($2), NULL, $4); }
;

fundec :
    FUNCTION ID LPAREN tyfields RPAREN COLON ID EQUAL exp	{ $$=A_FunctionDec(EM_tokPos, S_Symbol($2), $4, S_Symbol($7), $9); }
	| FUNCTION ID LPAREN tyfields RPAREN EQUAL exp		    { $$=A_FunctionDec(EM_tokPos, S_Symbol($2), $4, NULL, $7); }
;

%%
