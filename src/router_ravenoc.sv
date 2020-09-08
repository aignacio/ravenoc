/**
 * File: router_ravenoc.sv
 * Description: RaveNoC router datapath
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
module router_ravenoc import ravenoc_pkg::*; # (
  parameter ROUTER_X_ID = 0,
  parameter ROUTER_Y_ID = 0
) (
  input                             clk,
  input                             arst
);
  s_flit_req_t      [3:0] int_req_v;
  s_flit_req_t      [3:0] ext_req_v;
  s_flit_resp_t     [3:0] int_resp_v;
  s_flit_resp_t     [3:0] ext_resp_v;
  s_router_ports_t  [3:0] int_route_v;

  genvar in_mod;
  generate
    for(in_mod=0;in_mod<4;in_mod++) begin
      input_module # (
        .ROUTER_X_ID(ROUTER_X_ID),
        .ROUTER_Y_ID(ROUTER_Y_ID)
      ) u_input_module (
        .clk          (clk),
        .arst         (arst),
        .fin_req_i    (ext_req_v[in_mod[1:0]]),
        .fin_resp_o   (ext_resp_V[in_mod[1:0]]),
        .fout_req_o   (int_req_v[in_mod[1:0]),
        .fout_resp_i  (int_resp_V[in_mod[1:0]]),
        .router_port_o(int_route_v[in_mod[1:0]])
      );
    end
  endgenerate

  genvar out_mod;
  generate
    for(out_mod=0;out_mod<4;out_mod++) begin
      output_module u_output_module (
        .clk(clk),
        .arst(arst),
        .fin_req_i(),
        .fin_resp_o(),
        .fout_req_o(),
        .fout_resp_i()
      );
    end
  endgenerate

  always_comb begin
    int_north_req_ar = '0;
    int_north_resp_ar = '0;

    if (int_north_router.south_req) begin
      int_north_req_ar[SOUTH_PORT] = int_north_req;
      int_north_resp = '0;
    end

  end
endmodule
