// This module contains an AXI stream slave receiver for the Tx side, 
// and an AXI stream master transmitter for the Rx side. 
module clock_crossing_fifo (
    axi.RECEIVE tx_in,
    axi.TRANSMIT rx_out
    );

parameter DWIDTH=32;
parameter ADDRWIDTH=8;
parameter RX_CLOCK_IS_FASTER = 1;
localparam FIFODEPTH = 2**ADDRWIDTH;
localparam NET_WRITE_LIMIT = int'(0.9 * FIFODEPTH - 10);

//----------------------------------------------------------------------------------------------------------------------
//                                                    RAM Signals
//----------------------------------------------------------------------------------------------------------------------
logic we;
logic [DWIDTH-1:0] ram_din;
logic [ADDRWIDTH-1:0] wr_addr;
logic [ADDRWIDTH-1:0] prev_wr_addr_tx_side;
logic [ADDRWIDTH-1:0] prev_wr_addr_rx_side;
logic [ADDRWIDTH-1:0] prev_prev_wr_addr_rx_side;
logic [ADDRWIDTH-1:0] rd_addr;
logic [DWIDTH-1:0] memory [FIFODEPTH];
logic re;
logic signed [63:0] total_writes; // Synchronous with tx_in clock
logic signed [63:0] total_reads; // Synchronous with rx_out clock
logic signed [63:0] net_writes_tx_side;
logic signed [63:0] net_writes_rx_side;

// Signals for a bank of SRFF's:
// Note that the paths i_just_placed_a_thing[x] -> fifo_element_unused[x] should be constrained for 
// the faster of the two clock frequencies. Likewise for 
// i_just_used_a_thing[x] -> fifo_element_unused[x]
logic [FIFODEPTH-1:0] i_just_placed_a_thing;
logic [FIFODEPTH-1:0] i_just_used_a_thing;
logic [FIFODEPTH-1:0] fifo_element_unused;
logic srff_clock;
logic srff_aresetn;
genvar kk;

