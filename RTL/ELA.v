`timescale 1ns/10ps

module ELA(clk, rst, in_data, data_rd, req, wen, addr, data_wr, done);

input		clk;
input		rst;
input		[7:0]	in_data;
input		[7:0]	data_rd;

output		reg	req;
output		reg	wen;
output		reg	[9:0]	addr; //0~991
output		reg	[7:0]	data_wr;
output		reg	done;


//----------------------------------------------------------------
reg	[5:0]	row_cnt; //row's element count (0~31)
reg	[9:0]	pointer; //(0~991)


reg	[7:0]	tmp_row[0:31];
reg	[7:0]	pre_row[0:31];
reg	[7:0]	pos_row[0:31];


reg	[3:0]	curt_state;
reg	[3:0]	next_state;
parameter   DIN_1=4'd0,  STO_1=4'd1,  SET_pre=4'd2,  DIN_tmp=4'd3,  SET_pos=4'd4,  ELA_cal=4'd5,  STO_ELA=4'd6,  STO_tmp=4'd7; 

reg [7:0]   D1[0:31];
reg [7:0]   D2[0:31];
reg [7:0]   D3[0:31];


//----------------------------------------------------------------
always@(posedge clk or posedge rst) begin
  if(rst) begin //reset
    pointer <= 0;
    row_cnt <= -1; 
    done <= 0;
    curt_state <= DIN_1;
  end
  
  else begin
    curt_state <= next_state;
    row_cnt <= (row_cnt==31)? 0 : row_cnt + 1;
    case(curt_state)
      DIN_1: begin //0: DIN_1
        tmp_row[row_cnt] <= in_data;       
      end
      
      STO_1: begin //1: STO_1
        addr <= pointer;
        pointer <= pointer +1;
        data_wr <= tmp_row[row_cnt];
			end
    
      SET_pre: begin //2: SET_pre
        pre_row[row_cnt] <= tmp_row[row_cnt];
			end
      
      DIN_tmp: begin //3: DIN_tmp
        tmp_row[row_cnt] <= in_data;
      end
      
      SET_pos: begin //4: SET_pos
        pos_row[row_cnt] <= tmp_row[row_cnt];
      end
      
      ELA_cal: begin //5: ELA_cal
        if(row_cnt == 0 || row_cnt == 31) begin
          D1[row_cnt] <= 255;
          D2[row_cnt] <= (pre_row[row_cnt]>pos_row[row_cnt]) ? (pre_row[row_cnt]-pos_row[row_cnt]) : (pos_row[row_cnt]-pre_row[row_cnt]);
          D3[row_cnt] <= 255;          
        end
        else begin
          D1[row_cnt] <= (pre_row[row_cnt-1]>pos_row[row_cnt+1]) ? (pre_row[row_cnt-1]-pos_row[row_cnt+1]) : (pos_row[row_cnt+1]-pre_row[row_cnt-1]);
          D2[row_cnt] <= (pre_row[row_cnt]>pos_row[row_cnt]) ? (pre_row[row_cnt]-pos_row[row_cnt]) : (pos_row[row_cnt]-pre_row[row_cnt]);
          D3[row_cnt] <= (pre_row[row_cnt+1]>pos_row[row_cnt-1]) ? (pre_row[row_cnt+1]-pos_row[row_cnt-1]) : (pos_row[row_cnt-1]-pre_row[row_cnt+1]);          
        end
      end
      
      STO_ELA: begin //6: STO_ELA
        if(D2[row_cnt] <= D1[row_cnt] && D2[row_cnt] <= D3[row_cnt]) begin
          data_wr <= (pre_row[row_cnt] + pos_row[row_cnt])/2;
        end
        else if(D1[row_cnt] <= D2[row_cnt] && D1[row_cnt] <= D3[row_cnt]) begin
          data_wr <= (pre_row[row_cnt-1] + pos_row[row_cnt+1])/2;
        end
        else if(D3[row_cnt] <= D1[row_cnt] && D3[row_cnt] <= D2[row_cnt]) begin
          data_wr <= (pre_row[row_cnt+1] + pos_row[row_cnt-1])/2;
        end          
        addr <= pointer;
        pointer <= pointer +1;
      end
      
      STO_tmp: begin //7: STO_tmp
        if(addr >= 991) begin
          done <= 1; //finish
        end
        else begin
          addr <= pointer;
          pointer <= pointer +1;
          data_wr <= tmp_row[row_cnt];
        end
      end
    endcase
  end
end


//----------------------------------------------------------------
always@(*) begin
  if(rst) begin
    wen = 0;
    req = 1;
    next_state = DIN_1;
  end
  else begin
    case(curt_state)
      DIN_1: begin
        req = 1; //req data
        wen = 0; //wen ctrl
        next_state = (row_cnt==31) ? STO_1 : DIN_1;
      end
      STO_1: begin
        req = 0;
        wen = 1;
        next_state = (row_cnt==31) ? SET_pre : STO_1;
      end
      SET_pre: begin //<---
        req = 0;
        wen = 0;
        next_state = (row_cnt==31) ? DIN_tmp : SET_pre;
      end
      DIN_tmp: begin
        req = 1;
        wen = 0;
        next_state = (row_cnt==31) ? SET_pos : DIN_tmp;
      end
      SET_pos: begin
        req = 0;
        wen = 0;
        next_state = (row_cnt==31) ? ELA_cal : SET_pos;
      end
      ELA_cal: begin
        req = 0;
        wen = 0;
        next_state = (row_cnt==31) ? STO_ELA : ELA_cal;
      end
      STO_ELA: begin
        req = 0;
        wen = 1;
        next_state = (row_cnt==31) ? STO_tmp : STO_ELA;
      end
      STO_tmp: begin
        req = 0;
        wen = 1;
        next_state = (row_cnt==31) ? SET_pre : STO_tmp;
      end

    endcase
  end
end

endmodule
