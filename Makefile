# File              : Makefile
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 07.06.2022
# Last Modified Date: 26.12.2022
COV_REP	  :=	$(shell find run_dir -name 'coverage.dat')
SPEC_TEST	?=	#-k test_all_buffers['vanilla']
RUN_CMD		:=	docker run --rm --name ravenoc	\
							-v $(abspath .):/ravenoc -w			\
							/ravenoc aignacio/ravenoc

.PHONY: run cov clean all

all: run
	say ">Test run finished, please check the terminal"

run:
	$(RUN_CMD) tox -- $(SPEC_TEST)

coverage.info:
	verilator_coverage $(COV_REP) --write-info coverage.info

cov: coverage.info
	genhtml $< -o output_lcov

clean:
	$(RUN_CMD) rm -rf run_dir
