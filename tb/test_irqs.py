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
from common_noc.ravenoc_pkt import RaveNoC_pkt
from cocotb_test.simulator import run
from cocotb.regression import TestFactory
from random import randrange
from cocotb.result import TestFailure
from cocotb.triggers import ClockCycles
from cocotbext.axi import AxiResp,AxiBurstType
import itertools

async def run_test(dut, config_clk="NoC_slwT_AXI", idle_inserter=None, backpressure_inserter=None):
    noc_flavor = os.getenv("FLAVOR")
    noc_cfg = noc_const.NOC_CFG[noc_flavor]

    # Setup testbench
    idle = "no_idle" if idle_inserter == None else "w_idle"
    backp = "no_backpressure" if backpressure_inserter == None else "w_backpressure"
    tb = Tb(dut, f"sim_{config_clk}_{idle}_{backp}", noc_cfg)
    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)
    await tb.setup_clks(config_clk)
    await tb.arst(config_clk)
    csr = noc_const.NOC_CSRs


    encode_mux = {}
    encode_mux['DEFAULT']         = bytearray(0)
    encode_mux['MUX_EMPTY_FLAGS'] = bytearray([1,0,0,0])
    encode_mux['MUX_FULL_FLAGS']  = bytearray([2,0,0,0])
    encode_mux['MUX_COMP_FLAGS']  = bytearray([3,0,0,0])

    # Check MUX_EMPTY_FLAGS
    pkt = RaveNoC_pkt(cfg=noc_cfg, virt_chn_id=0)
    # First we setup the dest router with the correct switch
    req = await tb.write(sel=pkt.dest[0], address=csr['IRQ_RD_MUX'], data=encode_mux['MUX_EMPTY_FLAGS'], size=0x2)
    assert req.resp == AxiResp.OKAY, "AXI bus should not have raised an error here!"
    await tb.write_pkt(pkt)
    irq_wait = (2**(pkt.virt_chn_id)) << (pkt.dest[0]*noc_cfg['n_virt_chn'])
    tb.log.info("IRQ val to wait: %d",irq_wait)
    await tb.wait_irq_x(irq_wait)
    # Now we use the mask to disable all the IRQs
    req = await tb.write(sel=pkt.dest[0], address=csr['IRQ_RD_MASK'], data=bytearray([0,0,0,0]), size=0x2)
    assert tb.dut.irqs_out.value == 0, "No IRQs should be triggered on this scenario"
    # ... and we re-enable all the IRQs
    req = await tb.write(sel=pkt.dest[0], address=csr['IRQ_RD_MASK'], data=bytearray(str(2**32),'utf-8'), size=0x2)
    assert tb.dut.irqs_out.value != 0, "IRQs should be triggered on this scenario"

    # Check MUX_FULL_FLAGS
    await tb.arst(config_clk)
    pkt = RaveNoC_pkt(cfg=noc_cfg)
    pkt_copy = [pkt for i in range(0,buff_rd_vc(pkt.virt_chn_id))]
    # First we setup the dest router with the correct switch
    req = await tb.write(sel=pkt.dest[0], address=csr['IRQ_RD_MUX'], data=encode_mux['MUX_FULL_FLAGS'], size=0x2)
    assert req.resp == AxiResp.OKAY, "AXI bus should not have raised an error here!"
    await tb.write_pkt(pkt)
    # Wait some time to ensure the pkt has arrived in the dest
    await ClockCycles(tb.dut.clk_noc, 15)
    if (buff_rd_vc(pkt.virt_chn_id) != 1):
        assert tb.dut.irqs_out.value == 0, "No IRQs should be triggered on this scenario"
    await tb.read_pkt(pkt)
    # Now we don't have more pkts
    for pkt in pkt_copy:
        await tb.write_pkt(pkt)
        assert req.resp == AxiResp.OKAY, "AXI bus should not have raised an error here!"
    irq_wait = (2**(pkt.virt_chn_id)) << (pkt.dest[0]*noc_cfg['n_virt_chn'])
    tb.log.info("IRQ val to wait: %d",irq_wait)
    await tb.wait_irq_x(irq_wait)
    # Now we use the mask to disable all the IRQs
    req = await tb.write(sel=pkt.dest[0], address=csr['IRQ_RD_MASK'], data=bytearray([0,0,0,0]), size=0x2)
    assert tb.dut.irqs_out.value == 0, "No IRQs should be triggered on this scenario"
    # ... and we re-enable all the IRQs
    req = await tb.write(sel=pkt.dest[0], address=csr['IRQ_RD_MASK'], data=bytearray(str(2**32),'utf-8'), size=0x2)
    assert tb.dut.irqs_out.value != 0, "IRQs should be triggered on this scenario"

    # Check MUX_COMP_FLAGS
    await tb.arst(config_clk)
    pkt = RaveNoC_pkt(cfg=noc_cfg)
    pkt_copy = [pkt for i in range(0,buff_rd_vc(pkt.virt_chn_id))]
    # First we setup the dest router with the correct switch
    req = await tb.write(sel=pkt.dest[0], address=csr['IRQ_RD_MUX'], data=encode_mux['MUX_COMP_FLAGS'], size=0x2)
    assert req.resp == AxiResp.OKAY, "AXI bus should not have raised an error here!"
    # In COMP mode, MASK will work as ref. for comparison, thus we set it to ZERO, so every buff will trigger it
    req = await tb.write(sel=pkt.dest[0], address=csr['IRQ_RD_MASK'], data=bytearray([0,0,0,0]), size=0x2)
    await tb.write_pkt(pkt)
    await tb.wait_irq()
    assert tb.dut.irqs_out.value != 0, "IRQs should be triggered on this scenario"
    if (buff_rd_vc(pkt.virt_chn_id) != 1):
        # Now we change the comp. to >= 2
        req = await tb.write(sel=pkt.dest[0], address=csr['IRQ_RD_MASK'], data=bytearray([2,0,0,0]), size=0x2)
        assert tb.dut.irqs_out.value == 0, "No IRQs should be triggered on this scenario" #...bc we only sent one pkt
        # and we send another pkt
        await tb.write_pkt(pkt)
        # On this case IRQ should be triggered once we have >= 2 pkt sent
        await tb.wait_irq()

def buff_rd_vc(x):
    return (1<<x) if x<=2 else 4

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("config_clk", ["AXI_slwT_NoC", "NoC_slwT_AXI", "NoC_equal_AXI"])
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",noc_const.regression_setup)
def test_irqs(flavor):
    """
    Basic test that checks the IRQs modes inside the NoC

    Test ID: 8

    Description:
    Once it's possible to customize the way we drive the IRQ signals inside each Router of the NoC, this test
    checks different cfgs for IRQ_MUX/MASK sending/receiving flits from the NoC.
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
