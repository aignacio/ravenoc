/**
 * File              : noc.cpp
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 22.03.2020
 * Last Modified Date: 24.03.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#include "noc.h"

//void pe_chl::writePkt(int addr_x, int addr_y, int nBytes, TYPE_DATA_IF *data){
	//p_addr_x.write(addr_x);
	//p_addr_y.write(addr_x);
	//p_size.write(nBytes);

	//for (int i=0; i<nBytes; i++){
		//p_data.write(*(data++));
		//wait();
	//}
//}

//void pe_chl::readPkt(TYPE_DATA_IF *pBuffer){
	//for (int i=0; i<p_size.read(); i++){
		//*(pBuffer++) = p_data.read();
		//wait();
	//}
//}

void network_interface::run(){
	while(true){
		if (io.arst.read() == true) {
			cout << "[NI] Reset on NI" << endl;
		}
		else {
			if (vld.read() == true){
				for (int i=0; i<slave_port.p_size.read(); i++) {
					wait();
					inFIFO.write(slave_port.p_data.read());
				}
			}
		}
	}
}
