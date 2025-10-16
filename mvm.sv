/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2025 */
/* Lab 4                                           */
/* Matrix Vector Multiplication (MVM) Module       */
/***************************************************/

module mvm # (
    parameter IWIDTH = 8,
    parameter OWIDTH = 32,
    parameter MEM_DATAW = IWIDTH * 8, // bitwidth of vector and matrix memories
    parameter VEC_MEM_DEPTH = 256, // depth of vector memory 
    parameter VEC_ADDRW = $clog2(VEC_MEM_DEPTH), // bitwidth of the vector memory address
    parameter MAT_MEM_DEPTH = 512, // depth of matrix memory depth
    parameter MAT_ADDRW = $clog2(MAT_MEM_DEPTH), // bitwidth of the matrix memory address 
    parameter NUM_OLANES = 8 
)(
    input clk,
    input rst,
    input [MEM_DATAW-1:0] i_vec_wdata,
    input [VEC_ADDRW-1:0] i_vec_waddr,
    input i_vec_wen,
    input [MEM_DATAW-1:0] i_mat_wdata,
    input [MAT_ADDRW-1:0] i_mat_waddr,
    input [NUM_OLANES-1:0] i_mat_wen,
    input i_start,
    input [VEC_ADDRW-1:0] i_vec_start_addr,
    input [VEC_ADDRW:0] i_vec_num_words,
    input [MAT_ADDRW-1:0] i_mat_start_addr,
    input [MAT_ADDRW:0] i_mat_num_rows_per_olane,
    output o_busy,
    output [OWIDTH-1:0] o_result [0:NUM_OLANES-1],
    output o_valid
);

/******* Your code starts here *******/
// mat and vector data
logic [VEC_ADDRW-1:0] vec_mem_raddr;
logic signed [MEM_DATAW-1:0] vec_mem_rdata;
logic [MAT_ADDRW-1:0] mat_mem_raddr;
logic signed [MEM_DATAW-1:0] mat_mem_rdata [0:NUM_OLANES-1];

// dot8 signals
logic signed [OWIDTH-1:0] result_dot_r [0:NUM_OLANES-1];
logic ovalid_r [0:NUM_OLANES-1];

// accum signals
logic o_valid_accum [0:NUM_OLANES-1];

// external ctrl
logic ctrl_valid_r;
logic ctrl_first_r; 
logic ctrl_last_r;

// pipelining the ext ctrl signals
logic dot_valid_r;
logic first_delayed_r [0:5];
logic last_delayed_r [0:5];

// Pipeline for control signal alignment
always_ff @(posedge clk) begin
    if (rst) begin
        dot_valid_r <= 0;
        for (int i = 0; i < 6; i++) begin
            first_delayed_r[i] <= 0;
            last_delayed_r[i] <= 0;
        end
    end else begin
        dot_valid_r <= ctrl_valid_r;

        first_delayed_r[0] <= ctrl_first_r;
        last_delayed_r[0] <= ctrl_last_r;
        for (int i = 1; i < 6; i++) begin
            first_delayed_r[i] <= first_delayed_r[i-1];
            last_delayed_r[i] <= last_delayed_r[i-1];
        end
    end
end

assign o_valid = o_valid_accum[0];

// INSTANTIATE VEC HERE
mem # (
    .DATAW(MEM_DATAW),
    .DEPTH(VEC_MEM_DEPTH)
) vector_memory_blk (
    .clk(clk),
    .wdata(i_vec_wdata),
    .waddr(i_vec_waddr),
    .wen(i_vec_wen),
    .raddr(vec_mem_raddr),
    .rdata(vec_mem_rdata)
);

// INSTANTIATE MAT HERE
genvar i;
generate
    for (i = 0; i < NUM_OLANES; i++) begin: olane_mem_blk
        mem # (
            .DATAW(MEM_DATAW),
            .DEPTH(MAT_MEM_DEPTH)
        ) matrix_memory_blk (
            .clk(clk),
            .wdata(i_mat_wdata),
            .waddr(i_mat_waddr),
            .wen(i_mat_wen[i]),
            .raddr(mat_mem_raddr),
            .rdata(mat_mem_rdata[i])
        );
    end

    for (i = 0; i < NUM_OLANES; i++) begin: olane_compute_blk
        dot8 # (
            .IWIDTH(IWIDTH),
            .OWIDTH(OWIDTH)
        ) matrix_dot8_modules (
            .clk(clk),
            .rst(rst),
            .vec0(vec_mem_rdata),
            .vec1(mat_mem_rdata[i]),
            .ivalid(dot_valid_r),
            .result(result_dot_r[i]),
            .ovalid(ovalid_r[i])
        );

        accum # (
            .DATAW(OWIDTH),
            .ACCUMW(OWIDTH)
        ) matrix_accum_modules (
            .clk(clk),
            .rst(rst),
            .data(result_dot_r[i]),
            .ivalid(ovalid_r[i]),
            .first(first_delayed_r[5]),
            .last(last_delayed_r[5]),
            .result(o_result[i]),
            .ovalid(o_valid_accum[i])
        );
    end
endgenerate

ctrl # (
    .VEC_ADDRW(VEC_ADDRW),
    .MAT_ADDRW(MAT_ADDRW)
) controller_block (
    .clk(clk),
    .rst(rst),
    .start(i_start),
    .vec_start_addr(i_vec_start_addr),
    .vec_num_words(i_vec_num_words),
    .mat_start_addr(i_mat_start_addr),
    .mat_num_rows_per_olane(i_mat_num_rows_per_olane),
    .vec_raddr(vec_mem_raddr),
    .mat_raddr(mat_mem_raddr),
    .accum_first(ctrl_first_r),
    .accum_last(ctrl_last_r),
    .ovalid(ctrl_valid_r),
    .busy(o_busy)
);

/******* Your code ends here ********/

endmodule
