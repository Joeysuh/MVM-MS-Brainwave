/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2025 */
/* Lab 4                                           */
/* Accumulator Module                              */
/***************************************************/

module accum # (
    parameter DATAW = 32, // bitwidth of input data
    parameter ACCUMW = 32 // bitwidth of internal accum reg
)(
    input  clk,
    input  rst,
    input  signed [DATAW-1:0] data, // done
    input  ivalid, // done
    input  first, // done
    input  last, // done
    output signed [ACCUMW-1:0] result, // done
    output ovalid // done
);

logic signed [ACCUMW-1:0] accum_r;
logic signed [ACCUMW-1:0] result_r;
logic ovalid_r;

/******* Your code starts here *******/
always_ff @ (posedge clk) begin
    if (rst) begin
        accum_r <= '0;
        result_r <= '0;
        ovalid_r <= 1'b0;
    end else begin
        ovalid_r <= 1'b0; // since we xplicitly set ovalid

        if (ivalid) begin
            if (first)
                accum_r <= data;
            else
                accum_r <= accum_r + data; 

            if (last) begin
                result_r <= first ? data : accum_r + data; // first? then data else add it. edge case for first == last
                ovalid_r <= 1'b1;
            end
        end
    end
end

assign ovalid = ovalid_r;
assign result = result_r;
 
/******* Your code ends here ********/

endmodule
