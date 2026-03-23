module cfg_array #(parameter type dtype = logic[31:0], parameter BLOCK_SIZE = 4, parameter TOP = 1, parameter LEFT = 1)(

	input logic clk,
	input logic rst,

	input logic vld_in,
	input logic quad_mode,
	input logic mode,
	input logic ld_w,

  input logic vld_ws_in[BLOCK_SIZE - 1:0],
	
	input dtype b						[BLOCK_SIZE - 1:0],
	input dtype cfg_in			[BLOCK_SIZE - 1:0],

	output logic vld_out,
	output logic cfg_vld_out[BLOCK_SIZE - 1:0],
	output dtype y_h				[BLOCK_SIZE - 1:0],
	output dtype cfg_out		[BLOCK_SIZE - 1:0]
);

logic mvm_vld_out	[BLOCK_SIZE - 1:0];
logic ws_vld_out	[BLOCK_SIZE - 1:0];

dtype a			[BLOCK_SIZE - 1:0];
dtype a_sreg[BLOCK_SIZE - 1:0];
dtype b_in	[BLOCK_SIZE - 1:0];
dtype b_sreg[BLOCK_SIZE - 1:0];
dtype mvm_y	[BLOCK_SIZE - 1:0];
dtype ws_y	[BLOCK_SIZE - 1:0];

sreg #(.dtype(dtype), .block_size(BLOCK_SIZE)) sr_a(.clk(clk), .rst(rst), .a_in(cfg_in), .a_out(a_sreg));
sreg #(.dtype(dtype), .block_size(BLOCK_SIZE)) sr_b(.clk(clk), .rst(rst), .a_in(b), .a_out(b_sreg));

MVM #(.dtype(dtype), .BLOCK_SIZE(BLOCK_SIZE), .TOP(TOP)) mvm(.clk(clk), .rst(rst), .mode(mode), .quad_mode(quad_mode), .ld_w(ld_w), .vld_ws_in(vld_ws_in),.vld_in(vld_in), .x(a[0]), .b(b_in), .vld_out(mvm_vld_out), .y(mvm_y), .y_h(y_h[0]));
ws_arr #(.dtype(dtype), .BLOCK_SIZE(BLOCK_SIZE)) ws_arr(.clk(clk), .rst(rst), .ld_w(ld_w), .vld_in(mvm_vld_out), .b(mvm_y), .a(a[BLOCK_SIZE - 1:1]),.vld_output(ws_vld_out), .y_out(ws_y), .y_h(y_h[BLOCK_SIZE - 1:1]));

// Input conifguration for the integration to the quad systolic array
generate 
	if(LEFT == 1) begin
		assign a = a_sreg;
	end else begin
		assign a = cfg_in;
	end
endgenerate

assign b_in = mode ? b : b_sreg; 
assign cfg_out = mode ? ws_y : mvm_y;
assign cfg_vld_out = mode ? ws_vld_out : mvm_vld_out;
assign vld_out = mvm_vld_out[BLOCK_SIZE - 1];


endmodule
