/**
 * File: input_router.sv
 * Description: Input Router of RaveNoC, this module decodes the next route
 *              for the head flits according to the specific routing alg.
 *              configured. It's also responsible to save the last route
 *              in the case where the flits were preempted due to context
 *              switching, it's does that in a routing table format.
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
module input_router import ravenoc_pkg::*; # (
  parameter ROUTER_X_ID = 0,
  parameter ROUTER_Y_ID = 0
)(
  input                     clk,
  input                     arst,
  input   s_flit_req_t      flit_req_i,
  output  s_router_ports_t  router_port_o
);
  logic [N_VIRT_CHN-1:0] [2:0] routing_table_ff;
  routes_t  next_rt;
  s_flit_head_data_t flit;
  logic new_rt;

  always_comb begin : routing_process
    next_rt = NORTH_PORT;
    flit = flit_req_i.fdata;
    new_rt = (flit_req_i.valid && flit.type_f == HEAD_FLIT);

    /* verilator lint_off UNSIGNED */
    /* verilator lint_off CMPCONST */
    if (new_rt) begin
      if (ROUTING_ALG == "X_Y_ALG") begin
        if (flit.x_dest == ROUTER_X_ID &&
            flit.y_dest == ROUTER_Y_ID) begin : flit_arrived_x
          next_rt = LOCAL_PORT;
        end
        else if (flit.x_dest == ROUTER_X_ID) begin : adjust_y_then
          if (flit.y_dest < ROUTER_Y_ID) begin
            next_rt = WEST_PORT;
          end
          else begin
            next_rt = EAST_PORT;
          end
        end
        else begin : adjust_x_first
          if (flit.x_dest > ROUTER_X_ID) begin
            next_rt = SOUTH_PORT;
          end
          else begin
            next_rt = NORTH_PORT;
          end
        end
      end
      else if (ROUTING_ALG == "Y_X_ALG") begin
        if (flit.x_dest == ROUTER_X_ID &&
            flit.y_dest == ROUTER_Y_ID) begin : flit_arrived_y
          next_rt = LOCAL_PORT;
        end
        else if (flit.y_dest == ROUTER_Y_ID) begin : adjust_x_then
          if (flit.x_dest < ROUTER_X_ID) begin
            next_rt = NORTH_PORT;
          end
          else begin
            next_rt = SOUTH_PORT;
          end
        end
        else begin : adjust_y_first
          if (flit.y_dest > ROUTER_Y_ID) begin
            next_rt = EAST_PORT;
          end
          else begin
            next_rt = WEST_PORT;
          end
        end
      end
    end
    /* verilator lint_on UNSIGNED */
    /* verilator lint_on CMPCONST */
  end

  always_comb begin : router_mapping_control
    router_port_o = '0;

    if (new_rt) begin
      unique case(next_rt)
        NORTH_PORT: router_port_o.north_req = '1;
        SOUTH_PORT: router_port_o.south_req = '1;
        WEST_PORT:  router_port_o.west_req  = '1;
        EAST_PORT:  router_port_o.east_req  = '1;
        LOCAL_PORT: router_port_o.local_req = '1;
        default:    router_port_o           = '0;
      endcase
    end
    else if (flit_req_i.valid) begin
      unique case(routing_table_ff[flit_req_i.vc_id])
        NORTH_PORT: router_port_o.north_req = '1;
        SOUTH_PORT: router_port_o.south_req = '1;
        WEST_PORT:  router_port_o.west_req  = '1;
        EAST_PORT:  router_port_o.east_req  = '1;
        LOCAL_PORT: router_port_o.local_req = '1;
        default:    router_port_o           = '0;
      endcase
    end
  end

  always_ff @ (posedge clk or posedge arst) begin
    if (arst) begin
      routing_table_ff <= '0;
    end
    else begin
      if (new_rt) begin
        routing_table_ff[flit_req_i.vc_id] <= next_rt;
      end
    end
  end

`ifndef NO_ASSERTIONS
  //router_not_one_hot : assert property (
    //@(posedge clk) disable iff (arst)
    //$onehot(router_port_o)
  //) else $error("Input Router is not one hot type!");
`endif
endmodule
