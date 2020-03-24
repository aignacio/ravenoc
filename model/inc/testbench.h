/**
 * File              : testbench.h
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.03.2020
 * Last Modified Date: 24.03.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#ifndef TESTBENCH_H
#define TESTBENCH_H

#include <systemc.h>
#include "ravenNoCConfig.h"

SC_MODULE(testbench) {
	public:
		sc_in		<bool>	clk;
		sc_out	<bool>	arst;

		SC_CTOR(testbench) {
			SC_CTHREAD(source, clk.pos());
			SC_CTHREAD(sink, clk.pos());
		}

		void source();
		void sink();
};

#endif
