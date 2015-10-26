module in_order_cpu(
    input clk, rst,
    output spart_wrt_en,
    output [31:0] spart_wrt_add,
    output [31:0] spart_wrt_data
);

wire changeFlow;  //from EX stage, when branch or jump or branch mis_prediction
wire [31:0] jb_addr;  //from EX stage, provide address for jump or branch
wire [31:0] instr_IF; //instruction coming from I-mem
wire [31:0] pc_1_IF;   //pc+1 from IF stage

wire flush_ID, flush_EX, stall_PC_ID;
wire taken, not_taken;   //from EX stage, change the state of predictor
wire pred_taken;

IF_stage i_IF_stage(.instr(instr_IF), .pc_1(pc_1_IF), .jb_addr(jb_addr), .changeFlow(changeFlow), 
                    .clk(clk), .rst(rst), .stall_PC(stall_PC_ID), .taken(taken), .not_taken(not_taken),
                    .pred_taken(pred_taken));

reg [31:0] instr_IF_ID;   //the IF_ID pipe reg for instr
reg [31:0] pc_1_IF_ID;   //the IF_ID pipe reg for pc_1
reg pred_taken_IF_ID;
//IF/ID pipeline register
always @(posedge clk or posedge rst) begin
    if (rst)
        {instr_IF_ID, pc_1_IF_ID, pred_taken_IF_ID} <= 0;
    else if (flush_ID) 
        {instr_IF_ID, pc_1_IF_ID, pred_taken_IF_ID} <= 0; 
    else if (!stall_PC_ID)
        {instr_IF_ID, pc_1_IF_ID, pred_taken_IF_ID} <= {instr_IF, pc_1_IF, pred_taken};
end

//register data
wire [31:0] rs_data, rt_data;
//signals from WB
wire [31:0] wdata_WB;
wire [4:0] waddr_WB;
reg reg_wen_WB;

//control signals
//control signals for EX stage
wire writeRd, ldic, isSignEx, immed;
wire alu_ctrl0, alu_ctrl1, alu_ctrl2, alu_ctrl3;
wire isJump, isJR;
wire rs_read, rt_read;
//control signals for MEM stage
wire mem_ren, mem_wen;
//contorl signals for WB stage
wire lw, link, reg_wen;
//special control signals
wire halt, strcnt, stpcnt;
wire inc_instr;

//ID_stage
ID_stage i_ID_stage(
                    .instr(instr_IF_ID),
                    .clk(clk),
                    .wdata(wdata_WB),
                    .waddr(waddr_WB),
                    .reg_wen_WB(reg_wen_WB),
                    .rs_data(rs_data),
                    .rt_data(rt_data),
                    .rs_read(rs_read),
                    .rt_read(rt_read),
                    .writeRd(writeRd),
                    .ldic(ldic),
                    .isSignEx(isSignEx),
                    .immed(immed),
                    .alu_ctrl0(alu_ctrl0),
                    .alu_ctrl1(alu_ctrl1),
                    .alu_ctrl2(alu_ctrl2),
                    .alu_ctrl3(alu_ctrl3),
                    .isJump(isJump),
                    .isJR(isJR),
                    .mem_ren(mem_ren),
                    .mem_wen(mem_wen),
                    .lw(lw),
                    .link(link),
                    .reg_wen(reg_wen),
                    .halt(halt),
                    .strcnt(strcnt),
                    .stpcnt(stpcnt),
                    .inc_instr(inc_instr));

//from IF/ID pipeline
reg [31:0] instr_ID_EX;   //the IF_ID pipe reg for instr
reg [31:0] pc_1_ID_EX;   //the IF_ID pipe reg for pc_1
//control signals for EX stage
reg writeRd_ID_EX, ldic_ID_EX, isSignEx_ID_EX, immed_ID_EX;
reg alu_ctrl0_ID_EX, alu_ctrl1_ID_EX, alu_ctrl2_ID_EX, alu_ctrl3_ID_EX;
reg isJump_ID_EX, isJR_ID_EX;
//control signals for MEM stage
reg mem_ren_ID_EX, mem_wen_ID_EX;
//contorl signals for WB stage
reg lw_ID_EX, link_ID_EX, reg_wen_ID_EX;
reg strcnt_ID_EX, stpcnt_ID_EX;    //counter control signal
reg inc_instr_ID_EX;
reg pred_taken_ID_EX;

reg [31:0] rs_data_ID_EX, rt_data_ID_EX;
//ID/EX pipeline for register data
always @(posedge clk or posedge rst) begin
    if (rst) begin
        {rs_data_ID_EX, rt_data_ID_EX} <= 0;
    end
    else begin
        {rs_data_ID_EX, rt_data_ID_EX} <= {rs_data, rt_data};
    end
end

