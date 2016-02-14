# Compilador Tiger

# Utils
  - [Tiger compiler modules for programming exercises][compiler-refs]
  - [Tiger reference language][tiger-docs]

# Comandos:

## Compilação
```sh
$ gcc *.c -o compilador
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

### Adicionar no arquivo tiger.flex

```c
int main() {
    yylex();
    return 0;
}
```

Tokens
> tiger.flex

```sh
$ bison tiger.y
```

## Testar analisador sintático

Gramática
> tiger.y


 [compiler-refs]: <http://www.cs.princeton.edu/~appel/modern/c/project.html>
 [tiger-docs]: <https://www.lrde.epita.fr/~tiger/tiger.html>
