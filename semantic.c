
#include <stdio.h>
#include "semantic.h"
#include "table.h"
#include "type.h"
#include "temp.h"

static TAB_table _tabela;
static TAB_table _tabelaType;
typedef struct expr_type_s expr_type_t;

struct expr_type_s{
   Ty_ty type;
};

static expr_type_t expr_type(Ty_ty type){

   expr_type_t result;
   result.type = type;
   return result;
}

static expr_type_t trans_expr(A_exp expr );

static expr_type_t trans_simple_var(A_var var){

   Ty_ty entry = TAB_look(_tabela, var->u.simple);
   
   if (!entry){
      EM_error(var->pos, "variavel indefinido: %s", S_name(var->u.simple));
      return expr_type(Ty_Int());
   } 
   else if (entry->kind != Ty_var){
      EM_error(var->pos, "expected '%s' to be a variable, not a function", S_name(var->u.simple));
      return expr_type(Ty_Int());
   }

   return expr_type(Ty_Name(var->u.simple, Ty_Void()));
}

static expr_type_t trans_field_var( A_var var );
static expr_type_t trans_sub_var( A_var var );

static expr_type_t trans_var( A_var var ){

   switch( var->kind ){

      case A_simpleVar:
         return trans_simple_var( var );
/*      case A_fieldVar:
         return trans_field_var( var );
      case A_subscriptVar:
         return trans_sub_var( var );
*/
   }
}

static expr_type_t trans_assign_expr( A_exp expr ){

   expr_type_t var = trans_var(expr->u.assign.var);
   expr_type_t et  = trans_expr(expr->u.assign.exp);

   if (et.type == var.type/*!ty_match(var.type, et.type)*/)
      EM_error(expr->pos, "tipos incompativeis");

   if (expr->u.assign.var->kind == A_simpleVar /*&& var.type->kind == Ty_Int()*/){
      A_var v = expr->u.assign.var;
      A_exp entry = TAB_look(_tabela, v->u.simple);

//      if (entry && entry->kind == A_assignExp && entry->u.forr)
//         EM_error(expr->pos, "assigning to the for variable");
   }

   printf( "\n   %%%d = load i32* %%%s, align 4", getLabel(S_name(et.type->u.name.sym)), S_name(et.type->u.name.sym));
   printf( "\n   store i32 %%%d, i32* %%%s, align 4", getLabel(S_name(et.type->u.name.sym)), S_name(var.type->u.name.sym) );
   return expr_type(Ty_Void());
}

static void trans_var_decl( A_dec decl ){

   expr_type_t init = trans_expr(decl->u.var.init);

   Ty_ty type = init.type;

   if (decl->u.var.typ){
   
      type = TAB_look(_tabela, decl->u.var.typ); 

      if (!type)
         type = Ty_Int();

      if (type != init.type)
         EM_error(decl->pos, "initializer has incorrect type");

   }else if (init.type->kind == Ty_nil)
      EM_error(decl->pos, "don't know which record type to take");

    else if (init.type->kind == Ty_void)
      EM_error(decl->pos, "can't assign void value to a variable");

   TAB_enter(_tabela, decl->u.var.var, Ty_Var());

   printf("   %%%s = alloca i32, align 4", S_name( decl->u.var.var ) );
   printf("\n   store i32 %d, i32* %%%s, align 4", decl->u.var.init->u.intt , S_name( decl->u.var.var ) );

}

static void trans_decl( A_dec decl ){

   switch(decl->kind){

      case A_varDec:
         printf("\n");
         trans_var_decl(decl);
         break;
/*
      case A_typeDec:
         trans_types_decl(decl);

      case A_functionDec:
         trans_funcs_decl(decl);
*/
   }
}

static expr_type_t trans_let_expr(A_exp expr){

   expr_type_t result;
   A_decList p;
   S_beginScope(_tabela);
   //S_beginScope(_tabelaType);
   for (p = expr->u.let.decs; p; p = p->tail)
      trans_decl(p->head);
   result = trans_expr(expr->u.let.body);
   S_endScope(_tabela);
   //S_endScope(_tabelaType);
   return result;
}

static expr_type_t trans_seq_expr(A_exp expr){
   
   A_expList p;
   A_expList stmts = NULL, next = NULL;
   for (p = expr->u.seq; p; p = p->tail){
      expr_type_t et = trans_expr(p->head);

      if (!p->tail)
         return expr_type(et.type);
   }
   return expr_type(Ty_Void());

}

static expr_type_t trans_expr(A_exp exp){
   
   switch( exp->kind ){

      case A_varExp:
         return trans_var(exp->u.var);
/*
      case A_nilExp:
	 return trans_nil_expr(exp);

      case A_intExp:
         return trans_num_expr(exp);

      case A_stringExp:
         return trans_string_expr(exp);

      case A_callExp:
         return trans_call_expr(exp);

      case A_opExp:
         return trans_op_expr(exp);

      case A_recordExp:
         return trans_record_expr(exp);
*/
      case A_seqExp:
         return trans_seq_expr(exp);

      case A_assignExp:
         return trans_assign_expr(exp);
/*
      case A_ifExp:
         return trans_if_expr(exp);

      case A_whileExp:
         return trans_while_expr(exp);

      case A_forExp:
         return trans_for_expr(exp);

      case A_breakExp:
         return trans_break_expr(exp);
*/
      case A_letExp:
         return trans_let_expr(exp);
/*
      case A_arrayExp:
         return trans_array_expr(exp);
*/
   }
}

void analizador_semantico(A_exp prog){

   _tabela     = TAB_empty();
   //_tabelaType = TAB_empty();
   trans_expr(prog);
}
