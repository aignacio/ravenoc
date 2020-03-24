/**
 * File              : main.cpp
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.03.2020
 * Last Modified Date: 24.03.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */

#include <systemc.h>
#include "noc.h"
#include "ravenNoCConfig.h"
#include "testbench.h"
#include "router.h"

void dbgNoCcfg (void){
	cout << "\n\tProject:\t\t"							<<	PROJECT_NAME			<< endl;
	cout << "\tVersion:\t\t"								<<	PROJECT_VER				<< endl;
	cout << "\tNoC Size X:\t\t"							<<	NOC_SIZE_X				<< endl;
	cout << "\tNoC Size Y:\t\t"							<<	NOC_SIZE_Y				<< endl;
	cout << "\tNumber of nodes:\t"					<<	NUM_NODES_NOC			<< endl;
#ifdef	SMALL_NOC_CFG
	cout << "\n\tNoC setup:\t\t"						<<	"Small NoC"				<< endl;
	cout << "\tFIFO sz p/rt (32-bit):\t"		<<	BUF_FIFO_ENTRIES	<< endl;
#else
	cout << "\n\tNoC setup:\t\t"						<<	"Big NoC"					<< endl;
	cout << "\tFIFO sz p/rt (64-bit):\t"		<<	BUF_FIFO_ENTRIES	<< endl;
#endif
	cout << "\tNoC addr X/Y (bits):\t"			<<	NOC_WIDTH_ADDR_X	<<	" / "	<<	NOC_WIDTH_ADDR_Y	<< endl;
	cout << "\tFlit width (bits):\t"				<<	FLIT_WIDTH				<< endl;
	cout << "\tPkt buffer per rt:\t"				<<	NUM_BUF_RT				<< endl;
	cout << "\tMax. bytes per pkt:\t"				<<	PKT_MAX_SIZE_PLD	<< endl;
}

class top : public sc_module {
	public:
		testbench					*tb;
		network_interface	*ni;
		sc_clock					SC_NAMED(clk);
		sc_signal	<bool>	SC_NAMED(arst);

		top(sc_module_name name) : sc_module(name),
															 clk("clk_signal", 10, SC_NS, 0.5){
			tb = new testbench("tb");
			tb->clk(clk);
			tb->arst(arst);
		}

		~top() {
			delete	tb, ni;
		}
};

int sc_main(int argc, char* argv[]) {
	top	wrapper("top");

	dbgNoCcfg();

	sc_start();

	return 0;
}
