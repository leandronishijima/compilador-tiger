# Compilador Tiger

# Utils
  - [Tiger compiler modules for programming exercises][compiler-refs]
  - [Tiger reference language][tiger-docs]

# Comandos:

```sh
$ gcc *.c -o compilador
$ ./compilador ../teste > teste.ll
$ llc ../teste.ll				
$ clang ../teste.s
```
Tokens
> tiger.flex

Gramática
> tiger.y


 [compiler-refs]: <http://www.cs.princeton.edu/~appel/modern/c/project.html>
 [tiger-docs]: <https://www.lrde.epita.fr/~tiger/tiger.html>
