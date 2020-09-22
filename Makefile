WAVEFORM			?=	/tmp/$(ROOT_MOD_VERI).fst
TMPL_WAVES		?=	utils/ravenoc.gtkw
OUT_VERILATOR	?=	output
MAX_THREAD		?=	4
EN_TRACE			?=	1
SRC_VERILOG		:=	$(shell find src -type f -name *.svh)
SRC_VERILOG		+=	$(shell find src/include -type f -name *.sv)
SRC_VERILOG		+=	$(shell find src -type f -name *.v)
SRC_VERILOG		+=	$(shell find src -type f -name *.sv)
SRC_CPP				:=	$(wildcard tb/*.cpp)
ROOT_MOD_VERI	:=	ravenoc
INC_VERILOG		:=	src/include
INCS_VERILOG	:=	$(addprefix +incdir+,$(INC_VERILOG))
INC_CPP				:=
INCS_CPP			:=	$(addprefix -I,$(INC_CPP))
MACRO_VLOG		:=	SIMULATION
MACROS_VLOG		:=	$(addprefix +define+,$(MACRO_VLOG))
CPPFLAGS_VERI	:=	"$(INCS_CPP) -g3 -Wall		  	\
									-Werror												\
									-DWAVEFORM=\"$(WAVEFORM)\" 		\
									-DEN_TRACE=\"$(EN_TRACE)\""

#									-Wno-CASEINCOMPLETE 		\
#									-Wno-WIDTH							\
#									-Wno-COMBDLY						\
#									-Wno-UNOPTFLAT					\
#									-Wno-LITENDIAN					\
#									-Wno-UNSIGNED						\
#									-Wno-IMPLICIT						\
#									-Wno-CASEWITHX					\
#									-Wno-CASEX							\
#									-Wno-BLKANDNBLK					\
#									-Wno-CMPCONST						\
#									-Wno-MODDUP							\
									--Wno-WIDTH							\

VERIL_FLAGS		:=  --Wno-UNOPTFLAT					\
									-O3 										\
									--exe										\
									--threads	$(MAX_THREAD)	\
									--trace 								\
									--clk			clk						\
									--trace-fst							\
									--trace-structs					\
									--trace-threads 4				\
									--trace-underscore			\
									--trace-depth			10000	\
									--trace-max-array	10000	\
									--trace-max-width	10000	\
									--cc
VERIL_ARGS		:=	-CFLAGS $(CPPFLAGS_VERI) 			\
									--top-module $(ROOT_MOD_VERI) \
									--Mdir $(OUT_VERILATOR)				\
									$(VERIL_FLAGS)								\
									$(INCS_CPP)										\
									$(INCS_VERILOG) 							\
									$(MACROS_VLOG)							 	\
									$(SRC_VERILOG) 								\
									$(SRC_CPP) 										\
									-o 														\
									$(ROOT_MOD_VERI)

### Simvsion var
SRC_XRUN			:=	"+incdir+../src +incdir+../src/include"
SRC_XRUN			+=	$(addprefix -sv ../,$(SRC_VERILOG))
XRUN_FLAGS		+=	-64bit	\
									-top	tb_top \
									-smartlib	\
									-smartorder	\
									-access +rwc	\
									-clean	\
									-lineclean	\
									-gui	\
									-messages \
									-input ../utils/dump_all_xcelium.tcl
#"
########################################################################
###################### DO NOT EDIT ANYTHING BELOW ######################
########################################################################
VERILATOR_EXE	:=	$(OUT_VERILATOR)/$(ROOT_MOD_VERI)

$(OUT_VERILATOR)/V$(ROOT_MOD_VERI).mk: $(SRC_VERILOG) $(SRC_CPP)
	verilator $(VERIL_ARGS)

$(VERILATOR_EXE): $(OUT_VERILATOR)/V$(ROOT_MOD_VERI).mk
	+@make -C $(OUT_VERILATOR) -f V$(ROOT_MOD_VERI).mk

all: $(VERILATOR_EXE)
	$(VERILATOR_EXE)

wave:
	/Applications/gtkwave.app/Contents/Resources/bin/gtkwave $(WAVEFORM) $(TMPL_WAVES)

clean:
	$(info Cleaning verilator simulation files...)
	$(info rm -rf $(OUT_VERILATOR))
	@rm -rf $(OUT_VERILATOR)
	#@rm -rf sim

err:
	@grep --color "*E" sim/xrun.log

xrun:
	@mkdir -p sim
	@echo $(SRC_XRUN)
	@cd sim && xrun $(XRUN_FLAGS) $(SRC_XRUN) -sv ../tb/testbench.sv
