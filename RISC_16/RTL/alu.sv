module ALU(Ain,Bin,ALUop,out,status);
input [15:0] Ain, Bin;
input [1:0] ALUop;
output reg[15:0] out;
output reg [2:0] status; //lab6 addition extending the status register to 3 bits


// lab 6 additions internal signals
reg [15:0] sum; 
reg subtract;
reg overflow;


//status register update using combinational block
//status[3] : zero
//status[2] : negative
//status[1] : overflow
always_comb begin
//status register update for zero
	if(out==16'b0) 
		status[2]=1'b1;
	else 
		status[2]=1'b0;
//status register update for for negative value
	if(out[15]==1'b1) 
		status[1]=1'b1;
	else 		
		status[1]=1'b0;
//status register update for overflow
	
	status[0]=overflow;
end
	




// addition and subtraction with overlow detect from Dally 10.2
AddSub #(16) AddSub(Ain,Bin,subtract,sum,overflow);


//combinational block for ALU operation

always_comb begin
	case(ALUop) 	
		2'b00: out=sum;
		2'b01: out=sum;
		2'b10: out= Ain & Bin;
		default: out=~Bin;
	endcase
end


//flag for subtraction
always_comb begin
	if (ALUop==2'b01) begin
		subtract=1;
	end else begin
		subtract=0;
	end
end


endmodule


//overflow detect for addition and subtraction from Dally 10.2
module AddSub(a,b,sub,s,ovf);
parameter n=8;
input [n-1:0] a,b;
input sub; // subtract if sub=1, otherwise add
output[n-1:0] s;
output ovf; //1 if overflow
wire c1,c2 ; //carry out of last two bits
wire ovf = c1^c2; //overflow if signs dont match

// add non sign bits
Adder1 #(n-1) ai(a[n-2:0],b[n-2:0]^{n-1{sub}},sub,c1,s[n-2:0]);
// add sign bits
Adder1 #(1) as(a[n-1],b[n-1]^sub,c1,c2,s[n-1]);

endmodule

//half adder module from Dally 10.2
module Adder1(a,b,cin,cout,s);
  parameter n=8;
  input [n-1:0] a,b;
  input cin;
  output [n-1:0] s;
  output cout;
  wire [n-1:0] s;
  wire cout;

  assign {cout,s}= a+b+cin;
endmodule

