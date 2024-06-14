//----------------------------------------------------------------------------------------------------------------------
//                                          Net Write Tracker - Write Side
//----------------------------------------------------------------------------------------------------------------------
module net_write_tracker_read_side (
    aclk,
    aresetn,
    total_reads,
    total_writes,
    net_writes
    );

//----------------------------------------------------------------------------------------------------------------------
//                                                    Parameters
//----------------------------------------------------------------------------------------------------------------------
parameter DWIDTH = 64;

//----------------------------------------------------------------------------------------------------------------------
//                                                       Ports
//----------------------------------------------------------------------------------------------------------------------
input aclk;
input aresetn;
input signed [DWIDTH-1:0] total_reads;
input signed [DWIDTH-1:0] total_writes;
output logic signed [DWIDTH-1:0] net_writes;

//----------------------------------------------------------------------------------------------------------------------
//                                                      Signals
//----------------------------------------------------------------------------------------------------------------------
// Note: It is conceivable that if clock frequencies are far apart, say, more than 1 octave, 
// a longer delay chain might be needed in order to detect metastability. I chose not to handle that
// contingency for the time being, but if problems are encountered, that is one avenue that might 
// be explored. 
logic [DWIDTH-1:0] delay_chain [3];

always @(posedge aclk, negedge aresetn) begin 
    if (aresetn == 1'b0) begin 
        delay_chain[2] <= 0;
        delay_chain[1] <= 0;
        delay_chain[0] <= 0;
    end else begin 
        delay_chain[2] <= delay_chain[1];
        delay_chain[1] <= delay_chain[0];
        delay_chain[0] <= total_writes;
    end
end

always @(posedge aclk, negedge aresetn) begin 
    if (aresetn == 1'b0) begin 
        net_writes <= 0;
    end else if ((delay_chain[0] == delay_chain[1]) && (delay_chain[1] == delay_chain[2])) begin 
        net_writes <= delay_chain[0] - total_reads;
    end
end

endmodule
