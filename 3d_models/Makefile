# 3d_models Makefile – export STLs via OpenSCAD CLI
# Usage: make stl   |  make clean  |  make list
#
# All printable parts (export_stls.sh PARTS list):
#   powder_hopper_v01
#   auger_screw_v01
#   auger_housing_v01
#   test_stand_v01
#   scale_platform_v01
#   hopper_lid_v01
#   loadcell_fixed_base_v01

.PHONY: stl clean list

stl:
	@bash scripts/export_stls.sh

clean:
	rm -f stl/*.stl

list:
	@echo "Sources:" && ls -1 openscad/*.scad
	@echo "Libs:" && ls -1 openscad/lib/*.scad
	@echo "STLs:" && ls -lh stl/*.stl 2>/dev/null || echo "  (none yet — run make stl)"
