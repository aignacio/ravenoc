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
  input                 clk,
  input                 arst,
  // Input ports
  input   s_flit_req_t  fin_req_north_i,
  output  s_flit_resp_t fin_resp_north_o,
  input   s_flit_req_t  fin_req_south_i,
  output  s_flit_resp_t fin_resp_south_o,
  input   s_flit_req_t  fin_req_west_i,
  output  s_flit_resp_t fin_resp_west_o,
  input   s_flit_req_t  fin_req_east_i,
  output  s_flit_resp_t fin_resp_east_o,
  // Output ports
  output  s_flit_req_t  fout_req_north_o,
  input   s_flit_resp_t fout_resp_north_i,
  output  s_flit_req_t  fout_req_south_o,
  input   s_flit_resp_t fout_resp_south_i,
  output  s_flit_req_t  fout_req_west_o,
  input   s_flit_resp_t fout_resp_west_i,
  output  s_flit_req_t  fout_req_east_o,
  input   s_flit_resp_t fout_resp_east_i
);
  // Mapping input modules
  s_flit_req_t        [4:0] int_req_v;
  s_flit_resp_t       [4:0] int_resp_v;
  s_router_ports_t    [4:0] int_route_v;

  // Mapping output modules
  s_flit_req_t  [4:0] [3:0] int_map_req_v;
  s_flit_resp_t [4:0] [3:0] int_map_resp_v;

  // External connections
  s_flit_req_t        [4:0] ext_req_v_i;
  s_flit_resp_t       [4:0] ext_resp_v_o;

  s_flit_req_t        [4:0] ext_req_v_o;
  s_flit_resp_t       [4:0] ext_resp_v_i;

  genvar in_mod;
  generate
    for(in_mod=0;in_mod<5;in_mod++) begin : input_modules
      input_module # (
        .ROUTER_X_ID(ROUTER_X_ID),
        .ROUTER_Y_ID(ROUTER_Y_ID)
      ) u_input_module (
        .clk          (clk),
        .arst         (arst),
        .fin_req_i    (ext_req_v_i[in_mod[1:0]]),
        .fin_resp_o   (ext_resp_v_o[in_mod[1:0]]),
        .fout_req_o   (int_req_v[in_mod[1:0]]),
        .fout_resp_i  (int_resp_v[in_mod[1:0]]),
        .router_port_o(int_route_v[in_mod[1:0]])
      );
    end
  endgenerate

  genvar out_mod;
  generate
    for(out_mod=0;out_mod<5;out_mod++) begin : output_modules
      output_module u_output_module (
        .clk(clk),
        .arst(arst),
        .fin_req_i(int_map_req_v[out_mod]),
        .fin_resp_o(int_map_resp_v[out_mod]),
        .fout_req_o(ext_req_v_o[out_mod]),
        .fout_resp_i(ext_resp_v_i[out_mod])
      );
    end
  endgenerate

  always_comb begin : mapping_input_ports
    ext_req_v_i[NORTH_PORT] = fin_req_north_i;
    fin_resp_north_o = ext_resp_v_o[NORTH_PORT];
    ext_req_v_i[SOUTH_PORT] = fin_req_south_i;
    fin_resp_south_o = ext_resp_v_o[SOUTH_PORT];
    ext_req_v_i[WEST_PORT] = fin_req_west_i;
    fin_resp_west_o = ext_resp_v_o[WEST_PORT];
    ext_req_v_i[EAST_PORT] = fin_req_east_i;
    fin_resp_east_o = ext_resp_v_o[EAST_PORT];

    fout_req_north_o = ext_req_v_o[NORTH_PORT];
    ext_resp_v_i[NORTH_PORT] = fout_resp_north_i;
    fout_req_south_o = ext_req_v_o[SOUTH_PORT];
    ext_resp_v_i[SOUTH_PORT] = fout_resp_south_i;
    fout_req_west_o = ext_req_v_o[WEST_PORT];
    ext_resp_v_i[WEST_PORT] = fout_resp_west_i;
    fout_req_east_o = ext_req_v_o[EAST_PORT];
    ext_resp_v_i[EAST_PORT] = fout_resp_east_i;
  end

  always_comb begin : mapping_output_ports
    int_resp_v = '0;
    int_map_req_v = '0;

    // NORTH - Output module flit in / flit out
    int_map_req_v[NORTH_PORT] = {int_route_v[SOUTH_PORT].north_req ? int_req_v[SOUTH_PORT] : '0,
                                 int_route_v[WEST_PORT].north_req  ? int_req_v[WEST_PORT]  : '0,
                                 int_route_v[EAST_PORT].north_req  ? int_req_v[EAST_PORT]  : '0,
                                 int_route_v[LOCAL_PORT].north_req ? int_req_v[LOCAL_PORT] : '0};

    if (int_route_v[SOUTH_PORT].north_req)
      int_resp_v[SOUTH_PORT] = int_map_resp_v[NORTH_PORT][SOUTH_PORT];
    if (int_route_v[WEST_PORT].north_req)
      int_resp_v[WEST_PORT]  = int_map_resp_v[NORTH_PORT][WEST_PORT];
    if (int_route_v[EAST_PORT].north_req)
      int_resp_v[EAST_PORT]  = int_map_resp_v[NORTH_PORT][EAST_PORT];
    if (int_route_v[LOCAL_PORT].north_req)
      int_resp_v[LOCAL_PORT] = int_map_resp_v[NORTH_PORT][LOCAL_PORT];

    // SOUTH - Output module flit in / flit out
    int_map_req_v[SOUTH_PORT] = {int_route_v[WEST_PORT].south_req  ? int_req_v[WEST_PORT]  : '0,
                                 int_route_v[EAST_PORT].south_req  ? int_req_v[EAST_PORT]  : '0,
                                 int_route_v[LOCAL_PORT].south_req ? int_req_v[LOCAL_PORT] : '0,
                                 int_route_v[NORTH_PORT].south_req ? int_req_v[NORTH_PORT] : '0};

    if (int_route_v[WEST_PORT].south_req)
      int_resp_v[WEST_PORT]  = int_map_resp_v[SOUTH_PORT][WEST_PORT];
    if (int_route_v[EAST_PORT].south_req)
      int_resp_v[EAST_PORT]  = int_map_resp_v[SOUTH_PORT][EAST_PORT];
    if (int_route_v[LOCAL_PORT].south_req)
      int_resp_v[LOCAL_PORT] = int_map_resp_v[SOUTH_PORT][LOCAL_PORT];
    if (int_route_v[NORTH_PORT].south_req)
      int_resp_v[NORTH_PORT] = int_map_resp_v[NORTH_PORT][NORTH_PORT];

    // WEST - Output module flit in / flit out
    int_map_req_v[WEST_PORT]  = {int_route_v[EAST_PORT].west_req   ? int_req_v[EAST_PORT]  : '0,
                                 int_route_v[LOCAL_PORT].west_req  ? int_req_v[LOCAL_PORT] : '0,
                                 int_route_v[NORTH_PORT].west_req  ? int_req_v[NORTH_PORT] : '0,
                                 int_route_v[SOUTH_PORT].west_req  ? int_req_v[SOUTH_PORT] : '0};

    if (int_route_v[EAST_PORT].west_req)
      int_resp_v[EAST_PORT]  = int_map_resp_v[WEST_PORT][EAST_PORT];
    if (int_route_v[LOCAL_PORT].west_req)
      int_resp_v[LOCAL_PORT] = int_map_resp_v[WEST_PORT][LOCAL_PORT];
    if (int_route_v[NORTH_PORT].west_req)
      int_resp_v[NORTH_PORT] = int_map_resp_v[WEST_PORT][NORTH_PORT];
    if (int_route_v[SOUTH_PORT].west_req)
      int_resp_v[SOUTH_PORT] = int_map_resp_v[WEST_PORT][SOUTH_PORT];

    // EAST - Output module flit in / flit out
    int_map_req_v[EAST_PORT]  = {int_route_v[LOCAL_PORT].east_req  ? int_req_v[LOCAL_PORT] : '0,
                                 int_route_v[NORTH_PORT].east_req  ? int_req_v[NORTH_PORT] : '0,
                                 int_route_v[SOUTH_PORT].east_req  ? int_req_v[SOUTH_PORT] : '0,
                                 int_route_v[WEST_PORT].east_req   ? int_req_v[WEST_PORT]  : '0};

    if (int_route_v[LOCAL_PORT].east_req)
      int_resp_v[LOCAL_PORT] = int_map_resp_v[EAST_PORT][LOCAL_PORT];
    if (int_route_v[NORTH_PORT].east_req)
      int_resp_v[NORTH_PORT] = int_map_resp_v[EAST_PORT][NORTH_PORT];
    if (int_route_v[SOUTH_PORT].east_req)
      int_resp_v[SOUTH_PORT] = int_map_resp_v[EAST_PORT][SOUTH_PORT];
    if (int_route_v[WEST_PORT].east_req)
      int_resp_v[WEST_PORT]  = int_map_resp_v[EAST_PORT][WEST_PORT];

    // LOCAL - Output module flit in / flit out
    int_map_req_v[LOCAL_PORT] = {int_route_v[NORTH_PORT].local_req  ? int_req_v[NORTH_PORT] : '0,
                                 int_route_v[SOUTH_PORT].local_req  ? int_req_v[SOUTH_PORT] : '0,
                                 int_route_v[WEST_PORT].local_req   ? int_req_v[WEST_PORT]  : '0,
                                 int_route_v[EAST_PORT].local_req   ? int_req_v[EAST_PORT]  : '0};

    if (int_route_v[NORTH_PORT].local_req)
      int_resp_v[NORTH_PORT] = int_map_resp_v[LOCAL_PORT][NORTH_PORT];
    if (int_route_v[SOUTH_PORT].local_req)
      int_resp_v[SOUTH_PORT] = int_map_resp_v[LOCAL_PORT][SOUTH_PORT];
    if (int_route_v[WEST_PORT].local_req)
      int_resp_v[WEST_PORT]  = int_map_resp_v[LOCAL_PORT][WEST_PORT];
    if (int_route_v[EAST_PORT].local_req)
      int_resp_v[EAST_PORT]  = int_map_resp_v[LOCAL_PORT][EAST_PORT];
  end
endmodule