//ID/EX pipeline for control signals
always @(posedge clk or posedge rst) begin
    if (rst) begin
        {writeRd_ID_EX, ldic_ID_EX, isSignEx_ID_EX, immed_ID_EX} <= 0;
        {alu_ctrl0_ID_EX, alu_ctrl1_ID_EX, alu_ctrl2_ID_EX, alu_ctrl3_ID_EX} <= 0;
        {isJump_ID_EX, isJR_ID_EX} <= 0;
        {mem_ren_ID_EX, mem_wen_ID_EX} <= 0;
        {lw_ID_EX, link_ID_EX, reg_wen_ID_EX} <= 0;
        {instr_ID_EX, pc_1_ID_EX} <= 0;
        {strcnt_ID_EX, stpcnt_ID_EX, inc_instr_ID_EX} <= 0;
        pred_taken_ID_EX <= 0;
   end
   else if (flush_EX) begin
        {writeRd_ID_EX, ldic_ID_EX, isSignEx_ID_EX, immed_ID_EX} <= 0;
        {alu_ctrl0_ID_EX, alu_ctrl1_ID_EX, alu_ctrl2_ID_EX, alu_ctrl3_ID_EX} <= 0;
        {isJump_ID_EX, isJR_ID_EX} <= 0;
        {mem_ren_ID_EX, mem_wen_ID_EX} <= 0;
        {lw_ID_EX, link_ID_EX, reg_wen_ID_EX} <= 0;
        {instr_ID_EX, pc_1_ID_EX} <= 0;
        {strcnt_ID_EX, stpcnt_ID_EX, inc_instr_ID_EX} <= 0;
        pred_taken_ID_EX <= 0;
   end
   else begin
        {writeRd_ID_EX, ldic_ID_EX, isSignEx_ID_EX, immed_ID_EX} <= {writeRd, ldic, isSignEx, immed};
        {alu_ctrl0_ID_EX, alu_ctrl1_ID_EX, alu_ctrl2_ID_EX, alu_ctrl3_ID_EX} <= {alu_ctrl0, alu_ctrl1, alu_ctrl2, alu_ctrl3};
        {isJump_ID_EX, isJR_ID_EX} <= {isJump, isJR};
        {mem_ren_ID_EX, mem_wen_ID_EX} <= {mem_ren, mem_wen};
        {lw_ID_EX, link_ID_EX, reg_wen_ID_EX} <= {lw, link, reg_wen};
        {instr_ID_EX, pc_1_ID_EX} <= {instr_IF_ID, pc_1_IF_ID};
        {strcnt_ID_EX, stpcnt_ID_EX, inc_instr_ID_EX} <= {strcnt, stpcnt, inc_instr};
        pred_taken_ID_EX <= pred_taken_IF_ID;
   end
end

//EX stage outputs
wire [31:0] alu_result;
wire [31:0] mem_addr;
wire [4:0] dst_reg;
wire [15:0] instr_cnt, cycle_cnt;
//EX_stage
EX_stage i_EX_stage(
                    .rs_data(rs_data_ID_EX),
                    .rt_data(rt_data_ID_EX),
                    .instr(instr_ID_EX),
                    .instr_cnt(instr_cnt),
                    .cycle_cnt(cycle_cnt),
                    .pc_1(pc_1_ID_EX),
                    .writeRd(writeRd_ID_EX),
                    .ldic(ldic_ID_EX),
                    .isSignEx(isSignEx_ID_EX),
                    .immed(immed_ID_EX),
                    .alu_ctrl0(alu_ctrl0_ID_EX),
                    .alu_ctrl1(alu_ctrl1_ID_EX),
                    .alu_ctrl2(alu_ctrl2_ID_EX),
                    .alu_ctrl3(alu_ctrl3_ID_EX),
                    .isJump(isJump_ID_EX),
                    .isJR(isJR_ID_EX),
                    .pred_taken(pred_taken_ID_EX),
                    .alu_result(alu_result),
                    .mem_addr(mem_addr),
                    .jb_addr(jb_addr),
                    .dst_reg(dst_reg),
                    .changeFlow(changeFlow),
                    .taken(taken),
                    .not_taken(not_taken));

reg [31:0] store_data;
reg [31:0] pc_1_EX_MEM; 
reg [31:0] alu_result_EX_MEM;
reg [31:0] mem_addr_EX_MEM;
reg [4:0] dst_reg_EX_MEM;
//control signals for MEM stage
reg mem_ren_EX_MEM, mem_wen_EX_MEM;
//contorl signals for WB stage
reg lw_EX_MEM, link_EX_MEM, reg_wen_EX_MEM; 
reg strcnt_EX_MEM, stpcnt_EX_MEM;
reg inc_instr_EX_MEM;

