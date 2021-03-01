/**
 * File              : axi_tb.h
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 08.01.2021
 * Last Modified Date: 17.01.2021
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#ifndef AXI_TB_H
#define AXI_TB_H

#define TIMEOUT_AXI_CK  10

#include <cstdint>

template <class Design> class Axi_tb {
  bool  m_timeout_axi;
public:
  Design  *m_tb;

  Axi_tb(void) {
    m_tb = new Design;
  	Verilated::traceEverOn(true);
	  m_timeout_axi = false;
    m_tb->m_core->axi_sel  = 0UL;
    m_tb->m_core->awid     = 0UL;
    m_tb->m_core->awaddr   = 0UL;
    m_tb->m_core->awlen    = 0UL;
    m_tb->m_core->awsize   = 0UL;
    m_tb->m_core->awburst  = 0UL;
    m_tb->m_core->awlock   = 0UL;
    m_tb->m_core->awcache  = 0UL;
    m_tb->m_core->awprot   = 0UL;
    m_tb->m_core->awqos    = 0UL;
    m_tb->m_core->awregion = 0UL;
    m_tb->m_core->awuser   = 0UL;
    m_tb->m_core->awvalid  = 0UL;
    m_tb->m_core->wid      = 0UL;
    m_tb->m_core->wdata    = 0UL;
    m_tb->m_core->wstrb    = 0UL;
    m_tb->m_core->wlast    = 0UL;
    m_tb->m_core->wuser    = 0UL;
    m_tb->m_core->wvalid   = 0UL;
    m_tb->m_core->bready   = 0UL;
    m_tb->m_core->arid     = 0UL;
    m_tb->m_core->araddr   = 0UL;
    m_tb->m_core->arlen    = 0UL;
    m_tb->m_core->arsize   = 0UL;
    m_tb->m_core->arburst  = 0UL;
    m_tb->m_core->arlock   = 0UL;
    m_tb->m_core->arcache  = 0UL;
    m_tb->m_core->arprot   = 0UL;
    m_tb->m_core->arqos    = 0UL;
    m_tb->m_core->arregion = 0UL;
    m_tb->m_core->aruser   = 0UL;
    m_tb->m_core->arvalid  = 0UL;
    m_tb->m_core->rready   = 0UL;
  }

  virtual void write32(uint8_t slave, uint32_t addr, uint32_t *data, uint8_t len) {
    m_tb->m_core->axi_sel  = slave;
    m_tb->m_core->awvalid  = 1;
    m_tb->m_core->awaddr   = addr;
    m_tb->m_core->awburst  = 0;
    m_tb->m_core->awsize   = 2;
    m_tb->m_core->awlen    = len-1;
    tick();
    while (!m_tb->m_core->awready) tick();
    cleanup_write();
    for(int i=0;i<len+1;i++){
      m_tb->m_core->wstrb    = 0xf;
      m_tb->m_core->wvalid   = 1;
      m_tb->m_core->wdata    = *(data+i);
      m_tb->m_core->wlast    = (i==len) ? 1 : 0;
      do {
        tick();
      } while (!m_tb->m_core->wready);
    }
    m_tb->m_core->bready   = 1;
    while (!m_tb->m_core->bvalid) tick();
    m_tb->m_core->axi_sel  = 0UL;
    cleanup_write();
  }

  void cleanup_write(void) {
    m_tb->m_core->awvalid  = 0UL;
    m_tb->m_core->awaddr   = 0UL;
    m_tb->m_core->awburst  = 0UL;
    m_tb->m_core->wstrb    = 0UL;
    m_tb->m_core->awsize   = 0UL;
    m_tb->m_core->awlen    = 0UL;
    m_tb->m_core->wvalid   = 0UL;
    m_tb->m_core->wdata    = 0UL;
    m_tb->m_core->wlast    = 0UL;
  }

  virtual void write64(uint32_t addr, uint64_t data) {
  }

  virtual	void opentrace(const char *vcdname) {
		m_tb->opentrace(vcdname);
	}

  virtual void tick(void) {
	  m_tb->tick();
  }

  virtual	void reset(int clock_cycles) {
    for (int i=0;i<clock_cycles;i++) {
      m_tb->m_core->arst     = 1;
      m_tb->m_core->axi_sel  = 0UL;
      m_tb->m_core->awid     = 0UL;
      m_tb->m_core->awaddr   = 0UL;
      m_tb->m_core->awlen    = 0UL;
      m_tb->m_core->awsize   = 0UL;
      m_tb->m_core->awburst  = 0UL;
      m_tb->m_core->awlock   = 0UL;
      m_tb->m_core->awcache  = 0UL;
      m_tb->m_core->awprot   = 0UL;
      m_tb->m_core->awqos    = 0UL;
      m_tb->m_core->awregion = 0UL;
      m_tb->m_core->awuser   = 0UL;
      m_tb->m_core->awvalid  = 0UL;
      m_tb->m_core->wid      = 0UL;
      m_tb->m_core->wdata    = 0UL;
      m_tb->m_core->wstrb    = 0UL;
      m_tb->m_core->wlast    = 0UL;
      m_tb->m_core->wuser    = 0UL;
      m_tb->m_core->wvalid   = 0UL;
      m_tb->m_core->bready   = 0UL;
      m_tb->m_core->arid     = 0UL;
      m_tb->m_core->araddr   = 0UL;
      m_tb->m_core->arlen    = 0UL;
      m_tb->m_core->arsize   = 0UL;
      m_tb->m_core->arburst  = 0UL;
      m_tb->m_core->arlock   = 0UL;
      m_tb->m_core->arcache  = 0UL;
      m_tb->m_core->arprot   = 0UL;
      m_tb->m_core->arqos    = 0UL;
      m_tb->m_core->arregion = 0UL;
      m_tb->m_core->aruser   = 0UL;
      m_tb->m_core->arvalid  = 0UL;
      m_tb->m_core->rready   = 0UL;
		  tick();
    }
    m_tb->m_core->arst = 0UL;
	}

  ~Axi_tb(void) {
    delete m_tb;
  }

};
#endif
