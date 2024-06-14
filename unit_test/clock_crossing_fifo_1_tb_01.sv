// Testbench for clock_crossing_fifo_1
// Testbench variant: 01
`timescale 1 ns/1 ns  // time-unit = 1 ns, precision = 10 ps

module clock_crossing_fifo_1_tb_01;

//----------------------------------------------------------------------------------------------------------------------
//                                                   Boiler Plate
//----------------------------------------------------------------------------------------------------------------------
reg tx_clk;
reg rx_clk;
logic tx_aresetn;
logic rx_aresetn;
int points_possible;
int points_earned;
real percent_correct;
int MIN_PTS_POSSIBLE_FOR_PERCENT_SCORE = 10;
int test_stage;
axi tx_in();
axi rx_out();

//----------------------------------------------------------------------------------------------------------------------
//                                                    Drive Clock
//----------------------------------------------------------------------------------------------------------------------
initial begin 
    tx_clk = 1'b1;
    tx_aresetn = 1'b0;
    for (int i = 0; i < 20; i++) begin 
        #6 tx_clk = ~tx_clk;
    end
    tx_aresetn = 1'b1;
    forever begin 
        #6 tx_clk = ~tx_clk;
    end
end

initial begin 
    rx_clk = 1'b1;
    rx_aresetn = 1'b0;
    for (int jj = 0; jj < 20; jj++) begin 
        #5 rx_clk = ~rx_clk;
    end
    rx_aresetn = 1'b1;
    forever begin 
        #5 rx_clk = ~rx_clk;
    end
end

//----------------------------------------------------------------------------------------------------------------------
//                                             Calculate Percent Correct
//----------------------------------------------------------------------------------------------------------------------
always @(posedge rx_clk) begin 
    if (points_possible > MIN_PTS_POSSIBLE_FOR_PERCENT_SCORE) begin 
        percent_correct = 100.0 * real'(points_earned)/real'(points_possible);
    end 
end

clock_crossing_fifo  UUT (
    .tx_in(tx_in),
    .rx_out(rx_out)
    );

assign tx_in.aclk = tx_clk;
assign tx_in.aresetn = tx_aresetn;
assign rx_out.aclk = rx_clk;
assign rx_out.aresetn = rx_aresetn;

//----------------------------------------------------------------------------------------------------------------------
//                                                   Stim Process
//----------------------------------------------------------------------------------------------------------------------
initial begin 
    test_stage = 0;
    tx_in.tdata = 32'b0;
    tx_in.tlast = 1'b0;
    tx_in.tvalid = 1'b0;
    tx_in.tkeep = 4'b0;
    tx_in.tstrb = 4'b0;
    tx_in.tuser = 1'b0; // TODO: Double check what width should be
    tx_in.tid = 8'b0;
    tx_in.tdest = 8'b0;    
    #120 test_stage += 1;
    #240;
    // From timing diagram, tvalid is asserted 1 clk before data flows.
    #12 tx_in.tvalid = 1'b1;
    #12 tx_in.tdata = 32'h42;
    #12 tx_in.tdata = 32'h43;
    #12 tx_in.tdata = 32'h44;
    #12 tx_in.tdata = 32'h45;
    #12 tx_in.tdata = 32'hDEADBEEF;
    #12 tx_in.tdata = 32'h0;
        tx_in.tvalid = 1'b0;
    #1200;
    #120 $stop;
end

always @(posedge rx_out.aclk, negedge rx_out.aresetn) begin 
    if (rx_out.aresetn == 1'b0) begin 
        rx_out.tready <= 1'b1;
    end else begin 
    
    end
end


endmodule
