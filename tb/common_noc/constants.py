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
    RST_CYCLES  = 2
    TIMEOUT_AXI = (CLK_100MHz[0]*100, "ns")

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

    #NoC data width
    EXTRA_ARGS_VANILLA.append("-DFLIT_DATA=32")
    EXTRA_ARGS_COFFEE.append("-DFLIT_DATA=64")
    NOC_CFG_VANILLA['flit_data'] = 32
    NOC_CFG_COFFEE['flit_data'] = 64

    #NoC routing algorithm
    EXTRA_ARGS_VANILLA.append("-DROUTING_ALG=\"X_Y_ALG\"")
    EXTRA_ARGS_COFFEE.append("-DROUTING_ALG=\"Y_X_ALG\"")
    NOC_CFG_VANILLA['alg'] = "X_Y_ALG"
    NOC_CFG_COFFEE['alg'] = "Y_X_ALG"

    #NoC X and Y dimensions
    EXTRA_ARGS_VANILLA.append("-DNOC_CFG_SZ_X=2")
    EXTRA_ARGS_VANILLA.append("-DNOC_CFG_SZ_Y=2")
    NOC_CFG_VANILLA['x_s'] = 2
    NOC_CFG_VANILLA['y_s'] = 2
    NOC_CFG_VANILLA['x_w'] = int(math.log(NOC_CFG_VANILLA['x_s'],2))#len(bin(NOC_CFG_VANILLA['x_s']))-2
    NOC_CFG_VANILLA['y_w'] = int(math.log(NOC_CFG_VANILLA['y_s'],2))#len(bin(NOC_CFG_VANILLA['y_s']))-2
    NOC_CFG_VANILLA['max_nodes'] = NOC_CFG_VANILLA['x_s']*NOC_CFG_VANILLA['y_s']


    EXTRA_ARGS_COFFEE.append("-DNOC_CFG_SZ_X=4")
    EXTRA_ARGS_COFFEE.append("-DNOC_CFG_SZ_Y=4")
    NOC_CFG_COFFEE['x_s'] = 4
    NOC_CFG_COFFEE['y_s'] = 4
    NOC_CFG_COFFEE['x_w'] = int(math.log(NOC_CFG_COFFEE['x_s'],2))
    NOC_CFG_COFFEE['y_w'] = int(math.log(NOC_CFG_COFFEE['y_s'],2))
    NOC_CFG_COFFEE['max_nodes'] = NOC_CFG_COFFEE['x_s']*NOC_CFG_COFFEE['y_s']

    #NoC per InputBuffer buffering
    EXTRA_ARGS_VANILLA.append("-DFLIT_BUFF=2")
    NOC_CFG_VANILLA['buff'] = 2
    NOC_CFG_VANILLA['pkt_w'] = 8

    EXTRA_ARGS_COFFEE.append("-DFLIT_BUFF=4")
    NOC_CFG_COFFEE['buff'] = 4
    NOC_CFG_COFFEE['pkt_w'] = 8

    NOC_CFG_VANILLA['vc_w_id'] = (0x1000,0x1008,0x100c)
    NOC_CFG_VANILLA['vc_r_id'] = (0x2000,0x2008,0x200c)

    NOC_CFG_COFFEE['vc_w_id'] = (0x1000,0x1008,0x100c)
    NOC_CFG_COFFEE['vc_r_id'] = (0x2000,0x2008,0x200c)

    #NoC routing algorithm
    # extra_args_vanilla.append("-DN_VIRT_CHN=5")
    # extra_args_coffee.append("-DN_VIRT_CHN=2")

    NOC_CFG['coffee'] = NOC_CFG_COFFEE
    NOC_CFG['vanilla'] = NOC_CFG_VANILLA

