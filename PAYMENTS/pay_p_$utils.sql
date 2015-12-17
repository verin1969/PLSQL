create or replace package pay_p_$utils is
/*
  Author  : V.ERIN
  Created : 21.11.2014 12:00:00
  Purpose : ������� ��� ������ ��������.
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    21/11/2014     �������� ������
  -------------------------------------------------------------------------------------------------
*/
  -- ���������
  c_ok            constant integer := 0;
  c_no_data_found constant integer := -100;
  c_invalid_abon  constant integer := -20080;
  c_dublicate_pay constant integer := -20090;
  c_cant_add_pay  constant integer := -20099;
  c_invalid_id    constant integer := -1;
  c_logon         constant varchar2(50) := '213.167.39.10';
  c_cur_inf_num   constant integer := cifra.m2_clc.currentinformationnumber;
  -- ���� ������ 
  c_unknown_code       constant number := 0;  -- �� ���������
  c_esmp_code          constant number := 1;  -- OSMP
  c_bank_express_code  constant number := 2;  -- BANK_EXPRESS
  c_xcyberplat_code    constant number := 3;  -- XCyberPlat
  c_assist_code        constant number := 4;  -- Assist
  c_chronopay_code     constant number := 5;  -- ChronoPay
  c_payonline_code     constant number := 6;  -- PayOnline
  c_cyberplat_code     constant number := 7;  -- CyberPlat
  c_elecsnet_code      constant number := 8;  -- Elecsnet
  c_esgp_code          constant number := 9;  -- ESGP
  c_rib_code           constant number := 10; -- RIB
  c_rapida_code        constant number := 11; -- Rapida
  c_mosprivate_code    constant number := 12; -- Mosprivate
  c_mkb_code           constant number := 13; -- MKB
  c_sberbank_code      constant number := 14; -- SberBank
  c_mobelm_code        constant number := 15; -- MobElm
  c_ronin_code         constant number := 16; -- Ronin
  -- ���� ��������
  c_op_pay             constant varchar2(5) := 'PAY';
  -- ���� ���������� ��������
  c_res_ok             constant varchar2(5) := 'OK';
  c_res_err            constant varchar2(5) := 'ERR';
  --
  -- ������� ��� ��������� �� ������
  --
  function get_err_message(err_code in integer) return varchar2;
  --
  -- ������� ��� ����������� ����� ��������� �������
  --
  function get_pay_system_name(pay_system_code in integer) return varchar2;
  --
  -- ������� ��� ����������� ������ ��������� �������
  --
  function get_pay_system_num(pay_system_name in varchar2) return number;
  --
  -- ������� ��� ����������� �� ��������
  --
  function get_abonent_id(p_account in number) return number;
  --
  -- ��������� �������� ������������� ��������, 0 - ������� ����������
  --
  procedure check_abonent(p_account in number, p_result in out number);
  --
  -- ��������� �������� ������������� �������, 0 - ������ ����������
  --
  procedure check_payment(p_account in number, p_transaction_id in varchar2, p_result in out number);
  --
  -- ��������� ���������� �������
  --
  procedure do_payment(p_account in number, p_transaction_id in number, p_pay_sum in number, pay_date in date, pay_system_code in integer, p_result in out number);
  --
  -- ��������� ��������� ������ � ������
  --
  procedure add_request_to_log( p_paysys_num  in  integer,
                                p_account     in  varchar2,
                                p_trans_id    in  varchar2,
                                p_pay_date    in  varchar2,
                                p_pay_amount  in  varchar2,
                                p_req_type    in  varchar2,
                                p_response    in  varchar2,
                                p_pay_srv     in  varchar2,
                                p_remote_addr in  varchar2,
                                p_request     in  varchar2);
  --
  -- ������� ��� ��������� ���������� ��������
  --
  function get_result(p_paysys_name in varchar2, p_response in varchar2) return varchar2;
  --
  -- ������� ��� ��������� ����� �������
  --
  function get_pay_sum(p_paysys_name in varchar2, p_pay_sum in varchar2) return number;
  --
