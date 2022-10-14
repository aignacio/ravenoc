#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : constants.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 09.03.2021
# Last Modified Date: 14.10.2022
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
import os
import glob
import copy
import math

class noc_const:
    regression_setup = ['vanilla', 'coffee']
    if os.getenv("FULL_REGRESSION"):
        regression_setup.append('liquorice')

    # NoC CSRs addresses
    NOC_CSRs = {}
    NOC_CSRs['RAVENOC_VERSION']  = 0x3000
    NOC_CSRs['ROUTER_ROW_X_ID']  = 0x3004
    NOC_CSRs['ROUTER_COL_Y_ID']  = 0x3008
    NOC_CSRs['IRQ_RD_STATUS']    = 0x300c
    NOC_CSRs['IRQ_RD_MUX']       = 0x3010
    NOC_CSRs['IRQ_RD_MASK']      = 0x3014
    NOC_CSRs['RD_SIZE_VC_START'] = 0x3018

    NOC_VERSION = "v1.0"
    CLK_100MHz  = (10, "ns")
    CLK_200MHz  = (5, "ns")
    RST_CYCLES  = 3
    TIMEOUT_AXI = (CLK_100MHz[0]*200, "ns")
    TIMEOUT_AXI_EXT = (CLK_200MHz[0]*5000, "ns")
    TIMEOUT_IRQ_V = 100
    TIMEOUT_IRQ = (CLK_100MHz[0]*100, "ns")

    TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
    RTL_DIR   = os.path.join(TESTS_DIR,"../../src/")
    INC_DIR   = [f'{RTL_DIR}include']
    TOPLEVEL  = str(os.getenv("DUT"))
    SIMULATOR = str(os.getenv("SIM"))
    VERILOG_SOURCES = [] # The sequence below is important...
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}include/ravenoc_defines.svh',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'amba_sv_structs/amba_axi_pkg.sv',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}include/ravenoc_structs.svh',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}include/ravenoc_axi_fnc.svh',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}include/*.sv',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}**/*.sv',recursive=True)
    EXTRA_ENV = {}
    EXTRA_ENV['COCOTB_HDL_TIMEUNIT'] = os.getenv("TIMEUNIT")
    EXTRA_ENV['COCOTB_HDL_TIMEPRECISION'] = os.getenv("TIMEPREC")
    if SIMULATOR == "verilator":
        #EXTRA_ARGS = ["--trace-fst","--trace-structs","--Wno-UNOPTFLAT","--Wno-REDEFMACRO"]
        #EXTRA_ARGS = ["--threads 4","--trace-fst","--trace-structs","--Wno-UNOPTFLAT","--Wno-REDEFMACRO"]
        EXTRA_ARGS = ["--trace-fst","--coverage","--coverage-line","--coverage-toggle","--trace-structs","--Wno-UNOPTFLAT","--Wno-REDEFMACRO"]
    elif SIMULATOR == "icarus":
        EXTRA_ARGS = ["-g2012"]
    elif SIMULATOR == "xcelium" or SIMULATOR == "ius":
        EXTRA_ARGS = [" -64bit                                           \
                        -smartlib				                         \
                        -smartorder			                             \
                        -gui                                             \
                        -clean                                           \
                        -sv"    ]
    else:
        EXTRA_ARGS = []

    NOC_CFG = {}

    # Vanilla / Coffee HW mux
    # We need to use deepcopy bc of weak shallow copy of reference from python
    EXTRA_ARGS_VANILLA = copy.deepcopy(EXTRA_ARGS)
    EXTRA_ARGS_COFFEE = copy.deepcopy(EXTRA_ARGS)
    EXTRA_ARGS_LIQ = copy.deepcopy(EXTRA_ARGS)
    NOC_CFG_COFFEE = {}
    NOC_CFG_VANILLA = {}
    NOC_CFG_LIQ = {}

    #--------------------------
    #
    # Parameters that'll change the HW
    #
    #-------------------------

    #--------------------------
    # Vanilla
    #-------------------------
    #NoC width of AXI+NoC_DATA
    NOC_CFG_VANILLA['flit_data_width'] = 32
    #NoC routing algorithm
    NOC_CFG_VANILLA['routing_alg'] = "XYAlg"
    #NoC X and Y dimensions
    NOC_CFG_VANILLA['noc_cfg_sz_rows'] = 2 # Number of row/lines
    NOC_CFG_VANILLA['noc_cfg_sz_cols'] = 2 # Number of cols
    #NoC per InputBuffer buffering
    NOC_CFG_VANILLA['flit_buff'] = 1
    # Max number of flits per packet
    NOC_CFG_VANILLA['max_sz_pkt'] = 256
    # Number of virtual channels
    NOC_CFG_VANILLA['n_virt_chn'] = 2
    # Priority level of VCs - 0=0 has high prior / 1=0 has lower prior
    NOC_CFG_VANILLA['h_priority'] = "ZeroHighPrior"

    #--------------------------
    # Coffee
    #-------------------------
    #NoC width of AXI+NoC_DATA
    NOC_CFG_COFFEE['flit_data_width'] = 64
    #NoC routing algorithm
    NOC_CFG_COFFEE['routing_alg'] = "YXAlg"
    #NoC X and Y dimensions
    NOC_CFG_COFFEE['noc_cfg_sz_rows'] = 4 # Number of row/lines
    NOC_CFG_COFFEE['noc_cfg_sz_cols'] = 4 # Number of cols
    #NoC per InputBuffer buffering
    NOC_CFG_COFFEE['flit_buff'] = 2
    # Max number of flits per packet
    NOC_CFG_COFFEE['max_sz_pkt'] = 256
    # Number of virtual channels
    NOC_CFG_COFFEE['n_virt_chn'] = 3
    # Priority level of VCs - 0=0 has high prior / 1=0 has lower prior
    NOC_CFG_COFFEE['h_priority'] = "ZeroLowPrior"

    #--------------------------
    # Liquorice
    #-------------------------
    #NoC width of AXI+NoC_DATA
    NOC_CFG_LIQ['flit_data_width'] = 64
    #NoC routing algorithm
    NOC_CFG_LIQ['routing_alg'] = "XYAlg"
    #NoC X and Y dimensions
    NOC_CFG_LIQ['noc_cfg_sz_rows'] = 8 # Number of row/lines
    NOC_CFG_LIQ['noc_cfg_sz_cols'] = 8 # Number of cols
    #NoC per InputBuffer buffering
    NOC_CFG_LIQ['flit_buff'] = 4
    # Max number of flits per packet
    NOC_CFG_LIQ['max_sz_pkt'] = 256
    # Number of virtual channels
    NOC_CFG_LIQ['n_virt_chn'] = 4
    # Priority level of VCs - 0=0 has high prior / 1=0 has lower prior
    NOC_CFG_LIQ['h_priority'] = "ZeroHighPrior"

    for param in NOC_CFG_VANILLA.items():
        EXTRA_ARGS_VANILLA.append("-D"+param[0].upper()+"="+str(param[1]))

    for param in NOC_CFG_COFFEE.items():
        EXTRA_ARGS_COFFEE.append("-D"+param[0].upper()+"="+str(param[1]))

    for param in NOC_CFG_LIQ.items():
        EXTRA_ARGS_LIQ.append("-D"+param[0].upper()+"="+str(param[1]))
    #--------------------------
    #
    # Parameters that'll be used in tb
    #
    #-------------------------
    NOC_CFG_VANILLA['max_nodes'] = NOC_CFG_VANILLA['noc_cfg_sz_rows']*NOC_CFG_VANILLA['noc_cfg_sz_cols']
    NOC_CFG_VANILLA['x_w'] = len(bin(NOC_CFG_VANILLA['noc_cfg_sz_rows']-1))-2
    NOC_CFG_VANILLA['y_w'] = len(bin(NOC_CFG_VANILLA['noc_cfg_sz_cols']-1))-2
    NOC_CFG_VANILLA['sz_pkt_w'] = len(bin(NOC_CFG_VANILLA['max_sz_pkt']-1))-2
    NOC_CFG_VANILLA['vc_w_id'] = [(x*8+(0x1000)) for x in range(NOC_CFG_VANILLA['n_virt_chn'])]
    NOC_CFG_VANILLA['vc_r_id'] = [(x*8+(0x2000)) for x in range(NOC_CFG_VANILLA['n_virt_chn'])]
    NOC_CFG['vanilla'] = NOC_CFG_VANILLA

    NOC_CFG_COFFEE['max_nodes'] = NOC_CFG_COFFEE['noc_cfg_sz_rows']*NOC_CFG_COFFEE['noc_cfg_sz_cols']
    NOC_CFG_COFFEE['x_w'] = len(bin(NOC_CFG_COFFEE['noc_cfg_sz_rows']-1))-2
    NOC_CFG_COFFEE['y_w'] = len(bin(NOC_CFG_COFFEE['noc_cfg_sz_cols']-1))-2
    NOC_CFG_COFFEE['sz_pkt_w'] =len(bin(NOC_CFG_COFFEE['max_sz_pkt']-1))-2
    NOC_CFG_COFFEE['vc_w_id'] = [(x*8+(0x1000)) for x in range(NOC_CFG_COFFEE['n_virt_chn'])]
    NOC_CFG_COFFEE['vc_r_id'] = [(x*8+(0x2000)) for x in range(NOC_CFG_COFFEE['n_virt_chn'])]
    NOC_CFG['coffee'] = NOC_CFG_COFFEE

    NOC_CFG_LIQ['max_nodes'] = NOC_CFG_LIQ['noc_cfg_sz_rows']*NOC_CFG_LIQ['noc_cfg_sz_cols']
    NOC_CFG_LIQ['x_w'] = len(bin(NOC_CFG_LIQ['noc_cfg_sz_rows']-1))-2
    NOC_CFG_LIQ['y_w'] = len(bin(NOC_CFG_LIQ['noc_cfg_sz_cols']-1))-2
    NOC_CFG_LIQ['sz_pkt_w'] =len(bin(NOC_CFG_LIQ['max_sz_pkt']-1))-2
    NOC_CFG_LIQ['vc_w_id'] = [(x*8+(0x1000)) for x in range(NOC_CFG_LIQ['n_virt_chn'])]
    NOC_CFG_LIQ['vc_r_id'] = [(x*8+(0x2000)) for x in range(NOC_CFG_LIQ['n_virt_chn'])]
    NOC_CFG['liquorice'] = NOC_CFG_LIQ

    def _get_cfg_args(flavor):
        if flavor == "vanilla":
            return noc_const.EXTRA_ARGS_VANILLA
        elif flavor == "coffee":
            return noc_const.EXTRA_ARGS_COFFEE
        else:
            return noc_const.EXTRA_ARGS_LIQ

