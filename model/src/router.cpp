/**
 * File              : router.cpp
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.03.2020
 * Last Modified Date: 16.03.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#include "router.h"

void router::func(){
	while(true) {
		if (arst.read() == 1) {
			out.write(0);
			wait();
		}
		else {
			out.write(a.read() & b.read());
			wait();
		}
	}
}


