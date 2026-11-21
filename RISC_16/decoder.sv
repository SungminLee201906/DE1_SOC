module decoder(in, ALUop, sximm5, sximm8, shift, readnum, writenum, nsel, opcode, op);

//this module is simply for decoding the arm instruction


input [2:0] nsel;
input [15:0] in;

output  [1:0] ALUop;
output reg [15:0] sximm5;
output reg [15:0] sximm8;
output [1:0] shift;
output reg[2:0] readnum;
output reg[2:0] writenum;
output [2:0] opcode;
output [1:0] op;

wire [4:0]imm5;
wire [7:0]imm8;
wire [2:0] Rn;
wire [2:0] Rd;
wire [2:0] Rm;


//decode ALUop

assign ALUop=in[12:11];



//decode opcode

assign opcode=in[15:13];

//decode operand
assign op=in [12:11];

//decode Rn, Rd, Rm
assign  Rn=in [10:8];

assign  Rd=in [7:5];

assign Rm = in [2:0];

//decode shift
assign shift = in [4:3];

//for nsel
always_comb begin
	case(nsel) 
		3'b001 : begin
				readnum=Rn;
				writenum=Rn;
			end
		3'b010: begin
				readnum=Rd;
				writenum=Rd;
			end
		default: begin
				readnum=Rm;
				writenum=Rm;
			 end
	endcase
end

//sign extend immediate 8 bits

assign imm8=in[7:0];
always_comb begin
	if(imm8[7]==1'b1) 
		sximm8={8'b11111111,imm8};
	else 	
		sximm8={8'b00000000,imm8};
end

//sign extend for immediate 5 bits

assign imm5=in[4:0];
always_comb  begin
	if(imm5 [4]==1'b1)
		sximm5={11'b11111111111,imm5};
	else
		sximm5={11'b0,imm5};
end

endmodule







