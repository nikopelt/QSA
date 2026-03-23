module accumulator #(parameter type dtype = logic[31:0], parameter block_size = 5, parameter acc_size = 3)(
	input logic clk,
	input logic rst,
	input dtype a[block_size - 1:0],
	input logic vld_in[block_size - 1:0],
	
	output dtype acc_out[block_size - 1:0]
);

dtype acc[acc_size][block_size - 1:0];

always_ff @(posedge clk) begin
	if(rst) begin
		for(int i = 0; i < acc_size; i++)begin
			for(int j = 0; j < block_size; j++)begin
				acc[i][j]		<= 0;
			end
		end
	end else begin
		for(int i = 0; i < block_size; i++)begin
			if(vld_in[i])begin
				acc[0][i]		<= a[i] + acc[acc_size - 1][i];
				for(int j = 1; j <= acc_size; j++)begin
					acc[j][i] <= acc[j - 1][i];	
				end
			end		
		end
	end
end

assign acc_out = acc[acc_size - 1];

endmodule
