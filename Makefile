all: build run

build: hello-world.S bubble-sort.S
	loongarch64-unknown-linux-gnu-gcc -static hello-world.S -o hello-world
	loongarch64-unknown-linux-gnu-gcc -static bubble-sort.S -o bubble-sort

run: hello-world
	qemu-loongarch64 ./hello-world
	qemu-loongarch64 ./bubble-sort
	
