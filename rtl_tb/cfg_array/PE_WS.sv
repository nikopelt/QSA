/*
* Weight Stationary PEs for Systolic array grid
* */

module PE_WS #(parameter type dtype = logic[31:0], parameter INTEGER = 8, parameter FRACTIONAL = 24)(

	input logic clk,
	input logic rst,
	
	input logic ld_w,
	input logic vld_in,

	input dtype a,
	input dtype b,
	
	output logic vld_out,
	output dtype c,
	output dtype d
);


dtype w; 
dtype mul_res;

fixed_mul #(.dtype(dtype), .INTEGER(INTEGER), .FRACTIONAL(FRACTIONAL)) fm(.inA(a), .inB(w), .out(mul_res));

always_ff @(posedge clk) begin
		if(rst) begin
			c <= 0;
			d <= 0;
			w <= 0;
		end else begin 
				vld_out <= vld_in;
				c <= a;
		 if(ld_w) begin
				w <= b;
				d <= b;
			end else begin
				d <= mul_res + b;
			end 
		end 
end	


endmodule 



