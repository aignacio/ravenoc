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
from common_noc.noc_pkt import NoC_pkt
from cocotb_test.simulator import run
from cocotb.regression import TestFactory
from random import randint, randrange, getrandbits
from cocotb_bus.drivers.amba import (AXIBurst, AXI4LiteMaster, AXI4Master, AXIProtocolError, AXIReadBurstLengthMismatch,AXIxRESP)

async def run_test(dut, config_clk=None):
    tb = Tb(dut,f"sim_{config_clk}")
    await tb.setup_clks(config_clk)
    await tb.arst(config_clk)

    noc_cfg = noc_const.NOC_CFG[str(os.getenv("FLAVOR"))]
    axi_sel = randrange(0, noc_cfg['max_nodes']-1)

    data_width = 32
    address = 0x100c
    write_value = randrange(0, 2**(data_width * 8))
    strobe = 0xf

    try:
        await tb.write(axi_sel, address, write_value, burst=AXIBurst(0))
    except AXIProtocolError as e:
        tb.log.info("Exception: %s" % str(e))
        tb.log.info("Bus successfully raised an error")
    else:
        assert False, "AXI bus should have raised an error when writing to an invalid burst type"

    try:
        data = await tb.read(axi_sel, address, burst=AXIBurst(0))
    except AXIProtocolError as e:
        tb.log.info("Exception: %s" % str(e))
        tb.log.info("Bus successfully raised an error")
    else:
        assert False, "AXI bus should have raised an error when writing to an invalid burst type"

    await tb.arst(config_clk)

    try:
        data = await tb.read(axi_sel, address=0x200c)
    except AXIProtocolError as e:
        tb.log.info("Exception: %s" % str(e))
        tb.log.info("Bus successfully raised an error")
    else:
        assert False, "AXI bus should have raised an error when reading from an empty buffer"


if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("config_clk", ["AXI_gt_NoC", "NoC_gt_AXI"])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",["vanilla","coffee"])
def test_wrong_ops(flavor):
    """
    Checks if the AXI-S/NoC is capable of throwing an errors when illegal operations are done

    Test ID: 1
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
