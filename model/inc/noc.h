/**
 * File              : noc.h
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 22.03.2020
 * Last Modified Date: 24.03.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#ifndef NOC_H
#define NOC_H

#include <systemc.h>
#include "ravenNoCConfig.h"

#define	NUM_NODES_NOC	NOC_SIZE_X*NOC_SIZE_Y

#if NOC_SIZE_X <= 16
	#define	NOC_WIDTH_ADDR_X	4
#elif	NOC_SIZE_X	<=	32
	#define	NOC_WIDTH_ADDR_X	5
#elif	NOC_SIZE_X	<=	64
	#define	NOC_WIDTH_ADDR_X	6
#elif	NOC_SIZE_X	<=	128
	#define	NOC_WIDTH_ADDR_X	7
#elif	NOC_SIZE_X	<=	256
	#define	NOC_WIDTH_ADDR_X	8
#elif	NOC_SIZE_X	<=	512
	#define	NOC_WIDTH_ADDR_X	9
#elif	NOC_SIZE_X	<=	1024
	#define	NOC_WIDTH_ADDR_X	10
#else
	#error	"[NoC-CFG] The NoC X size selected is wider than the max. range!"
#endif

#if NOC_SIZE_Y <= 16
	#define	NOC_WIDTH_ADDR_Y	4
#elif	NOC_SIZE_Y	<=	32
	#define	NOC_WIDTH_ADDR_Y	5
#elif	NOC_SIZE_Y	<=	64
	#define	NOC_WIDTH_ADDR_Y	6
#elif	NOC_SIZE_Y	<=	128
	#define	NOC_WIDTH_ADDR_Y	7
#elif	NOC_SIZE_Y	<=	256
	#define	NOC_WIDTH_ADDR_Y	8
#elif	NOC_SIZE_Y	<=	512
	#define	NOC_WIDTH_ADDR_Y	9
#elif	NOC_SIZE_Y	<=	1024
	#define	NOC_WIDTH_ADDR_Y	10
#else
	#error	"[NoC-CFG] The NoC Y size selected is wider than the max. range!"
#endif

#define PKT_ID_WIDTH				4													// WIDTH: Size of pkt Identification Number
#define	BITS_P_PLD					8													// Each payload element has 8 bits
#define	PKT_MAX_SIZE_PLD		(1 << PKT_MAX_WIDTH_PLD)	// Max number of payload bytes per pkt
#define HEADER_MIN_WIDTH		(PKT_MAX_WIDTH_PLD+PKT_ID_WIDTH+NOC_WIDTH_ADDR_X+NOC_WIDTH_ADDR_Y+BITS_P_PLD)

#if HEADER_MIN_WIDTH < 32
	#define	SMALL_NOC_CFG
	#define	FLIT_WIDTH				32
	#define	TYPE_DATA_IF			uint
	#define	BUF_FIFO_ENTRIES	(PKT_MAX_SIZE_PLD/4)*NUM_BUF_RT
	#if ((PKT_MAX_SIZE_PLD%4)!=0)
		#error	"[NoC-CFG] Max. number of bytes per packet is not multiple of 4 bytes!"
	#endif
#else
	#define	BIG_NOC_CFG
	#define	FLIT_WIDTH				64
	#define	TYPE_DATA_IF			ulong
	#define	BUF_FIFO_ENTRIES	(PKT_MAX_SIZE_PLD/8)*NUM_BUF_RT
	#if ((PKT_MAX_SIZE_PLD%8)!=0)
		#error	"[NoC-CFG] Max. number of bytes per packet is not multiple of 8 bytes!"
	#endif
#endif

typedef enum {
	HEADER,
	BODY,
	TAIL
} pkt_type;

typedef struct {
	sc_signal<BASE_FMT_SGN(NOC_WIDTH_ADDR_X)>		addr_x;	// Destination address X pkt
	sc_signal<BASE_FMT_SGN(NOC_WIDTH_ADDR_Y)>		addr_y;	// Destination address Y pkt
	sc_signal<BASE_FMT_SGN(PKT_MAX_WIDTH_PLD)>	size;		// Max. bytes size pkt
	sc_signal<BASE_FMT_SGN(PKT_ID_WIDTH)>				id_seq; // Seq. ID number of the pkt
	pkt_type																		type;		// Type of the packet
} pkt_header;

//typedef struct {
	//sc_in		<bool>											SC_NAMED(valid);
	//sc_out	<bool>											SC_NAMED(ready);
	//sc_in		<bool>											SC_NAMED(rw);
	//sc_out	<BASE_FMT_SGN(FLIT_WIDTH)>	SC_NAMED(rdata);
	//sc_in		<BASE_FMT_SGN(FLIT_WIDTH)>	SC_NAMED(wdata);
//} mem_slave;

//typedef struct {
	//sc_signal<BASE_FMT_SGN(NOC_WIDTH_ADDR_X)>		addr_x;	// Destination address X pkt
	//sc_signal<BASE_FMT_SGN(NOC_WIDTH_ADDR_Y)>		addr_y;	// Destination address Y pkt
	//sc_signal<BASE_FMT_SGN(PKT_MAX_WIDTH_PLD)>	size;		// Max. bytes size pkt
//} pe_packet;

//// Interface - class w pure virtual access methods
//class pe_if : virtual public sc_interface {
	//public:
		//virtual void	writePkt (int addr_x, int addr_y, int nBytes, TYPE_DATA_IF *data) = 0;
		//virtual TYPE_DATA_IF*	readPkt () = 0;
//};

//// Hierarchical Channel
//class pe_chl : public pe_if, public sc_channel {
	//public:
		//sc_out		<BASE_FMT_SGN(NOC_WIDTH_ADDR_X)>	p_addr_x;
    //sc_out		<BASE_FMT_SGN(NOC_WIDTH_ADDR_Y)>	p_addr_y;
		//sc_inout	<BASE_FMT_SGN(PKT_MAX_WIDTH_PLD)>	p_size;
		//sc_inout	<BASE_FMT_SGN(FLIT_WIDTH)>				p_data;

		//pe_chl(sc_module_name name) : sc_channel (name) {
		//}

		//virtual void	writePkt (int addr_x, int addr_y, int nBytes, TYPE_DATA_IF *data) = 0;
		//virtual void	readPkt (TYPE_DATA_IF *pBuffer) = 0;
//};

typedef struct {
	sc_in		<bool>	SC_NAMED(clk);
	sc_in		<bool>	SC_NAMED(arst);
} basic_io;

typedef struct {
	sc_out		<BASE_FMT_SGN(NOC_WIDTH_ADDR_X)>	SC_NAMED(p_addr_x);
	sc_out		<BASE_FMT_SGN(NOC_WIDTH_ADDR_Y)>	SC_NAMED(p_addr_y);
	sc_inout	<BASE_FMT_SGN(PKT_MAX_WIDTH_PLD)>	SC_NAMED(p_size);
	sc_inout	<BASE_FMT_SGN(FLIT_WIDTH)>				SC_NAMED(p_data);
} ni_io;

class network_interface : public sc_module {
	public:
		basic_io														io;
		ni_io																slave_port;
		sc_in		<bool>											SC_NAMED(vld);
		sc_out	<bool>											SC_NAMED(rdy);
		sc_out	<bool>											SC_NAMED(pkt_received);
		sc_fifo <BASE_FMT_SGN(FLIT_WIDTH)>	SC_NAMED(inFIFO);
		sc_fifo <BASE_FMT_SGN(FLIT_WIDTH)>	SC_NAMED(outFIFO);

		SC_HAS_PROCESS(network_interface);

		network_interface(sc_module_name name) : sc_module(name),
																						 inFIFO(BUF_FIFO_ENTRIES),
																						 outFIFO(BUF_FIFO_ENTRIES) {
			SC_THREAD(run);
			sensitive	<< io.clk.posedge_event();
		}

		void run();
};

void dbgNoCcfg (void);

#endif

