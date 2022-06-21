# File              : Makefile
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 07.06.2022
# Last Modified Date: 21.06.2022
COV_REP	  :=	$(shell find run_dir -name 'coverage.dat')

.PHONY: cov

coverage.info:
	verilator_coverage $(COV_REP) --write-info coverage.info

cov: coverage.info
	genhtml $< -o output_lcov
