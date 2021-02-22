import os
import glob

#@pytest.mark.skipif((os.getenv("SIM") != "verilator") and (os.getenv("SIM") != "xcelium") and (os.getenv("SIM") != "ius"), reason="Verilator/Xcelium are the only supported to simulate...")
CLK_100MHz  = (10, "ns")
CLK_200MHz  = (5, "ns")
RST_CYCLES  = 2
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
    extra_args = ["--trace-fst","--trace-structs","--Wno-UNOPTFLAT"]
elif simulator == "xcelium" or simulator == "ius":
    extra_args = ["-64bit                                           \
				   -smartlib				                        \
				   -smartorder			                            \
				   -access +rwc		                                \
				   -clean					                        \
				   -lineclean			                            \
                   -createdebugdb                                   \
                   -gui                                             \
                   -sv"    ]
else:
    extra_args = []


