/**
 * File              : NoC.cpp
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 22.03.2020
 * Last Modified Date: 23.04.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#ifndef NOC_H
#define NOC_H

#include <systemc.h>
#include "RavenNoCConfig.h"
#include "DataStructs.h"

SC_MODULE(network_interface) {
	basic_io														io;

	sc_fifo <BASE_FMT_SGN(FLIT_WIDTH)>	SC_NAMED(inFIFO);
	sc_fifo <BASE_FMT_SGN(FLIT_WIDTH)>	SC_NAMED(outFIFO);

	void run();

	SC_CTOR(network_interface) :	inFIFO(BUF_FIFO_ENTRIES),
																outFIFO(BUF_FIFO_ENTRIES) {
		SC_THREAD(run);
		sensitive	<< io.clk.pos();
	}
};

#endif

