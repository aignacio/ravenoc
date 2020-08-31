/**
 * File: ravenoc.sv
 * Description: RaveNoC top module
 * Author: Anderson Ignacio da Silva <aignacio@aignacio.com>
 *
 * MIT License
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
module ravenoc import ravenoc_pkg::*; (
  input                             clk /*verilator clocker*/,
  input                             arst,
  // Input interface - from external input module
  input   [FLIT_WIDTH-1:0]          flit_data_i,
  input                             valid_i,
  output                            ready_o,
  input   [$clog2(N_VIRT_CHN)-1:0]  vc_id_i,
  // Output Interface - to Router Ctrl
  output  [FLIT_WIDTH-1:0]          flit_data_o,
  output                            valid_o,
  input                             ready_i,
  output  [$clog2(N_VIRT_CHN)-1:0]  vc_id_o
);
  s_flit_req_t      fin_req;
  s_flit_resp_t     fin_resp;

  s_flit_req_t      fout_req;
  s_flit_resp_t     fout_resp;

  assign fin_req.fdata = flit_data_i;
  assign fin_req.valid = valid_i;
  assign fin_req.vc_id = vc_id_i;
  assign ready_o = fin_resp.ready;

  assign flit_data_o = fout_req.fdata;
  assign valid_o = fout_req.valid;
  assign vc_id_o = fout_req.vc_id;
  assign fout_resp.ready = ready_i;

  input_module # (
    .ROUTER_X_ID(0),
    .ROUTER_Y_ID(0)
  ) u_input_module (
    .clk(clk),
    .arst(arst),
    .fin_req_i(fin_req),
    .fin_resp_o(fin_resp),
    .fout_req_o(fout_req),
    .fout_resp_i(fout_resp),
    .router_port_o()
  );
endmodule
