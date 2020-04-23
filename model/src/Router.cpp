/**
 * File              : Router.cpp
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.03.2020
 * Last Modified Date: 23.04.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#include "Router.h"

void router::routing(){
}

void router::localLink(){
	txProcess();
	rxProcess();
}

void router::rxProcess(){
	Flit	flt;

	if (io.arst.read() == 1) {
		flt.src_id = 0;
		flt.dst_id = 0;
		flt.flit_type = FLIT_TYPE_HEAD;
		flt.sequence_no = 0;
		flt.sequence_length = 0;
		flt.timestamp = 0.0;
		flt.hop_count = 0;

		flit_rx.write(flt);
		ni_rx_vld.write(0);
	}
	else {
		flt.src_id = 0;
		flt.dst_id = 0;
		flt.flit_type = FLIT_TYPE_HEAD;
		flt.sequence_no = 0;
		flt.sequence_length = 0;
		flt.timestamp = 0.0;
		flt.hop_count = 0;

		flit_rx.write(flt);
		ni_rx_vld.write(0);
	}
}

void router::txProcess(){
	if (io.arst.read() == 1) {
		ni_tx_rdy.write(0);
	}
	else {
		ni_tx_rdy.write(1);
		if (ni_tx_vld.read()){
			cout << flit_tx;
			cout << endl;
		}
	}
}
