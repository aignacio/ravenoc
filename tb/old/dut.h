/**
 * File              : dut.h
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 08.01.2021
 * Last Modified Date: 17.01.2021
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Desc.: This is a helper class for dut instant. based on ZipCPU autofpga sw
 */
#ifndef	DUT_H
#define	DUT_H

#include <stdio.h>
#include <stdint.h>

#ifdef	TRACE_FST
#define	TRACECLASS	VerilatedFstC
  #include <verilated_fst_c.h>
#else
  #define	TRACECLASS	VerilatedVcdC
  #include <verilated_vcd_c.h>
#endif

template <class Design>	class Dut {
public:
  Design	    *m_core;
	bool		    m_changed;
	TRACECLASS  *m_trace;
	bool	    	m_done, m_paused_trace;
  vluint64_t	m_time_ps;

  Dut(void) {
		m_core = new Design;
		m_time_ps  = 0ul;
		m_trace    = NULL;
		m_done     = false;
		m_paused_trace = false;
		Verilated::traceEverOn(true);
	}

  virtual ~Dut(void) {
		if (m_trace)
      m_trace->close();
		delete m_core;
		m_core = NULL;
	}

	virtual	void opentrace(const char *vcdname, int depth=99) {
		if (!m_trace) {
			m_trace = new TRACECLASS;
			m_core->trace(m_trace, 99);
			m_trace->spTrace()->set_time_resolution("ps");
			m_trace->spTrace()->set_time_unit("ps");
			m_trace->open(vcdname);
			m_paused_trace = false;
		}
	}

	virtual	bool pausetrace(bool pausetrace) {
		m_paused_trace = pausetrace;
		return m_paused_trace;
	}

  virtual	bool pausetrace(void) {
		return m_paused_trace;
	}

	virtual	void closetrace(void) {
		if (m_trace) {
			m_trace->close();
			delete m_trace;
			m_trace = NULL;
		}
	}

  virtual	void eval(void) {
		m_core->eval();
	}

	virtual	void tick(void) {
    // Pre-evaluate, to give verilator a chance
		// to settle any combinatorial logic that
		// that may have changed since the last clock
		// evaluation, and then record that in the
		// trace.
		//eval();
		//if (m_trace && !m_paused_trace) m_trace->dump(m_time_ps+2500);

    // Advance the one simulation clock, clk
    m_time_ps+= 5000;
    m_core->clk = 1;
    eval();
    // If we are keeping a trace, dump the current state to that
    // trace now
    if (m_trace && !m_paused_trace) {
      m_trace->dump(m_time_ps);
      m_trace->flush();
    }

    // <SINGLE CLOCK ONLY>:
    // Advance the clock again, so that it has its negative edge
    m_core->clk = 0;
    m_time_ps+= 5000;
    eval();
    if (m_trace && !m_paused_trace) m_trace->dump(m_time_ps);
	}

	virtual bool done(void) {
	  if (m_done)
			return true;

		if (Verilated::gotFinish())
			m_done = true;

		return m_done;
	}

	virtual	void reset(void) {
	  m_core->arst = 1;
		tick();
		m_core->arst = 0;
	}

  virtual	void reset(int clock_cycles) {
	  for (int i=0;i<clock_cycles;i++) {
      m_core->arst = 1;
		  tick();
    }
		m_core->arst = 0;
	}
};

#endif
