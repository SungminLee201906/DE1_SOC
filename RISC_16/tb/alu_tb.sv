module ALU_tb;

reg [15:0] sim_A;
reg [15:0] sim_B;
reg [1:0] sim_OP;

wire [15:0] sim_OUT;
wire sim_Z;
reg err;

ALU DUT(sim_A,sim_B,sim_OP,sim_OUT,sim_Z);

/*note foor this testbench:- 
clock is not needed
we will input values for A and B and perform all 4 operations to check if output is as expected.
we will also test to see the validity of z output 
*/

initial begin
err=1'b0; //initialize error to 0
sim_A=16'b0000000000100010; //enter value 34 for A
sim_B=16'b0000000000110100; //enter value 52 for B
sim_OP=2'b00;
//check if addition works

#5;




$display("checking addition of value A and B");
if(sim_OUT!=16'b0000000001010110) begin  //output should be 52+34=86
	$display("**ERROR output is %b, expected is %b", sim_OUT,16'b0000000001010110);
	err=1'b1;
end
//check for z output
$display("checking for the output of Z");
if(sim_Z!=1'b0)begin
	$display("**ERROR output is %b, expected is %b", sim_Z, 1'b0);
	err=1'b1;
end


//check if subtraction works

#5;
sim_OP=2'b01;
#5;

$display("checking subtraction of value A and B");
if(sim_OUT!=16'b1111111111101110) begin //output should be 34-52=-18. Note that -18 will be in twos complement form.
	$display("**ERROR output is %b, expected is %b",sim_OUT,16'b1111111111101110);
	err=1'b1;
end
//check for z output
$display("checking for the output of Z");
if(sim_Z!=1'b0)begin
	$display("**ERROR output is %b, expected is %b", sim_Z, 1'b0);
	err=1'b1;
end

//check if AND works

#5;
sim_OP=2'b10;
#5;

$display("checking multiplication  of value A and B");
if(sim_OUT!=16'b0000000000100000) begin //output should be 52-34=18
	$display("**ERROR output is %b, expected is %b",sim_OUT,16'b0000000000100000);
	err=1'b1;
end
//check for z output
$display("checking for the output of Z");
if(sim_Z!=1'b0)begin
	$display("**ERROR output is %b, expected is %b", sim_Z, 1'b0);
	err=1'b1;
end


//check if ~B works 
#5;
sim_OP=2'b11;
#5;

$display("checking inverse of value A and B");
if(sim_OUT!=16'b1111111111001011) begin //output should be 52-34=18
	$display("**ERROR output is %b, expected is %b",sim_OUT,16'b1111111111001011);
	err=1'b1;
end
//check for z output
$display("checking for the output of Z");
if(sim_Z!=1'b0)begin
	$display("**ERROR output is %b, expected is %b", sim_Z, 1'b0);
	err=1'b1;
end


//check if z output is zero when out is zero

#5;
sim_A=16'b0;
sim_B=16'b0;
sim_OP=2'b00;
#5;

//check for z output
$display("checking for the output of Z");
if(sim_Z!=1'b1)begin
	$display("**ERROR output is %b, expected is %b", sim_Z, 1'b1);
	err=1'b1;
end



if(~err)begin
	$display("All tests passed");
	$stop;
end

end

endmodule

