/**
 * File              : axi_tb.h
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 08.01.2021
 * Last Modified Date: 12.01.2021
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#ifndef AXI_TB_H
#define AXI_TB_H

#define TIMEOUT_AXI_CK  10

template <class Design> class Axi_tb {
  bool  m_timeout_axi;
public:
  Design  *m_tb;

  Axi_tb(void) {
    m_tb = new Design;
  	Verilated::traceEverOn(true);
	  m_timeout_axi = false;
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

  ~Axi_tb(void) {
    delete m_tb;
  }

};
#endif
