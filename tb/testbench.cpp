/**
 * File              : testbench.cpp
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 25.08.2020
 * Last Modified Date: 25.08.2020
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#include <iostream>
#include <fstream>
#include <string>
#include <stdlib.h>
#include <signal.h>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vravenoc.h"
#include "Vravenoc__Syms.h"

#define STRINGIZE(x) #x
#define STRINGIZE_VALUE_OF(x) STRINGIZE(x)

using namespace std;

void goingout(int s){
    printf("Caught signal %d\n",s);
    exit(1);
}

template<class module> class testbench {
	VerilatedVcdC *trace = new VerilatedVcdC;
  unsigned long tick_counter;
  bool getDataNextCycle;

  public:
    module *core = new module;
    bool loaded = false;

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

    virtual	void opentrace(const char *vcdname) {
      core->trace(trace, 99);
      trace->open(vcdname);
    }

    virtual void close(void) {
      if (trace) {
        trace->close();
        trace = NULL;
      }
    }

    virtual void tick(void) {

      // if (getDataNextCycle) {
      //   getDataNextCycle = false;
      //   // printf("%c",core->riscv_soc->getbufferReq());
      // }
      // if (core->riscv_soc->printfbufferReq())
      //   getDataNextCycle = true;

      core->clk = 0;
      core->eval();
      tick_counter++;
      if(trace) trace->dump(tick_counter);

      core->clk = 1;
      core->eval();
      tick_counter++;
      if(trace) trace->dump(tick_counter);
    }

    virtual bool done(void) {
      return (Verilated::gotFinish());
    }
};

int main(int argc, char** argv, char** env){
  Verilated::commandArgs(argc, argv);
  auto *noc = new testbench<Vravenoc>;

  if (EN_VCD)
    noc->opentrace(STRINGIZE_VALUE_OF(WAVEFORM_VCD));

  cout << "\n[RaveNoC] Emulator started ";
  if (EN_VCD)
    cout << "\n[VCD File] " << STRINGIZE_VALUE_OF(WAVEFORM_VCD) << " \n";

  struct sigaction sigIntHandler;
  sigIntHandler.sa_handler = goingout;
  sigemptyset(&sigIntHandler.sa_mask);
  sigIntHandler.sa_flags = 0;
  sigaction(SIGINT, &sigIntHandler, NULL);

  noc->core->write_i = 0;
  noc->core->read_i = 0;
  noc->core->data_i = 0;
  noc->reset(10);
  noc->core->write_i = 1;
  for (int i=0;i<10;i++) {
    noc->core->data_i = rand();
    noc->tick();
  }
  noc->core->write_i = 0;
  noc->core->read_i = 1;
  for (int i=0;i<10;i++)
    noc->tick();

  noc->close();
  exit(EXIT_SUCCESS);
}

static vluint64_t  cpuTime = 0;

double sc_time_stamp (){
    return cpuTime;
}
