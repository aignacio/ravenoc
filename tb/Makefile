COCOTB_HDL_TIMEUNIT				= 1ns
COCOTB_HDL_TIMEPRECISION	= 100ps

MODULE					?= test_ravenoc_basic
TOPLEVEL				?= ravenoc_wrapper
TOPLEVEL_LANG   ?= verilog
SIM							?= verilator
GUI							:= 1

VERILOG_SOURCES	:=	$(shell find ../src -type f -name *.svh)
VERILOG_SOURCES	+=	$(shell find ../src/include -type f -name *.sv)
VERILOG_SOURCES	+=	$(shell find ../src -type f -name *.v)
VERILOG_SOURCES	+=	$(shell find ../src -type f -name *.sv)

INCS_VERILOG		+=	../src/include
INCS_VERILOG		:=	$(addprefix +incdir+,$(INCS_VERILOG))

MACRO_VLOG			:=	SIMULATION NO_ASSERTIONS
MACROS_VLOG			:=	$(addprefix +define+,$(MACRO_VLOG))

DEF_PARAM				:=	DEBUG=1
DEFS_PARAM_XCL	:=	$(addprefix -defparam $(TOPLEVEL).,$(DEF_PARAM))
DEFS_PARAM_VER	:=	$(addprefix -G,$(DEF_PARAM))

ifeq ($(SIM),xcelium)
	EXTRA_ARGS	+=	$(INCS_VERILOG)		\
									$(MACROS_VLOG)		\
									$(DEFS_PARAM_XCL)	\
									-64bit						\
									-smartlib					\
									-smartorder				\
									-access +rwc			\
									-clean						\
									-lineclean				\
									-debugscript			dbg.csh	\
									-input utils/dump_all_xcelium.tcl
else ifeq ($(SIM),verilator)
	EXTRA_ARGS	+=	$(INCS_VERILOG)			\
									$(MACROS_VLOG)			\
									$(DEFS_PARAM_VER)		\
									--trace-fst					\
									--trace-structs			\
									--report-unoptflat	\
									--Wno-UNOPTFLAT
else
$(error "Only sims suported now are Verilator/Xcelium/IUS")
endif

rtls:
	@echo "Listing all RTLs $(VERILOG_SOURCES)"
clean::
	@rm -rf tb/sim_build* waves.shm xrun.*
err:
	@grep --color "*E" xrun.log
wv:
	/Applications/gtkwave.app/Contents/Resources/bin/gtkwave dump.fst

include $(shell cocotb-config --makefiles)/Makefile.sim
