// List of signals came from here:
// IHI0051B_amba_axi_stream_protocol_spec.pdf
// page 2-16
interface axi #(parameter DWIDTH=32, TKEEPWIDTH=4, TSTRBWIDTH=4, TIDWIDTH=8, TDESTWIDTH=8);
logic aclk;
logic aresetn;
logic [DWIDTH-1:0] tdata;
logic tlast;
logic tready;
logic tvalid;
logic [TKEEPWIDTH-1:0] tkeep;
logic [TSTRBWIDTH-1:0] tstrb;
logic tuser;
logic [TIDWIDTH-1:0] tid;
logic [TDESTWIDTH-1:0] tdest;

modport TRANSMIT (
    input aclk,
    input aresetn,
    output tdata,
    output tlast,
    input tready,
    output tvalid,
    output tkeep,
    output tstrb,
    output tuser,
    output tid,
    output tdest
    );

modport RECEIVE (
    input aclk,
    input aresetn,
    input tdata,
    input tlast,
    output tready,
    input tvalid,
    input tkeep,
    input tstrb,
    input tuser,
    input tid,
    input tdest
    );

endinterface
