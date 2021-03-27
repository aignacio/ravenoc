#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : test_wrong_ops.py
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

from common_noc.testbench import Tb
from common_noc.constants import noc_const
from cocotb_test.simulator import run
from cocotb.regression import TestFactory
from random import randint, randrange, getrandbits
from cocotbext.axi import AxiResp,AxiBurstType
import itertools

async def run_test(dut, config_clk="NoC_slwT_AXI", idle_inserter=None, backpressure_inserter=None):
    noc_flavor = os.getenv("FLAVOR")
    noc_cfg = noc_const.NOC_CFG[noc_flavor]

    # Setup testbench
    idle = "no_idle" if idle_inserter == None else "w_idle"
    backp = "no_backpressure" if backpressure_inserter == None else "w_backpressure"
    tb = Tb(dut,f"sim_{config_clk}_{idle}_{backp}")
    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)
    await tb.setup_clks(config_clk)
    await tb.arst(config_clk)

    # Valid write region
    result = await tb.write(sel=randrange(0,noc_cfg['max_nodes']),
                            address=noc_cfg['vc_w_id'][randrange(0,noc_cfg['n_virt_chn'])],
                            data="Test")
    assert result.resp == AxiResp.OKAY, "AXI should not raise an error on this txn"

    # Invalid memory address WR - out of range
    await tb.arst(config_clk)
    rand_addr = randrange(0,2**32)
    while rand_addr in noc_cfg['vc_w_id']:
        rand_addr = randrange(0,2**32)
    result = await tb.write(sel=randrange(0,noc_cfg['max_nodes']),
                            address=rand_addr,
                            data="Test")
    assert result.resp == AxiResp.SLVERR, "AXI bus should have raised an error when writing to an invalid region of memory"

    # Invalid memory address WR - writing in RD buffer
    await tb.arst(config_clk)
    result = await tb.write(sel=randrange(0,noc_cfg['max_nodes']),
                            address=noc_cfg['vc_r_id'][randrange(0,noc_cfg['n_virt_chn'])],
                            data="Test")
    assert result.resp == AxiResp.SLVERR, "AXI bus should have raised an error when writing to an invalid region of memory"

    # Invalid burst type
    await tb.arst(config_clk)
    result = await tb.write(sel=randrange(0,noc_cfg['max_nodes']),
                            address=noc_cfg['vc_w_id'][randrange(0,noc_cfg['n_virt_chn'])],
                            burst=AxiBurstType.FIXED,
                            data="Test")
    assert result.resp == AxiResp.SLVERR, "AXI bus should have raised an error when writing with a not supported burst type"

    # Invalid memory address RD - reading in WR buffer
    await tb.arst(config_clk)
    sel_out = randrange(0,noc_cfg['max_nodes'])
    sel_in = sel_out
    while (sel_in == sel_out):
        sel_in = randrange(0,noc_cfg['max_nodes'])
    tb.dut.axi_sel_in.setimmediatevalue(sel_in)
    result = await tb.read(sel=sel_out,
                           address=noc_cfg['vc_w_id'][randrange(0,noc_cfg['n_virt_chn'])],
                           length=0x1)
    assert result.resp == AxiResp.SLVERR, "AXI bus should have raised an error when reading to an invalid region of memory"

    # Invalid memory address RD - reading out of range
    await tb.arst(config_clk)
    sel_out = randrange(0,noc_cfg['max_nodes'])
    sel_in = sel_out
    while (sel_in == sel_out):
        sel_in = randrange(0,noc_cfg['max_nodes'])
    tb.dut.axi_sel_in.setimmediatevalue(sel_in)
    rand_addr = randrange(0,2**32)
    while rand_addr in noc_cfg['vc_r_id']:
        rand_addr = randrange(0,2**32)
    result = await tb.read(sel=sel_out,
                           address=rand_addr,
                           length=0x1)
    assert result.resp == AxiResp.SLVERR, "AXI bus should have raised an error when reading to an invalid region of memory"

    # Valid read region
    await tb.arst(config_clk)
    sel_out = randrange(0,noc_cfg['max_nodes'])
    sel_in = sel_out
    while (sel_in == sel_out):
        sel_in = randrange(0,noc_cfg['max_nodes'])
    tb.dut.axi_sel_in.setimmediatevalue(sel_in)
    result = await tb.read(sel=sel_out,
                           address=noc_cfg['vc_r_id'][randrange(0,noc_cfg['n_virt_chn'])],
                           length=0x1)
    assert result.resp == AxiResp.SLVERR, "AXI should have raise an error on this txn"

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("config_clk", ["AXI_slwT_NoC", "NoC_slwT_AXI", "NoC_equal_AXI"])
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",["vanilla","coffee"])
def test_wrong_ops(flavor):
    """
    Checks if the AXI-S/NoC is capable of throwing an errors when illegal operations are done

    Test ID: 2
    Expected Results: It's expected the NoC/AXI slave interface to refuse the txn throwing
    an error on the slave interface due to not supported requests
    """
    module = os.path.splitext(os.path.basename(__file__))[0]
    SIM_BUILD = os.path.join(noc_const.TESTS_DIR, f"../../run_dir/sim_build_{noc_const.SIMULATOR}_{module}_{flavor}")
    noc_const.EXTRA_ENV['SIM_BUILD'] = SIM_BUILD
    noc_const.EXTRA_ENV['FLAVOR'] = flavor
    extra_args_sim = noc_const.EXTRA_ARGS_VANILLA if flavor == "vanilla" else noc_const.EXTRA_ARGS_COFFEE
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
