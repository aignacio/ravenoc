/**
 * File: axi_slave_if.sv
 * Description: AXI Slave interface to receive requests from the PE.
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
module axi_slave_if
  import amba_axi_pkg::*;
  import ravenoc_pkg::*;
#(
  parameter logic [XWidth-1:0] ROUTER_X_ID = 0,
  parameter logic [YWidth-1:0] ROUTER_Y_ID = 0,
  parameter bit                CDC_REQUIRED = 1
) (
  input                     clk_axi,
  input                     arst_axi,

  // AXI I/F with PE
  input   s_axi_mosi_t      axi_mosi_if_i,
  output  s_axi_miso_t      axi_miso_if_o,

  // Interface with the Packet Generator
  // AXI Slave -> Pkt Gen
  output  s_pkt_out_req_t   pkt_out_req_o,
  input   s_pkt_out_resp_t  pkt_out_resp_i,
  input                     full_wr_fifo_i,

  // AXI Salve <- Pkt Gen
  input   s_pkt_in_req_t    pkt_in_req_i,
  output  s_pkt_in_resp_t   pkt_in_resp_o,

  // IRQ signals
  output  s_irq_ni_t        irqs_o
);
  // AXI Variables
  logic                                       vld_axi_txn_wr;
  logic                                       vld_axi_txn_rd;

  // WRITE signals
  logic                                       fifo_wr_req_empty;
  logic                                       fifo_wr_req_full;
  logic                                       write_wr;
  logic                                       read_wr;
  s_ot_fifo_t                                 in_fifo_wr_data;
  s_ot_fifo_t                                 out_fifo_wr_data;
  axi_error_t                                 bresp_ff;
  logic                                       bvalid_ff;
  axi_error_t                                 next_bresp;
  logic                                       next_bvalid;
  s_axi_mm_dec_t                              decode_req_wr;
  logic                                       ready_from_in_buff;
  logic                                       normal_txn_resp;
  logic                                       error_wr_txn;
  logic                                       error_csr_wr_txn;
  s_axi_mm_dec_t                              def_wr_dec;

  // READ signals
  logic [NumVirtChn-1:0]                      full_rd_arr;
  logic [NumVirtChn-1:0]                      empty_rd_arr;
  logic [NumVirtChn-1:0]                      write_rd_arr;
  logic [NumVirtChn-1:0]                      read_rd_arr;
  logic [NumVirtChn-1:0][15:0]                fifo_ocup_rd_arr;
  logic [NumVirtChn-1:0][`AXI_DATA_WIDTH-1:0] data_rd_buff;
  logic [`AXI_DATA_WIDTH-1:0]                 data_rd_sel;
  logic                                       fifo_rd_req_empty;
  logic                                       fifo_rd_req_full;
  logic                                       write_rd;
  logic                                       read_rd;
  s_ot_fifo_t                                 in_fifo_rd_data;
  s_ot_fifo_t                                 out_fifo_rd_data;
  s_axi_mm_dec_t                              decode_req_rd;
  s_axi_mm_dec_t                              def_rd_dec;
  logic                                       error_rd_txn;
  logic [`AXI_ALEN_WIDTH-1:0]                 beat_count_ff;
  logic [`AXI_ALEN_WIDTH-1:0]                 next_beat_count;
  logic                                       txn_rd_ff;
  logic                                       next_txn_rd;
  logic                                       data_rvalid;
  logic                                       read_txn_done;
  logic [NumVirtChn-1:0][PktWidth-1:0]        pkt_sz_rd_buff;
  axi_tid_t                                   bid_ff, next_bid;

  // CSR signals
  s_csr_req_t                                 csr_req;
  s_csr_resp_t                                csr_resp;

  always_comb begin : axi_protocol_handshake
    axi_miso_if_o = s_axi_miso_t'('0);
    pkt_out_req_o = s_pkt_out_req_t'('0);
    csr_req       = s_csr_req_t'('0);

    // ----------------------------------
    // WRITE AXI CHANNEL (ADDR+DATA+RESP)
    // ----------------------------------
    // We define the write channel availability based
    // on size of outstanding txns in the wr fifo
    axi_miso_if_o.awready = ~fifo_wr_req_full;
    vld_axi_txn_wr  = axi_mosi_if_i.awvalid &&
                      axi_miso_if_o.awready &&
                      (axi_mosi_if_i.awburst == AXI_INCR) &&
                      valid_addr_wr(axi_mosi_if_i.awaddr) &&
                      valid_op_size(axi_mosi_if_i.awaddr, axi_mosi_if_i.awsize);
    // We translate the last req. in the OT fifo to get the address space + virtual channel ID (if applicable)
    def_wr_dec.region = NONE;
    def_wr_dec.virt_chn_id = 'h0;
    decode_req_wr  = out_fifo_wr_data.error == 1'b1 ? def_wr_dec :
                                                      check_mm_req({16'h0,out_fifo_wr_data.addr});

    ready_from_in_buff = 1'b1;
    if (~fifo_wr_req_empty) begin
      unique case(decode_req_wr.region)
        NOC_WR_FIFOS: begin
          pkt_out_req_o.vc_id    = decode_req_wr.virt_chn_id;
          ready_from_in_buff     = pkt_out_resp_i.ready;
          if (axi_mosi_if_i.wvalid) begin
            pkt_out_req_o.valid     = 1'b1;
            pkt_out_req_o.flit_data_width = axi_mosi_if_i.wdata;
            pkt_out_req_o.pkt_sz   = axi_mosi_if_i.wdata[(MinDataWidth)+:PktWidth];
          end
        end
        NOC_CSR: begin
          if (axi_mosi_if_i.wvalid) begin
            csr_req.valid    = 'b1;
            csr_req.rd_or_wr = 'b1;
            csr_req.addr     = out_fifo_wr_data.addr;
            /* verilator lint_off SELRANGE */
            // In case of 64-bit version and the CSR addr is not DWORD aligned, we need to shift to the MSBi
            // see AMBA AXI v4 - Page 53 / Narrow txn
            if (`AXI_DATA_WIDTH == 64) begin
              csr_req.data_in = (out_fifo_wr_data.addr[2:0] == 'h0) ? axi_mosi_if_i.wdata[31:0] :
                                                                      axi_mosi_if_i.wdata[63:32];
            end
            else begin
              csr_req.data_in  = axi_mosi_if_i.wdata[31:0];
            end
            /* verilator lint_on SELRANGE */
          end
        end
        NOC_RD_FIFOS:
          ready_from_in_buff = 1'b1;
        NONE: // Used as error condition
          ready_from_in_buff = 1'b1;
        //assert (0) else $error("[AXI_SLAVE] It should not decode a read op. in this fifo!");
        default:  ready_from_in_buff = 1'b1;
      endcase
    end
    // When sending the flit, our availability is based on input buffer fifo
    // if the req fifo is empty it means that master has transferred all
    // so we should not be available to receive more data. In case of CSR
    // it comes from the csr_resp.ready signal
    if (decode_req_wr.region == NOC_WR_FIFOS) begin
      axi_miso_if_o.wready = fifo_wr_req_empty ? 1'b0 : ready_from_in_buff;
    end
    else begin
      axi_miso_if_o.wready = fifo_wr_req_empty ? 1'b0 : csr_resp.ready;
    end
    // We send a write response right after we finished the write
    // it's not implemented error handling on this channel
    axi_miso_if_o.bvalid = bvalid_ff;
    axi_miso_if_o.bresp = bresp_ff;
    axi_miso_if_o.bid = bid_ff;

    normal_txn_resp = axi_mosi_if_i.wvalid && axi_mosi_if_i.wlast && axi_miso_if_o.wready;
    error_wr_txn  = axi_mosi_if_i.awvalid &&
                    axi_miso_if_o.awready &&
                    ~vld_axi_txn_wr;

    next_bid    = read_wr ? axi_tid_t'(out_fifo_wr_data.id) : bid_ff;
    next_bresp  = bvalid_ff ? (axi_mosi_if_i.bready ?
                              (out_fifo_wr_data.error ? AXI_SLVERR : AXI_OKAY) : bresp_ff) :
                              ((out_fifo_wr_data.error ||
                              ((decode_req_wr.region == NOC_CSR) && csr_resp.error)) ? AXI_SLVERR :
                              AXI_OKAY);
    // We stop sending bvalid when the master accept it
    next_bvalid = bvalid_ff ? (normal_txn_resp ? 1'b1 : ~axi_mosi_if_i.bready) : normal_txn_resp;

    // ----------------------------------
    // READ AXI CHANNEL (ADDR+DATA)
    // ----------------------------------
    axi_miso_if_o.arready = ~fifo_rd_req_full;
    vld_axi_txn_rd  = axi_mosi_if_i.arvalid &&
                      axi_miso_if_o.arready &&
                      (axi_mosi_if_i.arburst == AXI_INCR) &&
                      valid_addr_rd(axi_mosi_if_i.araddr, empty_rd_arr) &&
                      valid_op_size(axi_mosi_if_i.araddr, axi_mosi_if_i.arsize);


    def_rd_dec.region = NONE;
    def_rd_dec.virt_chn_id = 'h0;

    decode_req_rd  = out_fifo_rd_data.error == 1'b1 ? def_rd_dec :
                                                      check_mm_req({16'h0,out_fifo_rd_data.addr});

    error_rd_txn  = axi_mosi_if_i.arvalid &&
                    axi_miso_if_o.arready &&
                    ~vld_axi_txn_rd;

    next_txn_rd = 1'b0;
    next_beat_count = '0;

    if (~out_fifo_rd_data.error) begin
      if (decode_req_rd.region == NOC_RD_FIFOS) begin
        if (txn_rd_ff) begin
          axi_miso_if_o.rid = out_fifo_rd_data.id;
          axi_miso_if_o.rvalid = data_rvalid;
          axi_miso_if_o.rdata = data_rvalid ? data_rd_sel : '0;
        end

        if ((beat_count_ff == out_fifo_rd_data.alen) && (axi_miso_if_o.rvalid)) begin
          axi_miso_if_o.rid = out_fifo_rd_data.id;
          axi_miso_if_o.rlast = axi_miso_if_o.rvalid;
        end
      end
      else begin // We're in the CSR read region
        if (txn_rd_ff) begin
          axi_miso_if_o.rid = out_fifo_rd_data.id;
          axi_miso_if_o.rvalid = csr_resp.ready;
          axi_miso_if_o.rlast = 1'b1;
          /* verilator lint_off WIDTH */
          // In case of 64-bit version and the CSR addr is not DWORD aligned, we need to shift to the MSB
          // see AMBA AXI v4 - Page 53 / Narrow txn
          if (`AXI_DATA_WIDTH == 64) begin
            if (csr_resp.ready) begin
              axi_miso_if_o.rdata = (out_fifo_rd_data.addr[2:0] == 'h0) ?
                                    {32'h0,csr_resp.data_out} :
                                    {csr_resp.data_out,32'h0};
            end
            else begin
              axi_miso_if_o.rdata = '0;
            end
          end
          else begin
            axi_miso_if_o.rdata = csr_resp.ready ? csr_resp.data_out : '0;
          end
          /* verilator lint_on WIDTH */
        end
      end
    end
    else begin
      if (txn_rd_ff) begin
        axi_miso_if_o.rid = out_fifo_rd_data.id;
        axi_miso_if_o.rvalid = 1'b1;
        axi_miso_if_o.rlast = 1'b1;
        axi_miso_if_o.rdata = '0;
        axi_miso_if_o.rresp = AXI_SLVERR;
      end
    end

    // This signal indicates that the beat was transferred successfully
    read_txn_done = axi_mosi_if_i.rready && axi_miso_if_o.rvalid;

    if (~fifo_rd_req_empty) begin
      unique case(decode_req_rd.region)
        NONE: begin // Used as error condition
          next_txn_rd = 1'b1;
          if (txn_rd_ff && read_txn_done)
            next_txn_rd = 1'b0;
        end
        NOC_CSR: begin
          next_txn_rd = 1'b1;
          if (txn_rd_ff && read_txn_done)
            next_txn_rd = 1'b0;

          if (next_txn_rd && ~txn_rd_ff) begin
            csr_req.valid    = 'b1;
            csr_req.rd_or_wr = 'b0;
            csr_req.addr     = out_fifo_rd_data.addr;
          end
        end
        NOC_RD_FIFOS: begin
          if (~txn_rd_ff) begin
            next_txn_rd = 1'b1;
            next_beat_count = 'd0;
          end
          else begin
            if (beat_count_ff < out_fifo_rd_data.alen)
              next_beat_count = beat_count_ff + (read_txn_done ? 'd1 : 'd0);
            else
              next_beat_count = beat_count_ff;

            if (read_txn_done && beat_count_ff == out_fifo_rd_data.alen)
              next_txn_rd = 1'b0;
            else
              next_txn_rd = 1'b1;
          end
        end
        default: next_txn_rd = 1'b0;
      endcase
    end
  end

  // **************************
  //
  // Write AXI
  //
  // **************************
  // In the case of a WRITE, master will
  // write in the input buffers depending
  // the virtual channel availability
  always_ff @ (posedge clk_axi or posedge arst_axi) begin
    if (arst_axi) begin
      bvalid_ff    <= 1'b0;
      bresp_ff     <= axi_error_t'('0);
      bid_ff       <= axi_tid_t'('0);
    end
    else begin
      bvalid_ff    <= next_bvalid;
      bresp_ff     <= next_bresp;
      bid_ff       <= next_bid;
    end
  end

  always_comb begin : ctrl_fifo_ot_write
    // Address channel fifo frame
    // -----------------=----------------------------------------------------
    // | error | axi.id | axi.asize[1:0] | axi.awsize[1:0] | axi.addr[15:0] |
    // ----------------------------------------------------------------------
    in_fifo_wr_data.addr  = axi_mosi_if_i.awaddr[15:0];
    in_fifo_wr_data.alen  = 'd0;
    in_fifo_wr_data.asize = axi_mosi_if_i.awsize[1:0];
    in_fifo_wr_data.id    = axi_mosi_if_i.awid;
    in_fifo_wr_data.error = error_wr_txn;
    write_wr  = vld_axi_txn_wr || error_wr_txn;
    read_wr   = ~fifo_wr_req_empty   &&
                axi_mosi_if_i.wvalid &&
                axi_mosi_if_i.wlast  &&
                pkt_out_resp_i.ready;
  end

  // **************************
  // Outstanding WR TXN buffers
  // **************************
  fifo#(
    .SLOTS(`AXI_MAX_OUTSTD_WR),
    .WIDTH(AxiOtFifoWidth)
  ) u_fifo_axi_ot_wr (
    .clk      (clk_axi),
    .arst     (arst_axi),
    .write_i  (write_wr),
    .read_i   (read_wr),
    .data_i   (in_fifo_wr_data),
    .data_o   (out_fifo_wr_data),
    .full_o   (fifo_wr_req_full),
    .empty_o  (fifo_wr_req_empty),
    .error_o  (),
    .ocup_o   ()
  );

  // **************************
  //
  // Read AXI
  //
  // **************************
  always_comb begin : ctrl_fifo_ot_read
    // Address channel fifo frame
    // ----------------------------------------------------
    // | axi.awsize[1:0] | axi.alen[7:0] | axi.addr[15:0] |
    // ----------------------------------------------------
    in_fifo_rd_data.addr  = axi_mosi_if_i.araddr[15:0];
    in_fifo_rd_data.alen  = axi_mosi_if_i.arlen;
    in_fifo_rd_data.asize = axi_mosi_if_i.arsize[1:0];
    in_fifo_rd_data.id    = axi_mosi_if_i.arid;
    in_fifo_rd_data.error = error_rd_txn;
    write_rd  = vld_axi_txn_rd || error_rd_txn;
    read_rd   = ~fifo_rd_req_empty &&
                read_txn_done      &&
                axi_miso_if_o.rlast;
  end

  always_ff @ (posedge clk_axi or posedge arst_axi) begin
    if (arst_axi) begin
      beat_count_ff <= '0;
      txn_rd_ff <= '0;
    end
    else begin
      beat_count_ff <= next_beat_count;
      txn_rd_ff <= next_txn_rd;
    end
  end

  // **************************
  // Outstanding RD TXN buffers
  // **************************
  // In the case of a READ, master will
  // read from one of the buffers of a virtual
  // channel, this means we need to store only
  // which virtual ch he wants to read and how many
  // bytes of the txn
  fifo#(
    .SLOTS(`AXI_MAX_OUTSTD_RD),
    .WIDTH(AxiOtFifoWidth)
  ) u_fifo_axi_ot_rd (
    .clk      (clk_axi),
    .arst     (arst_axi),
    .write_i  (write_rd),
    .read_i   (read_rd),
    .data_i   (in_fifo_rd_data),
    .data_o   (out_fifo_rd_data),
    .full_o   (fifo_rd_req_full),
    .error_o  (),
    .empty_o  (fifo_rd_req_empty),
    .ocup_o   ()
  );

  always_comb begin : ctrl_rx_buffers
    write_rd_arr  = '0;
    read_rd_arr   = '0;
    pkt_in_resp_o = s_pkt_in_resp_t'('0);
    data_rd_sel   = '0;
    data_rvalid   = '0;
    pkt_in_resp_o.ready = ~full_rd_arr[pkt_in_req_i.rq_vc];

    for (int i=0;i<NumVirtChn;i++) begin
      write_rd_arr[i] = (pkt_in_req_i.rq_vc == i[VcWidth-1:0]) &&
                        (pkt_in_req_i.valid)                    &&
                        ~full_rd_arr[i];
    end

    for (int i=0;i<NumVirtChn;i++) begin
      /* verilator lint_off WIDTH */
      if (txn_rd_ff && (i == decode_req_rd.virt_chn_id) &&
          (decode_req_rd.region == NOC_RD_FIFOS) && ~empty_rd_arr[i]) begin
      /* verilator lint_on WIDTH */
        read_rd_arr[i] = axi_mosi_if_i.rready;
        data_rd_sel = data_rd_buff[i];
        data_rvalid = 1'b1;
        break;
      end
    end
  end

  // **************************
  // [BUFFERs] Read buff of packets
  // **************************
  // Here are the instances of all buffers
  // that'll store the packets temporarily
  for (genvar buff_idx=0; buff_idx<NumVirtChn; buff_idx++) begin : gen_rd_vc_buffer
    fifo#(
      .SLOTS(`RD_AXI_BFF(buff_idx)),
      .WIDTH(FlitWidth-FlitTpWidth)
    ) u_vc_buffer (
      .clk      (clk_axi),
      .arst     (arst_axi),
      .write_i  (write_rd_arr[buff_idx]),
      .read_i   (read_rd_arr[buff_idx]),
      .data_i   (pkt_in_req_i.flit_data_width),
      .data_o   (data_rd_buff[buff_idx]),
      .full_o   (full_rd_arr[buff_idx]),
      .error_o  (),
      .empty_o  (empty_rd_arr[buff_idx]),
      /* verilator lint_off WIDTH */
      .ocup_o   (fifo_ocup_rd_arr[buff_idx])
      /* verilator lint_on WIDTH */
    );
  end

  always_comb begin : wireup_pkt_size
    for (int i=0;i<NumVirtChn;i++)
      pkt_sz_rd_buff[i] = data_rd_buff[i][(PktPosWidth-1):(PktPosWidth-PktWidth)];
  end

  // **************************
  // [CSRs] NoC CSRs
  // **************************
  axi_csr#(
    .ROUTER_X_ID        (ROUTER_X_ID),
    .ROUTER_Y_ID        (ROUTER_Y_ID),
    .CDC_REQUIRED       (CDC_REQUIRED)
  ) u_axi_csr (
    .clk_axi            (clk_axi),
    .arst_axi           (arst_axi),
    .csr_req_i          (csr_req),
    .csr_resp_o         (csr_resp),
    // Additional inputs
    .empty_rd_bff_i     (empty_rd_arr),
    .full_rd_bff_i      (full_rd_arr),
    .fifo_ocup_rd_bff_i (fifo_ocup_rd_arr),
    .pkt_size_vc_i      (pkt_sz_rd_buff),
    .full_wr_fifo_i     (full_wr_fifo_i),
    // Additional outputs
    .irqs_out_o         (irqs_o)
  );
endmodule
