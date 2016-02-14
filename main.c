#include <stdio.h>
#include <stdlib.h>
#include "util.h"
#include "symbol.h"
#include "absyn.h"
#include "errormsg.h"
#include "parse.h"
#include "prabsyn.h"
#include "temp.h"

int main(int argc, char **argv){
   A_exp prog;
   if (argc != 2) {
      fprintf(stderr, "Usage: %s filename\n", argv[0]);
      exit(1);
   }
   /* yydebug = 1; */

   if (!(prog = parse(argv[1])))
      exit(1);
   
   printf("\n arvore gerada -> \n\n");
   pr_exp(stdout, prog, 3);
   printf("\n\n");

   // //cabecalho
   // printf("; ModuleID = '%s'\n", argv[1]);
   // printf("target datalayout = \"e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:32:32-n8:16:32-S128\"\n");
   // printf("target triple = \"i386-pc-linux-gnu\"\n\n");
   // //fim cabecalho

   // //inicio main
   // printf("define i32 @main() nounwind {\n");
   // printf("   %%%d = alloca i32, align 4", getLabel(""));
   // analizador_semantico(prog);
   // printf("\n   %%%d = load i32* %%%d\n", getLabel("exit"), getLabel(""));
   // printf("   ret i32 %%%d\n", getLabel("exit"));
   // printf("}");
   return 0;
}
