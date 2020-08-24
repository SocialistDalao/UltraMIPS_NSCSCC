`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/28 19:57:16
// Design Name: 
// Module Name: ICache_sim
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


module ICache_sim(

    );
    reg clk=0;     
    always #10 clk=~clk;
    
    reg rst=1;
    reg cpu_req_i=0;
    reg [`RegBus]virtual_addr_i=0;
    
    wire hit_o;
    wire cpu_inst_valid_o;
    wire [`InstBus] cpu_inst_o;
    
    reg mem_rvalid_i=0;
    reg mem_arready_i=1;
    reg [`WayBus]mem_rdata_i;
    
    wire mem_ren_o;
    wire mem_rready_o;
    wire mem_arvalid_o;
    wire [`InstAddrBus]mem_araddr_o;
    
//    reg LRU_pick=1;
    ICache icache1(
        .clk(clk),                       
        .rst(rst), 
        
        //read inst request           
        .cpu_req_i(cpu_req_i),                 
        .virtual_addr_i(virtual_addr_i),  
        
        //read inst result                 
        .hit_o(hit_o),                    
        .cpu_inst_valid_o(cpu_inst_valid_o),          
        .cpu_inst_o(cpu_inst_o),     
        
        //from_mem read result            
        .mem_rvalid_i(mem_rvalid_i),              
        .mem_arready_i(mem_arready_i),             
        .mem_rdata_i(mem_rdata_i),
        
        //to_mem ready to recieve request 
        .mem_ren_o(mem_ren_o),                
        .mem_rready_o(mem_rready_o),             
        .mem_arvalid_o(mem_arvalid_o),            
        .mem_araddr_o(mem_araddr_o)
        
        //test
//        .LRU_pick(LRU_pick)
        );
        
    initial begin
        #500 rst =0;
        
        //valid test: addr==0 but not valid
        #100 cpu_req_i=1;
        virtual_addr_i = 32'hDEBA_D000;
        #20 cpu_req_i=0;
        wait(mem_arvalid_o)begin
             #140   mem_rvalid_i=1;
             mem_rdata_i=256'h12345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
             wait(mem_rready_o==`Ready) #20 mem_rvalid_i=0;
         end
        wait(cpu_inst_valid_o==`Valid && hit_o == `HitFail) begin
            if(cpu_inst_o == 32'h78910234)
                $display("sucess:not hit, addr==0 but not valid");
            else    begin
                $display("FAIL!!!");
                $stop;
            end
        end
        
        //normal test
        #500 cpu_req_i=1;
        virtual_addr_i = 32'h24687_570;
        #20 cpu_req_i=0;
        wait(mem_arvalid_o)begin
             #140   mem_rvalid_i=1;
             mem_rdata_i=256'h12345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
             wait(mem_rready_o==`Ready) #20 mem_rvalid_i=0;
         end
        wait(cpu_inst_valid_o==`Valid && hit_o == `HitFail) begin
            if(cpu_inst_o == 32'h56789102)
                $display("sucess:not hit, send to way0");
            else    begin
                $display("FAIL!!!");
                $stop;
            end
        end
        
        //hit test: same set but not same addr
        #100    cpu_req_i=1;
        virtual_addr_i = 32'h24687_574;
        #20 cpu_req_i=0;
        wait(cpu_inst_valid_o==`Valid && hit_o==`HitSuccess)begin
            if(cpu_inst_o == 32'h78910234)
                $display("sucess:hit, directly send data to CPU");
            else    begin
                $display("FAIL!!!");
                $stop;
            end
        end
        
        //normal test
        #500 cpu_req_i=1;
        virtual_addr_i = 32'h33487_570;
        #20 cpu_req_i=0;
        wait(mem_arvalid_o)begin
             #140   mem_rvalid_i=1;
             mem_rdata_i=256'h12345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
             wait(mem_rready_o==`Ready) #20 mem_rvalid_i=0;
         end
        wait(cpu_inst_valid_o==`Valid && hit_o == `HitFail) begin
            if(cpu_inst_o == 32'h56789102)
                $display("sucess:not hit, addr==0 but not valid");
            else    begin
                $display("FAIL!!!");
                $stop;
            end
        end
        
        //hit test: same set but not same addr
        #100    cpu_req_i=1;
        virtual_addr_i = 32'h33487_574;
        #20 cpu_req_i=0;
        wait(cpu_inst_valid_o==`Valid && hit_o==`HitSuccess)begin
            if(cpu_inst_o == 32'h78910234)
                $display("sucess:hit, directly send data to CPU");
            else    begin
                $display("FAIL!!!");
                $stop;
            end
        end
        
        //replace test: check cache stored before to prove it's not replaced
        #100    cpu_req_i=1;
        virtual_addr_i = 32'h24687_578;
        #20 cpu_req_i=0;
        wait(cpu_inst_valid_o==`Valid && hit_o==`HitSuccess)begin
            if(cpu_inst_o == 32'h91023456)
                $display("sucess:hit, it's not replaced (2-way)");
            else    begin
                $display("FAIL!!!");
                $stop;
            end
        end
        
        //replace test: check cache stored before to prove it's not replaced
        #100    cpu_req_i=1;
        virtual_addr_i = 32'h33487_574;
        #20 cpu_req_i=0;
        wait(cpu_inst_valid_o==`Valid && hit_o==`HitSuccess)begin
            if(cpu_inst_o == 32'h78910234)
                $display("sucess:hit, directly send data to CPU");
            else    begin
                $display("FAIL!!!");
                $stop;
            end
        end
        
        //normal test
        #500 cpu_req_i=1;
        virtual_addr_i = 32'h57365_570;
        #20 cpu_req_i=0;
        wait(mem_arvalid_o)begin
             #140   mem_rvalid_i=1;
             mem_rdata_i=256'h12345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
             wait(mem_rready_o==`Ready) #20 mem_rvalid_i=0;
         end
        wait(cpu_inst_valid_o==`Valid && hit_o == `HitFail)begin
            if(cpu_inst_o == 32'h56789102)
                $display("sucess:not hit");
            else    begin
                $display("FAIL!!!");
                $stop;
            end
        end
            
        //normal test
        #500 cpu_req_i=1;
        virtual_addr_i = 32'h24687_570;
        #20 cpu_req_i=0;
        wait(mem_arvalid_o)begin
             #140   mem_rvalid_i=1;
             mem_rdata_i=256'h12345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
             wait(mem_rready_o==`Ready) #20 mem_rvalid_i=0;
         end
        wait(cpu_inst_valid_o==`Valid && hit_o == `HitFail)begin
            if(cpu_inst_o == 32'h56789102)begin
                $display("sucess:not hit, replacement is right");
                $stop;
            end
            else    begin
                $display("FAIL!!!");
                $stop;
            end
        end
    end
endmodule
