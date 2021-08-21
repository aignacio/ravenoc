/**
 * File: async_gp_fifo.sv
 * Description: General purpose Asynchronous FIFO,
 *              based on the following articles:
 *              -> http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf
 *              -> https://zipcpu.com/blog/2018/07/06/afifo.html* File: async_fifo.sv
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
module async_gp_fifo # (
  parameter int SLOTS = 2,
  parameter int WIDTH = 8
) (
  // Clock domain 1
  input                     clk_wr,
  input                     arst_wr,
  input                     wr_en_i,
  input   [WIDTH-1:0]       wr_data_i,
  output  logic             wr_full_o,

  // Clock domain 2
  input                     clk_rd,
  input                     arst_rd,
  input                     rd_en_i,
  output  logic [WIDTH-1:0] rd_data_o,
  output  logic             rd_empty_o
);
  `define IDX_PTR   w_wr_bin_ptr_ff[$clog2(SLOTS)-1:0]  // Valid index pointer

  // Naming convention
  // ptr - pointer
  // wr  - write
  // rd  - read
  // bin - binary
  //
  // Pointers convention used follows the below pattern:
  //  -> CLKDOMAIN(w/r)_TYPE(wr/rd)_ENCODING(bin/gray)_ptr
  // Example:
  // w_wr_bin_ptr - Write binary pointer in write clock domain
  // r_wr_gray_ptr - Write gray pointer in read clock domain
  // META_... - Metastable transition FF
  typedef logic [$clog2(SLOTS):0] ptr_t;
  logic [SLOTS-1:0] [WIDTH-1:0] array_fifo_ff;

  ptr_t  w_wr_bin_ptr_ff, next_w_wr_bin_ptr;
  ptr_t  w_rd_gry_ptr_ff, w_rd_bin_ptr; // We only bring to wr domain
                                        // the rd gray encoded ptr once
                                        // we only use it to gen the full
                                        // flag, and crossing gray encoding
                                        // it's more stable than bin encoding

  ptr_t  r_rd_bin_ptr_ff, next_r_rd_bin_ptr;
  ptr_t  r_wr_gry_ptr_ff; // We only bring to rd domain
                          // the wr gray encoded ptr once
                          // we only use it to gen the empty
                          // flag, and crossing gray encoding
                          // it's more stable than bin encoding
  ptr_t META_w_rd_gry_ff;
  ptr_t META_r_wr_gry_ff;

  //************************
  // Functions
  //************************
  function automatic ptr_t bin_to_gray (ptr_t input_bin);
    ptr_t value;
    value = (input_bin >> 1) ^ input_bin;
    return value;
  endfunction

  function automatic ptr_t gray_to_bin (ptr_t input_gray);
    ptr_t value;
    value = input_gray;
    for (int i=$clog2(SLOTS);i>0;i--)
      value[i-1] = value[i]^value[i-1];
    return value;
  endfunction

  //************************
  // Write logic
  //************************
  always_comb begin : wr_pointer
    next_w_wr_bin_ptr = w_wr_bin_ptr_ff;
    w_rd_bin_ptr = gray_to_bin(w_rd_gry_ptr_ff);

    wr_full_o = (w_wr_bin_ptr_ff[$clog2(SLOTS)] == ~w_rd_bin_ptr[$clog2(SLOTS)]) &&
                (w_wr_bin_ptr_ff[$clog2(SLOTS)-1:0] == w_rd_bin_ptr[$clog2(SLOTS)-1:0]);

    if (wr_en_i && ~wr_full_o) begin
      next_w_wr_bin_ptr = w_wr_bin_ptr_ff + 'd1;
    end
  end

  always_ff @ (posedge clk_wr or posedge arst_wr) begin
    if (arst_wr) begin
      w_wr_bin_ptr_ff  <= ptr_t'(0);
      META_w_rd_gry_ff <= ptr_t'(0);
      w_rd_gry_ptr_ff  <= ptr_t'(0);
      //array_fifo_ff    <= '0; // --> Let's make it "low power"
    end
    else begin
      w_wr_bin_ptr_ff  <= next_w_wr_bin_ptr;
      // 2FF Synchronizer:
      // Bring RD ptr to WR domain
      META_w_rd_gry_ff <= bin_to_gray(r_rd_bin_ptr_ff);
      w_rd_gry_ptr_ff  <= META_w_rd_gry_ff;

      if (wr_en_i && ~wr_full_o) begin
        array_fifo_ff[`IDX_PTR] <= wr_data_i;
      end
    end
  end

  //************************
  // Read logic
  //************************
  always_comb begin : rd_pointer
    next_r_rd_bin_ptr = r_rd_bin_ptr_ff;

    rd_empty_o = (bin_to_gray(r_rd_bin_ptr_ff) == r_wr_gry_ptr_ff);

    if (rd_en_i && ~rd_empty_o) begin
      next_r_rd_bin_ptr = r_rd_bin_ptr_ff + 'd1;
    end

    rd_data_o = array_fifo_ff[r_rd_bin_ptr_ff[$clog2(SLOTS)-1:0]];
  end

  always_ff @ (posedge clk_rd or posedge arst_rd) begin
    if (arst_rd) begin
      r_rd_bin_ptr_ff  <= ptr_t'(0);
      META_r_wr_gry_ff <= ptr_t'(0);
      r_wr_gry_ptr_ff  <= ptr_t'(0);
    end
    else begin
      r_rd_bin_ptr_ff  <= next_r_rd_bin_ptr;
      // 2FF Synchronizer:
      // Bring RD ptr to WR domain
      META_r_wr_gry_ff <= bin_to_gray(w_wr_bin_ptr_ff);
      r_wr_gry_ptr_ff  <= META_r_wr_gry_ff;
    end
  end

`ifndef NO_ASSERTIONS
  initial begin
    illegal_fifo_slot : assert (2**$clog2(SLOTS) == SLOTS)
    else $error("ASYNC FIFO Slots must be power of 2");

    min_fifo_size_2 : assert (SLOTS >= 2)
    else $error("ASYNC FIFO size of SLOTS defined is illegal!");
  end
`endif
endmodule
