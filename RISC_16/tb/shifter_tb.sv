module shifter_tb;
reg [15:0]sim_IN;
reg [1:0]sim_SHIFT;
reg err;
wire[15:0]sim_SOUT;

shifter DUT(sim_IN,sim_SHIFT,sim_SOUT);

initial begin

//for an input value in we will check if the expected out is shown according to the operation entered.

err=1'b0; //set error to zero

//check for shift operation when shift=00
sim_IN=16'b1111000011001111;
sim_SHIFT=2'b00;
#5;

$display("checking for shift=00");
if(sim_SOUT!=16'b1111000011001111) begin
	$display("**ERROR output is %b, expected is %b",sim_SOUT,16'b1111000011001111);
	err=1'b1;
end


//check for shift operation when shift=01
#5;
sim_SHIFT=2'b01;
#5;

$display("checking for shift=01");
if(sim_SOUT!=16'b1110000110011110) begin
	$display("**ERROR output is %b, expected is %b",sim_SOUT,16'b1110000110011110);
	err=1'b1;
end

//check for shift operation when shift=10
#5;
sim_SHIFT=2'b10;
#5;

$display("checking for shift=10");
if(sim_SOUT!=16'b0111100001100111) begin
	$display("**ERROR output is %b, expected is %b",sim_SOUT,16'b0111100001100111);
	err=1'b1;
end

//check for shift operation when shift=11
#5;
sim_SHIFT=2'b11;
#5;

$display("checking for shift=11");
if(sim_SOUT!=16'b1111100001100111) begin
	$display("**ERROR output is %b, expected is %b",sim_SOUT,16'b1111100001100111);
	err=1'b1;
end

if(~err)begin
	$display("PASSED");
	$stop;
end
end
endmodule


