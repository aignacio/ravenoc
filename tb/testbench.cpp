/**
 * File              : testbench.cpp
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 25.08.2020
 * Last Modified Date: 09.09.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#include <iostream>
#include <fstream>
#include <string>
#include <stdlib.h>
#include <signal.h>

#include "verilated.h"
#include "verilated_fst_c.h"
#include "Vravenoc.h"
#include "Vravenoc__Syms.h"

#define STRINGIZE(x) #x
#define STRINGIZE_VALUE_OF(x) STRINGIZE(x)

using namespace std;

union s_flit_req_t {
  struct {
    unsigned long fdata:34;
    unsigned long valid:1;
  } val;
  unsigned long packed;
};

template<class module> class testbench {
	VerilatedFstC *trace = new VerilatedFstC; // We dump FST cause we can see better than VCD (mems, structs)
  unsigned long tick_counter;
  bool getDataNextCycle;

  public:
    module *core = new module;

    testbench() {
      Verilated::traceEverOn(true);
      tick_counter = 0l;
    }

    ~testbench(void) {
      delete core;
      core = NULL;
    }

    virtual void reset(int rst_cyc) {
      for (int i=0;i<rst_cyc;i++) {
        core->arst = 1;
        this->tick();
      }
      core->arst = 0;
      this->tick();
    }

    virtual	void opentrace(const char *fstname) {
      core->trace(trace, 99);
      trace->open(fstname);
    }

    virtual void close(void) {
      if (trace) {
        trace->close();
        trace = NULL;
      }
    }

    virtual unsigned long get_tick(){
      return tick_counter;
    }

    virtual void tick(void) {
      // if (getDataNextCycle) {
      //   getDataNextCycle = false;
      //   // printf("%c",core->riscv_soc->getbufferReq());
      // }
      // if (core->riscv_soc->printfbufferReq())
      //   getDataNextCycle = true;

      tick_counter++;

      core->clk = 0;
      core->eval();

      if(trace) trace->dump(10*tick_counter-2);

      core->clk = 1;
      core->eval();

      if(trace) trace->dump(10*tick_counter);

      core->clk = 0;
      core->eval();

      if(trace){
        trace->dump(10*tick_counter+5);
        trace->flush();
      }
    }

    virtual bool done(void) {
      return (Verilated::gotFinish());
    }
};

int main(int argc, char** argv, char** env){
  Verilated::commandArgs(argc, argv);
  auto *noc = new testbench<Vravenoc>;

  if (EN_TRACE)
    noc->opentrace(STRINGIZE_VALUE_OF(WAVEFORM));

  cout << "\n[RaveNoC] Emulator started ";
  if (EN_TRACE)
    cout << "\n[Trace File] " << STRINGIZE_VALUE_OF(WAVEFORM) << " \n";

  noc->reset(2);
  //noc->core->flit_data_i = 0;
  //noc->core->valid_i = 0;
  //noc->core->ready_i = 0;
  //for(int i=0;i<4;i++){
    //cout << "Virtual channel id = " << i << "\n";
    //for (int j=0;j<4;j++) {
      //noc->core->flit_data_i = rand();
      //noc->core->valid_i = 1;
      //noc->core->vc_id_i = i;
      //noc->tick();
    //}
  //}

  //noc->core->valid_i = 0;
  //for (int i=0;i<20;i++){
    //noc->core->ready_i = 1;
    //noc->tick();
  //}

  //noc->core->ready_i = 0;
  noc->tick();

  noc->close();
  exit(EXIT_SUCCESS);
}

static vluint64_t  cpuTime = 0;

double sc_time_stamp (){
    return cpuTime;
}
