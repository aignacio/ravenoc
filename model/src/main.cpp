/**
 * File              : main.cpp
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.03.2020
 * Last Modified Date: 16.03.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */

#include <systemc.h>
#include "ravenNoCConfig.h"
#include "testbench.h"
#include "router.h"

SC_MODULE( SYSTEM ){
	public:
		testbench *tb;
		router *rt;

		sc_signal<FIFO_SIZE> a, b;
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

	//sc_trace_file *vcd_dump;

	//vcd_dump = sc_create_vcd_trace_file("waveform.vcd");

	//((vcd_trace_file*)vcd_dump)->sc_set_vcd_time_unit(-9);
  //sc_trace(vcd_dump, a, "a" );
  //sc_trace(vcd_dump, b, "b" );
  //sc_trace(vcd_dump, out, "out" );
  //sc_trace(vcd_dump, rst, "rst");
  //sc_trace(vcd_dump, clk, "S2");

	sc_start();

	//sc_close_vcd_trace_file(vcd_dump);

	return 0;
}
