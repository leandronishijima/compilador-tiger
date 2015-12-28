# compilador-tiger

gcc *.c -o compilador
./compilador ../teste > teste.ll 
llc ../teste.ll				
clang ../teste.s
