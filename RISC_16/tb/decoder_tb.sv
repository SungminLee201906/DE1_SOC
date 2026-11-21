module decoder_tb();




//this module is simply for decoding the arm instruction


reg [2:0] nsel;
reg [15:0] in;
reg err=0;

wire [1:0] ALUop;
wire [15:0] sximm5;
wire [15:0] sximm8;
wire [1:0] shift;
wire [2:0] readnum;
wire [2:0] writenum;
wire [2:0] opcode;
wire [1:0] op;


decoder DUT(in, ALUop, sximm5, sximm8, shift, readnum, writenum, nsel, opcode, op,);

initial begin 

nsel=3'b100;
in=16'b1101010100101010;
#20;
end


endmodule