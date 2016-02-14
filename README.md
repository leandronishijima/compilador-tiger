# Compilador Tiger

# Utils
  - [Tiger compiler modules for programming exercises][compiler-refs]
  - [Tiger reference language][tiger-docs]

# Comandos:

## Compilação
```sh
$ gcc *.c -o compilador
$ ./compilador Tiger/nome-do-arquivo.tig
$ ./compilador ../teste > teste.ll
$ llc ../teste.ll				
$ clang ../teste.s
```

## Testar analisador lexico

```sh
$ flex tiger.flex
$ gcc lex.yy.c -lfl
$ ./a.out
```

Tokens
> tiger.flex

## Testar analisador sintático

```sh
$ bison -d tiger.y
```

Gramática
> tiger.y


 [compiler-refs]: <http://www.cs.princeton.edu/~appel/modern/c/project.html>
 [tiger-docs]: <https://www.lrde.epita.fr/~tiger/tiger.html>
