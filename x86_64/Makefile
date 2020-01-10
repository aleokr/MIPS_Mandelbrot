CC = g++
CFLAGS = -Wall -m64 -g
SFMLFLAGS = -lsfml-graphics -lsfml-window -lsfml-system

all: f.o main.o
	$(CC) f.o main.o $(CFLAGS) $(SFMLFLAGS) -o mandelbrot

f.o: f.s
	nasm -f elf64 -g -o f.o f.s

main.o: main.cpp
	$(CC) $(CFLAGS) $(SFMLFLAGS) -c main.cpp -o main.o 

clean:
	rm -f *.o
	rm -f mandelbrot
