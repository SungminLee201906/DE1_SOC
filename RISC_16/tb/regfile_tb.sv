module regfile_tb;

reg [15:0]sim_data_in;
reg [2:0]sim_write_num,sim_read_num;
reg sim_write,sim_clk;
reg err;


wire [15:0]sim_data_out;

regfile DUT(sim_data_in,sim_write_num,sim_write,sim_read_num,sim_clk,sim_data_out);

initial begin 
	sim_clk=0; #5;
	forever begin
		sim_clk=1; #5;
		sim_clk=0; #5;
	end
end

initial begin

// checking to write in register
sim_data_in = 16'b0000000000101010;  //input number 42 as a 16 bit binary code
sim_write_num=3'b011; // write to register 3
err = 1'b0; // set error to zero
sim_write=1'b1; // Since we are writing to register write=1

#10; //wait until rising edge of clock

$display("checking if valued stored in register 3");
if(DUT.R3!=sim_data_in) begin
	$display("**ERROR value in R3 is %b, expected is %b", DUT.R3, sim_data_in );
	err=1'b1;
end




//check to read from register
sim_write_num=3'b010;  //write to register 2
sim_data_in = 16'b0000000001000101; // enter 69 as a decimal


#10;

sim_read_num=3'b010;
#10;
$display("checking if value is read from register2");
if(sim_data_out!=sim_data_in)begin
	$display("**ERROR value output is %b, expected is %b", sim_data_out, sim_data_in );
	err=1'b1;
end

//check if value will be written to register 5 in register when write is zero

sim_write=0; // change write to zero to check if write to register is valid or not when 0
sim_write_num=3'b101; //write to register 5
sim_data_in=16'b0000000000010100; //data in is 20
#10;

$display("checking if data entered will be written to register 5 when write is zero");
if(DUT.R5==sim_data_in) begin
	$display("**ERROR value in R5 is %b expected %b", sim_data_in, 16'bx);
	err=1'b1;
end

#10;







if(~err)begin
	$display("All Tests Passed");
	$stop;
end

end // end of initial block
endmodule




