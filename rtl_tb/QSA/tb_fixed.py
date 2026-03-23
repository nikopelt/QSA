import numpy as np
import random
import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer

# Clock task for sequential logic
async def generate_clock(dut):
    for _ in range(1000):
        dut.clk.value = 0
        await Timer(1, unit = "ns")
        dut.clk.value = 1
        await Timer(1, unit = "ns")


# Reset task for internal registers
async def reset(dut):
    dut.rst.value = 1
    
    for _ in range(5):
        await RisingEdge(dut.clk)
    
    dut.rst.value = 0
    await RisingEdge(dut.clk) 

def golden_mul(result, matrix, sequences):

    golden = np.matmul(sequences, matrix)
    for i in range(len(golden)):
        for j in range(len(matrix)):
            if (abs(float(golden[i][j]) - float(result[i][j]))) > 0.0001:
                return False
    
    cocotb.log.info("================================")
    cocotb.log.info("ERROR RESULTS")
    cocotb.log.info("ERROR: %e", (golden-result).max())
    cocotb.log.info("================================")
    return True 

# Load task to load stationary weights
async def load(dut, weights, block_size):
    for i in range(block_size):
        await RisingEdge(dut.clk)
        dut.ld_w.value = 1
        for j in range(4):
            w = weights[j][block_size - 1 - i]
            for k in range(block_size):
                dut.b[j][k].value = w[k]
    
    await RisingEdge(dut.clk)
    dut.ld_w.value = 0;
    
    await RisingEdge(dut.clk)
    for j in range(4):
        for i in range(block_size):
            dut.b[j][i].value = 0

# Load task to load the stationary weighs of the fused quad array
async def load_quad(dut, weights, block_size):
    for i in range(block_size):
        await RisingEdge(dut.clk)
        dut.ld_w.value = 1
        for j in range(4):
            w = weights[j][block_size - 1 - i]
            for k in range(block_size):
                dut.b[j][k].value = w[k]
    
    await RisingEdge(dut.clk)
    dut.ld_w.value = 0;
    
    await RisingEdge(dut.clk)
    for j in range(4):
        for i in range(block_size):
            dut.b[j][i].value = 0

# Drive the valid input data for weight stationary execution of the partial systolic array grids 
async def drive_data_valid(dut, seq_len, block_size,sequences_0, sequences_1):
    try:
        dut.vld_in[0].value = 1
        dut.vld_in[1].value = 1
        
        for i in range(seq_len):
            for j in range(block_size):
                dut.qsa_in[0][j].value = sequences_0[i][j] 
                dut.qsa_in[1][j].value = sequences_1[i][j]
            await RisingEdge(dut.clk)
    
    finally:
        dut.vld_in[0].value = 0
        dut.vld_in[1].value = 0

