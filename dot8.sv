/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2025 */
/* Lab 4                                           */
/* 8-Lane Dot Product Module                       */
/***************************************************/

module dot8 # (
    parameter IWIDTH = 8,
    parameter OWIDTH = 32
)(
    input clk,
    input rst,
    input signed [8*IWIDTH-1:0] vec0,
    input signed [8*IWIDTH-1:0] vec1,
    input ivalid,
    output signed [OWIDTH-1:0] result,
    output ovalid
);

// declaring wires
logic signed [OWIDTH-1:0] result_r;
logic signed [IWIDTH-1:0] a_r[7:0], b_r[7:0]; // size 8 and 8 entrier per vec0, vec1
logic valid_r [0:4]; // 4 stages
logic signed [2*IWIDTH-1:0] mult_r [0:7]; // mult reg, need 8 and 64-1:0 
logic signed [2*IWIDTH:0] adder1_r [0:3]; // need +1 bit for addition from mult stage
logic signed [2*IWIDTH+1:0] adder2_r [0:1]; // need +1 bit for addition from prev adder stage
logic signed [OWIDTH-1:0] adder3_r; // output is 32 bit signed

/******* Your code starts here *******/

always_ff @ (posedge clk) begin
    if (rst) begin
        for (int i = 0; i < 8; i++) begin
            a_r[i] <= '0;
            b_r[i] <= '0;
        end
        for (int i = 0; i < 5; i++) valid_r[i] <= 0;
        for (int i = 0; i < 8; i++) mult_r[i] <= 0;
        for (int i = 0; i < 4; i++) adder1_r[i] <= 0;
        for (int i = 0; i < 2; i++) adder2_r[i] <= 0;
        adder3_r <= 0;
        result_r <= 0;
    end else begin
        if (ivalid) begin
            // stage 0: unpack input vectors into a and b for computation
            for (int i = 0; i < 8; i++) begin
                a_r[i] <= vec0[(i+1)*IWIDTH - 1 -: IWIDTH];
                b_r[i] <= vec1[(i+1)*IWIDTH - 1 -: IWIDTH];
            end
        end
        // valid signal pipelining
        valid_r[0] <= ivalid;
        for (int i = 1; i < 5; i++) begin
            valid_r[i] <= valid_r[i-1];
        end 
        
        // stage 1: multiplication line
        for (int i = 0; i < 8; i++) begin
            mult_r[i] <= a_r[i] * b_r[i];
        end
        
        // stage 2: first adders
        for (int i = 0; i < 4; i++) begin   
            adder1_r[i] <= mult_r[2*i] + mult_r[2*i+1]; // mult by 2 so we don't re-read a used index
        end
        
        // stage 3: second adder stage
        for (int i = 0; i < 2; i++) begin
            adder2_r[i] <= adder1_r[2*i] + adder1_r[2*i+1];
        end
        
        // stage 4: final adder stage
        adder3_r <= adder2_r[0] + adder2_r[1];
    end
end

assign result = adder3_r;
assign ovalid = valid_r[4];
 

/******* Your code ends here ********/

endmodule