/**
 * File              : Dbg.cpp
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 19.04.2020
 * Last Modified Date: 23.04.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#include "Dbg.h"

using namespace std;

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
	cout << endl;
}
