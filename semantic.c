/*
#include <stdlib.h>
#include "env.h"
#include "errmsg.h"
#include "ir.h"
#include "ppast.h"
#include "semantic.h"
#include "translate.h"
#include "types.h"
*/

#include <stdio.h>
#include "semantic.h"
#include "table.h"
#include "type.h"
#include "temp.h"

static table_t _venv;
static table_t _tenv;

typedef struct expr_type_s expr_type_t;

struct expr_type_s
{
    tr_expr_t expr;
    type_t type;
};

static expr_type_t expr_type(tr_expr_t expr, type_t type) {
    expr_type_t result;
    result.expr = expr;
    result.type = type;
    return result;
}

static void trans_decl(tr_level_t level, ast_decl_t decl);
static expr_type_t trans_expr(tr_level_t level, ast_expr_t expr);
static type_t trans_type(ast_type_t type);
static expr_type_t trans_var(tr_level_t level, ast_var_t var);

static type_t lookup_type(symbol_t name, int pos) {
    type_t type = sym_lookup(_tenv, name);
    if (type)
        type = ty_actual(type);
    else
        em_error(pos, "Tipo indefinido '%s'", sym_name(name));
    return type;
}

static list_t formal_type_list(list_t params, int pos) {
    list_t p, q = NULL, r = NULL;

    for (p = params; p; p = p->next) {
        ast_field_t field = p->data;
        type_t type = lookup_type(field->type, pos);
        if (!type)
            type = ty_int();
        if (r) {
            r->next = list(type, NULL);
            r = r->next;
        }
        else
            q = r = list(type, NULL);
    }
    return q;
}

static list_t formal_escape_list(list_t params) {
    list_t p = params, q = NULL, r = NULL;
    for (; p; p = p->next) {
        list_t bl = bool_list(((ast_field_t) p->data)->escape, NULL);
        if (r) {
            r->next = bl;
            r = r->next;
        }
        else
            q = r = bl;
    }
    return q;
}

static void trans_funcs_decl(tr_level_t level, ast_decl_t decl) {
    list_t p, q;

    for (p = decl->u.funcs; p && p->next; p = p->next)
        for (q = p->next; q; q = q->next) {
            ast_func_t func = q->data;
            if (((ast_func_t) p->data)->name == func->name)
                em_error(func->pos, "função '%s' redefinida", sym_name(func->name));
        }

    for (p = decl->u.funcs; p; p = p->next) {
        ast_func_t func = p->data;
        list_t formals = formal_type_list(func->params, decl->pos);
        list_t escapes = formal_escape_list(func->params);
        type_t result;
        tmp_label_t label = tmp_label();

        if (func->result) {
            result = lookup_type(func->result, decl->pos);

            if (!result)
                result = ty_int();
        }
        else
            result = ty_void();

        sym_enter(_venv, func->name, env_func_entry(tr_level(level, label, escapes), label, formals, result));
    }

    for (p = decl->u.funcs; p; p = p->next) {
        ast_func_t func = p->data;
        env_entry_t entry = sym_lookup(_venv, func->name);
        list_t q = func->params;
        list_t r = entry->u.func.formals;
        list_t s = tr_formals(entry->u.func.level)->next;
        expr_type_t result;

        sym_begin_scope(_venv);
        for (; q; q = q->next, r = r->next, s = s->next) {
            sym_enter(_venv,
                      ((ast_field_t) q->data)->name,
                      env_var_entry(s->data, r->data, false));
        }

        assert(!q && !r);
        result = trans_expr(entry->u.func.level, func->body);

        if (!ty_match(result.type, entry->u.func.result))
            em_error(func->pos, "corpo da função possui tipo incorreto");

        sym_end_scope(_venv);
    }
}

