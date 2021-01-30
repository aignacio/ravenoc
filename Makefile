COCOTB_HDL_TIMEUNIT				= 1ns
COCOTB_HDL_TIMEPRECISION	= 1ns

VERILOG_SOURCES	:=	$(shell find src -type f -name *.svh)
VERILOG_SOURCES	+=	$(shell find src/include -type f -name *.sv)
VERILOG_SOURCES	+=	$(shell find src -type f -name *.v)
VERILOG_SOURCES	+=	$(shell find src -type f -name *.sv)

INCS_VERILOG		+=	src/include
INCS_VERILOG		:=	$(addprefix +incdir+,$(INCS_VERILOG))

MACRO_VLOG			:=	SIMULATION NO_ASSERTIONS
MACROS_VLOG			:=	$(addprefix +define+,$(MACRO_VLOG))

MODULE					?= test_ravenoc
TOPLEVEL				?= ravenoc
TOPLEVEL_LANG   ?= verilog
SIM							?= xcelium
GUI							:= 1

ifeq ($(SIM),xcelium)
	EXTRA_ARGS	+=	$(INCS_VERILOG)	\
									-64bit					\
									-smartlib				\
									-smartorder			\
									-access +rwc		\
									-clean					\
									-lineclean			\
									$(MACROS_VLOG)	\
									-input utils/dump_all_xcelium.tcl
else ifeq ($(SIM),verilator)
	EXTRA_ARGS	+=	--trace-fst					\
									--trace-structs			\
									$(INCS_VERILOG)			\
									--report-unoptflat	\
									--Wno-UNOPTFLAT
else
$(error "Only sims suported now are Verilator/Xcelium/IUS")
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

rtls:
	@echo "Listing all RTLs $(VERILOG_SOURCES)"
clean::
	@rm -rf sim_build waves.shm xrun.*
err:
	@grep --color "*E" xrun.log
wv:
	/Applications/gtkwave.app/Contents/Resources/bin/gtkwave dump.fst

