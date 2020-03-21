/**
 * File              : router.h
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.03.2020
 * Last Modified Date: 17.03.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#ifndef ROUTER_H
#define ROUTER_H

#include <systemc.h>
#include "ravenNoCConfig.h"

#define	FIFO_SIZE	sc_uint<32>

// SC_THREAD === initial
// SC_METHOD === always_comb/always_ff
// SC_CTHREAD === always_ff

SC_MODULE (router) {
	public:
		sc_in <bool> clk, arst {"arst"};
		sc_in <FIFO_SIZE> a, b;
		sc_out <FIFO_SIZE> out;

		void func();

		SC_CTOR (router) {
			SC_CTHREAD(func, clk.pos());
			//sensitive << clk, arst;
		}
};

#endif
