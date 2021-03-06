create or replace function get_f_$maxterm(p_account_id in number)return integer is
/*
  Author  : V.ERIN
  Created : 21.02.2015 12:00:00
  Purpose : ������� ��� ����������� ���������� ���������� IPTV
  Version : 1.1.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    21.02.2015     �������� 
  -------------------------------------------------------------------------------------------------
*/
  c_def_maxterm constant integer := 2;
  -- ������������ ��������
  v_retval integer;
  v_stb integer;
begin
  select nvl(sum(nvl(srv.quantity,0)),0) into v_stb
   from cifra.m3_services srv 
  where srv.type_id = 53 
    and srv.state_id = 100003 -- ������ " � ������"
    and srv.plan_id in (2777, 2778, 2783, 1043)
    and (srv.bdate <= sysdate and (srv.edate is null or srv.edate >= sysdate)) 
    and srv.abonent_id = p_account_id;
  if (v_stb = 0) then
    v_retval := c_def_maxterm;
  else
    v_retval := v_stb + 1;
  end if;
  -- ������� ��� �������� 1100001182
  if (p_account_id = 429367) then
    v_retval := 6;
  end if;
  return v_retval;
end get_f_$maxterm;
/
