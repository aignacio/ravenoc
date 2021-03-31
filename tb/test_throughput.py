#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : test_throughput.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 09.03.2021
# Last Modified Date: 09.03.2021
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
import random
import cocotb
import os
import logging
import pytest
import random
import string

from common_noc.testbench import Tb
from common_noc.constants import noc_const
from common_noc.ravenoc_pkt import RaveNoC_pkt
from cocotb_test.simulator import run
from cocotb.regression import TestFactory
from cocotb.utils import get_sim_time
from random import randrange
from cocotb.result import TestFailure
import itertools

async def run_test(dut, config_clk="NoC_slwT_AXI", idle_inserter=None, backpressure_inserter=None):
    noc_flavor = os.getenv("FLAVOR")
    noc_cfg = noc_const.NOC_CFG[noc_flavor]

    # Setup testbench
    tb = Tb(dut, f"sim_{config_clk}", noc_cfg)
    await tb.setup_clks(config_clk)
    await tb.arst(config_clk)

    max_size = (noc_cfg['max_sz_pkt']-1)*(int(noc_cfg['flit_data_width']/8))
    msg = tb._get_random_string(length=max_size)
    pkt = RaveNoC_pkt(cfg=noc_cfg, src_dest=(0,noc_cfg['max_nodes']-1), msg=msg)
    start_time = get_sim_time(units='ns')
    write = cocotb.fork(tb.write_pkt(pkt, timeout=noc_const.TIMEOUT_AXI_EXT))
    await tb.wait_irq()
    resp = await tb.read_pkt(pkt, timeout=noc_const.TIMEOUT_AXI_EXT)
    end_time = get_sim_time(units='ns')
    delta_time_txn = end_time - start_time
    max_size += (int(noc_cfg['flit_data_width']/8)) # Adding header flit into account
    tb.log.info("Delta time = %d ns",delta_time_txn)
    tb.log.info("Bytes transferred = %d B",max_size)
    bw = []
    bw.append(float(max_size/(1024**2))/float(delta_time_txn*10**-9))
    bw.append(float(max_size/(1024**3))/float(delta_time_txn*10**-9))
    tb.log.info("BW = %.2f MB/s (%.2f GB/s)",bw[0],bw[1])
    tb.check_pkt(resp.data,pkt.msg)

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("config_clk", ["AXI_slwT_NoC", "NoC_slwT_AXI", "NoC_equal_AXI"])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",noc_const.regression_setup)
def test_throughput(flavor):
    """
    Test to compute the max throughput of the NoC

    Test ID: 4

    Description:
    In this test we send the maximum payload pkt through the NoC from the router 0 to the
    last router (longest datapath), once we receive the first flit in the destination router,
    we start reading it simultaneously, once both operations are over. We then compare the
    data to check the integrity and compute the total throughput of this pkt over the NoC.
    """
    module = os.path.splitext(os.path.basename(__file__))[0]
    SIM_BUILD = os.path.join(noc_const.TESTS_DIR,
            f"../../run_dir/sim_build_{noc_const.SIMULATOR}_{module}_{flavor}")
    noc_const.EXTRA_ENV['SIM_BUILD'] = SIM_BUILD
    noc_const.EXTRA_ENV['FLAVOR'] = flavor

    extra_args_sim = noc_const._get_cfg_args(flavor)

    run(
        python_search=[noc_const.TESTS_DIR],
        includes=noc_const.INC_DIR,
        verilog_sources=noc_const.VERILOG_SOURCES,
        toplevel=noc_const.TOPLEVEL,
        module=module,
        sim_build=SIM_BUILD,
        extra_env=noc_const.EXTRA_ENV,
        extra_args=extra_args_sim
    )
