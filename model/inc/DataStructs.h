/**
 * File              : DataStructs.h
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 19.04.2020
 * Last Modified Date: 23.04.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#ifndef DATASTRUCTS_H
#define DATASTRUCTS_H

#include "RavenNoCConfig.h"

typedef struct {
	sc_in_clk						SC_NAMED(clk);
	sc_in				<bool>	SC_NAMED(arst);
} basic_io;

// Flit
typedef enum {
	FLIT_TYPE_HEAD,
	FLIT_TYPE_BODY,
	FLIT_TYPE_TAIL
} FlitType;

struct Flit {
	int	src_id;
  int	dst_id;
	FlitType flit_type;
  int	sequence_no;		// The sequence number of the flit inside the packet
  int	sequence_length;
	double timestamp;		// Unix timestamp at packet generation
  int	hop_count;			// Current number of hops from source to destination

	// Operator overloading functions
  inline bool operator == (const Flit & flit) const {
		return (flit.src_id == src_id
				 && flit.dst_id == dst_id
				 && flit.flit_type	== flit_type
				 && flit.sequence_no == sequence_no
				 && flit.sequence_length == sequence_length
				 && flit.timestamp == timestamp
				 && flit.hop_count == hop_count);
	}

	inline friend ostream& operator << ( ostream& os,  Flit const & flit) {
		cout << "[Flit] Src ID: "				<< flit.src_id << endl;
		cout << "[Flit] Dst ID: "				<< flit.dst_id << endl;
		cout << "[Flit] Flit type: "		<< flit.flit_type << endl;
		cout << "[Flit] Seq. no: "			<< flit.sequence_no << endl;
		cout << "[Flit] Seq. length: "	<< flit.sequence_length << endl;
		cout << "[FLit] Timestamp: "		<< flit.timestamp << endl;
		cout << "[Flit] Hop counter: "	<< flit.hop_count << endl;
    return os;
  }

	inline friend void sc_trace (sc_trace_file *tf, const Flit & flit, const std::string & name){
		sc_trace(tf, flit.src_id, name+".src_id");
		sc_trace(tf, flit.dst_id, name+".dest_id");
		sc_trace(tf, flit.flit_type, name+".flit_type");
		sc_trace(tf, flit.sequence_no, name+".seq_no");
		sc_trace(tf, flit.sequence_length, name+".seq_length");
		sc_trace(tf, flit.timestamp, name+".timestamp");
		sc_trace(tf, flit.hop_count, name+".hop_count");
	}
};

// Packet
class Packet {
	public:
		int src_id;
    int dst_id;
    double timestamp;
    int size;
    int flit_left;

    Packet(){}

    Packet(const int s, const int d, const double ts, const int sz) :
			src_id{s}, dst_id{d}, timestamp{ts}, size{sz} {
    }
};

#endif
