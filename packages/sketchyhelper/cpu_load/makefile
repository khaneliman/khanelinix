bin/sketchy_cpu_load: cpu_load.c cpu.h ../sketchybar.h | bin
	clang -std=c99 -O3 $< -o $@

bin:
	mkdir bin

install: bin/sketchy_cpu_load
	mkdir -p ${out}/bin
	cp bin/sketchy_cpu_load ${out}/bin
