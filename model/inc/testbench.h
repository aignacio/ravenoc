/**
 * File              : testbench.h
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.03.2020
 * Last Modified Date: 16.03.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#ifndef TESTBENCH_H
#define TESTBENCH_H

#include <systemc.h>
#include "ravenNoCConfig.h"
#include "router.h"

SC_MODULE (testbench) {
	public:
		sc_in <bool> clk;
		sc_out <bool> arst;
		sc_out <FIFO_SIZE> a, b;
		sc_in <FIFO_SIZE> out;

		void source();
		void sink();

		SC_CTOR (testbench) {
			SC_CTHREAD(source, clk.pos());
			SC_CTHREAD(sink, clk.pos());
		}
};

#endif
