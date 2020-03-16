/**
 * File              : testbench.cpp
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.03.2020
 * Last Modified Date: 16.03.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#include "testbench.h"

void testbench::source(){
	FIFO_SIZE tmp_in_a, tmp_in_b;

	arst.write(0);
	arst.write(1);
	wait();
	arst.write(0);
	wait();

	tmp_in_a = 0;
	tmp_in_b = 0;

	for(int i=0; i<200; i++) {
		tmp_in_a = tmp_in_a+1;
		tmp_in_b = tmp_in_b+3;
		a.write(tmp_in_a);
		b.write(tmp_in_b);
		wait();
	}

	sc_stop();
}

void testbench::sink(){
	while(true) {
		cout << "\tTimestamp (ns):" << sc_time_stamp();
		cout << "\tInA: " << a.read();
		cout << "\tInB: " << b.read();
		cout << "\tOut: " << out.read() << endl;
		wait();
	}
}
