/**
 * File              : main.cpp
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.03.2020
 * Last Modified Date: 17.03.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */

#include <systemc.h>
//#include "sc_vcd_trace.h"
#include "ravenNoCConfig.h"
#include "testbench.h"
#include "router.h"

SC_MODULE( SYSTEM ){
	public:
		testbench *tb;
		router *rt;

		sc_signal<FIFO_SIZE> SC_NAMED(a),SC_NAMED(b);
		sc_signal<FIFO_SIZE> out;
		sc_signal <bool>	rst;
		sc_clock clk;

	SC_CTOR( SYSTEM ) : clk("clk_signal", 10, SC_NS, 0.5){
			tb = new testbench("tb");
			tb->clk(clk);
			tb->arst(rst);
			tb->a(a);
			tb->b(b);
			tb->out(out);

			rt = new router("router");
			rt->clk(clk);
			rt->arst(rst);
			rt->a(a);
			rt->b(b);
			rt->out(out);
		}

		~SYSTEM() {
			delete tb, rt;
		}
};

int sc_main(int argc, char* argv[]) {
	SYSTEM *top = new SYSTEM("top");

	cout << "\n\tProject: " << PROJECT_NAME << endl;
	cout << "\tVersion: " << PROJECT_VER << endl;

	// sc_trace_file *vcd_dump;
	// vcd_dump = sc_create_vcd_trace_file("waveform");
  // sc_trace(vcd_dump, top->a, "a" );
  // sc_trace(vcd_dump, top->b, "b" );
  // sc_trace(vcd_dump, top->out, "out" );
  // sc_trace(vcd_dump, top->rst, "rst");
  // sc_trace(vcd_dump, top->clk, "clk");
  // sc_trace(vcd_dump, top->rt->out, "rt->out");

	sc_start();

	//sc_close_vcd_trace_file(vcd_dump);

	return 0;
}
