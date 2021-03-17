#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : test_ravenoc_basic.py
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
from common_noc.ravenoc_pkt import RaveNoC_pkt
from cocotb.regression import TestFactory
from cocotb.triggers import ClockCycles, Timer, with_timeout, Edge
from random import randint, randrange, getrandbits
from cocotb_bus.drivers.amba import AXIBurst

async def run_test(dut, config_clk=None):
    noc_flavor = os.getenv("FLAVOR")
    noc_cfg = noc_const.NOC_CFG[noc_flavor]

    tb = Tb(dut,f"sim_{config_clk}_{noc_flavor}")
    await tb.setup_clks(config_clk)
    await tb.arst(config_clk)

    rnd_src  = randrange(0, noc_cfg['max_nodes']-1)
    rnd_dest = randrange(0, noc_cfg['max_nodes']-1)
    while rnd_dest == rnd_src:
        rnd_dest = randrange(0, noc_cfg['max_nodes']-1)
    message = ">>>>>Coffee is life "+str(randrange(0,1024))
    pkt = RaveNoC_pkt(cfg=noc_cfg, message=message,
                  src=rnd_src, dest=rnd_dest,
                  virt_chn_id=randrange(0, len(noc_cfg['vc_w_id'])))

    await tb.write_pkt(pkt)
    # We need to wait some clock cyles because the in/out axi I/F is muxed
    # once verilator 4.106 doesn't support array of structs. This time is
    # required because we read much faster than we write and if we don't
    # wait for the flit to arrive, it'll throw an error of empty buffer
    if int(tb.dut.irqs_out) == 0:
        await with_timeout(Edge(tb.dut.irqs_out), *noc_const.TIMEOUT_IRQ)
    tb.log.info(f"Value IRQS before read {dut.irqs_out}")
    data = await tb.read_pkt(pkt)
    for i in range(len(data)):
        assert data[i] == pkt.message[i]

if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("config_clk", ["AXI_slwT_NoC", "NoC_slwT_AXI"])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",["vanilla","coffee"])
def test_ravenoc_basic(flavor):
    """
    Basic test that sends a packet over the NoC and checks it

    Test ID: 2
    Expected Results: Received packet should match with the sent one
    """
    module = os.path.splitext(os.path.basename(__file__))[0]
    SIM_BUILD = os.path.join(noc_const.TESTS_DIR,
            f"../../run_dir/sim_build_{noc_const.SIMULATOR}_{module}_{flavor}")
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
