all: build run

build: hello-world.S bubble-sort.S
	loongarch64-unknown-linux-gnu-gcc -static hello-world.S -o hello-world
	loongarch64-unknown-linux-gnu-gcc -static bubble-sort.S -o bubble-sort
	loongarch64-unknown-linux-gnu-gcc -static inline-assembly.c -o inline-assembly
	loongarch64-unknown-linux-gnu-gcc -O2 -static inline-assembly.c -o inline-assembly-opt

run: hello-world
	qemu-loongarch64 ./hello-world
	qemu-loongarch64 ./bubble-sort
	qemu-loongarch64 ./inline-assembly
	qemu-loongarch64 ./inline-assembly-opt
	