static void trans_types_decl(tr_level_t level, ast_decl_t decl) {
    list_t p, q;

    for (p = decl->u.types; p && p->next; p = p->next)
        for (q = p->next; q; q = q->next) {
            ast_nametype_t nt = q->data;
            if (((ast_nametype_t) p->data)->name == nt->name)
                em_error(decl->pos, "tipo '%s' redefinido", sym_name(nt->name));
        }

    for (p = decl->u.types; p; p = p->next) {
        ast_nametype_t nametype = p->data;
        sym_enter(_tenv, nametype->name, ty_name(nametype->name, NULL));
    }

    for (p = decl->u.types; p; p = p->next) {
        ast_nametype_t nametype = p->data;
        type_t type = sym_lookup(_tenv, nametype->name);
        type->u.name.type = trans_type(nametype->type);
    }

    for (p = decl->u.types; p; p = p->next) {
        ast_nametype_t nametype = p->data;
        type_t type = sym_lookup(_tenv, nametype->name);

        if (ty_actual(type) == type)
            em_error(decl->pos, "tipo infinito de recursão '%s'", sym_name(nametype->name));
    }
}

static void trans_var_decl(tr_level_t level, ast_decl_t decl) {
    expr_type_t init = trans_expr(level, decl->u.var.init);
    type_t type = init.type;
    tr_access_t access = tr_alloc_local(level, decl->u.var.escape);

    if (decl->u.var.type) {
        type = lookup_type(decl->u.var.type, decl->pos);
        if (!type)
            type = ty_int();

        if (!ty_match(type, init.type))
            em_error(decl->pos, "Inicialização incorreta do tipo");
    }
    else if (init.type->kind == TY_NIL)
        em_error(decl->pos, "Não sabe-se o tipo de registro para pegar");
    else if (init.type->kind == TY_VOID)
        em_error(decl->pos, "não se pode assimilar um valor void a uma variável");

    sym_enter(_venv, decl->u.var.var, env_var_entry(access, type, false));
}

typedef void (*trans_decl_func)(tr_level_t level, ast_decl_t);

static trans_decl_func _trans_decl_funcs[] = {
    trans_funcs_decl,
    trans_types_decl,
    trans_var_decl,
};

static void trans_decl(tr_level_t level, ast_decl_t decl) {
    _trans_decl_funcs[decl->kind](level, decl);
}

static expr_type_t trans_nil_expr(tr_level_t level, ast_expr_t expr) {
    return expr_type(tr_num_expr(0), ty_nil());
}

static expr_type_t trans_var_expr(tr_level_t level, ast_expr_t expr) {
    return trans_var(level, expr->u.var);
}

static expr_type_t trans_num_expr(tr_level_t level, ast_expr_t expr) {
    return expr_type(tr_num_expr(expr->u.num), ty_int());
}

static expr_type_t trans_string_expr(tr_level_t level, ast_expr_t expr) {
    return expr_type(tr_string_expr(expr->u.str), ty_string());
}

static expr_type_t trans_call_expr(tr_level_t level, ast_expr_t expr) {
    env_entry_t entry = sym_lookup(_venv, expr->u.call.func);
    list_t l_formals, l_args, l_args2 = NULL, l_next = NULL;
    int i;

    if (!entry) {
        em_error(expr->pos, "função indefinida '%s'", sym_name(expr->u.call.func));

        return expr_type(NULL, ty_int());
    }
    else if (entry->kind != ENV_FUNC_ENTRY) {
        em_error(expr->pos, "'%s' não é uma função", sym_name(expr->u.call.func));

        return expr_type(NULL, ty_int());
    }

    for (l_formals = entry->u.func.formals, l_args = expr->u.call.args, i = 1; l_formals && l_args; l_formals = l_formals->next, l_args = l_args->next, i++) {
        expr_type_t et = trans_expr(level, (ast_expr_t) l_args->data);

        if (!ty_match(l_formals->data, et.type))
            em_error(expr->pos, "passagem de argumento %d de '%s' com tipo errado", i, sym_name(expr->u.call.func));

        if (l_args2)
            l_next = l_next->next = list(et.expr, NULL);
        else
            l_args2 = l_next = list(et.expr, NULL);
    }
    if (l_formals)
        em_error(expr->pos, "esperado mais agrupamentos");
    else if (l_args)
        em_error(expr->pos, "esperado menos argumentos");

    return expr_type(tr_call_expr(entry->u.func.level, entry->u.func.label, l_args2), ty_actual(entry->u.func.result));
}

