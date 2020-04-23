/**
 * File              : Tile.h
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 22.04.2020
 * Last Modified Date: 23.04.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#ifndef TILE_H
#define TILE_H

#include <systemc.h>
#include "RavenNoCConfig.h"
#include "DataStructs.h"
#include "PktGen.h"
#include "Router.h"

SC_MODULE(tile){
	basic_io	io;

	int local_id;

	sc_signal	<bool>	SC_NAMED(ni_tx_vld);
	sc_signal	<bool>	SC_NAMED(ni_tx_rdy);
	sc_signal	<Flit>	SC_NAMED(flit_tx);

	sc_signal	<bool>	SC_NAMED(ni_rx_vld);
	sc_signal	<bool>	SC_NAMED(ni_rx_rdy);
	sc_signal	<Flit>	SC_NAMED(flit_rx);

	PktGen		*pkt_gen;
	router		*rt;

	SC_HAS_PROCESS(tile);

	tile (sc_module_name name, int tile_id)
		: sc_module(name), local_id(tile_id) {
		pkt_gen = new PktGen("packet_generator", tile_id, false);
		pkt_gen->io.clk(io.clk);
		pkt_gen->io.arst(io.arst);
		pkt_gen->ni_tx_vld(ni_tx_vld);
		pkt_gen->ni_tx_rdy(ni_tx_rdy);
		pkt_gen->flit_tx(flit_tx);
		pkt_gen->ni_rx_vld(ni_rx_vld);
		pkt_gen->ni_rx_rdy(ni_rx_rdy);
		pkt_gen->flit_rx(flit_rx);

		rt = new router("router", tile_id);
		rt->io.clk(io.clk);
		rt->io.arst(io.arst);
		rt->ni_tx_vld(ni_tx_vld);
		rt->ni_tx_rdy(ni_tx_rdy);
		rt->flit_tx(flit_tx);
		rt->ni_rx_vld(ni_rx_vld);
		rt->ni_rx_rdy(ni_rx_rdy);
		rt->flit_rx(flit_rx);
	}
};



#endif
