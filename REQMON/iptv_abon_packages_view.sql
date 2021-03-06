create or replace view iptv_abon_packages$ as
select to_char(ab.card_num)            abon_num,
       decode(srv.plan_id, 2900, 500,
                           2901, 499,
                           2902, 501)  package
  from cifra.m3_services srv, cifra.ao_abonent ab
 where ab.id = srv.abonent_id
   and (srv.type_id = 53 -- ���������
    and srv.plan_id in (2900, 2901, 2902) -- �� ������� IPTV
    and srv.state_id = 100003 -- ������ " � ������"
    and (srv.bdate <= sysdate and (srv.edate is null or srv.edate >= sysdate)))
union
select ap.pin,
       case
         when instr(trim(upper(ap.package)),'AMEDIA')   > 0 then 500
         when instr(trim(upper(ap.package)),'��������') > 0 then 501
         when instr(trim(upper(ap.package)),'������')   > 0 then 499
         else -1
       end package 
  from lt_abon_packages$ ap
 where (trim(upper(ap.package)) like '%AMEDIA%')
    or (trim(upper(ap.package)) like '%��������%')
    or (trim(upper(ap.package)) like '%������%');