static expr_type_t trans_op_expr(tr_level_t level, ast_expr_t expr) {
    ast_binop_t op = expr->u.op.op;
    expr_type_t left = trans_expr(level, expr->u.op.left);
    expr_type_t right = trans_expr(level, expr->u.op.right);

    switch (op) {
        case AST_PLUS:
        case AST_MINUS:
        case AST_TIMES:
        case AST_DIVIDE:
            if (left.type->kind != TY_INT)
                em_error(expr->u.op.left->pos, "integer necessário");
            
            if (right.type->kind != TY_INT)
                em_error(expr->u.op.right->pos, "integer necessário");

            return expr_type(tr_op_expr(op-AST_PLUS+IR_PLUS, left.expr, right.expr), ty_int());

        case AST_EQ:
        case AST_NEQ: {
            tr_expr_t result = NULL;
            if (!ty_match(left.type, right.type))
                em_error(expr->pos, "O tipo dos dois operandos deve ser o mesmo");
            else if (left.type->kind == TY_STRING)
                result = tr_string_rel_expr(
                  op-AST_EQ+IR_EQ, left.expr, right.expr);
            else
                result = tr_rel_expr(op-AST_EQ+IR_EQ, left.expr, right.expr);

            return expr_type(result, ty_int());
        }

        case AST_LT:
        case AST_LE:
        case AST_GT:
        case AST_GE: {
            tr_expr_t result = NULL;
            
            if (!ty_match(left.type, right.type))
                em_error(expr->pos,
                         "O tipo dos dois operandos deve ser o mesmo");

            if (left.type->kind != TY_INT && left.type->kind != TY_STRING)
                em_error(expr->pos,ng
                        "Os tipos de operadores de comparação precisam ser com int ou strig");

            if (left.type->kind == TY_STRING)
                result = tr_string_rel_expr(
                  op-AST_LT+IR_LT, left.expr, right.expr);
            else
                result = tr_rel_expr(op-AST_LT+IR_LT, left.expr, right.expr);
            return expr_type(result, left.type);
        }
    }

    assert(0);
}

static expr_type_t trans_record_expr(tr_level_t level, ast_expr_t expr) {
    type_t type = lookup_type(expr->u.record.type, expr->pos);
    list_t p, q;
    list_t fields = NULL, next = NULL;
    int size = 0;

    if (!type)
        return expr_type(NULL, ty_nil());

    if (type->kind != TY_RECORD)
        em_error(expr->pos, "'%s' não é do tipo record", sym_name(expr->u.record.type));

    for (p = type->u.record, q = expr->u.record.efields; p && q; p = p->next, q = q->next, size++) {
        ast_efield_t efield = q->data;
        expr_type_t et = trans_expr(level, efield->expr);

        if (!ty_match(((ty_field_t) p->data)->type, et.type))
            em_error(efield->pos, "Campo do tipo errado");

        if (fields)
            next = next->next = list(et.expr, NULL);
        else
            fields = next = list(et.expr, NULL);
    }
    if (p || q)
        em_error(expr->pos, "Campo number errado");

    return expr_type(tr_record_expr(fields, size), type);
}

static expr_type_t trans_array_expr(tr_level_t level, ast_expr_t expr) {
    type_t type = lookup_type(expr->u.array.type, expr->pos);
    expr_type_t size = trans_expr(level, expr->u.array.size);
    expr_type_t init = trans_expr(level, expr->u.array.init);

    if (!type)
        return expr_type(NULL, ty_int());
   
    if (type->kind != TY_ARRAY)
        em_error(expr->pos, "'%s' não é do tipo array", sym_name(expr->u.array.type));
    
    if (size.type->kind != TY_INT)
        em_error(expr->pos, "tamanho do array deveria ser do tipo int");
    
    if (!ty_match(type->u.array, init.type))
        em_error(expr->pos, "tipo iniciado incorretamente");

    return expr_type(tr_array_expr(size.expr, init.expr), type);
}

static expr_type_t trans_seq_expr(tr_level_t level, ast_expr_t expr) {
    list_t p = expr->u.seq;
    list_t stmts = NULL, next = NULL;

    for (; p; p = p->next) {
        expr_type_t et = trans_expr(level, (ast_expr_t) p->data);
    
        if (stmts)
            next = next->next = list(et.expr, NULL);
        else
            stmts = next = list(et.expr, NULL);
        if (!p->next)
            return expr_type(tr_seq_expr(stmts), et.type);
    }

    return expr_type(tr_num_expr(0), ty_void());
}

