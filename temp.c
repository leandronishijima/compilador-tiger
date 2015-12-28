#include <stdio.h>
#include <string.h>
#include "temp.h"

static int label = 1;
static char* temporario[100];

int getLabel(char* variavel){
   int i;
   for ( i = 1; i <= label-1; i++ ){
      if ( strcmp(temporario[i], variavel) == 0 )
         return i;
   }
   temporario[label] = variavel;
   return label++;
}
