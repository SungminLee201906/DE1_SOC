module datapath(clk, write, vsel, loada, loadb, asel, bsel, 
                   loadc, loads, readnum, writenum, shift, ALUop,datapath_out,mdata,sximm8,pc,sximm5,N,V,Z);


output [15:0] datapath_out;
input clk;
input write;
input loada,loadb,asel,bsel,loadc,loads;
input [1:0] vsel;
input [2:0] readnum;
input [2:0] writenum;
input [1:0] ALUop;
input [1:0] shift;

//lab 6 additions:
input [15:0] mdata;
input [15:0] sximm8;
input [15:0] sximm5;	
output reg N;
output reg V;
output reg Z;
input [8:0] pc;

wire[15:0] sout;// output of shifter
reg[15:0]data_in;
wire[15:0]data_out;

wire [15:0] out; // output after ALU operation performed
reg [2:0] status; //output status value
reg [15:0]a_out; //output value stored temporarily in register A
reg [15:0]b_out; //output value stored temporarily in register B
reg [15:0]c_out; //output value stored temporarily in register C


//signals to be used in datapath module 

wire [15:0] val_a;
wire [15:0] val_b;


//instantiate modules 
regfile REGFILE(data_in,writenum,write,readnum,clk,data_out);

//for vsel
always_comb begin
	case(vsel)
		2'b00 : data_in=c_out;
		2'b01 : data_in=sximm8;
		2'b10 : data_in={8'b0,pc};
		2'b11 : data_in=mdata;
	endcase
end

always_ff @(posedge clk) begin // at rising egde of clock pass data to a or b checking if load is 1
	if (loada) begin
		a_out <= data_out;
	end 
	if (loadb) begin
		b_out <= data_out;
	end
end

assign val_a=(asel)? 16'b0000000000000000 : a_out ; //mux part 6

shifter shifter(b_out,shift,sout); // shift b_out by using shifter

assign val_b=(bsel)? sximm5 : sout ; //mux part 7

ALU ALU(val_a,val_b,ALUop,out,status); //perform arithmetic operations on the two values




always_ff @(posedge clk) begin
	if(loadc)begin
		c_out<=out;
	end
end

always_ff @(posedge clk) begin
	if(loads) begin
		
 		Z<=status[2];
 		N<=status[1];
		V<=status[0];
	
	end
end

assign datapath_out=c_out;




endmodule