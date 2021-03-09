import os
import glob

#@pytest.mark.skipif((os.getenv("SIM") != "verilator") and (os.getenv("SIM") != "xcelium") and (os.getenv("SIM") != "ius"), reason="Verilator/Xcelium are the only supported to simulate...")
CLK_100MHz  = (10, "ns")
CLK_200MHz  = (5, "ns")
RST_CYCLES  = 2
TIMEOUT_AXI = (CLK_100MHz[0]*100, "ns")

tests_dir = os.path.dirname(os.path.abspath(__file__))
rtl_dir   = os.path.join(tests_dir,"../src/")
inc_dir   = [f'{rtl_dir}include']
toplevel  = str(os.getenv("DUT"))
simulator = str(os.getenv("SIM"))
verilog_sources = [] # The sequence below is important...
verilog_sources = verilog_sources + glob.glob(f'{rtl_dir}include/*.sv',recursive=True)
verilog_sources = verilog_sources + glob.glob(f'{rtl_dir}include/*.svh',recursive=True)
verilog_sources = verilog_sources + glob.glob(f'{rtl_dir}**/*.sv',recursive=True)
extra_env = {}
extra_env['COCOTB_HDL_TIMEUNIT'] = os.getenv("TIMEUNIT")
extra_env['COCOTB_HDL_TIMEPRECISION'] = os.getenv("TIMEPREC")
if simulator == "verilator":
    extra_args = ["--trace-fst","--trace-structs","--Wno-UNOPTFLAT","--Wno-REDEFMACRO"]
elif simulator == "xcelium" or simulator == "ius":
    extra_args = ["-64bit                                           \
                   -smartlib				                        \
                   -smartorder			                            \
                   -gui                                             \
                   -clean                                           \
                   -sv"    ]
else:
    extra_args = []

# Vanilla / Coffee HW mux
extra_args_vanilla = extra_args
extra_args_coffee = extra_args

#NoC data width
extra_args_vanilla.append("-DFLIT_DATA=32")
extra_args_coffee.append("-DFLIT_DATA=64")

#NoC routing algorithm
extra_args_vanilla.append("-DROUTING_ALG=\"X_Y_ALG\"")
extra_args_coffee.append("-DROUTING_ALG=\"Y_X_ALG\"")

#NoC routing algorithm
# extra_args_vanilla.append("-DN_VIRT_CHN=5")
# extra_args_coffee.append("-DN_VIRT_CHN=2")

#NoC X and Y dimensions
extra_args_vanilla.append("-DNOC_CFG_SZ_X=2")
extra_args_vanilla.append("-DNOC_CFG_SZ_Y=2")

extra_args_coffee.append("-DNOC_CFG_SZ_X=4")
extra_args_coffee.append("-DNOC_CFG_SZ_Y=3")

#NoC per InputBuffer buffering
extra_args_vanilla.append("-DFLIT_BUFF=2")
extra_args_coffee.append("-DFLIT_BUFF=4")


