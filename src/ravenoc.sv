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
  input                             arst//,
  // Input interface - from external input module
  //input   [FLIT_WIDTH-1:0]          flit_data_i,
  //input                             valid_i,
  //output                            ready_o,
  //input   [$clog2(N_VIRT_CHN>1?N_VIRT_CHN:2)-1:0]  vc_id_i,
  //// Output Interface - to Router Ctrl
  //output  [FLIT_WIDTH-1:0]          flit_data_o,
  //output                            valid_o,
  //input                             ready_i,
  //output  [$clog2(N_VIRT_CHN>1?N_VIRT_CHN:2)-1:0]  vc_id_o
);
  s_flit_req_t  [NOC_CFG_SZ_X-1:0]  [NOC_CFG_SZ_Y-1:0] north_req_fin, north_req_fout;
  s_flit_resp_t [NOC_CFG_SZ_X-1:0]  [NOC_CFG_SZ_Y-1:0] north_resp_fin, north_resp_fout;
  s_flit_req_t  [NOC_CFG_SZ_Y-1:0]  dummy_north_req;
  s_flit_resp_t [NOC_CFG_SZ_Y-1:0]  dummy_north_resp;

  s_flit_req_t  [NOC_CFG_SZ_X-1:0]  [NOC_CFG_SZ_Y-1:0] south_req_fin, south_req_fout;
  s_flit_resp_t [NOC_CFG_SZ_X-1:0]  [NOC_CFG_SZ_Y-1:0] south_resp_fin, south_resp_fout;
  s_flit_req_t  [NOC_CFG_SZ_Y-1:0]  dummy_south_req;
  s_flit_resp_t [NOC_CFG_SZ_Y-1:0]  dummy_south_resp;

  genvar x_idx,y_idx;
  generate
    for(x_idx=0;x_idx<NOC_CFG_SZ_X;x_idx++) begin
      for(y_idx=0;y_idx<NOC_CFG_SZ_Y;y_idx++) begin
        router_ravenoc#(
          .ROUTER_X_ID(x_idx),
          .ROUTER_Y_ID(y_idx)
        ) u_router (
          .clk              (clk),
          .arst             (arst),
          // North
          .fin_req_north_i  (x_idx>0?south_req_fout [x_idx][y_idx]:'0),
          .fin_resp_north_o (x_idx>0?south_resp_fin [x_idx][y_idx]:dummy_north_resp[y_idx]),
          //.fout_req_north_o (x_idx>0?south_req_fin  [x_idx][y_idx]:dummy_north_req [y_idx]),
          .fout_req_north_o (),
          .fout_resp_north_i(x_idx>0?south_resp_fout[x_idx][y_idx]:'0),
          // South
          .fin_req_south_i  (x_idx<(NOC_CFG_SZ_X-1)?north_req_fout [x_idx][y_idx]:'0),
          //.fin_resp_south_o (x_idx<(NOC_CFG_SZ_X-1)?north_resp_fin [x_idx][y_idx]:dummy_south_resp[y_idx]),
          .fin_resp_south_o (),
          //.fout_req_south_o (x_idx<(NOC_CFG_SZ_X-1)?north_req_fin  [x_idx][y_idx]:dummy_south_req [y_idx]),
          .fout_req_south_o (),
          .fout_resp_south_i(x_idx<(NOC_CFG_SZ_X-1)?north_resp_fout[x_idx][y_idx]:'0),
          // West
          .fin_req_west_i   ('0),
          .fin_resp_west_o  (),
          .fout_req_west_o  (),
          .fout_resp_west_i ('0),
          // East
          .fin_req_east_i   ('0),
          .fin_resp_east_o  (),
          .fout_req_east_o  (),
          .fout_resp_east_i ('0)
        );
      end
    end
  endgenerate
endmodule
