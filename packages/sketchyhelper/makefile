
sketchyhelper: sketchyhelper.c cpu.h sketchybarhelper/sketchybar.h
	clang -std=c99 -O3 sketchyhelper.c -o sketchyhelper

install: sketchyhelper
	mkdir -p ${out}/bin
	cp sketchyhelper ${out}/bin
