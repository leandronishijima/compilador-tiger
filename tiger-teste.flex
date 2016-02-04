%{
/* need this for the call to atof() below */
#include <math.h>
#include "tiger.tab.h"
#include "absyn.h"
#include "errormsg.h"

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
VARIAVEL_INVALIDA [0-9._-]+[a-zA-Z0-9]+
INTEGER  [0-9]+

%%

<INITIAL>

","  { adjust(); printf("[',']");   }
":"  { adjust(); printf("[':']");   }
"("  { adjust(); printf("['(']");   }
")"  { adjust(); printf("[')']");   }
"["  { adjust(); printf("['[']");   }
"]"  { adjust(); printf("[']']");   }
"{"  { adjust(); printf("['{']");   }
"}"  { adjust(); printf("['}']");   }
"."  { adjust(); printf("['.']");   }
"+"  { adjust(); printf("['+']");   }
"-"  { adjust(); printf("['-']");   }
"*"  { adjust(); printf("['*']");   }
"/"  { adjust(); printf("['/']");   }
"="  { adjust(); printf("['=']");   }
"<>" { adjust(); printf("['<>']");  }
"<"  { adjust(); printf("['<']");   }
"<=" { adjust(); printf("['<=']");  }
">"  { adjust(); printf("['>']");   }
">=" { adjust(); printf("['>=']");  }
"&"  { adjust(); printf("['&']");   }
"|"  { adjust(); printf("['|']");   }
":=" { adjust(); printf("[':=']");  }

array     { adjust();  printf("['array']");        }
if        { adjust();  printf("['if']");           }
then      { adjust();  printf("['then']");         }
else      { adjust();  printf("['else']");         }
let       { adjust();  printf("['let']");          }
in        { adjust();  printf("['in']");           }
end       { adjust();  printf("['end']");          }
of        { adjust();  printf("['of']");           }
nil       { adjust();  printf("['nil']");          }
function  { adjust();  printf("['function']");     }
var       { adjust();  printf("['var']");          }
type      { adjust();  printf("['type']");         }
import    { adjust();  printf("['import']");       }
primitive { adjust();  printf("['primitive']");    }

{VARIAVEL}  { adjust(); printf("['id']"); }

{VARIAVEL_INVALIDA}  { adjust(); printf("token inválido"); }

{DIGIT}+    { adjust(); printf("['int']");  }

"/*" { BEGIN(IN_COMMENT); contadorComentario++; }

<IN_COMMENT>{
   "/*" { contadorComentario++; }
   .    {}
   "*/" { if (--contadorComentario == 0) { BEGIN(INITIAL); } }
   printf("['IN_COMMENT']");
}

"\"" BEGIN(IN_STRING);

<IN_STRING>{
   "\"" { BEGIN(INITIAL); }
   .    {  }
   printf("['STRING']");
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
