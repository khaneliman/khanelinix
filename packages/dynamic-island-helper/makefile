dynamic-island-helper: islandhelper.c dynamicisland.h sketchybar.h notificationhelper.h
	clang -std=c99 -O3 islandhelper.c -o dynamic-island-helper -l sqlite3 -framework CoreFoundation

install: dynamic-island-helper
	mkdir -p ${out}/bin
	cp dynamic-island-helper ${out}/bin
