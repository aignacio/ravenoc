
VERILOG_SOURCES	:=	$(shell find src -type f -name *.svh)
VERILOG_SOURCES	+=	$(shell find src/include -type f -name *.sv)
VERILOG_SOURCES	+=	$(shell find src -type f -name *.v)
VERILOG_SOURCES	+=	$(shell find src -type f -name *.sv)

INCS_VERILOG		+=	src/include
INCS_VERILOG		:=	$(addprefix +incdir+,$(INCS_VERILOG))

TOPLEVEL		:=	ravenoc
MODULE			:=	test_ravenoc
SIM					:=	verilator
EXTRA_ARGS	+= --trace-fst --trace-structs $(INCS_VERILOG) --report-unoptflat
#--Wno-UNOPTFLAT

all:
	@echo "Listing all RTLs $(VERILOG_SOURCES)"

include $(shell cocotb-config --makefiles)/Makefile.sim
