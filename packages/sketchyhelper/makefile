all:
	(cd cpu_load && $(MAKE))
	(cd network_load && $(MAKE))

install: all
	mkdir -p ${out}/bin
	cp network_load/bin/sketchy_network_load ${out}/bin
	cp cpu_load/bin/sketchy_cpu_load ${out}/bin
