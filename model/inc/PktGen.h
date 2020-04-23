/**
 * File              : PktGen.h
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 20.04.2020
 * Last Modified Date: 23.04.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#ifndef PKTGEN_H
#define PKTGEN_H

#include <systemc.h>
#include "RavenNoCConfig.h"
#include "DataStructs.h"
#include <queue>

SC_MODULE(PktGen){
	basic_io	io;

	int								local_id;
	bool							tx_off;
	bool							flt_sent;
	int								pkt_tx_cnt;

	std::queue	<Packet>	packet_queue;

	sc_out	<bool>		SC_NAMED(ni_tx_vld);
	sc_in		<bool>		SC_NAMED(ni_tx_rdy);
	sc_out	<Flit>		SC_NAMED(flit_tx);

	sc_in		<bool>		SC_NAMED(ni_rx_vld);
	sc_out	<bool>		SC_NAMED(ni_rx_rdy);
	sc_in		<Flit>		SC_NAMED(flit_rx);

	void	sendPacket();
	void	recvPacket();
	bool	getPkt(Packet & pkt);
	Flit	getNxtFlit();

	SC_HAS_PROCESS(PktGen);

	PktGen(sc_module_name name, int tile_id, bool do_not_tx)
		: sc_module(name), local_id(tile_id), tx_off(do_not_tx) {
		SC_METHOD(sendPacket)
		sensitive << io.arst << io.clk.pos();

		SC_METHOD(recvPacket);
		sensitive << io.arst << io.clk.pos();
	}
};

#endif