static expr_type_t trans_if_expr(tr_level_t level, ast_expr_t expr) {
    expr_type_t cond = trans_expr(level, expr->u.if_.cond);
    expr_type_t then = trans_expr(level, expr->u.if_.then);

    if (cond.type->kind != TY_INT)
        em_error(expr->pos, "tipo da condição deveria ser int");

    if (expr->u.if_.else_) {
        expr_type_t else_ = trans_expr(level, expr->u.if_.else_);
        if (!ty_match(then.type, else_.type))
            em_error(expr->pos, "tipos do then e do else são diferentes");
        return expr_type(tr_if_expr(cond.expr, then.expr, else_.expr),
                         then.type);
    }
    else if (then.type->kind != TY_VOID)
        em_error(expr->pos, "if-then não deveria retornar nada");

    return expr_type(tr_if_expr(cond.expr, then.expr, NULL), ty_void());
}

static expr_type_t trans_while_expr(tr_level_t level, ast_expr_t expr) {
    expr_type_t cond = trans_expr(level, expr->u.while_.cond);
    expr_type_t body = trans_expr(level, expr->u.while_.body);
    
    if (cond.type->kind != TY_INT)
        em_error(expr->pos, "tipo da condição deve ser um int");
    
    if (body.type->kind != TY_VOID)
        em_error(expr->pos, "while não deveria retornar nada");

    return expr_type(tr_while_expr(cond.expr, body.expr), ty_void());
}

static expr_type_t trans_for_expr(tr_level_t level, ast_expr_t expr) {

    expr_type_t lo = trans_expr(level, expr->u.for_.lo);
    expr_type_t hi = trans_expr(level, expr->u.for_.hi);
    expr_type_t body;
    tr_access_t access = tr_alloc_local(level, expr->u.for_.escape);

    if (lo.type->kind != TY_INT)
        em_error(expr->pos, "lo expressão deveria ser do tipo int");

    if (hi.type->kind != TY_INT)
        em_error(expr->pos, "hi expressão deveria ser do tipo int");

    sym_begin_scope(_venv);
    sym_enter(_venv, expr->u.for_.var, env_var_entry(access, ty_int(), true));
    
    body = trans_expr(level, expr->u.for_.body);

    if (body.type->kind != TY_VOID)
        em_error(expr->pos, "for não deve retornar nada");

    sym_end_scope(_venv);

    return expr_type(tr_for_expr(access, lo.expr, hi.expr, body.expr), ty_void());
}

static expr_type_t trans_break_expr(tr_level_t level, ast_expr_t expr) {
    return expr_type(NULL, ty_void());
}

static expr_type_t trans_let_expr(tr_level_t level, ast_expr_t expr) {
    expr_type_t result;
    list_t p;

    sym_begin_scope(_venv);
    sym_begin_scope(_tenv);

    for (p = expr->u.let.decls; p; p = p->next)
        trans_decl(level, p->data);

    result = trans_expr(level, expr->u.let.body);
    sym_end_scope(_venv);
    sym_end_scope(_tenv);
    return result;
}

static expr_type_t trans_assign_expr(tr_level_t level, ast_expr_t expr) {
    expr_type_t var = trans_var(level, expr->u.assign.var);
    expr_type_t et = trans_expr(level, expr->u.assign.expr);

    if (!ty_match(var.type, et.type))
        em_error(expr->pos, "Incompatibilidade de tipo");

    if (expr->u.assign.var->kind == AST_SIMPLE_VAR && var.type->kind == TY_INT) {
        ast_var_t v = expr->u.assign.var;
        env_entry_t entry = sym_lookup(_venv, v->u.simple);
        if (entry && entry->kind == ENV_VAR_ENTRY && entry->u.var.for_)
            em_error(expr->pos, "Atribuído para uma variável");
    }

    return expr_type(tr_assign_expr(var.expr, et.expr), ty_void());
}

typedef expr_type_t (*trans_expr_func)(tr_level_t level, ast_expr_t);
static trans_expr_func _trans_expr_funcs[] = {
    trans_nil_expr,
    trans_var_expr,
    trans_num_expr,
    trans_string_expr,
    trans_call_expr,
    trans_op_expr,
    trans_record_expr,
    trans_array_expr,
    trans_seq_expr,
    trans_if_expr,
    trans_while_expr,
    trans_for_expr,
    trans_break_expr,
    trans_let_expr,
    trans_assign_expr,
};