//EX_MEM pipeline
always @(posedge clk or posedge rst) begin
    if (rst) begin 
        {store_data, pc_1_EX_MEM, alu_result_EX_MEM, mem_addr_EX_MEM, dst_reg_EX_MEM} <= 0;   //data
        {mem_ren_EX_MEM, mem_wen_EX_MEM} <= 0;          //control for MEM stage
        {lw_EX_MEM, link_EX_MEM, reg_wen_EX_MEM} <= 0;   //control for WB stage
        {strcnt_EX_MEM, stpcnt_EX_MEM, inc_instr_EX_MEM} <= 0;
    end
    else begin
        {store_data, pc_1_EX_MEM, alu_result_EX_MEM}  <= {rt_data_ID_EX, pc_1_ID_EX, alu_result};   //data
        {mem_addr_EX_MEM, dst_reg_EX_MEM} <= {mem_addr, dst_reg};       //data
        {mem_ren_EX_MEM, mem_wen_EX_MEM} <= {mem_ren_ID_EX, mem_wen_ID_EX};          //control for MEM stage
        {lw_EX_MEM, link_EX_MEM, reg_wen_EX_MEM} <= {lw_ID_EX, link_ID_EX, reg_wen_ID_EX};   //control for WB stage
        {strcnt_EX_MEM, stpcnt_EX_MEM, inc_instr_EX_MEM} <= {strcnt_ID_EX, stpcnt_ID_EX, inc_instr_ID_EX};
    end
end

//stall and hazard detection control
hazard_detect i_hazard_detect(
                              .changeFlow(changeFlow),
                              .ID_rs(instr_IF_ID[25:21]),
                              .ID_rt(instr_IF_ID[20:16]),
                              .rs_read(rs_read),
                              .rt_read(rt_read),
                              .EX_dst_reg(dst_reg),
                              .MEM_dst_reg(dst_reg_EX_MEM),
                              .EX_reg_wen(reg_wen_ID_EX),
                              .MEM_reg_wen(reg_wen_EX_MEM),
                              .flush_ID(flush_ID),
                              .flush_EX(flush_EX),
                              .stall_PC_ID(stall_PC_ID));
wire [31:0] mem_rdata_MEM_WB;
//MEM stage
MEM_stage i_MEM_stage(
                      .clk(clk),
                      .mem_addr(mem_addr_EX_MEM),
                      .mem_wdata(store_data),
                      .mem_ren(mem_ren_EX_MEM),
                      .mem_wen(mem_wen_EX_MEM),
                      .mem_rdata(mem_rdata_MEM_WB));

assign spart_wrt_en = mem_wen_EX_MEM;
assign spart_wrt_add = mem_addr_EX_MEM;
assign spart_wrt_data = store_data;

reg [31:0] pc_1_MEM_WB;
reg [31:0] alu_result_MEM_WB;
reg [4:0] dst_reg_MEM_WB;
reg lw_MEM_WB, link_MEM_WB;  //reg_wen_WB is defined in ID stage
reg strcnt_MEM_WB, stpcnt_MEM_WB;
reg inc_instr_MEM_WB;

//MEM_WB pipeline
always @(posedge clk or posedge rst) begin
    if (rst) begin
        {pc_1_MEM_WB, alu_result_MEM_WB, dst_reg_MEM_WB} <= 0;
        {lw_MEM_WB, link_MEM_WB, reg_wen_WB} <= 0;
        {strcnt_MEM_WB, stpcnt_MEM_WB} <= 0;
    end
    else begin
        {pc_1_MEM_WB, alu_result_MEM_WB, dst_reg_MEM_WB} <= {pc_1_EX_MEM, alu_result_EX_MEM, dst_reg_EX_MEM};
        {lw_MEM_WB, link_MEM_WB, reg_wen_WB} <= {lw_EX_MEM, link_EX_MEM, reg_wen_EX_MEM};
        {strcnt_MEM_WB, stpcnt_MEM_WB, inc_instr_MEM_WB} <= {strcnt_EX_MEM, stpcnt_EX_MEM, inc_instr_EX_MEM};
    end
end

WB_stage i_WB_stage(
                    .pc_1(pc_1_MEM_WB),
                    .alu_result(alu_result_MEM_WB),
                    .mem_rdata(mem_rdata_MEM_WB),
                    .dst_reg(dst_reg_MEM_WB),
                    .lw(lw_MEM_WB),
                    .link(link_MEM_WB),
                    .wb_data(wdata_WB),
                    .wb_addr(waddr_WB));

perf_counter i_perf_counter(.strcnt(strcnt_MEM_WB), .stpcnt(stpcnt_MEM_WB), .clk(clk), .rst(rst), .inc_instr(inc_instr_MEM_WB),
                            .instr_cnt(instr_cnt), .cycle_cnt(cycle_cnt));
endmodule
