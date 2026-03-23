/*
* Matrix-Vector-Multiplication systolic grid to perform both output and weight stationary systolic array operation for the integration to configurable systolic array grid
* */
module MVM #(parameter type dtype = logic[31:0], parameter BLOCK_SIZE = 4, parameter TOP = 1)(
	input logic clk,
	input logic rst,
	
	input logic mode,
	input logic quad_mode,
	input logic ld_w,
	input logic vld_in,
	input logic vld_ws_in[BLOCK_SIZE - 1:0],
	
	input dtype x,
	input dtype b[BLOCK_SIZE - 1:0],

	output logic vld_out[BLOCK_SIZE - 1:0],
	
	output dtype y_h,
	output dtype y[BLOCK_SIZE - 1:0]
);


dtype c[BLOCK_SIZE - 1:0];
dtype d[BLOCK_SIZE - 1:0];
logic vld_ws[BLOCK_SIZE - 1:0];

genvar i;
generate 
	if(TOP == 1) begin
		for(i = 0; i < BLOCK_SIZE; i++) begin
			if(i == 0) begin
				PE #(.dtype(dtype))	pe(.clk(clk), .rst(rst), .mode(mode), .ld_w(ld_w),	.vld_in(vld_in), .a(x), .b(b[i]), .vld_out(vld_out[i]),	.c(c[i]),	.d(d[i]));
			end else begin
				PE #(.dtype(dtype))	pe(.clk(clk), .rst(rst), .mode(mode), .ld_w(ld_w),	.vld_in(vld_out[i - 1]), .a(c[i - 1]), .b(b[i]), .vld_out(vld_out[i]),	.c(c[i]),	.d(d[i]));
			end
		end 
	end else begin
		for(i = 0; i < BLOCK_SIZE; i++) begin
			if(i == 0) begin
				PE #(.dtype(dtype))	pe(.clk(clk), .rst(rst), .mode(mode), .ld_w(ld_w),	.vld_in(vld_ws[i]), .a(x), .b(b[i]), .vld_out(vld_out[i]),	.c(c[i]),	.d(d[i]));
			end else begin
				PE #(.dtype(dtype))	pe(.clk(clk), .rst(rst), .mode(mode), .ld_w(ld_w),	.vld_in(vld_ws[i]), .a(c[i - 1]), .b(b[i]), .vld_out(vld_out[i]),	.c(c[i]),	.d(d[i]));
			end
		end
	
	end
endgenerate

always_comb begin 
	for(int i = 1; i < BLOCK_SIZE; i++) begin
		vld_ws[i] = (mode & quad_mode) ? vld_ws_in[i] : vld_out[i - 1]; 
	end
		
	vld_ws[0] = (mode & quad_mode) ? vld_ws_in[0] : vld_in;
end



assign y = d;
assign y_h = c[BLOCK_SIZE - 1];

endmodule