static expr_type_t trans_expr(tr_level_t level, ast_expr_t expr) {
    return _trans_expr_funcs[expr->kind](level, expr);
}

static type_t trans_name_type(ast_type_t type) {
    type_t t = sym_lookup(_tenv, type->u.name);
    if (!t) {
        em_error(type->pos, "tipo indefinido '%s'", sym_name(type->u.name));
        t = ty_int();
    }
    return t;
}

static type_t trans_record_type(ast_type_t type) {
    list_t p = type->u.record;
    list_t q = NULL, r = NULL;

    for (; p; p = p->next) {
        ast_field_t field = p->data;
        type_t t = sym_lookup(_tenv, field->type);

        if (!t) {
            em_error(type->pos, "Tipo indefinido '%s'", sym_name(field->type));
            t = ty_int();
        }
        if (r) {
            r->next = list(ty_field(field->name, t), NULL);
            r = r->next;
        }
        else
            q = r = list(ty_field(field->name, t), NULL);
    }

    return ty_record(q);
}

static type_t trans_array_type(ast_type_t type) {
    type_t t = sym_lookup(_tenv, type->u.array);
    if (!t) {
        em_error(type->pos, "Tipo indefinido '%s'", type->u.array);
        t = ty_int();
    }
    return ty_array(t);
}

typedef type_t (*trans_type_func)(ast_type_t);

static trans_type_func _trans_type_funcs[] = {
    trans_name_type,
    trans_record_type,
    trans_array_type,
};

static type_t trans_type(ast_type_t type) {
    return _trans_type_funcs[type->kind](type);
}

static expr_type_t trans_simple_var(tr_level_t level, ast_var_t var) {
    env_entry_t entry = sym_lookup(_venv, var->u.simple);

    if (!entry) {
        em_error(var->pos, "Variável indefinida '%s'", sym_name(var->u.simple));
        return expr_type(tr_num_expr(0), ty_int());
    }
    else if (entry->kind != ENV_VAR_ENTRY) {
        em_error(var->pos, "esperava-se '%s' ser uma variável, não uma função", sym_name(var->u.simple));

        return expr_type(tr_num_expr(0), ty_int());
    }

    return expr_type(tr_simple_var(entry->u.var.access, level), ty_actual(entry->u.var.type));
}

static expr_type_t trans_field_var(tr_level_t level, ast_var_t var) {
    expr_type_t et = trans_var(level, var->u.field.var);
    list_t p;

    if (et.type->kind != TY_RECORD) {
        em_error(var->pos, "Era esperado uma variável do tipo de registro");
        return expr_type(NULL, ty_int());
    }

    for (p = et.type->u.record; p; p = p->next) {
        ty_field_t field = p->data;

        if (field->name == var->u.field.field)
            return expr_type(NULL, ty_actual(field->type));
    }

    em_error(var->pos, "Não há nenhuma variável chamada '%s'", sym_name(var->u.field.field));

    return expr_type(NULL, ty_int());
}

static expr_type_t trans_sub_var(tr_level_t level, ast_var_t var) {
    expr_type_t et = trans_var(level, var->u.sub.var);
    expr_type_t sub = trans_expr(level, var->u.sub.sub);

    if (et.type->kind != TY_ARRAY) {
        em_error(var->pos, "expected array type variable");
        return expr_type(NULL, ty_int());
    }
    if (sub.type->kind != TY_INT)
        em_error(var->pos, "expected integer type subscript");

    return expr_type(NULL, ty_actual(et.type->u.array));
}

typedef expr_type_t (*trans_var_func)(tr_level_t level, ast_var_t);

static trans_var_func _trans_var_funcs[] = {
    trans_simple_var,
    trans_field_var,
    trans_sub_var,
};

static expr_type_t trans_var(tr_level_t level, ast_var_t var) {
    return _trans_var_funcs[var->kind](level, var);
}

void sem_trans_prog(ast_expr_t prog) {
    _venv = env_base_venv();
    _tenv = env_base_tenv();
    trans_expr(tr_outermost(), prog);
}
