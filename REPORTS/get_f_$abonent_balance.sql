create or replace function get_f_$abonent_balance(p_account_id in number)return number is
/*
  Author  : V.ERIN
  Created : 25.03.2015 12:00:00
  Purpose : ������� ��� ����������� ������� �������� M2000
  Version : 1.1.02
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    25.03.2015     �������� 
  -------------------------------------------------------------------------------------------------
  V.ERIN    17.10.2015     �������� ������ ����� 
  -------------------------------------------------------------------------------------------------
*/
   v_retval  number := 0;
   v_balance number := 0;
   v_limit   number := 0;
begin
   -- ������ �������� ������� 
   select sum(pa.pay_saldo)
     into v_balance
     from  cifra.pay_abonent pa, 
           cifra.ao_abonent ab                        
    where (pa.pay_abon_num = ab.id)
      and (pa.pay_abon_num = p_account_id)
      and (pa.pay_inf_num = rpt_p_$utils.get_current_period); 
   -- ������ �����
   begin
     select ab.limit
       into v_limit
       from cifra.ao_abonent ab
      where ab.id = p_account_id
        and (ab.bdate  <= sysdate and (ab.edate is null or ab.edate > sysdate));
   exception
     when no_data_found or too_many_rows then null;
   end;
   -- ������ � ������ ������� �����
   v_retval := v_balance + v_limit;
   return v_retval;
   -- ������ �����
end get_f_$abonent_balance;
/
