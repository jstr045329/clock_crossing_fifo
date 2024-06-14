module srff (
    aclk,
    aresetn,
    s,
    r,
    q
    );

input aclk;
input aresetn;
input s;
input r;
output logic q;

always @(posedge aclk, negedge aresetn) begin 
    if (aresetn == 1'b0) begin 
        q <= 1'b1;
    end else if (r) begin 
        // It is important that r has precedence over s in this application.
        // The reason is that the receive side needs to be able to mark a 
        // memory element as used even if the tx side has a lower clock frequency
        // and the set pin has not been de-asserted yet. 
        q <= 1'b0;
    end else if (s) begin 
        q <= 1'b1;
    end
end

endmodule
