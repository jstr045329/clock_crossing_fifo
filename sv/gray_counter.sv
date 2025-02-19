//----------------------------------------------------------------------------------------------------------------------
//                                                 Gray Code Counter
//----------------------------------------------------------------------------------------------------------------------
module gray_counter #(parameter DWIDTH=8) (
    aclk,
    aresetn,
    enable,
    gray_code, 
    next_gray_code
    );

//----------------------------------------------------------------------------------------------------------------------
//                                                       Ports
//----------------------------------------------------------------------------------------------------------------------
input aclk;
input aresetn;
input enable;
output logic [DWIDTH-1:0] gray_code;
output logic [DWIDTH-1:0] next_gray_code;

//----------------------------------------------------------------------------------------------------------------------
//                                                      Signals
//----------------------------------------------------------------------------------------------------------------------
logic [DWIDTH-1:0] count;
logic [DWIDTH-1:0] next_count;

//----------------------------------------------------------------------------------------------------------------------
//                                                      Counter
//----------------------------------------------------------------------------------------------------------------------
always @(posedge aclk, negedge aresetn) begin 
    if (aresetn == 1'b0) begin 
        count <= {DWIDTH{1'b0}};
    end else begin 
        if (enable == 1'b1) begin 
            count <= count + 1;
        end
    end
end

always @(count) begin 
    next_count <= count + 1;
end

//----------------------------------------------------------------------------------------------------------------------
//                                               Convert to Gray Code
//----------------------------------------------------------------------------------------------------------------------
always @(count) begin 
    gray_code = count ^ {1'b0, count[DWIDTH-1:1]};
end

always @(next_count) begin 
    next_gray_code = next_count ^ {1'b0, next_count[DWIDTH-1:1]};
end

endmodule
