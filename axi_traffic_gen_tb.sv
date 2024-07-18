`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/02/2024 11:48:24 PM
// Design Name: 
// Module Name: axi_traffic_gen_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import axi_vip_pkg::*;
import design_1_axi_vip_0_1_pkg::*;

module axi_traffic_gen_tb();
//
xil_axi_uint slv_mem_agent_verbosity = 0;
design_1_axi_vip_0_1_slv_mem_t slv_mem_agent;

//
reg aclk;
wire aclk_out;
reg aresetn;
wire aresetn_out;
//
// singlex2, 16, singlex3, 16, 16, singlex2
reg  [31:0] u_addr [0:9] = 
{
    'h10000000, 
    'h10000040, 
    'h10000080, 
    'h100000C0, 
    'h10000100, 
    'h10000140, 
    'h10000180, 
    'h100001C0, 
    'h10000200, 
    'h10000240
};

reg  [3:0]  u_b_len [0:9] =
{
'h0,
'h0,
'd15,
'h0,
'h0,
'h0,
'd15,
'd15,
'h0,
'h0
};

reg  [63:0] u_data_in [0:54] =
{
'hF8F4F2F1,
'h87654321,
'h0000000A,'h000000BA,'h00000CBA,'h0000DCBA,'h000EDCBA,'h00FEDCBA,'h0AFEDCBA,'hBAFEDCBA,'h0BAFEDCB,'h00BAFEDC,'h000BAFED,'h0000BAFE,'h00000BAF,'h000000BA,'h0000000B,'h00000000,
'h12345678,
'h08060402,
'h07050301,
'h1000000A,'h200000BA,'h30000CBA,'h4000DCBA,'h500EDCBA,'h60FEDCBA,'h7AFEDCBA,'h8AFEDCBA,'h9BAFEDCB,'hA0BAFEDC,'hB00BAFED,'hC000BAFE,'hD0000BAF,'hE00000BA,'hF000000B,'h10000000,
'h00000000,'h11111111,'h22222222,'h33333333,'h44444444,'h55555555,'h66666666,'h77777777,'h88888888,'h99999999,'hAAAAAAAA,'hBBBBBBBB,'hCCCCCCCC,'hDDDDDDDD,'hEEEEEEEE,'hFFFFFFFF,
'hBADCAFEE,
'hDEADBEEF
};

reg         u_pix_len [0:9] =
{
'b1,
'b1,
'b1,
'b1,
'b1,
'b1,
'b1,
'b1,
'b0,
'b0
};

reg         user_start;

wire        user_free;
wire        user_stall_data;
wire [1:0]  user_status;
//

reg  [31:0] user_addr_in;
reg  [3:0]  user_burst_len_in;
reg  [63:0] user_data_in;
reg         user_pixels_1_2;
int         running_index;
//
reg axi_ready;

initial
begin
    axi_ready = 0;
    slv_mem_agent = new("slave vip agent",dw0.design_1_i.axi_vip_0.inst.IF);
    slv_mem_agent.set_agent_tag("Slave VIP");
    slv_mem_agent.set_verbosity(slv_mem_agent_verbosity);
    slv_mem_agent.start_slave();
    slv_mem_agent.mem_model.pre_load_mem("compile.sh", 0);

    axi_ready = 1;
end

initial
begin
    aclk = 0;
    aresetn = 0;
    user_addr_in = 'h0;
    user_burst_len_in = 'h0;
    user_data_in = 'h0;
    user_pixels_1_2 = 'h0;
    user_start = 'h0;
end

always
begin
    #8ns aclk = ~aclk;
end

initial
begin
    wait(axi_ready);
    aresetn = 1;
    #20us;
    @(posedge aclk_out);
    
    
    #10us;
    
    user_start      = 1'd0;
    running_index   = 1'd0;
    
    //#5ms;
    @(posedge aclk_out);
    
    for(int i = 0; i < 10; i++)
    begin
        wait(user_free);
        @(posedge aclk_out);
        
        user_addr_in        = u_addr[i];
        user_burst_len_in   = u_b_len[i];
        user_pixels_1_2     = u_pix_len[i];
        user_data_in        = u_data_in[running_index];
        user_start          = 1'd1;
        
        @(posedge aclk_out);
        
        for(int b = 0; b < u_b_len[i]+1; b++)
        begin
            running_index++;
            @(negedge user_stall_data);
            //@(posedge aclk_out);
            user_data_in = u_data_in[running_index];
        end
    end
    
    $finish;
end

design_1_wrapper dw0
   (aclk,
    aclk_out,
    aresetn,
    user_addr_in,
    user_burst_len_in,
    user_data_in,
    user_free,
    user_pixels_1_2,
    user_stall_data,
    user_start,
    user_status);

endmodule