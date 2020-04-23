/**
 * File              : Main.cpp
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.03.2020
 * Last Modified Date: 23.04.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#include <systemc.h>
#include "RavenNoCConfig.h"
#include "Tile.h"
#include "Dbg.h"

#define	RESET_TIME	10
#define SIMUL_TIME	100

int sc_main(int argc, char* argv[]) {
	dbgNoCcfg();

	sc_clock					SC_NAMED(clk, 10, SC_NS, 0.5);
	sc_signal	<bool>	SC_NAMED(arst);

	tile *ti;

	ti = new tile("tile",0);

	ti->io.clk(clk);
	ti->io.arst(arst);

	arst.write(1);
	sc_start(RESET_TIME, SC_NS);
	arst.write(0);
	sc_start(SIMUL_TIME, SC_NS);

	return 0;
}
