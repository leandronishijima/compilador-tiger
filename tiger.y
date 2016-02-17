%{
#include <stdio.h>
#include "absyn.h"
#include "errormsg.h"
#include "symbol.h"

A_exp absyn_root;

%}


%union {
	int ival;
	char* sval;
	float fval;

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
%token <ival> FLOAT
%token COMMA COLON SEMICOLON LPAREN RPAREN LBRACK RBRACK 
%token LBRACE RBRACE DOT 
%token PLUS MINUS TIMES DIVIDE EQUAL NEQUAL LT LE GT GE
%token AND OR ASSIGN
%token ARRAY IF THEN ELSE WHILE FOR TO DO LET IN END OF 
%token BREAK NIL
%token FUNCTION VAR TYPE 
%token IMPORT PRIVATE

%type <A_exp> preExp exp ifExp orExp andExp BooleanExp plusMinusExp TimesDivideExp exps
%type <A_var> lvalue 
%type <A_efieldList> recordfields efieldList
%type <A_efield> recordfield
%type <A_expList> listExp
%type <A_expList> funcParametros parametrosTail
%type <A_decList> decs
%type <A_dec> dec vardec
%type <A_namety> typedec
%type <A_nametyList> typedecs
%type <A_fundec> fundec
%type <A_fundecList> fundecs
%type <A_ty> ty
%type <A_fieldList> tyfields fieldList
%type <A_field> tyfield 

%left OR
%left AND

%left EQUAL NEQUAL
%left GT LT GE LE

%left PLUS MINUS
%left TIMES DIVIDE

%right THEN ELSE

%start program

%%

program: 
	exp 											{ absyn_root=$1; }
;

preExp : 
	NIL 											{ $$=A_NilExp(EM_tokPos); }
	| INT 											{ $$=A_IntExp(EM_tokPos, $1); }
	| lvalue 										{ $$=A_VarExp(EM_tokPos, $1); }
	| MINUS preExp 									{ $$=A_OpExp(EM_tokPos, A_minusOp, A_IntExp(EM_tokPos, 0), $2); }
	| ID LPAREN funcParametros RPAREN				{ $$=A_CallExp(EM_tokPos, S_Symbol($1), $3); }
	| STRING 										{ $$=A_StringExp(EM_tokPos, $1); }
	| exps 											{ $$=$1; }
;

exp	: 
	ID LBRACK exp RBRACK OF exp						{ $$=A_ArrayExp(EM_tokPos, S_Symbol($1), $3, $6); }      
	| ID LBRACE recordfields RBRACE					{ $$=A_RecordExp(EM_tokPos, S_Symbol($1), $3); }
	| orExp											{ $$=$1; }
	| ifExp 										{ $$=$1; }
	| LET decs IN listExp END						{ $$=A_LetExp(EM_tokPos, $2, A_SeqExp(EM_tokPos, $4)); }
;

exps : 
	LPAREN listExp RPAREN 							{ $$=A_SeqExp(EM_tokPos, $2); }
;

listExp :
													{ $$=NULL; }
	| exp											{ $$=A_ExpList($1, NULL); }
	| exp SEMICOLON listExp							{ $$=A_ExpList($1, $3); }
;

ifExp : 
	IF exp THEN exp									{ $$=A_IfExp(EM_tokPos, $2, $4, NULL); } 
	| IF exp THEN exp ELSE exp						{ $$=A_IfExp(EM_tokPos, $2, $4, $6); }
;

recordfields:
 													{ $$=NULL; }
	| recordfield efieldList						{ $$=A_EfieldList($1, $2); }
;

recordfield: 
	ID EQUAL exp									{ $$=A_Efield(S_Symbol($1), $3); }
;

efieldList :
													{ $$=NULL; }
	| COMMA recordfield efieldList					{ $$=A_EfieldList($2, $3); }
;


lvalue 	: 
	ID						 						{ $$=A_SimpleVar(EM_tokPos, S_Symbol($1));}
	| ID DOT ID										{ $$=A_FieldVar(EM_tokPos, A_SimpleVar(EM_tokPos, S_Symbol($1)), S_Symbol($3)); }
	| ID LBRACK exp RBRACK							{ $$=A_SubscriptVar(EM_tokPos, A_SimpleVar(EM_tokPos, S_Symbol($1)), $3); }
;

BooleanExp : 
	plusMinusExp 									{ $$=$1; }
	| BooleanExp LE plusMinusExp  					{ $$=A_OpExp(EM_tokPos, A_leOp, $1, $3); }
	| BooleanExp GE plusMinusExp  					{ $$=A_OpExp(EM_tokPos, A_geOp, $1, $3); }
	| BooleanExp GT plusMinusExp  					{ $$=A_OpExp(EM_tokPos, A_gtOp, $1, $3); }
	| BooleanExp LT plusMinusExp  					{ $$=A_OpExp(EM_tokPos, A_ltOp, $1, $3); }
	| BooleanExp EQUAL plusMinusExp  				{ $$=A_OpExp(EM_tokPos, A_eqOp, $1, $3); }
	| BooleanExp NEQUAL plusMinusExp 				{ $$=A_OpExp(EM_tokPos, A_neqOp, $1, $3); }
;

plusMinusExp : 
	TimesDivideExp 									{ $$=$1; }
	| plusMinusExp PLUS TimesDivideExp 				{ $$=A_OpExp(EM_tokPos, A_plusOp, $1, $3); }
	| plusMinusExp MINUS TimesDivideExp 			{ $$=A_OpExp(EM_tokPos, A_minusOp, $1, $3); }
;

TimesDivideExp : 
	preExp 											{ $$=$1; }
	| TimesDivideExp TIMES preExp  					{ $$=A_OpExp(EM_tokPos, A_timesOp, $1, $3); }
	| TimesDivideExp DIVIDE preExp 					{ $$=A_OpExp(EM_tokPos, A_divideOp, $1, $3); }
;

orExp:	
	andExp											{ $$=$1; }
	| orExp OR andExp 								{ $$=A_OpExp(EM_tokPos, A_orOp, $1, $3); }
;

andExp :	
	BooleanExp										{ $$=$1; }
	| andExp OR BooleanExp 							{ $$=A_OpExp(EM_tokPos, A_andOp, $1, $3); }
;

funcParametros:
													{ $$=NULL; }
	| exp parametrosTail							{ $$=A_ExpList($1, $2); }
;
 
parametrosTail:
													{ $$=NULL; }
	| COMMA exp parametrosTail						{ $$=A_ExpList($2, $3); }
;
		
decs:
 													{ $$=NULL;}
	| dec decs										{ $$=A_DecList($1, $2);}
;

dec : 
	vardec											{ $$=$1; }
	| typedecs 										{ $$=A_TypeDec(EM_tokPos, $1); }
	| fundecs										{ $$=A_FunctionDec(EM_tokPos, $1); }
;

vardec 	: 
	VAR ID COLON ID ASSIGN exp						{ $$=A_VarDec(EM_tokPos, S_Symbol($2), S_Symbol($4), $6); }
	| VAR ID ASSIGN exp								{ $$=A_VarDec(EM_tokPos, S_Symbol($2), NULL, $4); }
;

typedecs :
	typedec											{ $$=A_NametyList($1, NULL); }
	| typedec typedecs								{ $$=A_NametyList($1, $2); }
;

typedec : 
	TYPE ID EQUAL ty								{ $$=A_TypeDec(EM_tokPos, A_NametyList($2, $4)); }
;

ty 	: 
	ID												{ $$=A_NameTy(EM_tokPos, S_Symbol($1)); }
    | LBRACE tyfields RBRACE						{ $$=A_RecordTy(EM_tokPos, $2); }
    | ARRAY OF ID									{ $$=A_ArrayTy(EM_tokPos, S_Symbol($3));}
;

tyfields:
													{ $$=NULL; }
    | tyfield fieldList								{ $$=A_FieldList($1, $2); }	
;

tyfield	: 
	ID COLON ID										{ $$=A_Field(EM_tokPos, S_Symbol($1), S_Symbol($3)); }
;
		
fieldList:
													{ $$=NULL; }
	| COMMA tyfield fieldList						{ $$=A_FieldList($2, $3); }	
;

fundecs	: 
	fundec											{ $$=A_FundecList($1, NULL);}
	| fundec fundecs								{ $$=A_FundecList($1, $2); }
;

fundec: 
	FUNCTION ID LPAREN tyfields RPAREN COLON ID EQUAL exp		{ $$=A_Fundec(EM_tokPos, S_Symbol($2), $4, S_Symbol($7), $9); }
	| FUNCTION ID LPAREN tyfields RPAREN EQUAL exp				{ $$=A_Fundec(EM_tokPos, S_Symbol($2), $4, NULL, $7); }
;

%%

void yyerror(char *msg) {
	EM_error(EM_tokPos, "%s", msg);
}
