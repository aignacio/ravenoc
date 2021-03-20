#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : testbench.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 09.03.2021
# Last Modified Date: 09.03.2021
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
import cocotb
import logging
from logging.handlers import RotatingFileHandler
from cocotb.log import SimLogFormatter, SimColourLogFormatter, SimLog, SimTimeContextFilter
from common_noc.constants import noc_const
from cocotb.clock import Clock
from datetime import datetime
from cocotb.triggers import ClockCycles, RisingEdge, with_timeout, ReadOnly
from common_noc.ravenoc_pkt import RaveNoC_pkt
from cocotbext.axi import AxiBus, AxiMaster, AxiRam
from cocotb.result import TestFailure

class Tb:
    """
    Base class for RaveNoC testbench

    Args:
        dut: The Dut object coming from cocotb
        log_name: Name of the log file inside the run folder, it's append the timestamp only
    """
    def __init__(self, dut, log_name):
        self.dut = dut
        self.log = SimLog(log_name)
        self.log.setLevel(logging.DEBUG)
        now = datetime.now()
        timestamp = datetime.timestamp(now)
        timenow = datetime.now().strftime("%d_%b_%Y_%Hh_%Mm_%Ss")
        timenow_wstamp = timenow + str("_") + str(timestamp)
        self.file_handler = RotatingFileHandler(f"{log_name}_{timenow}.log", maxBytes=(5 * 1024 * 1024), backupCount=2, mode='w')
        self.file_handler.setFormatter(SimLogFormatter())
        self.log.addHandler(self.file_handler)
        self.log.addFilter(SimTimeContextFilter())
        self.log.info("------------[LOG - %s]------------",timenow_wstamp)
        self.log.info("RANDOM_SEED => %s",str(cocotb.RANDOM_SEED))
        self.log.info("CFG => %s",log_name)
        self.noc_axi = AxiMaster(AxiBus.from_prefix(self.dut, "noc"), self.dut.clk_axi, self.dut.arst_axi)

    def __del__(self):
        # Need to write the last strings in the buffer in the file
        self.log.info("Closing log file.")
        self.log.removeHandler(self.file_handler)

    """
    Write method to transfer pkts over the NoC

    Args:
        pkt: Input pkt to be trasnfered to the NoC
        kwargs: All aditional args that can be passed to the amba AXI driver
    """
    async def write_pkt(self, pkt=RaveNoC_pkt, **kwargs):
        self.dut.axi_sel.setimmediatevalue(pkt.src[0])
        self.log.info(f"[AXI Master - Write NoC Packet] Slave = ["+str(pkt.src[0])+"] / "
                        "Address = ["+str(hex(pkt.axi_address_w))+"] / "
                        "Length = ["+str(pkt.length)+"]")
        self.log.info("[AXI Master - Write NoC Packet] Data:")
        for i in pkt.message:
            self.log.info("----------> [%s]"%hex(i))
        # await self.noc_axi.write(address=pkt.axi_address_w, data=23, **kwargs)
        self.noc_axi.init_write(address=pkt.axi_address_w, data=255, **kwargs)
        await self.noc_axi.wait()

    """
    Read method to fetch pkts from the NoC

    Args:
        pkt: Valid pkt to be used as inputs args (vc_channel, node on the axi_mux input,..) to the read op from the NoC
        kwargs: All aditional args that can be passed to the amba AXI driver
    Returns:
        Return the packet message with the head flit
    """
    async def read_pkt(self, pkt=RaveNoC_pkt, **kwargs):
        self.dut.axi_sel.setimmediatevalue(pkt.dest[0])
        self.log.info(f"[AXI Master - Read NoC Packet] Slave = ["+str(pkt.dest[0])+"] / "
                        "Address = ["+str(hex(pkt.axi_address_r))+"] / "
                        "Length = ["+str(pkt.length)+"]")
        self.log.info("[AXI Master - Read NoC Packet] Data:")
        pkt_payload = self.noc_axi.read(address=pkt.axi_address_r, length=pkt.length, **kwargs)
        #for i in pkt_payload:
        #    self.log.info("----------> [%s]"%hex(i))
        return pkt_payload

    # """
    # Write AXI method

    # Args:
        # sel: axi_mux switch to select the correct node to write through
        # kwargs: All aditional args that can be passed to the amba AXI driver
    # """
    # async def write(self, sel=0, address=0x0, data=0x0, strobe=0xff, **kwargs):
        # self.log.info(f"[AXI Master - Write] Slave = ["+str(sel)+"] / "
                        # "Address = ["+str(hex(address))+"] / "
                        # "Data = ["+str(hex(data))+"] / "
                        # "Byte strobe = ["+str(hex(strobe))+"]")
        # self.dut.axi_sel.setimmediatevalue(sel)
        # await with_timeout(self.noc_axi.write(address, data, byte_enable=strobe, **kwargs), *noc_const.TIMEOUT_AXI)

    # """
    # Read AXI method

    # Args:
        # sel: axi_mux switch to select the correct node to read from
        # kwargs: All aditional args that can be passed to the amba AXI driver
    # Returns:
        # Return the data read from the specified node
    # """
    # async def read(self, sel=0, address=0x0, **kwargs):
        # self.log.info("[AXI Master - Read] Slave = ["+str(sel)+"] / Address = ["+str(hex(address))+"]")
        # self.dut.axi_sel.setimmediatevalue(sel)
        # result = await with_timeout(self.noc_axi.read(address, **kwargs), *noc_const.TIMEOUT_AXI)
        # return result

    """
    Setup and launch the clocks on the simulation

    Args:
        clk_mode: Selects between AXI clk higher than NoC clk and vice-versa
    """
    async def setup_clks(self, clk_mode="NoC_slwT_AXI"):
        self.log.info(f"[Setup] Configuring the clocks: {clk_mode}")
        if clk_mode == "NoC_slwT_AXI":
            cocotb.fork(Clock(self.dut.clk_noc, *noc_const.CLK_100MHz).start())
            cocotb.fork(Clock(self.dut.clk_axi, *noc_const.CLK_200MHz).start())
        else:
            cocotb.fork(Clock(self.dut.clk_axi, *noc_const.CLK_100MHz).start())
            cocotb.fork(Clock(self.dut.clk_noc, *noc_const.CLK_200MHz).start())

    """
    Setup and apply the reset on the NoC

    Args:
        clk_mode: Depending on the input clock mode, we need to wait different
        clk cycles for the reset, we always hold as long as the slowest clock
    """
    async def arst(self, clk_mode="NoC_slwT_AXI"):
        self.log.info("[Setup] Reset DUT")
        self.dut.arst_axi.setimmediatevalue(0)
        self.dut.arst_noc.setimmediatevalue(0)
        self.dut.axi_sel.setimmediatevalue(0)
        self.dut.arst_axi <= 1
        self.dut.arst_noc <= 1
        # await NextTimeStep()
        await ReadOnly() #https://github.com/cocotb/cocotb/issues/2478
        if clk_mode == "NoC_slwT_AXI":
            await ClockCycles(self.dut.clk_noc, noc_const.RST_CYCLES)
        else:
            await ClockCycles(self.dut.clk_axi, noc_const.RST_CYCLES)
        self.dut.arst_axi <= 0
        self.dut.arst_noc <= 0

    """
    Method to wait for IRQs from the NoC

    """
    async def wait_irq(self):
        #await with_timeout(First(*(Edge(bit) for bit in tb.dut.irqs_out)), *noc_const.TIMEOUT_IRQ)
        # This only exists bc of this:
        # https://github.com/cocotb/cocotb/issues/2478
        timeout_cnt = 0
        while int(self.dut.irqs_out) == 0:
            await RisingEdge(self.dut.clk_noc)
            if timeout_cnt == noc_const.TIMEOUT_IRQ_V:
                raise TestFailure("Timeout on waiting for IRQ")
            else:
                timeout_cnt += 1
