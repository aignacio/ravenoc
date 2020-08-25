WAVEFORM_VCD	?=	/tmp/$(ROOT_MOD_VERI).vcd
TMPL_WAVES		?=	utils/ravenoc.gtkw
OUT_VERILATOR	?=	output
MAX_THREAD		?=	4
EN_VCD				?=	1
SRC_VERILOG		:=	$(shell find src -type f -name *.v)
SRC_VERILOG		+=	$(shell find src -type f -name *.sv)
SRC_VERILOG		+=	$(shell find src -type f -name *.svh)
SRC_CPP				:=	$(wildcard tb/*.cpp)
ROOT_MOD_VERI	:=	ravenoc
INC_VERILOG		:=	src/include
INCS_VERILOG	:=	$(addprefix +incdir+,$(INC_VERILOG))
INC_CPP				:=
INCS_CPP			:=	$(addprefix -I,$(INC_CPP))
MACRO_VLOG		:=	SIMULATION
MACROS_VLOG		:=	$(addprefix +define+,$(MACRO_VLOG))
CPPFLAGS_VERI	:=	"$(INCS_CPP) -O3 -g3 -Wall 						\
									-Werror									 							\
									-DWAVEFORM_VCD=\"$(WAVEFORM_VCD)\" 		\
									-DEN_VCD=\"$(EN_VCD)\""
VERIL_FLAGS		:=	-O3 										\
									-Wno-CASEINCOMPLETE 		\
									-Wno-WIDTH							\
									-Wno-COMBDLY						\
									-Wno-UNOPTFLAT					\
									-Wno-LITENDIAN					\
									-Wno-UNSIGNED						\
									-Wno-IMPLICIT						\
									-Wno-CASEWITHX					\
									-Wno-CASEX							\
									-Wno-BLKANDNBLK					\
									-Wno-CMPCONST						\
									-Wno-MODDUP							\
									--exe										\
									--threads	$(MAX_THREAD)	\
									--trace 								\
									--trace-depth			10000	\
									--trace-max-array	10000	\
									--trace-max-width 10000	\
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
	gtkwave -go $(WAVEFORM_VCD) $(TMPL_WAVES)

clean:
	$(info Cleaning verilator simulation files...)
	$(info rm -rf $(OUT_VERILATOR))
	@rm -rf $(OUT_VERILATOR)