//----------------------------------------------------------------------------------------------------------------------
//                                      Drive RAM Write Port Using AXI Receiver
//----------------------------------------------------------------------------------------------------------------------
always @(posedge tx_in.aclk, negedge tx_in.aresetn) begin 
    if (tx_in.aresetn == 1'b0) begin 
        we <= 1'b0;
    end else begin 
        we <= (tx_in.tvalid && tx_in.tready && (net_writes_tx_side < NET_WRITE_LIMIT)) ? 1'b1 : 1'b0;
    end
end

assign net_writes_tx_side = 0; // TODO: Replace with formula

always @(posedge tx_in.aclk, negedge tx_in.aresetn) begin 
    if (tx_in.aresetn == 1'b0) begin 
        prev_wr_addr_tx_side <= 0;
    end else begin 
        prev_wr_addr_tx_side <= wr_addr;
    end
end

//----------------------------------------------------------------------------------------------------------------------
//                                Decide Which Clock and Reset We're Using for SRFF's
//----------------------------------------------------------------------------------------------------------------------
assign srff_clock = (RX_CLOCK_IS_FASTER == 1) ? rx_out.aclk : tx_in.aclk;
assign srff_aresetn = (RX_CLOCK_IS_FASTER == 1) ? rx_out.aresetn : tx_in.aresetn;

//----------------------------------------------------------------------------------------------------------------------
//                                             Generate a Bank of SRFF's
//
// These allow the receive clock domain to track whether it has used a particular memory element already.
//
//----------------------------------------------------------------------------------------------------------------------
generate
    for (kk = 0; kk < FIFODEPTH; kk++) begin 
        // Here we exploit the fact that all addresses are used in a predetermined order 
        // to eliminate a potentially large demux. 
        always @(posedge srff_clock, negedge srff_aresetn) begin 
            if (srff_aresetn == 1'b0) begin 
                i_just_placed_a_thing[kk] <= 1'b0;
            end else begin 
                i_just_placed_a_thing[kk] <= ((wr_addr == 0) && (prev_wr_addr_tx_side != 0)) ? 1'b1 : 1'b0;
            end
        end

        srff ELEMENET_UNUSED (
            .aclk(srff_clock),
            .aresetn(tx_in.aresetn),
            .s(i_just_placed_a_thing[kk]),
            .r(i_just_used_a_thing[kk]),
            .q(fifo_element_unused[kk])
            );
    end
endgenerate

gray_counter #( 
    .DWIDTH(ADDRWIDTH)
    ) GRAY_COUNTER_WRITE_SIDE (
    .aclk(tx_in.aclk),
    .aresetn(tx_in.aresetn),
    .enable(we),
    .gray_code(wr_addr),
    .next_gray_code()
    );

// Drive the RAM itself:
always @(posedge tx_in.aclk, negedge tx_in.aresetn) begin 
    if (we) begin 
        memory[wr_addr] <= tx_in.tdata;
    end
end

always @(posedge tx_in.aclk, negedge tx_in.aresetn) begin 
    if (tx_in.aresetn == 1'b0) begin 
        tx_in.tready <= 1'b0;
    end else begin 
        tx_in.tready <= (net_writes_tx_side < NET_WRITE_LIMIT) ? 1'b1 : 1'b0;
    end
end

//----------------------------------------------------------------------------------------------------------------------
//                                     Move Write Address Across Clock Boundary
//
// Gray code can move safely across clock boundary because only 1 bit changes at a time. 
//
//----------------------------------------------------------------------------------------------------------------------
always @(posedge rx_out.aclk, negedge rx_out.aresetn) begin 
    if (rx_out.aresetn == 1'b0) begin 
        prev_wr_addr_rx_side <= {ADDRWIDTH{1'b0}};
        prev_prev_wr_addr_rx_side <= {ADDRWIDTH{1'b0}};
    end else begin 
        prev_wr_addr_rx_side <= wr_addr;
        prev_prev_wr_addr_rx_side <= prev_wr_addr_rx_side;
    end
end

//----------------------------------------------------------------------------------------------------------------------
//                                           Detect When Something Changed
//----------------------------------------------------------------------------------------------------------------------
always @(posedge rx_out.aclk, negedge rx_out.aresetn) begin 
    if (rx_out.aresetn == 1'b0) begin 
        re <= 1'b0;
        total_reads <= 0;
    end else begin 
        re <= ((rx_out.tready) && 
               (prev_wr_addr_rx_side != prev_prev_wr_addr_rx_side) &&
               (rd_addr != prev_wr_addr_rx_side) &&
               (fifo_element_unused[prev_prev_wr_addr_rx_side])) ? 1'b1 : 1'b0;
    end
end

gray_counter #( 
    .DWIDTH(ADDRWIDTH)
    ) GRAY_COUNTER_READ_SIDE (
    .aclk(rx_out.aclk),
    .aresetn(rx_out.aresetn),
    .enable(re),
    .gray_code(rd_addr),
    .next_gray_code()
    );

generate 
    for (kk = 0; kk < FIFODEPTH; kk++) begin 
        always @(posedge rx_out.aclk, negedge rx_out.aresetn) begin 
            if (rx_out.aresetn == 1'b0) begin 
                i_just_used_a_thing[kk] <= 1'b0;
            end else begin 
                i_just_used_a_thing[kk] <= ((prev_prev_wr_addr_rx_side == kk) && (re)) ? 1'b1 : 1'b0;
            end
        end
    end 
endgenerate

always @(posedge rx_out.aclk, negedge rx_out.aresetn) begin 
    if (rx_out.aresetn == 1'b0) begin 
        rx_out.tdata <= {DWIDTH{1'b0}};
        rx_out.tkeep <= {rx_out.TKEEPWIDTH{1'b0}};
        rx_out.tlast <= 1'b0;
        rx_out.tvalid <= {4{1'b0}}; // TODO: Make this variable size
        rx_out.tkeep <= {4{1'b0}};
        rx_out.tstrb <= {4{1'b0}};
        rx_out.tuser <= {4{1'b0}};
        rx_out.tid <= {8{1'b0}};
        rx_out.tdest <= {8{1'b0}};
    end else begin 
        rx_out.tdata <= memory[rd_addr];
    end
end

endmodule
