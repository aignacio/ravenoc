/**
 * File: input_module.sv
 * Description: Input module that has the structural connection
 *              between datapath with the flit's fifos and the
 *              router that maps to different output modules.
 * Author: Anderson Ignacio da Silva <anderson@aignacio.com>
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
module input_module
  import ravenoc_pkg::*;
#(
  parameter logic [XWidth-1:0] ROUTER_X_ID = 0,
  parameter logic [YWidth-1:0] ROUTER_Y_ID = 0
)(
  input                     clk,
  input                     arst,
  // Input interface - from external
  input   s_flit_req_t      fin_req_i,
  output  s_flit_resp_t     fin_resp_o,
  // Output Interface - Output module
  output  s_flit_req_t      fout_req_o,
  input   s_flit_resp_t     fout_resp_i,
  output  s_router_ports_t  router_port_o
);

  input_datapath u_input_datapath (
    .clk        (clk),
    .arst       (arst),
    .fin_req_i  (fin_req_i),
    .fin_resp_o (fin_resp_o),
    .fout_req_o (fout_req_o),
    .fout_resp_i(fout_resp_i)
  );

  input_router#(
    .ROUTER_X_ID(ROUTER_X_ID),
    .ROUTER_Y_ID(ROUTER_Y_ID)
  ) u_input_router (
    .clk          (clk),
    .arst         (arst),
    .flit_req_i   (fout_req_o),
    .router_port_o(router_port_o)
  );
endmodule
