module QSA #(parameter type dtype = logic[31:0], parameter BLOCK_SIZE = 4, parameter ACC_SIZE = 3)(
	input logic clk,
	input logic rst,
	
	input logic vld_in			[1:0],
	input logic mode,
	input logic quad_mode,
	input logic ld_w,

	input dtype b				[3:0][BLOCK_SIZE - 1:0],
	input dtype qsa_in			[1:0][BLOCK_SIZE - 1:0],
	
  	output logic qsa_vld_out	[3:0][BLOCK_SIZE - 1:0],
  	output dtype acc_out		[1:0][BLOCK_SIZE - 1:0],
	output dtype qsa_out		[3:0][BLOCK_SIZE - 1:0]
);

logic vld_out		[3:0];
logic vld_ws_in		[3:0][BLOCK_SIZE - 1:0];

dtype y_h				[3:0][BLOCK_SIZE - 1:0];
dtype b_sr				[1:0][BLOCK_SIZE - 1:0];
dtype b_in				[3:0][BLOCK_SIZE - 1:0];

dtype qsa_in_sr			 [BLOCK_SIZE - 1:0];
dtype qsa_in_2			 [BLOCK_SIZE - 1:0];


cfg_array #(.dtype(dtype), .BLOCK_SIZE(BLOCK_SIZE), .TOP(1), .LEFT(1)) arr_0(.clk(clk), .rst(rst), .vld_in(vld_in[0]), .quad_mode(quad_mode),.mode(mode), .ld_w(ld_w), .vld_ws_in(vld_ws_in[0]),.b(b_in[0]), .cfg_in(qsa_in[0]), .vld_out(vld_out[0]), .cfg_vld_out(qsa_vld_out[0]), .cfg_out(qsa_out[0]), .y_h(y_h[0]));  
cfg_array #(.dtype(dtype), .BLOCK_SIZE(BLOCK_SIZE), .TOP(1), .LEFT(0)) arr_1(.clk(clk), .rst(rst), .vld_in(vld_out[0]), .quad_mode(quad_mode), .mode(mode), .ld_w(ld_w), .vld_ws_in(vld_ws_in[1]), .b(b_in[1]), .cfg_in(y_h[0]), .vld_out(vld_out[1]), .cfg_vld_out(qsa_vld_out[1]), .cfg_out(qsa_out[1]), .y_h(y_h[1]));  
cfg_array #(.dtype(dtype), .BLOCK_SIZE(BLOCK_SIZE), .TOP(0), .LEFT(1)) arr_2(.clk(clk), .rst(rst), .vld_in(vld_in[1]), .quad_mode(quad_mode), .mode(mode), .ld_w(ld_w), .vld_ws_in(vld_ws_in[2]), .b(b_in[2]), .cfg_in(qsa_in_2), .vld_out(vld_out[2]), .cfg_vld_out(qsa_vld_out[2]), .cfg_out(qsa_out[2]), .y_h(y_h[2]));  
cfg_array #(.dtype(dtype), .BLOCK_SIZE(BLOCK_SIZE), .TOP(0), .LEFT(0)) arr_3(.clk(clk), .rst(rst), .vld_in(vld_out[2]), .quad_mode(quad_mode), .mode(mode), .ld_w(ld_w), .vld_ws_in(vld_ws_in[3]), .b(b_in[3]), .cfg_in(y_h[2]), .vld_out(vld_out[3]), .cfg_vld_out(qsa_vld_out[3]), .cfg_out(qsa_out[3]), .y_h(y_h[3]));  

square_sreg #(.dtype(dtype), .block_size(BLOCK_SIZE)) sr_0(.clk(clk), .rst(rst), .inp(qsa_in[1]), .out(qsa_in_sr));
square_sreg #(.dtype(dtype), .block_size(BLOCK_SIZE)) sr_1(.clk(clk), .rst(rst), .inp(b[1]), .out(b_sr[0]));
square_sreg #(.dtype(dtype), .block_size(BLOCK_SIZE)) sr_2(.clk(clk), .rst(rst), .inp(b[3]), .out(b_sr[1]));

accumulator #(.dtype(dtype), .block_size(BLOCK_SIZE), .acc_size(ACC_SIZE)) acc_0(.clk(clk), .rst(rst), .a(qsa_out[2]), .vld_in(qsa_vld_out[2]), .acc_out(acc_out[0]));
accumulator #(.dtype(dtype), .block_size(BLOCK_SIZE), .acc_size(ACC_SIZE)) acc_1(.clk(clk), .rst(rst), .a(qsa_out[3]), .vld_in(qsa_vld_out[3]), .acc_out(acc_out[1]));

assign qsa_in_2 = (quad_mode) ? qsa_in_sr : qsa_in[1];

assign vld_ws_in[2] = qsa_vld_out[0];
assign vld_ws_in[3] = qsa_vld_out[1];

assign b_in[0] = b[0];
assign b_in[1] = ld_w ? b[1] : b_sr[0];
assign b_in[2] = (ld_w | (~mode) | ~quad_mode) ? b[2] : qsa_out[0];
assign b_in[3] = ld_w ? b[3] : (((~mode) | ~quad_mode )? b_sr[1] : qsa_out[1]);
	
endmodule
