create or replace procedure add_pr_$sms_log(p_log_string in varchar2) is
/*
  Author  : V.ERIN
  Created : 29.03.2015 12:00:00
  Purpose : ������� ��� ���������� ������ � ������� ������� SMS
  Version : 1.1.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    28.03.2015     �������� 
  -------------------------------------------------------------------------------------------------
  -- ������ ���������� ������
  --
  -- 01.04.2015 09:32:02 ;PAY_REQ_INFO; 79859685786;�������� ���������.Test message � "Hello";["491181709186826268"]
  --
*/
  c_group_div     constant char(1) := ';';
  p_sms_name      varchar2(50);
  p_sms_phone     varchar2(50);
  p_sms_text      varchar2(4000);
  p_sms_response  varchar2(4000);
  p_sms_date      date;
  i               integer := 0;
begin
  -- ��������� ������ �� ����
  for val_r in (select trim(regexp_substr(str, '[^'||c_group_div||']+', 1, level)) str
                  from (select p_log_string str from dual) t 
               connect by instr(str, c_group_div, 1, level - 1) > 0) loop
      i := i + 1;
      case i
         when 1 then p_sms_date      := to_date(trim(val_r.str), 'dd.mm.yyyy hh24:mi:ss');
         when 2 then p_sms_name      := val_r.str;
         when 3 then p_sms_phone     := val_r.str;
         when 4 then p_sms_text      := val_r.str;
         when 5 then p_sms_response  := val_r.str;
         else   exit;
      end case; 
          
  end loop;
  -- ��������� ������ � ������� ����������
  insert into sms_log$(smlg_id, sms_name, sms_phone, sms_text, sms_response, sms_date)
                values(smlg$_seq.nextval, p_sms_name, p_sms_phone, p_sms_text, p_sms_response, p_sms_date);
  commit;
end add_pr_$sms_log;
/
