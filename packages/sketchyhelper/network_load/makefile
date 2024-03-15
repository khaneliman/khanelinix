bin/sketchy_network_load: network_load.c network.h ../sketchybar.h | bin
	clang -std=c99 -O3 $< -o $@

bin:
	mkdir bin

install: bin/sketchy_network_load
	mkdir -p ${out}/bin
	cp bin/sketchy_network_load ${out}/bin
