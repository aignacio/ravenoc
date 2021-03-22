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
from cocotb.triggers import ClockCycles, RisingEdge, with_timeout, ReadOnly, Event
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

    def set_idle_generator(self, generator=None):
        if generator:
            self.noc_axi.write_if.aw_channel.set_pause_generator(generator())
            self.noc_axi.write_if.w_channel.set_pause_generator(generator())
            self.noc_axi.read_if.ar_channel.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.noc_axi.write_if.b_channel.set_pause_generator(generator())
            self.noc_axi.read_if.r_channel.set_pause_generator(generator())
    """
    Write method to transfer pkts over the NoC

    Args:
        pkt: Input pkt to be transfered to the NoC
        kwargs: All aditional args that can be passed to the amba AXI driver
    """
    async def write_pkt(self, pkt=RaveNoC_pkt, **kwargs):
        self.dut.axi_sel.setimmediatevalue(pkt.src[0])
        self.log.info(f"[AXI Master - Write NoC Packet] Slave = ["+str(pkt.src[0])+"] / "
                        "Address = ["+str(hex(pkt.axi_address_w))+"] / "
                        "Length = ["+str(pkt.length)+"]")
        self.log.info("[AXI Master - Write NoC Packet] Data:")
        self.print_pkt(pkt.message, pkt.num_bytes_per_beat)
        write = Event()
        self.noc_axi.init_write(address=pkt.axi_address_w, data=pkt.message, event=write,**kwargs)
        await with_timeout(write.wait(), *noc_const.TIMEOUT_AXI)

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
        read = Event()
        self.noc_axi.init_read(address=pkt.axi_address_r, length=pkt.length, event=read, **kwargs)
        await with_timeout(read.wait(), *noc_const.TIMEOUT_AXI)
        resp = read.data # read.data => AxiReadResp
        self.print_pkt(resp.data, pkt.num_bytes_per_beat)
        return resp

    """
    Write AXI method

    Args:
        sel: axi_mux switch to select the correct node to write through
        kwargs: All aditional args that can be passed to the amba AXI driver
    """
    async def write(self, sel=0, address=0x0, data=0x0, **kwargs):
        self.log.info(f"[AXI Master - Write] Slave = ["+str(sel)+"] / "
                        "Address = ["+str(hex(address))+"] / "
                        "Data = ["+str(hex(data))+"] / "
                        "Byte strobe = ["+str(hex(strobe))+"]")
        write = Event()
        self.noc_axi.init_write(address, data, event=write, **kwargs)
        await with_timeout(write.wait(), *noc_const.TIMEOUT_AXI)
        resp = write.data
        return resp

    """
    Read AXI method

    Args:
        sel: axi_mux switch to select the correct node to read from
        kwargs: All aditional args that can be passed to the amba AXI driver
    Returns:
        Return the data read from the specified node
    """
    async def read(self, sel=0, address=0x0, **kwargs):
        self.log.info("[AXI Master - Read] Slave = ["+str(sel)+"] / Address = ["+str(hex(address))+"]")
        self.dut.axi_sel.setimmediatevalue(sel)
        read = Event()
        self.noc_axi.init_read(address, 4, event=read,**kwargs)
        await with_timeout(read.wait(), *noc_const.TIMEOUT_AXI)
        resp = read.data # read.data => AxiReadResp
        return resp

    """
    Auxiliary method to check received data
    """
    def check_pkt(self, data, received):
        assert len(data) == len(received), "Lengths are different from received to sent pkt"
        for i in range(len(data)):
            assert data[i] == received[i], "Mismatch on received vs sent NoC packet!"

    """
    Auxiliary method to print/log AXI payload
    """
    def print_pkt(self, data, bytes_per_beat):
        for i in range(0,len(data),bytes_per_beat):
            beat_burst_hex = [data[x] for x in range(i,i+bytes_per_beat)][::-1]
            # beat_burst_s = [chr(data[x]) for x in range(i,i+bytes_per_beat)][::-1]
            beat_burst_hs = ""
            for j in beat_burst_hex:
                beat_burst_hs += hex(j)
                beat_burst_hs += "\t("+chr(j)+")"
                beat_burst_hs += "\t"
            tmp = "Beat["+str(int(i/bytes_per_beat))+"]---> "+beat_burst_hs
            self.log.info(tmp)
            #print("--)

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
        elif clk_mode == "AXI_slwT_NoC":
            cocotb.fork(Clock(self.dut.clk_axi, *noc_const.CLK_100MHz).start())
            cocotb.fork(Clock(self.dut.clk_noc, *noc_const.CLK_200MHz).start())
        else:
            cocotb.fork(Clock(self.dut.clk_axi, *noc_const.CLK_200MHz).start())
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
        bypass_cdc = 1 if clk_mode == "NoC_equal_AXI" else 0
        self.dut.bypass_cdc.setimmediatevalue(bypass_cdc)
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
        # https://github.com/alexforencich/cocotbext-axi/issues/19
        await ClockCycles(self.dut.clk_axi, 1)
        await ClockCycles(self.dut.clk_noc, 1)

    """
    Method to wait for IRQs from the NoC
    """
    async def wait_irq(self):
        # We need to wait some clock cyles because the in/out axi I/F is muxed
        # once verilator 4.106 doesn't support array of structs in the top.
        # This trigger is required because we read much faster than we write
        # and if we don't wait for the flit to arrive, it'll throw an error of
        # empty rd buffer
        # if tb.dut.irqs_out.value.integer == 0:
        #await with_timeout(First(*(Edge(bit) for bit in tb.dut.irqs_out)), *noc_const.TIMEOUT_IRQ)
        # This only exists bc of this:
        # https://github.com/cocotb/cocotb/issues/2478
        timeout_cnt = 0
        while int(self.dut.irqs_out) == 0:
            await RisingEdge(self.dut.clk_noc)
            if timeout_cnt == noc_const.TIMEOUT_IRQ_V:
                raise TestFailure("Timeout on waiting for an IRQ")
            else:
                timeout_cnt += 1
