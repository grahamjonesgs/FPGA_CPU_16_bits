all: klausscc

klausscc: klausscc.o opcodes_parse.o helper.o macros.o
	 gcc -o klausscc klausscc.o opcodes_parse.o helper.o macros.o

klausscc.o: klausscc.c klausscc.h
	 gcc -c -g klausscc.c

opcodes_parse.o: opcodes_parse.c klausscc.h
	 	 gcc -c -g opcodes_parse.c

helper.o: helper.c klausscc.h
		 	 	 gcc -c -g helper.c

macros.o: macros.c klausscc.h
				 		 	 	 gcc -c -g macros.c
clean:
	 rm klausscc.o opcodes_parse.o helper.o macros.o klausscc

install:
	cp klausscc /usr/bin/.
