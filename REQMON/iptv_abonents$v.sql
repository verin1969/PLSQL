create or replace view iptv_abonents$ as
select to_char(ab.card_num)        abon_num,
       nvl(ab.name,'������ �2000') name,
       'M2000'                     branch,
       to_char(ab.id)              pswd,
       498                         params,
       decode(ab.state_id,5,1,0)   atype,
       get_f_$maxterm(ab.id)         maxterm,
       get_f_$servstate(ab.id)       state,
       get_f_$abonent_address(ab.id) address,
       get_f_$abonent_segment(ab.id) segment
  from cifra.m3_services srv, cifra.ao_abonent ab
 where ab.id = srv.abonent_id
   and ((srv.type_id in (64, 65, 70) -- ��������-���������� + Unlim
        and (srv.state_dt < sysdate and (srv.edate is null or srv.edate > sysdate))
        and srv.plan_id in (select rqp.rqpm_value from req_parameters$ rqp where rqp.rqpm_id like 'IPTV_TP_ID%'))
        or
        (srv.type_id = 72 and srv.state_id = 100003        -- ������ IPTV
        and (srv.state_dt < sysdate and (srv.edate is null or srv.edate > sysdate)))) -- ����������� ������
union
select replace(lab.pin,'-','')         abon_num,
       get_f_$lt_abonent_name(lab.pin) name,
       '����'                          branch,
       lab.p_password                  pswd,
       498 params,
       0 atype,
       get_f_$lt_maxterm(lab.pin)             maxterm,
       1 state,
       get_f_$ltabonent_address(lab.pin) address,
       get_f_$ltabonent_segment(lab.pin) segment
  from lt_abonents$ lab
 where (trim(upper(lab.tarif_name)) like '%������_IPTV%')
    or (trim(upper(lab.tarif_name)) like '%������_IPTV%')
    or (trim(upper(lab.tarif_name)) like '%�����_IPTV%')
    or (trim(upper(lab.tarif_name)) like '%��_3_�_1%')
    or (trim(upper(lab.tarif_name)) like '%3_�_1%')
    or (trim(upper(lab.tarif_name)) like '%��_���������%')
    or (trim(upper(lab.tarif_name)) like '%�����_�����%')
    or (trim(upper(lab.tarif_name)) like '%��������_IPTV_������_NV300%')
    or (trim(upper(lab.tarif_name)) like '%����_IPTV%')
;
