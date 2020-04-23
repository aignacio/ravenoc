/**
 * File              : Router.h
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.03.2020
 * Last Modified Date: 23.04.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#ifndef ROUTER_H
#define ROUTER_H

#include <systemc.h>
#include "RavenNoCConfig.h"
#include "DataStructs.h"

SC_MODULE (router) {
	basic_io	io;

	int								local_id;

	sc_out	<bool>		SC_NAMED(ni_rx_vld);
	sc_in		<bool>		SC_NAMED(ni_rx_rdy);
	sc_out	<Flit>		SC_NAMED(flit_rx);

	sc_in		<bool>		SC_NAMED(ni_tx_vld);
	sc_out	<bool>		SC_NAMED(ni_tx_rdy);
	sc_in		<Flit>		SC_NAMED(flit_tx);

	void routing();
	void localLink();
	void rxProcess();
	void txProcess();

	SC_HAS_PROCESS(router);

	router(sc_module_name name, int tile_id)
		: sc_module(name), local_id(tile_id) {
		SC_METHOD(routing);
		sensitive << io.arst << io.clk.pos();

		SC_METHOD(localLink);
		sensitive << io.arst << io.clk.pos();
	}

};

#endif
