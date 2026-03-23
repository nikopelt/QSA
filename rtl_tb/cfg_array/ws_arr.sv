/*
*  Weight Stationary systolic array grid for the integration to a configurable
*  systolic array grid
**/
module ws_arr #(parameter type dtype = logic[31:0], parameter BLOCK_SIZE = 4)(

	input logic clk,
	input logic rst,
	
	input logic ld_w,
	input logic vld_in[BLOCK_SIZE - 1:0],
	input dtype b[BLOCK_SIZE - 1:0], 
	input dtype a[BLOCK_SIZE - 2:0],

	output logic vld_output[BLOCK_SIZE - 1:0],
	output dtype y_h[BLOCK_SIZE - 2:0],
	output dtype y_out[BLOCK_SIZE - 1:0]
);


dtype c				[BLOCK_SIZE-2:0][BLOCK_SIZE-1:0];
dtype d				[BLOCK_SIZE-2:0][BLOCK_SIZE-1:0];
logic vld_out	[BLOCK_SIZE-2:0][BLOCK_SIZE-1:0];


genvar i;
genvar j;
generate
	for(i = 0; i < BLOCK_SIZE - 1; i++)
		for(j = 0; j < BLOCK_SIZE; j++) begin
			if(j == 0 && i == 0)
				PE_WS #(.dtype(dtype)) pe(.clk(clk), .rst(rst), .ld_w(ld_w), .vld_in(vld_in[j]), .a(a[i]), .b(b[j]), .vld_out(vld_out[i][j]),.c(c[i][j]), .d(d[i][j]));
			else if(i == 0 && j > 0)
				PE_WS #(.dtype(dtype)) pe(.clk(clk), .rst(rst), .ld_w(ld_w), .vld_in(vld_in[j]),.a(c[i][j - 1]), .b(b[j]), .vld_out(vld_out[i][j]), .c(c[i][j]), .d(d[i][j]));
			else if(j == 0 && i > 0)
				PE_WS #(.dtype(dtype)) pe(.clk(clk), .rst(rst), .ld_w(ld_w), .vld_in(vld_out[i-1][j]), .a(a[i]), .b(d[i - 1][j]), .vld_out(vld_out[i][j]) ,.c(c[i][j]), .d(d[i][j]));	
			else 
				PE_WS #(.dtype(dtype)) pe(.clk(clk), .rst(rst), .ld_w(ld_w), .vld_in(vld_out[i-1][j]), .a(c[i][j - 1]), .b(d[i - 1][j]), .vld_out(vld_out[i][j]),.c(c[i][j]), .d(d[i][j]));		
		end
endgenerate



genvar k;
generate
    for (k = 0; k < BLOCK_SIZE; k++) begin 
        assign y_out[k] = d[BLOCK_SIZE - 2][k];
				assign vld_output[k] = vld_out[BLOCK_SIZE-2][k];
		end

    for (k = 0; k < BLOCK_SIZE - 1; k++) begin 
				assign y_h[k] = c[k][BLOCK_SIZE - 1];
		end
endgenerate


endmodule
