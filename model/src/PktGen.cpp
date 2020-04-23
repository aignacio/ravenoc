/**
 * File              : PktGen.cpp
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 21.04.2020
 * Last Modified Date: 23.04.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#include "PktGen.h"

void PktGen::sendPacket() {
	if (io.arst.read() == 1) {
		ni_tx_vld.write(0);
		flt_sent = 0;
		pkt_tx_cnt = 0;
	}
	else {
		Packet pkt;

		if (getPkt(pkt)){
			packet_queue.push(pkt);
		}

		if (packet_queue.empty() == 0) {
			if (flt_sent == 0) {
				Flit flt = getNxtFlit();
				flit_tx.write(flt);
				ni_tx_vld.write(1);
				flt_sent = 1;
				pkt_tx_cnt++;
			}
			else if (flt_sent && ni_tx_rdy.read() == 1){
				Flit flt = getNxtFlit();
				flit_tx.write(flt);
				ni_tx_vld.write(1);
				flt_sent = 1;
				pkt_tx_cnt++;
			}
		}
		else {
			flt_sent = 0;
			ni_tx_vld.write(0);
		}
	}
}

bool PktGen::getPkt(Packet & pkt) {
	if (tx_off == true)
		return false;

	pkt.src_id = local_id;
	pkt.dst_id = local_id+1;
  pkt.timestamp = sc_time_stamp().to_double();
  pkt.size = 100;
	pkt.flit_left = 100;

  return true;
}

Flit PktGen::getNxtFlit() {
    Flit flit;
    Packet packet = packet_queue.front();

    flit.src_id = packet.src_id;
    flit.dst_id = packet.dst_id;
    flit.timestamp = packet.timestamp;
    flit.sequence_no = packet.size - packet.flit_left;
    flit.sequence_length = packet.size;
    flit.hop_count = 0;

    if (packet.size == packet.flit_left)
			flit.flit_type = FLIT_TYPE_HEAD;
    else if (packet.flit_left == 1)
			flit.flit_type = FLIT_TYPE_TAIL;
    else
			flit.flit_type = FLIT_TYPE_BODY;

    packet_queue.front().flit_left--;
    if (packet_queue.front().flit_left == 0)
			packet_queue.pop();

    return flit;
}

void PktGen::recvPacket() {
	if (io.arst.read() == 1) {
		ni_rx_rdy.write(0);
	}
}
