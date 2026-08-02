# 3d_models Makefile – export STLs via OpenSCAD CLI
# Usage: make stl   |  make clean

.PHONY: stl clean list

stl:
	@bash scripts/export_stls.sh

clean:
	rm -f stl/*.stl

list:
	@echo "Sources:" && ls -1 openscad/*.scad
	@echo "Libs:" && ls -1 openscad/lib/*.scad
	@echo "STLs:" && ls -1 stl/*.stl 2>/dev/null || echo "  (none yet — run make stl)"
