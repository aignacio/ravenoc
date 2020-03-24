/**
 * File              : testbench.cpp
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.03.2020
 * Last Modified Date: 24.03.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#include "testbench.h"
#include "ravenNoCConfig.h"

void testbench::source(){
	arst.write(0);
	arst.write(1);
	wait();
	arst.write(0);
	wait();

	for(int i=0; i<200; i++) {
		wait();
	}

	sc_stop();
}

void testbench::sink(){
}


