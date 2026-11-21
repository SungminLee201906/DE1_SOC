module controller_tb();



reg clk, reset, s;

reg [2:0] opcode;
reg[1:0] op;


wire loada, loadb, loadc, write, asel, bsel, vsel, loads, w;
wire [2:0] nsel;

controller DUT(clk, reset, s, w, opcode, op, loada, loadb, loadc, nsel, write, asel, bsel, vsel, loads );

initial begin
	clk=0; #5
	forever begin
		clk=1; #5;
		clk=0; #5;
	end
end


initial begin

reset=0;
s=1;
opcode=3'b110;
op=2'b10;
#20

$stop;
end

endmodule