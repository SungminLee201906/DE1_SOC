module Synchronizer(

input logic clk,
input logic rst,
input logic in,
output logic out);



logic ff1; // The first flip to stabilize input signal

always_ff @(posedge clk or posedge rst) begin
	if (rst)
		ff1<=1'b0;
	else
		ff1<=in; 
end


always_ff @(posedge clk or posedge rst) begin
	if(rst)
		out <=1'b0;
	else
		out<=ff1;
end

endmodule