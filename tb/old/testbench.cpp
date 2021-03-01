/**
 * File              : testbench.cpp
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 25.08.2020
 * Last Modified Date: 14.01.2021
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#include <iostream>
#include <fstream>
#include <string>
#include <stdlib.h>
#include <signal.h>
#include <cstdint>

#include "verilated.h"
#include "verilated_fst_c.h"
#include "axi_tb.h"
#include "dut.h"
#include "Vravenoc_wrapper.h"
#include "Vravenoc_wrapper__Syms.h"

#define STRINGIZE(x) #x
#define STRINGIZE_VALUE_OF(x) STRINGIZE(x)

using namespace std;

union flit_t {
  struct {
    unsigned long type_f:2;
    unsigned long x_dest:2;
    unsigned long y_dest:2;
    unsigned long pkt_size:8;
    unsigned long data:20;
  } val;
  unsigned long packed;
};

//union s_flit_req_t {
  //struct {
    //unsigned long fdata:34;
    //unsigned long valid:1;
  //} val;
  //unsigned long packed;
//};

int main(int argc, char** argv, char** env){
  Verilated::commandArgs(argc, argv);
  auto *noc = new Axi_tb<Dut<Vravenoc_wrapper>>;
  string str = "Anderson";
  uint32_t data = stoul(str,nullptr,16);

  noc->opentrace(STRINGIZE_VALUE_OF(WAVEFORM));
  noc->reset(2);
  for (int i=0;i<100;i++)
    noc->tick();

  noc->write32(5, 0x100c, &data, 8);
  noc->write32(6, 0x100b, &data, 1);
  noc->write32(2, 0x100a, &data, 2);

  for (int i=0;i<100;i++)
    noc->tick();

  exit(EXIT_SUCCESS);
}
