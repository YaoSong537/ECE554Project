module branch_pred(
    output pred_taken,   //asserted when the branch is predicted as taken
    output [31:0] pred_addr,     //branch address
    input [31:0] pc_1, 
    input branch,          //from the pre-decoder, asserted if the instruction is a branch
    input taken, not_taken,  //from EX stage, the branch result of the previous branch
    input [15:0] offset,    //offset value used to calculate branch address
    input clk, rst_n   
);

localparam TT = 2'b00;  //strong taken
localparam T = 2'b01;    //weak taken
localparam NT = 2'b10;   //weak not taken
localparam NNT = 2'b11;  //strong taken

reg [1:0] state, nstate;
reg pred_taken_int;

always @(posedge clk or negedge rst_n) begin   
    if (!rst_n) 
        state <= T;   //initialize to weak taken, 
    else 
        state <= nstate; 
end

always @(state or taken or not_taken) begin
    pred_taken_int = 0;
    nstate = T;
    
    case (state)
        TT: begin
            pred_taken_int = 1;
            if (not_taken) nstate = T;
            else nstate = TT;
            end
        T: begin
            pred_taken_int = 1;
            if (not_taken) nstate = NT;
            else if (taken) nstate = TT;
            else nstate = T;
           end
        NT: begin
             if (not_taken) nstate = NNT;
             else if (taken) nstate = T;
             else nstate = NT;
            end
       default: begin
             if (not_taken) nstate = NNT;
             else if (taken) nstate = NT;
             else nstate = NNT;
            end
    endcase
end

assign pred_taken = pred_taken_int && branch;
assign pred_addr = pc_1 + {{16{offset[15]}}, offset[15:0]};

endmodule
