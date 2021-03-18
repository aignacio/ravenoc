#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : constants.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 09.03.2021
# Last Modified Date: 09.03.2021
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
import os
import glob
import copy
import math

class noc_const:
    CLK_100MHz  = (10, "ns")
    CLK_200MHz  = (5, "ns")
    RST_CYCLES  = 3
    TIMEOUT_AXI = (CLK_100MHz[0]*100, "ns")
    TIMEOUT_IRQ_V = 100
    TIMEOUT_IRQ = (CLK_100MHz[0]*100, "ns")

    TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
    RTL_DIR   = os.path.join(TESTS_DIR,"../../src/")
    INC_DIR   = [f'{RTL_DIR}include']
    TOPLEVEL  = str(os.getenv("DUT"))
    SIMULATOR = str(os.getenv("SIM"))
    VERILOG_SOURCES = [] # The sequence below is important...
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}include/*.sv',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}include/*.svh',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}**/*.sv',recursive=True)
    EXTRA_ENV = {}
    EXTRA_ENV['COCOTB_HDL_TIMEUNIT'] = os.getenv("TIMEUNIT")
    EXTRA_ENV['COCOTB_HDL_TIMEPRECISION'] = os.getenv("TIMEPREC")
    if SIMULATOR == "verilator":
        #EXTRA_ARGS = ["--trace-fst","--trace-structs","--Wno-UNOPTFLAT","--Wno-REDEFMACRO"]
        #EXTRA_ARGS = ["--threads 4","--trace-fst","--trace-structs","--Wno-UNOPTFLAT","--Wno-REDEFMACRO"]
        EXTRA_ARGS = ["--trace-fst","--trace-structs","--Wno-UNOPTFLAT","--Wno-REDEFMACRO"]
    elif SIMULATOR == "xcelium" or SIMULATOR == "ius":
        EXTRA_ARGS = ["-64bit                                           \
                       -smartlib				                        \
                       -smartorder			                            \
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
    NOC_CFG_COFFEE = {}
    NOC_CFG_VANILLA = {}

    #--------------------------
    #
    # Parameters that'll change the HW
    #
    #-------------------------
    #NoC width of AXI+NoC_DATA
    NOC_CFG_VANILLA['flit_data_width'] = 32
    #NoC routing algorithm
    NOC_CFG_VANILLA['routing_alg'] = "X_Y_ALG"
    #NoC X and Y dimensions
    NOC_CFG_VANILLA['noc_cfg_sz_rows'] = 2 # Number of row/lines
    NOC_CFG_VANILLA['noc_cfg_sz_cols'] = 2 # Number of cols
    #NoC per InputBuffer buffering
    NOC_CFG_VANILLA['flit_buff'] = 2
    # Max number of flits per packet
    NOC_CFG_VANILLA['max_sz_pkt'] = 256


    #NoC width of AXI+NoC_DATA
    NOC_CFG_COFFEE['flit_data_width'] = 64
    #NoC routing algorithm
    NOC_CFG_COFFEE['routing_alg'] = "Y_X_ALG"
    #NoC X and Y dimensions
    NOC_CFG_COFFEE['noc_cfg_sz_rows'] = 4 # Number of row/lines
    NOC_CFG_COFFEE['noc_cfg_sz_cols'] = 3 # Number of cols
    #NoC per InputBuffer buffering
    NOC_CFG_COFFEE['flit_buff'] = 2
    # Max number of flits per packet
    NOC_CFG_COFFEE['max_sz_pkt'] = 256


    for param in NOC_CFG_VANILLA.items():
        EXTRA_ARGS_VANILLA.append("-D"+param[0].upper()+"="+str(param[1]))

    for param in NOC_CFG_COFFEE.items():
        EXTRA_ARGS_COFFEE.append("-D"+param[0].upper()+"="+str(param[1]))

    #--------------------------
    #
    # Parameters that'll be used in tb
    #
    #-------------------------
    NOC_CFG_VANILLA['max_nodes'] = NOC_CFG_VANILLA['noc_cfg_sz_rows']*NOC_CFG_VANILLA['noc_cfg_sz_cols']
    NOC_CFG_COFFEE['max_nodes'] = NOC_CFG_COFFEE['noc_cfg_sz_rows']*NOC_CFG_COFFEE['noc_cfg_sz_cols']

    NOC_CFG_VANILLA['x_w'] = len(bin(NOC_CFG_VANILLA['noc_cfg_sz_rows']-1))-2
    NOC_CFG_COFFEE['x_w'] = len(bin(NOC_CFG_COFFEE['noc_cfg_sz_rows']-1))-2

    NOC_CFG_VANILLA['y_w'] = len(bin(NOC_CFG_VANILLA['noc_cfg_sz_cols']-1))-2
    NOC_CFG_COFFEE['y_w'] = len(bin(NOC_CFG_COFFEE['noc_cfg_sz_cols']-1))-2

    NOC_CFG_VANILLA['sz_pkt_w'] = len(bin(NOC_CFG_VANILLA['max_sz_pkt']-1))-2
    NOC_CFG_COFFEE['sz_pkt_w'] =len(bin(NOC_CFG_COFFEE['max_sz_pkt']-1))-2

    NOC_CFG_VANILLA['vc_w_id'] = (0x1000,0x1008,0x1010)
    NOC_CFG_COFFEE['vc_w_id'] = (0x1000,0x1008,0x1010)

    NOC_CFG_VANILLA['vc_r_id'] = (0x2000,0x2008,0x2010)
    NOC_CFG_COFFEE['vc_r_id'] = (0x2000,0x2008,0x2010)

    NOC_CFG['coffee'] = NOC_CFG_COFFEE
    NOC_CFG['vanilla'] = NOC_CFG_VANILLA