end pay_p_$utils;
/
create or replace package body pay_p_$utils is
  --
  -- ������� ��� ��������� ���������� ��������
  --
  function get_result(p_paysys_name in varchar2, p_response in varchar2) return varchar2 is
    v_retval     varchar2(5) := c_res_err;
    p_paysys_num integer;
  begin
    p_paysys_num := get_pay_system_num(p_paysys_name);
    case p_paysys_num
      when  c_esmp_code          then  -- 'OSMP'
        begin
          if instr(upper(p_response), '<RESULT>0</RESULT>') > 0 then  
             v_retval := c_res_ok;
          end if;
        end;
      when  c_bank_express_code  then  --'BANK_EXPRESS'
        begin
          v_retval := null;
        end;
      when  c_xcyberplat_code    then  --  'XCyberPlat'
        begin
          v_retval := null;
        end;
      when  c_assist_code        then   --  'Assist'
        begin
          if instr(upper(p_response), '<PUSHPAYMENTRESULT FIRSTCODE="0" SECONDCODE="0">') > 0 then  
             v_retval := c_res_ok;
          end if;
        end;
      when  c_chronopay_code     then   --  'ChronoPay'
        begin
          if (instr(upper(p_response), 'HTTP/1.1 200 OK') > 0) then
            v_retval := c_res_ok;
          end if;
        end;
      when  c_payonline_code     then   --  'PayOnline'
        begin
          if (instr(upper(p_response), '<RESULT>0</RESULT>') > 0) or (instr(upper(p_response), 'SUCCESS') > 0) then  
             v_retval := c_res_ok;
          end if;
        end;
      when  c_cyberplat_code     then   --  'CyberPlat'
        begin
          if instr(upper(p_response), '<CODE>0</CODE>') > 0 then  
             v_retval := c_res_ok;
          end if;
        end;
      when  c_elecsnet_code      then   --  'Elecsnet'
        begin
          if instr(upper(p_response), 'ANS_CODE=00') > 0 then  
             v_retval := c_res_ok;
          end if;
        end;
      when  c_esgp_code          then   --  'ESGP'
        begin
          if instr(upper(p_response), '<RESULT>0</RESULT>') > 0 then  
             v_retval := c_res_ok;
          end if;
        end;
      when  c_rib_code           then   --  'RIB'
        begin
          if instr(upper(p_response), '<RESULT>0</RESULT>') > 0 then  
             v_retval := c_res_ok;
          end if;
        end;
      when  c_rapida_code        then   --  'Rapida'
        begin
          if instr(upper(p_response), '<CODE>0</CODE>') > 0 then  
             if (instr(upper(p_response), 'PAYMENT ALREADY EXISTS') > 0) then
               v_retval := c_res_err;
             else
               v_retval := c_res_ok;
             end if;
          end if;
        end;
      when  c_mosprivate_code    then   --  'Mosprivate'
        begin
          if instr(upper(p_response), '<RESULT>0</RESULT>') > 0 then  
             v_retval := c_res_ok;
          end if;
        end;
      when  c_mkb_code           then   --  'MKB'
        begin
          if (instr(upper(p_response), '<RESULT>0</RESULT>') > 0)  then  
             if (instr(upper(p_response), '<COMMENT>PAYMENT ALREADY EXISTS</COMMENT>') > 0) then
               v_retval := c_res_err;
             else
               v_retval := c_res_ok;
             end if;
          end if;
        end;
      when  c_sberbank_code      then   --  'SberBank'
        begin
          if instr(upper(p_response), '<ERR_CODE>0</ERR_CODE>') > 0 then  
             v_retval := c_res_ok;
          end if;
        end;
      when  c_mobelm_code        then   --  'MobElm'
        begin
          if instr(upper(p_response), '<RESULT>0</RESULT>') > 0 then  
             v_retval := c_res_ok;
          end if;
        end;
      when  c_ronin_code         then   --  'Ronin'
        begin
          if instr(upper(p_response), '<RESULT>0</RESULT>') > 0 then  
             v_retval := c_res_ok;
          end if;
        end;
      else  v_retval := null;
     end case ;
    return v_retval;
  end;
  --
  -- ������� ��� ��������� ����� �������
  --
  function get_pay_sum(p_paysys_name in varchar2, p_pay_sum in varchar2) return number is
    v_retval     number := 0;
    p_paysys_num integer;
    num_divider  varchar2(1) := '';
    v_pay_sum    varchar2(256) := p_pay_sum;
  begin
    select substr(t.value,1,1) into num_divider from nls_session_parameters t where t.parameter = 'NLS_NUMERIC_CHARACTERS';
    v_pay_sum := replace(v_pay_sum, '.', num_divider);
    p_paysys_num := get_pay_system_num(p_paysys_name);
    if p_paysys_num in (c_sberbank_code, c_elecsnet_code) then
      v_retval := to_number(v_pay_sum)/100;
    else
      v_retval := to_number(v_pay_sum);
    end if ;
    return v_retval;
 end;
  --
  -- ������� ��� ��������� �� ������
  --
  function get_err_message(err_code in integer) return varchar2 is
    v_retval varchar2(256);
  begin
    case err_code
      when  c_ok             then  v_retval := '���������� ����������';
      when  c_invalid_abon   then  v_retval := '������� �� ������';
      when  c_dublicate_pay  then  v_retval := '������������ �������';
      when  c_cant_add_pay   then  v_retval := '������ �� ����� ���� ��������';
      else  v_retval := '����������� ������ ��� ������ �������';
     end case ;
    return v_retval;
 end;
  --
  -- ������� ��� ����������� ������ ��������� �������
  --
  function get_pay_system_num(pay_system_name in varchar2) return number is
    v_retval number;
  begin
    case pay_system_name
      when  'OSMP'          then  v_retval := c_esmp_code;
      when  'BANK_EXPRESS'  then  v_retval := c_bank_express_code;
      when  'XCyberPlat'    then  v_retval := c_xcyberplat_code;
      when  'Assist'        then  v_retval := c_assist_code;
      when  'ChronoPay'     then  v_retval := c_chronopay_code;
      when  'PayOnline'     then  v_retval := c_payonline_code;
      when  'CyberPlat'     then  v_retval := c_cyberplat_code;
      when  'Elecsnet'      then  v_retval := c_elecsnet_code;
      when  'ESGP'          then  v_retval := c_esgp_code;
      when  'RIB'           then  v_retval := c_rib_code;
      when  'Rapida'        then  v_retval := c_rapida_code;
      when  'Mosprivate'    then  v_retval := c_mosprivate_code;
      when  'MKB'           then  v_retval := c_mkb_code;
      when  'SberBank'      then  v_retval := c_sberbank_code;
      when  'MobElm'        then  v_retval := c_mobelm_code;
      when  'Ronin'         then  v_retval := c_ronin_code;
      else  v_retval := c_unknown_code;
     end case ;
    return v_retval;
 end;
  --
  -- ������� ��� ����������� ����� ��������� �������
  --
  function get_pay_system_name(pay_system_code in integer) return varchar2 is
    v_retval varchar2(50);
  begin
    case pay_system_code
      when  c_esmp_code          then  v_retval := 'OSMP';
      when  c_bank_express_code  then  v_retval := 'BANK_EXPRESS';
      when  c_xcyberplat_code    then  v_retval := 'XCyberPlat';
      when  c_assist_code        then  v_retval := 'Assist';
      when  c_chronopay_code     then  v_retval := 'ChronoPay';
      when  c_payonline_code     then  v_retval := 'PayOnline';
      when  c_cyberplat_code     then  v_retval := 'CyberPlat';
      when  c_elecsnet_code      then  v_retval := 'Elecsnet';
      when  c_esgp_code          then  v_retval := 'ESGP';
      when  c_rib_code           then  v_retval := 'RIB';
      when  c_rapida_code        then  v_retval := 'Rapida';
      when  c_mosprivate_code    then  v_retval := 'Mosprivate';
      when  c_mkb_code           then  v_retval := 'MKB';
      when  c_sberbank_code      then  v_retval := 'SberBank';
      when  c_mobelm_code        then  v_retval := 'MobElm';
      when  c_ronin_code         then  v_retval := 'Ronin';
      else  v_retval := 'Unknown';
     end case ;
    return v_retval;
 end;
  --
  -- ������� ��� ����������� �� ��������
  --
  function get_abonent_id(p_account in number) return number is
    v_retval number;
  begin
    begin
      select id into v_retval from cifra.ao_abonent ao where ao.card_num = p_account and ao.bdate <= sysdate and ao.edate is null;
    exception 
      when too_many_rows then null;
      when no_data_found then v_retval := c_invalid_id;
    end;
    return v_retval;
  end;
  --
  -- ��������� �������� ������������� ��������
  --
  procedure check_abonent(p_account in number, p_result in out number) is
    v_result integer;       
  begin
    select count(1) into v_result from cifra.ao_abonent ab where ab.card_num = p_account;
    -- ���� ����� ������� �� 0 ���� ��� -100
    if v_result = 0 then
       p_result := c_no_data_found;
    else
       p_result := 0;
    end if;
  end;
  --
  -- ��������� �������� ����������� �������
  --
  procedure check_payment(p_account in number, p_transaction_id in varchar2, p_result in out number) is
    v_result integer;       
    v_cnt    integer;       
  begin
    check_abonent(p_account, v_result);
    if v_result = 0 then
      select count(1) into v_cnt
        from prps.payments p 
        join prps.transactions t on p.trans_id = t.id 
        join cifra.operations o on t.ext_trans_id = o.o_id 
       where t.pos_trans_no = p_transaction_id; 
      if v_cnt = 0 then
         v_result := c_ok; 
      else
         v_result := c_dublicate_pay;
      end if;
    else
       v_result := c_invalid_abon;
    end if;
    p_result := v_result;
  end;
  --
  -- ��������� ���������� �������
  --
  procedure do_payment(p_account in number, p_transaction_id in number, p_pay_sum in number, pay_date in date, pay_system_code in integer, p_result in out number) is
    v_result       integer := 0;       
    v_pos_trans_dt date := pay_date;
    v_req_id       number := -1;
    v_trans_err_id number := -1;
    v_req_err_id   number := -1;
    v_reqs_type_id number := 1;
    v_reqs         number := p_account;
    v_sum          number := p_pay_sum;
    v_res          number := -1;
    v_inst_id      number := 1;
    v_trans_id     number := -1;
    v_prv_trans_id number := -1;
    v_pay_system   varchar2(50) := get_pay_system_name(pay_system_code);
    v_message      varchar2(100);
    v_saldo_msg    varchar2(100);
    v_saldo        number;
    v_abonent_id   number;
    function get_operation_id return number is
      v_retval number;
    begin
      select max(o_id) into v_retval 
        from cifra.operations 
       where ab_num = v_abonent_id 
         and o_fullsumma = p_pay_sum 
         and lvo_cod = 6 
         and o_bdate = pay_date;
      return v_retval;
    end;
  begin
    -- ���������� ������� �� ������
    prps.prepare_request_without_check(p_req_type_id    => 2,
                                       p_trans_type_id  => 1,
                                       p_station_no     => null,
                                       p_dep_name       => v_pay_system,
                                       p_logon_param_id => 1,
                                       p_logon_value    => c_logon,
                                       p_pos_trans_id   => p_transaction_id,
                                       p_pos_trans_dt   => v_pos_trans_dt,
                                       p_req_id         => v_req_id,
                                       p_trans_err_id   => v_trans_err_id,
                                       p_req_err_id     => v_req_err_id,
                                       p_reqs_type_id   => v_reqs_type_id,
                                       p_reqs           => v_reqs,
                                       p_sum            => v_sum,
                                       p_res            => v_res,
                                       p_inst_id        => v_inst_id,
                                       p_trans_id       => v_trans_id,
                                       p_prv_trans_id   => v_prv_trans_id,
                                       p_prv_code       => v_pay_system,
                                       p_srv_cls_code   => 'Phone'); 
    if v_res = 0 then
      -- ������
      v_abonent_id := get_abonent_id(p_account);
      if v_abonent_id <> c_invalid_id then 
        cifra.prps_sync.prps_pay (tr_id     => v_trans_id,
                                  ab_id     => v_abonent_id,
                                  ab        => p_account,
                                  xsum      => p_pay_sum,
                                  lso_cod   => 0,
                                  dt        => pay_date,
                                  res       => v_res,
                                  res_msg   => v_message,
                                  saldo     => v_saldo,
                                  saldo_msg => v_saldo_msg);
         if v_res = 0 then
           if v_res = 0 then
             -- �������� ������� �� ������
             prps.post_request_without_check(p_req_id => v_req_id, 
                                             p_trans_state_id => 0,
                                             p_req_state_id   => 0,
                                             p_trans_err_id   => 0,
                                             p_pay_state_id   => 0,
                                             p_req_err_id     => 0,
                                             p_res            => v_res,
                                             p_trans_id       => v_trans_id,
                                             p_ext_trans_id   => get_operation_id,
                                             p_pay_err_id     => 0);
           else
             v_result := c_cant_add_pay;
           end if;
         else
           v_result := c_cant_add_pay;
         end if;
       else
        v_result := c_invalid_abon;
      end if; 
    elsif v_res = 5 then
      v_result := c_dublicate_pay; 
    else
      v_result := c_cant_add_pay;
    end if;
    -- ������ ��������� ������
    p_result := v_result; 
  end;
  --
  -- ��������� ��������� ������ � ������
  --
  procedure add_request_to_log( p_paysys_num  in  integer,
                                p_account     in  varchar2,
                                p_trans_id    in  varchar2,
                                p_pay_date    in  varchar2,
                                p_pay_amount  in  varchar2,
                                p_req_type    in  varchar2,
                                p_response    in  varchar2,
                                p_pay_srv     in  varchar2,
                                p_remote_addr in  varchar2,
                                p_request     in  varchar2) is
     
  begin
    --if (p_req_type = c_op_pay) then
      insert into pay_log$(plog_id, plog_log_date, plog_paysys_name, plog_account, plog_trans_id, plog_pay_date, plog_pay_amount, plog_req_type, plog_response, plog_pay_srv, plog_in_ip, plog_request, plog_inf_num)
                    values(plog$_seq.nextval, sysdate, get_pay_system_name(p_paysys_num), p_account, p_trans_id, p_pay_date, p_pay_amount, p_req_type, p_response, p_pay_srv, p_remote_addr, p_request, c_cur_inf_num);
    --end if;
  end;
  --
  -- ��������� ��������� "," � �������� ����������� ������� ����� �����
  --
  procedure set_comma is
  begin
    execute immediate 'alter session set nls_numeric_characters='',.''';
  end;
  --
  -- ��������� ��������� "." � �������� ����������� ������� ����� �����
  --
  procedure set_dot is
  begin
    execute immediate 'alter session set nls_numeric_characters=''.,''';
  end;
  --
begin
  set_dot;
end pay_p_$utils;
/
