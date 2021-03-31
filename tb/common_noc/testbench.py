#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : testbench.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 09.03.2021
# Last Modified Date: 09.03.2021
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
import cocotb
import os, errno
import logging, string, random
from logging.handlers import RotatingFileHandler
from cocotb.log import SimLogFormatter, SimColourLogFormatter, SimLog, SimTimeContextFilter
from common_noc.constants import noc_const
from cocotb.clock import Clock
from datetime import datetime
from cocotb.triggers import ClockCycles, RisingEdge, with_timeout, ReadOnly, Event
from common_noc.ravenoc_pkt import RaveNoC_pkt
from cocotbext.axi import AxiBus, AxiMaster, AxiRam, AxiResp
from cocotb.result import TestFailure

class Tb:
    """
    Base class for RaveNoC testbench

    Args:
        dut: The Dut object coming from cocotb
        log_name: Name of the log file inside the run folder, it's append the timestamp only
        cfg: NoC cfg dict
    """
    def __init__(self, dut, log_name, cfg):
        self.dut = dut
        self.cfg = cfg
        timenow_wstamp = self._gen_log(log_name)
        self.log.info("------------[LOG - %s]------------",timenow_wstamp)
        self.log.info("SEED: %s",str(cocotb.RANDOM_SEED))
        self.log.info("Log file: %s",log_name)
        self._print_noc_cfg()
        # Create the AXI Master I/Fs and connect it to the two main AXI Slave I/Fs in the top wrappers
        self.noc_axi_in = AxiMaster(AxiBus.from_prefix(self.dut, "noc_in"), self.dut.clk_axi, self.dut.arst_axi)
        self.noc_axi_out = AxiMaster(AxiBus.from_prefix(self.dut, "noc_out"), self.dut.clk_axi, self.dut.arst_axi)
        # Tied to zero the inputs
        self.dut.act_in.setimmediatevalue(0)
        self.dut.act_out.setimmediatevalue(0)
        self.dut.axi_sel_in.setimmediatevalue(0)
        self.dut.axi_sel_out.setimmediatevalue(0)

    def __del__(self):
        # Need to write the last strings in the buffer in the file
        self.log.info("Closing log file.")
        self.log.removeHandler(self.file_handler)

    def set_idle_generator(self, generator=None):
        if generator:
            self.noc_axi_in.write_if.aw_channel.set_pause_generator(generator())
            self.noc_axi_in.write_if.w_channel.set_pause_generator(generator())
            self.noc_axi_in.read_if.ar_channel.set_pause_generator(generator())
            self.noc_axi_out.write_if.aw_channel.set_pause_generator(generator())
            self.noc_axi_out.write_if.w_channel.set_pause_generator(generator())
            self.noc_axi_out.read_if.ar_channel.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.noc_axi_in.write_if.b_channel.set_pause_generator(generator())
            self.noc_axi_in.read_if.r_channel.set_pause_generator(generator())
            self.noc_axi_out.write_if.b_channel.set_pause_generator(generator())
            self.noc_axi_out.read_if.r_channel.set_pause_generator(generator())

    """
    Write method to transfer pkts over the NoC

    Args:
        pkt: Input pkt to be transfered to the NoC
        kwargs: All aditional args that can be passed to the amba AXI driver
    """
    async def write_pkt(self, pkt=RaveNoC_pkt, timeout=noc_const.TIMEOUT_AXI,  use_side_if=0, **kwargs):
        if use_side_if == 0:
            self.dut.axi_sel_in.setimmediatevalue(pkt.src[0])
            self.dut.act_in.setimmediatevalue(1)
        else:
            self.dut.axi_sel_out.setimmediatevalue(pkt.src[0])
            self.dut.act_out.setimmediatevalue(1)

        self._print_pkt_header("write",pkt)
        #self.log.info("[AXI Master - Write NoC Packet] Data:")
        #self._print_pkt(pkt.message, pkt.num_bytes_per_beat)
        if use_side_if == 0:
            write = self.noc_axi_in.init_write(address=pkt.axi_address_w, awid=0x0, data=pkt.msg, **kwargs)
        else:
            write = self.noc_axi_out.init_write(address=pkt.axi_address_w, awid=0x0, data=pkt.msg, **kwargs)

        await with_timeout(write.wait(), *timeout)
        ret = write.data

        if use_side_if == 0:
            self.dut.act_in.setimmediatevalue(0)
            self.dut.axi_sel_in.setimmediatevalue(0)
        else:
            self.dut.act_out.setimmediatevalue(0)
            self.dut.axi_sel_out.setimmediatevalue(0)
        return ret

    """
    Read method to fetch pkts from the NoC

    Args:
        pkt: Valid pkt to be used as inputs args (vc_channel, node on the axi_mux input,..) to the read op from the NoC
        kwargs: All aditional args that can be passed to the amba AXI driver
    Returns:
        Return the packet message with the head flit
    """
    async def read_pkt(self, pkt=RaveNoC_pkt, timeout=noc_const.TIMEOUT_AXI, **kwargs):
        self.dut.axi_sel_out.setimmediatevalue(pkt.dest[0])
        self.dut.act_out.setimmediatevalue(1)
        self._print_pkt_header("read",pkt)
        read = self.noc_axi_out.init_read(address=pkt.axi_address_r, arid=0x0, length=pkt.length, **kwargs)
        await with_timeout(read.wait(), *timeout)
        ret = read.data # read.data => AxiReadResp
        # self.log.info("[AXI Master - Read NoC Packet] Data:")
        #self._print_pkt(ret.data, pkt.num_bytes_per_beat)
        self.dut.act_out.setimmediatevalue(0)
        self.dut.axi_sel_out.setimmediatevalue(0)
        return ret

    """
    Write AXI method

    Args:
        sel: axi_mux switch to select the correct node to write through
        kwargs: All aditional args that can be passed to the amba AXI driver
    """
    async def write(self, sel=0, address=0x0, data=0x0, **kwargs):
        self.dut.act_in.setimmediatevalue(1)
        self.dut.axi_sel_in.setimmediatevalue(sel)
        self.log.info("[AXI Master - Write] Slave = ["+str(sel)+"] / "
                      "Address = ["+str(hex(address))+"] ")
                      #"Data = ["+data+"]")
        write = self.noc_axi_in.init_write(address=address, awid=0x0, data=data, **kwargs)
        await with_timeout(write.wait(), *noc_const.TIMEOUT_AXI)
        ret = write.data
        self.dut.axi_sel_in.setimmediatevalue(0)
        self.dut.act_in.setimmediatevalue(0)
        return ret

    """
    Read AXI method

    Args:
        sel: axi_mux switch to select the correct node to read from
        kwargs: All aditional args that can be passed to the amba AXI driver
    Returns:
        Return the data read from the specified node
    """
    async def read(self, sel=0, address=0x0, length=4, **kwargs):
        self.dut.act_out.setimmediatevalue(1)
        self.dut.axi_sel_out.setimmediatevalue(sel)
        self.log.info("[AXI Master - Read] Slave = ["+str(sel)+"] / Address = ["+str(hex(address))+"] / Length = ["+str(length)+" bytes]")
        read = self.noc_axi_out.init_read(address=address, arid=0x0, length=length, **kwargs)
        await with_timeout(read.wait(), *noc_const.TIMEOUT_AXI)
        resp = read.data # read.data => AxiReadResp
        self.dut.axi_sel_out.setimmediatevalue(0)
        self.dut.act_out.setimmediatevalue(0)
        return resp

    """
    Auxiliary method to check received data
    """
    def check_pkt(self, data, received):
        assert len(data) == len(received), "Lengths are different from received to sent pkt"
        for i in range(len(data)):
            assert data[i] == received[i], "Mismatch on received vs sent NoC packet!"

    """
    Auxiliary method to log flit header
    """
    def _print_pkt_header(self, op, pkt):
        axi_addr = str(hex(pkt.axi_address_r)) if op=="read" else str(hex(pkt.axi_address_w))
        mux = str(pkt.dest[0]) if op=="read" else str(pkt.src[0])
        self.log.info(f"[AXI Master - "+str(op)+" NoC Packet] Router=["+mux+"] "
                        "Address=[AXI_Addr="+axi_addr+"] Mux_"+op+"=["+mux+"] "
                        "SRC(x,y)=["+str(pkt.src[1])+","+str(pkt.src[2])+"] "
                        "DEST(x,y)=["+str(pkt.dest[1])+","+str(pkt.dest[2])+"] "
                        "Length=["+str(pkt.length)+" bytes / "+str(pkt.length_beats)+" beats]")

    """
    Auxiliary method to print/log AXI payload
    """
    def _print_pkt(self, data, bytes_per_beat):
        print("LEN="+str(len(data))+" BYTES PER BEAT="+str(bytes_per_beat))
        if len(data) == bytes_per_beat:
            beat_burst_hex = [data[x] for x in range(0,bytes_per_beat)][::-1]
            beat_burst_hs = ""
            for j in beat_burst_hex:
                beat_burst_hs += hex(j)
                beat_burst_hs += "\t("+chr(j)+")"
                beat_burst_hs += "\t"
            tmp = "Beat[0]---> "+beat_burst_hs
            self.log.info(tmp)
        else:
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
        self.dut.axi_sel_in.setimmediatevalue(0)
        self.dut.axi_sel_out.setimmediatevalue(0)
        self.dut.act_in.setimmediatevalue(0)
        self.dut.act_out.setimmediatevalue(0)
        bypass_cdc = 1 if clk_mode == "NoC_equal_AXI" else 0
        self.dut.bypass_cdc.setimmediatevalue(bypass_cdc)
        self.dut.arst_axi <= 1
        self.dut.arst_noc <= 1
        # await NextTimeStep()
        #await ReadOnly() #https://github.com/cocotb/cocotb/issues/2478
        if clk_mode == "NoC_slwT_AXI":
            await ClockCycles(self.dut.clk_noc, noc_const.RST_CYCLES)
        else:
            await ClockCycles(self.dut.clk_axi, noc_const.RST_CYCLES)
        self.dut.arst_axi <= 0
        self.dut.arst_noc <= 0
        # https://github.com/alexforencich/cocotbext-axi/issues/19
        #await ClockCycles(self.dut.clk_axi, 1)
        #await ClockCycles(self.dut.clk_noc, 1)

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
                self.log.error("Timeout on waiting for an IRQ")
                raise TestFailure("Timeout on waiting for an IRQ")
            else:
                timeout_cnt += 1

    """
    Method to wait for IRQs from the NoC with a specific value
    """
    async def wait_irq_x(self, val):
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
        while int(self.dut.irqs_out) != val:
            await RisingEdge(self.dut.clk_noc)
            if timeout_cnt == noc_const.TIMEOUT_IRQ_V:
                self.log.error("Timeout on waiting for an IRQ")
                raise TestFailure("Timeout on waiting for an IRQ")
            else:
                timeout_cnt += 1

    """
    Creates the tb log obj and start filling with headers
    """
    def _gen_log(self, log_name):
        timenow = datetime.now().strftime("%d_%b_%Y_%Hh_%Mm_%Ss")
        timenow_wstamp = timenow + str("_") + str(datetime.timestamp(datetime.now()))
        self.log = SimLog(log_name)
        self.log.setLevel(logging.DEBUG)
        self.file_handler = RotatingFileHandler(f"{log_name}_{timenow}.log", maxBytes=(5 * 1024 * 1024), backupCount=2, mode='w')
        self._symlink_force(f"{log_name}_{timenow}.log",f"latest_{log_name}.log")
        self.file_handler.setFormatter(SimLogFormatter())
        self.log.addHandler(self.file_handler)
        self.log.addFilter(SimTimeContextFilter())
        return timenow_wstamp

    """
    Used to create the symlink with the latest log in the run dir folder
    """
    def _symlink_force(self, target, link_name):
        try:
            os.symlink(target, link_name)
        except OSError as e:
            if e.errno == errno.EEXIST:
                os.remove(link_name)
                os.symlink(target, link_name)
            else:
                raise e

    """
    Returns a random string with the length equal to input argument
    """
    def _get_random_string(self, length=1):
        # choose from all lowercase letter
        letters = string.ascii_lowercase
        result_str = ''.join(random.choice(letters) for i in range(length))
        return result_str

    def _print_noc_cfg(self):
        cfg = self.cfg

        self.log.info("------------------------------")
        self.log.info("RaveNoC configuration:")
        self.log.info(f"--> Flit data width: "+str(cfg['flit_data_width']))
        self.log.info(f"--> AXI data width: "+str(cfg['flit_data_width']))
        self.log.info(f"--> Routing algorithm: "+cfg['routing_alg'])
        self.log.info(f"--> NoC Size: "+str(cfg['noc_cfg_sz_rows']),"x"+str(cfg['noc_cfg_sz_cols']))
        self.log.info(f"--> Number of flit buffers per input module: "+str(cfg['flit_buff']))
        self.log.info(f"--> Max size per pkt (beats): "+str(cfg['max_sz_pkt']))
        self.log.info(f"--> Number of virtual channels: "+str(cfg['n_virt_chn']))
        self.log.info(f"--> VC ID priority: "+("VC[0] has highest priority" if cfg['h_priority'] == 1 else "VC[0] has lowest priority"))
        self.log.info("------------------------------")
