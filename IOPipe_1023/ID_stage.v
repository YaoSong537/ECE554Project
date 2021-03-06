module ID_stage(
    input [31:0] instr,
    input clk,
    input [31:0] wdata,
    input [4:0] waddr,
    input reg_wen_WB,   
    //write enable from WB stage
    output [31:0] rs_data, rt_data,
    //control signals for EX stage
    output writeRd, ldic, isSignEx, immed,
    output alu_ctrl0, alu_ctrl1, alu_ctrl2, alu_ctrl3,
    output isJump, isJR, 
    output rs_read, rt_read,
    //control signals for MEM stage
    output mem_ren, mem_wen,
    //contorl signals for WB stage
    output lw, link, reg_wen,
    //special control signals
    output halt, strcnt, stpcnt,
    output inc_instr  //to performance counter, increase the instruction count
);


register_file i_register_file(
                              .raddr0(instr[25:21]),   //rs
                              .raddr1(instr[20:16]),   //rt
                              .we(reg_wen_WB),
                              .waddr(waddr),
                              .din(wdata),
                              .clk(clk),
                              .dout0(rs_data),
                              .dout1(rt_data));

decoder i_decoder(
                  .opcode(instr[31:26]),
                  .writeRd(writeRd),
                  .isSignEx(isSignEx),
                  .ldic(ldic),
                  .immed(immed),
                  .alu_ctrl3(alu_ctrl3),
                  .alu_ctrl2(alu_ctrl2),
                  .alu_ctrl1(alu_ctrl1),
                  .alu_ctrl0(alu_ctrl0),
                  .isJump(isJump),
                  .isJR(isJR),
                  .rs_read(rs_read),
                  .rt_read(rt_read),
                  .mem_ren(mem_ren),
                  .mem_wen(mem_wen),
                  .lw(lw),
                  .link(link),
                  .reg_wen(reg_wen),
                  .strcnt(strcnt),
                  .stpcnt(stpcnt),
                  .halt(halt),
                  .inc_instr(inc_instr));


endmodule