# Drive the valid input data for weight stationary execution of the fused systolic array grids 
async def drive_data_valid_quad(dut, sequences):
    try:
        dut.vld_in[0].value = 1
        for sequence in sequences:
            for i in range(len(sequence)//2):
                dut.qsa_in[0][i].value = sequence[i]
                dut.qsa_in[1][i].value = sequence[i + len(sequence)//2]
            await RisingEdge(dut.clk)
    finally:
        dut.vld_in[0].value = 0

# Drive the valid input data for output stationary execution of the partial systolic array mvm grids 
async def drive_data_valid_os(dut, a_in_0, a_in_1, b_in):
    block_size = len(a_in_0)

    try:
        for i in range(block_size):
            await RisingEdge(dut.clk)
            for k in range(4):
                for j in range(block_size):
                    dut.b[k][j].value = b_in[k][i][j]
            dut.qsa_in[0][0].value = a_in_0[i]  
            dut.qsa_in[1][0].value = a_in_1[i]  

            if(i == block_size - 1):
                dut.vld_in[0].value = 1 
                dut.vld_in[1].value = 1 
        await RisingEdge(dut.clk)
    finally:
        dut.vld_in[0].value = 0 
        dut.vld_in[1].value = 0 


async def capture_ws_values(dut, block_size, seq_len, result):
    dut_values = [[[] for _ in range(block_size)] for _ in range(4)]
    for _ in range(4*block_size + seq_len - 1):
        await RisingEdge(dut.clk)
        for i in range(4):
            for j in range(block_size):
                if(dut.qsa_vld_out[i][j].value == 1):
                    dut_values[i][j].append(hex_fixed_to_float(dut.qsa_out[i][j].value))
    
    for j in range(4):
        cocotb.log.info(f"ARRAY {j} VALUES: ")
        for i in range(block_size):
            int_vals = [float(val) for val in dut_values[j][i]]
            for k in range(seq_len):
                result[j][k].append(int_vals[k])
        cocotb.log.info(result[j])

async def capture_ws_values_quad(dut, block_size, seq_len, result):
    dut_values = [[] for _ in range(2*block_size)] 
    for _ in range(4*block_size + seq_len - 1):
        await RisingEdge(dut.clk)
        for j in range(2,4):
            for i in range(block_size):
                if(dut.qsa_vld_out[j][i].value == 1):
                    dut_values[(j % 2)*block_size + i].append(hex_fixed_to_float(dut.qsa_out[j][i].value))
    

    cocotb.log.info("QUAD ARRAY VALUES: ")
    for i in range(2*block_size):
        int_vals = [float(val) for val in dut_values[i]]
        
        for k in range(seq_len):
            result[k].append(int_vals[k])
        
    cocotb.log.info(result)

async def capture_os_values(dut, block_size, result):
    dut_values = [[[] for _ in range(block_size)] for _ in range(4)]
    for _ in range(4*block_size + 1):
        await RisingEdge(dut.clk)
        for i in range(4):
            for j in range(block_size):
                if(dut.qsa_vld_out[i][j].value == 1):
                    dut_values[i][j].append(hex_fixed_to_float(dut.qsa_out[i][j].value))
    for j in range(4):
        cocotb.log.info(f"ARRAY {j} VALUES: ")
        for i in range(block_size):
            int_vals = [float(val) for val in dut_values[j][i]]
            result[j][0].append(int_vals[0])
        cocotb.log.info(result[j])


# Function to convert floating point inputs to fixed point hex
def float_to_hex_fixed(value, integer_bits=8, fractional_bits=24):
    total_bits = integer_bits + fractional_bits
    
    scaled_int = round(value * (1 << fractional_bits))
    
    max_val = (1 << (total_bits - 1)) - 1
    min_val = -(1 << (total_bits - 1))
    
    if scaled_int > max_val: scaled_int = max_val
    if scaled_int < min_val: scaled_int = min_val
    
    if scaled_int < 0:
        scaled_int = (1 << total_bits) + scaled_int
        
    return scaled_int

# Function to convert fixed point hex to decimal float
def hex_fixed_to_float(hex_log, integer_bits=8, fractional_bits=24):
    total_bits = integer_bits + fractional_bits
    
    int_val = int(hex_log)
    
    if int_val & (1 << (total_bits - 1)):
        int_val -= (1 << total_bits)
        
    return int_val / (1 << fractional_bits)



@cocotb.test()
async def weight_stationary_tb(dut):

    # Block Size and sequence length parameters 
    block_size = 4
    seq_len = 6 
    
    # Clock initialization
    cocotb.start_soon(generate_clock(dut))
    
    # Wait for 5ns before beggining
    await Timer(5, unit = "ns")
    
    # Reseting internal registers
    await reset(dut)
    
    # Setting Weight Stationary mode
    await RisingEdge(dut.clk)
    dut.mode.value = 1

    weights_float = [[[random.uniform(-5, 5) for _ in range(block_size)] for _ in range(block_size)] for _ in range(4)]
    sequences_0_float = [[random.uniform(-5, 5) for _ in range(block_size)] for _ in range(seq_len)]
    sequences_1_float = [[random.uniform(-5, 5) for _ in range(block_size)] for _ in range(seq_len)]

    weights = [[[float_to_hex_fixed(val) for val in row] for row in matrix] for matrix in weights_float]
    sequences_0 = [[float_to_hex_fixed(val) for val in row] for row in sequences_0_float]
    sequences_1 = [[float_to_hex_fixed(val) for val in row] for row in sequences_1_float]
    
    # Load the stationary weights
    await load(dut, weights, block_size) 
    
    # Concurrent execution of the data driving function
    cocotb.start_soon(drive_data_valid(dut, seq_len, block_size,sequences_0, sequences_1))
    
    result = [[[] for _ in range(seq_len)] for _ in range(4)]
    await capture_ws_values(dut, block_size, seq_len, result)
    
    assert golden_mul(result[0], weights_float[0], sequences_0_float)        
    assert golden_mul(result[1], weights_float[1], sequences_0_float)        
    assert golden_mul(result[2], weights_float[2], sequences_1_float)        
    assert golden_mul(result[3], weights_float[3], sequences_1_float)        


@cocotb.test()
async def quad_array_tb(dut):

    # Block Size parameter 
    block_size = 4
    seq_len = 5 
    # Clock initialization
    cocotb.start_soon(generate_clock(dut))
    
    # Wait for 5ns before beggining
    await Timer(5, unit = "ns")
    
    # Reseting internal registers
    await reset(dut)
    
    # Setting Weight Stationary mode
    await RisingEdge(dut.clk)
    dut.mode.value = 1
    dut.quad_mode.value = 1
    
    weights_float = [[[random.uniform(-5, 5) for _ in range(block_size)] for _ in range(block_size)] for _ in range(4)]
    sequences_float = [[random.uniform(-5, 5) for _ in range(2 * block_size)] for _ in range(seq_len)]

    quad_weights_float = [[0 for _ in range(2 * block_size)] for _ in range(2 * block_size)]
    for i in range(2):
        for j in range(block_size):
            quad_weights_float[i * block_size + j] = weights_float[2 * i][j] + weights_float[2 * i + 1][j] 

    weights = [[[float_to_hex_fixed(val) for val in row] for row in matrix] for matrix in weights_float]
    sequences = [[float_to_hex_fixed(val) for val in row] for row in sequences_float]

    quad_weights = [[float_to_hex_fixed(val) for val in row] for row in quad_weights_float]

    await load_quad(dut, weights, block_size) 
    
    # Concurrent execution of the data driving function
    cocotb.start_soon(drive_data_valid_quad(dut, sequences))
    
    
    result = [[] for _ in range(seq_len)]
    await capture_ws_values_quad(dut, block_size, seq_len, result)
    
    assert golden_mul(result, quad_weights_float, sequences_float)        



@cocotb.test()
async def output_stationary_tb(dut):

    # Block Size parameter 
    block_size = 4
    
    a_in_0_float = [[random.uniform(-5, 5) for _ in range(block_size)]]
    a_in_1_float = [[random.uniform(-5, 5) for _ in range(block_size)]]
    b_in_float = [[[random.uniform(-5, 5) for _ in range(block_size)] for _ in range(block_size)] for _ in range(4)]

    a_in_0 = [[float_to_hex_fixed(val) for val in row] for row in a_in_0_float]
    a_in_1 = [[float_to_hex_fixed(val) for val in row] for row in a_in_1_float]
    b_in = [[[float_to_hex_fixed(val) for val in row] for row in matrix] for matrix in b_in_float]
    
    # Clock initialization
    cocotb.start_soon(generate_clock(dut))

    # Wait for 5ns before begining
    await Timer(5, unit = "ns")
    
    # Reseting internal registers
    await reset(dut)

    # Setting Output Stationary mode
    await RisingEdge(dut.clk)
    dut.mode.value = 0
    dut.quad_mode.value = 0

    await reset(dut)
    
    # Concurrent execution of the data driving function
    cocotb.start_soon(drive_data_valid_os(dut, a_in_0[0], a_in_1[0], b_in))
   

    result = [[[]] for _ in range(4)]
    await capture_os_values(dut, block_size, result)
    
    assert golden_mul(result[0], b_in_float[0], a_in_0_float)        
    assert golden_mul(result[1], b_in_float[1], a_in_0_float)        
    assert golden_mul(result[2], b_in_float[2], a_in_1_float)        
    assert golden_mul(result[3], b_in_float[3], a_in_1_float)        
