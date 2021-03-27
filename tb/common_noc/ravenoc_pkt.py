#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : ravenoc_pkt.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 17.03.2021
# Last Modified Date: 17.03.2021
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
import cocotb
import logging
import math
from common_noc.constants import noc_const
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer
from cocotb.log import SimColourLogFormatter, SimLog, SimTimeContextFilter
from datetime import datetime
from random import randint, randrange, getrandbits

class RaveNoC_pkt:
    """
    Base class for RaveNoC pkt creation

    Args:
        cfg: Configuration dictionary for the specific hardware NoC on test
        message: Message in string format that'll compose the payload of the packet
        if the message cannot fit into a single pkt, the head flit will contain random
        data and the message will be send in the following flits.
        src_dest: Sets the source node that's sending the flit, it's needed to select
        the correct input mux when writing the flits. Sets also the destination node
        that'll receive the pkt, also used in the pkt
        creation to assemble the head flit
        virt_chn_id: Virtual channel used to send the flit over the NoC, required to
        define which AXI address we should use to read/write
    """
    def __init__(self, cfg, message="test", src_dest=(None,None), virt_chn_id=None):
        # Head Flit:
        # -> Considering coffee/vanilla flavors, the head flit can be written as:
        # 1) Coffee:
        # 65---------------63-----------------------------------------------------------0
        # | FLIT_TYPE (2b) | X_DEST (2b) | Y_DEST (2b) | PKT_WIDTH (8b) | MESSAGE (52b) |
        # +-----------------------------------------------------------------------------+
        # FLIT_TYPE is prepended by the NoC
        # 2) Vanilla:
        # 33---------------31-----------------------------------------------------------0
        # | FLIT_TYPE (2b) | X_DEST (1b) | Y_DEST (1b) | PKT_WIDTH (8b) | MESSAGE (20b) |
        # +-----------------------------------------------------------------------------+
        # FLIT_TYPE is prepended by the NoC
        # It's required to apply a mask on top of the initial flit head msg
        # To make things simpler, if message size is smaller or equal to the size
        # of min num bytes into a single flit, we concatenate in the head flit
        # otherwise we add some random data on head flit and send the message in
        # the following flits (body+tail)
        self.cfg = cfg
        if virt_chn_id == None:
            virt_chn_id = self._get_random_vc()
        if src_dest == (None,None):
            src_dest = self._get_random_src_dest()  # it means we need to initialize it
        assert src_dest[0] != src_dest[1], "A RaveNoC pkt cannot have src == dest!"
        length_bytes = len(message)
        x_src, y_src = self._get_coord(src_dest[0], cfg)
        x_dest, y_dest = self._get_coord(src_dest[1], cfg)
        # Max width in bits of head flit msg
        self.max_hflit_w = cfg['flit_data_width']-cfg['x_w']-cfg['y_w']-cfg['sz_pkt_w']
        # Max width in bytes of head flit msg
        self.src = (src_dest[0],x_src,y_src)
        self.dest = (src_dest[1],x_dest,y_dest)
        self.max_bytes_hflit = math.floor(self.max_hflit_w/8)
        self.axi_address_w = cfg['vc_w_id'][virt_chn_id]
        self.axi_address_r = cfg['vc_r_id'][virt_chn_id]
        num_bytes_per_flit = int(cfg['flit_data_width']/8)
        self.num_bytes_per_beat = num_bytes_per_flit
        if length_bytes <= self.max_bytes_hflit:
            self.message = bytearray(message,'utf-8')
            self.length = num_bytes_per_flit
            # This value can vary from 1 (single head flit) up to MAX, where MAX=255
            # actually MAX will be 256 because 255 data + 1 head flit but if we overflow
            # we mess with the y dest of the pkt
            self.length_beats = int(self.length/self.num_bytes_per_beat)
            msg_hflit = 0
            msg_hflit = int.from_bytes(self.message,byteorder="big")
            self.hflit = msg_hflit
            self.hflit = self.hflit | (self.length_beats << (self.max_hflit_w))
            self.hflit = self.hflit | (y_dest << (cfg['sz_pkt_w']+self.max_hflit_w))
            self.hflit = self.hflit | (x_dest << (cfg['y_w']+cfg['sz_pkt_w']+self.max_hflit_w))
            self.message = bytearray(self.hflit.to_bytes(num_bytes_per_flit,"little"))
        else:
            # Length is always in bytes
            self.length = (1+math.ceil(length_bytes/num_bytes_per_flit))*num_bytes_per_flit
            self.length_beats = 0xFF & int(self.length/self.num_bytes_per_beat)-1
            msg_hflit = randrange(0, (self.max_bytes_hflit*(256))-1)
            self.hflit = msg_hflit
            self.hflit = self.hflit | (self.length_beats << (self.max_hflit_w))
            self.hflit = self.hflit | (y_dest << (cfg['sz_pkt_w']+self.max_hflit_w))
            self.hflit = self.hflit | (x_dest << (cfg['y_w']+cfg['sz_pkt_w']+self.max_hflit_w))
            # We need to pad with zero chars to match bus data width once each beat of burst is full width
            if length_bytes%num_bytes_per_flit != 0:
                while len(message)%num_bytes_per_flit != 0:
                    message += '\0'
            message = bytearray(message,'utf-8')
            self.message = bytearray(self.hflit.to_bytes(num_bytes_per_flit,"little")) + message
        self.length_beats = int(self.length/self.num_bytes_per_beat)

    """
    Method to convert from single flat address in the NoC to row/col (x/y) coord.

    Args:
        node: Absolute address between 0 to max number of nodes in the NoC
        noc_cfg: Hardware of the NoC in test used to compute the x,y parameters
    Returns:
        noc_enc[node]: Return a list with the coord. row/col (x/y) inside the NoC
    """
    def _get_coord(self, node, noc_cfg):
        noc_enc, row, col = [], 0, 0
        for i in range(noc_cfg['max_nodes']):
            noc_enc.append([row,col])
            if col == (noc_cfg['noc_cfg_sz_cols']-1):
                row, col = row+1, 0
            else:
                col += 1
        return noc_enc[node]

    """
    Helper method to get random src/dest for the the pkt
    """
    def _get_random_src_dest(self):
        rnd_src  = randrange(0, self.cfg['max_nodes'])
        rnd_dest = randrange(0, self.cfg['max_nodes'])
        while rnd_dest == rnd_src:
            rnd_dest = randrange(0, self.cfg['max_nodes'])
        return (rnd_src,rnd_dest)

    """
    Helper method to get random virtual channel for the the pkt
    """
    def _get_random_vc(self):
        vc_id = randrange(0, len(self.cfg['vc_w_id']))
        return vc_id

