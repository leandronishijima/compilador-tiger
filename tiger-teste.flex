%{
/* need this for the call to atof() below */
#include <math.h>
#include "tiger.tab.h"

//extern YYSTYPE yylval;

int   contadorComentario = 0;
char* string = "";
int   linha  = 1;
int   coluna = 1;

void adjust();

%}

%x IN_STRING
%x IN_COMMENT

DIGIT    [0-9]
VARIAVEL [a-zA-Z][a-zA-Z0-9_]*
INTEGER  [0-9]+

%%

<INITIAL>

","  { adjust(); printf("[',']");   return COMMA      ; }
":"  { adjust(); printf("[':']");   return COLON      ; }
"("  { adjust(); printf("['(']");   return LPAREN     ; }
")"  { adjust(); printf("[')']");   return RPAREN     ; }
"["  { adjust(); printf("['[']");   return LBRACK     ; }
"]"  { adjust(); printf("[']']");   return RBRACK     ; }
"{"  { adjust(); printf("['{']");   return LBRACE     ; }
"}"  { adjust(); printf("['}']");   return RBRACE     ; }
"."  { adjust(); printf("['.']");   return DOT        ; }
"+"  { adjust(); printf("['+']");   return PLUS       ; }
"-"  { adjust(); printf("['-']");   return MINUS      ; }
"*"  { adjust(); printf("['*']");   return TIMES      ; }
"/"  { adjust(); printf("['/']");   return DIVIDE     ; }
"="  { adjust(); printf("['=']");   return EQUAL      ; }
"<>" { adjust(); printf("['<>']");  return NEQUAL     ; }
"<"  { adjust(); printf("['<']");   return LT         ; }
"<=" { adjust(); printf("['<=']");  return LE         ; }
">"  { adjust(); printf("['>']");   return GT         ; }
">=" { adjust(); printf("['>=']");  return GE         ; }
"&"  { adjust(); printf("['&']");   return AND        ; }
"|"  { adjust(); printf("['|']");   return OR         ; }
":=" { adjust(); printf("[':=']");  return ASSIGN     ; }

array     { adjust();  printf("['array']");        return ARRAY     ; }
if        { adjust();  printf("['if']");           return IF        ; }
then      { adjust();  printf("['then']");         return THEN      ; }
else      { adjust();  printf("['else']");         return ELSE      ; }
let       { adjust();  printf("['let']");          return LET       ; }
in        { adjust();  printf("['in']");           return IN        ; }
end       { adjust();  printf("['end']");          return END       ; }
of        { adjust();  printf("['of']");           return OF        ; }
nil       { adjust();  printf("['nil']");          return NIL       ; }
function  { adjust();  printf("['function']");     return FUNCTION  ; }
var       { adjust();  printf("['var']");          return VAR       ; }
type      { adjust();  printf("['type']");         return TYPE      ; }
import    { adjust();  printf("['import']");       return IMPORT    ; }
primitive { adjust();  printf("['primitive']");    return PRIVATE   ; }

{VARIAVEL}  { adjust(); printf("['id']"); return ID    ; }

{DIGIT}+    { adjust(); printf("['int']");  return INT     ; }

"/*" { BEGIN(IN_COMMENT); contadorComentario++; }

<IN_COMMENT>{
   "/*" { contadorComentario++; }
   .    {}
   "*/" { if (--contadorComentario == 0) { BEGIN(INITIAL); } }
}

"\"" BEGIN(IN_STRING);

<IN_STRING>{
   "\"" { return STRING; BEGIN(INITIAL); }
   .    {  }
}

[ \t\n]+ { adjust(); }

.  ;

%%

int yywrap() {}

int main() {
    yylex();
    return 0;
}

void adjust(){
   if (strcmp( yytext, "\n" ) == 0 ) {
      coluna = 1;
      linha++;
   }else{
      coluna += yyleng;
   }
//   printf( "%d %d ", linha, coluna);

}
