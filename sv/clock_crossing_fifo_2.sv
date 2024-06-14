// This module contains an AXI stream slave receiver for the Tx side, 
// and an AXI stream master transmitter for the Rx side. 
module clock_crossing_fifo_2 #(parameter DWIDTH=32, ADDRWIDTH=8) (
    axi.RECEIVE tx_in,
    axi.TRANSMIT rx_out
    );

localparam FIFODEPTH = 2**ADDRWIDTH;
localparam NET_WRITE_LIMIT = int'(0.9 * FIFODEPTH - 10);
// TODO: Use DWIDTH to drive axi.DWIDTH

//----------------------------------------------------------------------------------------------------------------------
//                                                    RAM Signals
//----------------------------------------------------------------------------------------------------------------------
logic we;
logic [DWIDTH-1:0] ram_din;
logic [ADDRWIDTH-1:0] wr_addr;
logic [ADDRWIDTH-1:0] prev_wr_addr;
logic [ADDRWIDTH-1:0] prev_prev_wr_addr;
logic [ADDRWIDTH-1:0] rd_addr;
logic [DWIDTH-1:0] memory [FIFODEPTH];
logic [DWIDTH-1:0] ram_dout;
logic re;
logic signed [63:0] total_writes; // Synchronous with tx_in clock
logic signed [63:0] total_reads; // Synchronous with rx_out clock
logic signed [63:0] net_writes_tx_side;
logic signed [63:0] net_writes_rx_side;

function [DWIDTH-1:0] binary2gray(logic [DWIDTH-1:0] x)
    return {x[DWIDTH-1, x[DWIDTH-1:1] ^ x[DWIDTH-2:0]};
endfunction

function [DWIDTH-1:0] gray2binary(logic [DWIDTH-1:0] x)
    return {x[DWIDTH-1, x[DWIDTH-1:1] ^ x[DWIDTH-2:0]};
endfunction

//----------------------------------------------------------------------------------------------------------------------
//                                      Drive RAM Write Port Using AXI Receiver
//----------------------------------------------------------------------------------------------------------------------
always @(posedge tx_in.aclk, negedge tx_in.aresetn) begin 
    if (tx_in.aresetn == 1'b0) begin 
        we <= 1'b0;
        total_writes <= 0;
    end else begin 
        we <= (tx_in.tvalid && tx_in.tready && (net_writes_tx_side < NET_WRITE_LIMIT)) ? 1'b1 : 1'b0;
        if (we) begin 
            total_writes <= total_writes + 1;
        end
    end
end

net_write_tracker_write_side NET_WRITE_TRACKER_WRITE_SIDE_INST (
    .aclk(tx_in.aclk),
    .aresetn(tx_in.aresetn),
    .total_reads(total_reads),
    .total_writes(total_writes),
    .net_writes(net_writes_tx_side)
    );

gray_counter WRITE_SIDE_GRAY_COUNTER (
    .aclk(tx_in.aclk),
    .aresetn(tx_in.aresetn),
    .enable(we),
    .gray_code(wr_addr),
    .next_gray_code()
    );

always @(posedge tx_in.aclk, negedge tx_in.aresetn) begin 
    if (tx_in.tvalid && tx_in.tready) begin 
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
//----------------------------------------------------------------------------------------------------------------------

// TODO: Think about whether this is still necessary
always @(posedge rx_out.aclk, negedge rx_out.aresetn) begin 
    if (rx_out.aresetn == 1'b0) begin 
        prev_wr_addr <= {ADDRWIDTH{1'b0}};
        prev_prev_wr_addr <= {ADDRWIDTH{1'b0}};
    end else begin 
        prev_wr_addr <= wr_addr;
        prev_prev_wr_addr <= prev_wr_addr;
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
               (wr_addr != rd_addr) && 
               (net_writes_rx_side > 0)) ? 1'b1 : 1'b0;
        if (re) begin 
            total_reads <= total_reads + 1;
        end
    end
end

net_write_tracker_read_side NET_WRITE_TRACKER_READ_SIDE_INST (
    .aclk(rx_in.aclk),
    .aresetn(rx_in.aresetn),
    .total_reads(total_reads),
    .total_writes(total_writes),
    .net_writes(net_writes_rx_side)
    );

gray_counter READ_SIDE_GRAY_COUNTER (
    .aclk(rx_out.aclk),
    .aresetn(rx_out.aresetn),
    .enable(re),
    .gray_code(rd_addr),
    .next_gray_code() 
    );

always @(posedge rx_out.aclk, negedge rx_out.aresetn) begin 
    if (rx_out.aresetn == 1'b0) begin 
        rx_out.tdata <= {DWIDTH{1'b0}};
        rx_out.tkeep <= {axi.TKEEPWIDTH{1'b0}};
        rx_out.tlast <= 1'b0;
        rx_out.tvalid <= {4{1'b0}}; // TODO: Make this variable size
        rx_out.tkeep <= {4{1'b0}}; // TODO: Make this variable size
        rx_out.tstrb <= {4{1'b0}}; // TODO: Make this variable size
        rx_out.tuser <= {4{1'b0}}; // TODO: Make this variable size
        rx_out.tid <= {8{1'b0}}; // TODO: Make this variable size
        rx_out.tdest <= {8{1'b0}}; // TODO: Make this variable size
    end else begin 
        rx_out.tdata <= memory[rd_addr];
    end
end

endmodule
