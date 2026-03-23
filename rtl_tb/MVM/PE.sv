/*
* Configurable PE for a matrix-vector-multiplication, weight stationary
* systolic array grid
**/
module PE #(parameter type dtype = logic[31:0], parameter INTEGER = 8, parameter FRACTIONAL = 24)(

	input logic clk,
	input logic rst,

	input logic mode,
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
dtype inB;

fixed_mul #(.dtype(dtype), .INTEGER(INTEGER), .FRACTIONAL(FRACTIONAL)) fm(.inA(a), .inB(inB), .out(mul_res));

always_ff @(posedge clk) begin
		if(rst) begin
			c <= 0;
			d <= 0;
			w <= 0;
		end else if(mode) begin 
			if(ld_w) begin 
				w <= b;
				d <= b;
			end else begin
				vld_out <= vld_in;
				c <= a;
				d <= mul_res + b;
			end 
		end else begin
			vld_out <= vld_in;
			d <=  mul_res + d;
			c <= a;
		end
end	

assign inB = mode ? w : b;

endmodule 



