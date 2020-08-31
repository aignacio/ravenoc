/**
 * File: vc_buffer.sv
 * Description: Virtual Channel Buffer, contains the flit fifo and the
 *              handshake mech. to push out flit through the output in
 *              terface.
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
module vc_buffer import ravenoc_pkg::*; (
  input                     clk,
  input                     arst,
  // Input interface - from external input module
  input   [FLIT_WIDTH-1:0]  fdata_i,
  input                     valid_i,
  output  logic             ready_o,
  // Output Interface - to Router Ctrl
  output  [FLIT_WIDTH-1:0]  fdata_o,
  output  logic             valid_o,
  input                     ready_i
);
  logic write_flit;
  logic full, empty, error;
  logic read_flit;
  logic locked_by_route_ff;
  logic next_locked;
  s_flit_head_data_t flit;

  fifo # (
    .SLOTS(FLIT_BUFF),
    .WIDTH(FLIT_WIDTH)
  ) u_virt_chn_fifo (
    .clk     (clk),
    .arst    (arst),
    .write_i (write_flit),
    .read_i  (read_flit),
    .data_i  (fdata_i),
    .data_o  (fdata_o),
    .error_o (error),
    .full_o  (full),
    .empty_o (empty)
  );

  always_comb begin
    next_locked = locked_by_route_ff;
    flit = fdata_i;

    if (valid_i && flit.type_f == HEAD_FLIT && flit.pkt_size != '0) begin
      next_locked = 1;
    end
    else if (valid_i && flit.type_f == TAIL_FLIT) begin
      next_locked = 0;
    end
  end

  always_comb begin
    write_flit = ~full && valid_i && (flit.type_f == HEAD_FLIT ? ~locked_by_route_ff : '1);
    ready_o = ~full && (flit.type_f == HEAD_FLIT ? ~locked_by_route_ff : '1);
    valid_o = ~empty;
    read_flit = valid_o && ready_i;
  end

  always_ff @ (posedge clk or posedge arst) begin
    if (arst) begin
      locked_by_route_ff <= '0;
    end
    else begin
      locked_by_route_ff <= next_locked;
    end
  end

`ifndef NO_ASSERTIONS
  illegal_vcd_ctrl_behaviour : assert property (
    @(posedge clk) disable iff (arst)
    error == 'h0
  ) else $error("Illegal Virtual channel value behaviour - Error on FIFO!");
`endif
endmodule
