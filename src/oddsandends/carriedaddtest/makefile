build:  ./obj/carried-add.o ./obj/carried-add-gen.o
	cc -shared -o libcarry.so ./obj/carried-add.o ./obj/carried-add-gen.o
	mv libcarry.so ./bin/

./obj/carried-add.o: ./src/carried-add.c
	cc -c -fpic ./src/carried-add.c
	mv carried-add.o ./obj/

./obj/carried-add-gen.o: ./src/carried-add-gen.c
	cc -c -fpic ./src/carried-add-gen.c
	mv carried-add-gen.o ./obj/

./src/carried-add-gen.c: ./src/carried_addgen.py
	python ./src/carried_addgen.py > ./src/carried-add-gen.c

clean:
	  rm ./src/carried-add-gen.c
		rm ./bin/*
		rm ./obj/*
