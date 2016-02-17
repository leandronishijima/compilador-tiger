%{
/* need this for the call to atof() below */
#include <math.h>
#include "tiger.tab.h"
#include "errormsg.h"

extern YYSTYPE yylval;

int   contadorComentario = 0;
char string[1000];
int   linha  = 1;
int   coluna = 1;

void adjust();

%}

%x IN_STRING
%x IN_COMMENT

DIGIT    [0-9]
VARIAVEL [a-zA-Z][a-zA-Z0-9_]*
VARIAVEL_INVALIDA_ANTES [0-9._-]+[a-zA-Z0-9]+
VARIAVEL_INVALIDA_DEPOIS [a-zA-Z]+[0-9.-_]+
INTEGER  [0-9]+
NUMBER_FLOAT [0-9]*.[0-9]+

%%

<INITIAL>

","       { adjust(); return COMMA     ; }
":"       { adjust(); return COLON     ; }
"("       { adjust(); return LPAREN    ; }
")"       { adjust(); return RPAREN    ; }
"["       { adjust(); return LBRACK    ; }
"]"       { adjust(); return RBRACK    ; }
"{"       { adjust(); return LBRACE    ; }
"}"       { adjust(); return RBRACE    ; }
"."       { adjust(); return DOT       ; }
"+"       { adjust(); return PLUS      ; }
"-"       { adjust(); return MINUS     ; }
"*"       { adjust(); return TIMES     ; }
"/"       { adjust(); return DIVIDE    ; }
"="       { adjust(); return EQUAL     ; }
"<>"      { adjust(); return NEQUAL    ; }
"<"       { adjust(); return LT        ; }
"<="      { adjust(); return LE        ; }
">"       { adjust(); return GT        ; }
">="      { adjust(); return GE        ; }
"&"       { adjust(); return AND       ; }
"|"       { adjust(); return OR        ; }
":="      { adjust(); return ASSIGN    ; }

array     { adjust(); return ARRAY     ; }
if        { adjust(); return IF        ; }
then      { adjust(); return THEN      ; }
else      { adjust(); return ELSE      ; }
let       { adjust(); return LET       ; }
in        { adjust(); return IN        ; }
end       { adjust(); return END       ; }
of        { adjust(); return OF        ; }
nil       { adjust(); return NIL       ; }
function  { adjust(); return FUNCTION  ; }
var       { adjust(); return VAR       ; }
type      { adjust(); return TYPE      ; }
import    { adjust(); return IMPORT    ; }
primitive { adjust(); return PRIVATE   ; }

{VARIAVEL}                 { yylval.sval = strdup(yytext); adjust(); return ID    ; }
{VARIAVEL_INVALIDA_ANTES}  { adjust(); EM_error(EM_tokPos, "token inválido")      ; }
{VARIAVEL_INVALIDA_DEPOIS} { adjust(); EM_error(EM_tokPos, "token inválido")      ; }
{INTEGER}                  { yylval.ival = atoi(yytext); adjust();   return INT   ; }
{NUMBER_FLOAT}             { yylval.ival = atoi(yytext); adjust();   return FLOAT ; }

"/*" { BEGIN(IN_COMMENT); contadorComentario++; }

<IN_COMMENT>{
   "/*" { contadorComentario++; }
   \n   { adjust(); }
   .    {}
   "*/" { if (--contadorComentario == 0) { BEGIN(INITIAL); } }
}

"\"" { strcat(string, yytext); BEGIN(IN_STRING); }

<IN_STRING>{
   "\"" { strcat(string, yytext); yylval.sval = strdup(string); strcpy(string, ""); BEGIN(INITIAL); return STRING; }
   .    { strcat(string, yytext); }
}

[ \t\n] { adjust(); }

.  ;

%%

int yywrap() {}

void adjust(){
   if (strcmp( yytext, "\n" ) == 0 ) {
      EM_newline();
   }else{
      EM_tokPos += yyleng;
   }
}
