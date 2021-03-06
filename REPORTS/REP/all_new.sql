select ab.filial,
       ab.card_num, 
       dates.dt, 
       reports.rpt_p_$utils.get_market_segment(ab.id) as segment,
       reports.rpt_p_$utils.get_abon_tpname(ab.id) as tar_plan,
       (select sum(reports.rpt_p_$utils.get_iabonplata(s.id, s.type_id, s.plan_id)) from cifra.m3_services s where s.abonent_id = ab.id) abonplata, 
       '�������� '||reports.rpt_p_$utils.get_abon_addparam_value(ab.id, 32, '') as srv_main
 from (select distinct (a.id) id, 
              a.card_num,
              ltz.ltz_name as filial
         from cifra.ao_abonent a,
              cifra.list_telzone ltz,
              cifra.m3_services srv 
        where ltz.ltz_cod = a.telzone_id
          and srv.type_id in (44, 51, 54, 64, 65, 70) 
          and srv.edate is null 
          and srv.abonent_id = a.id) ab,
      (select dts.column_value as dt from table(reports.rpt_p_$utils.get_dates(to_date('01.06.2015','dd.mm.yyyy'), to_date('30.06.2015','dd.mm.yyyy'))) dts) dates
 where reports.get_f_$abo_first_charge(ab.id, dates.dt) = trunc(dates.dt)
union all
select ab.filial,
       ab.card_num, 
       dates.dt, 
       reports.rpt_p_$utils.get_market_segment(ab.id) as segment,
       reports.rpt_p_$utils.get_abon_tpname(ab.id) as tar_plan,
       (select sum(reports.rpt_p_$utils.get_tabonplata(s.cusl_ucod, s.cusl_vid)) from cifra.cusl s where s.cusl_abon_num = ab.id) abonplata, 
       decode(ab.stype, 17, '��', '���������') as srv_main
 from (select distinct (a.id) id, 
              a.card_num,
              ltz.ltz_name as filial,
              srv.cusl_vid as stype
         from cifra.ao_abonent a,
              cifra.list_telzone ltz,
              cifra.cusl srv 
        where ltz.ltz_cod = a.telzone_id
          and srv.cusl_vid in (1, 17) 
          and srv.cusl_edate is null 
          and srv.cusl_abon_num = a.id) ab,
      (select dts.column_value as dt from table(reports.rpt_p_$utils.get_dates(to_date('01.06.2015','dd.mm.yyyy'), to_date('30.06.2015','dd.mm.yyyy'))) dts) dates
 where reports.get_f_$abo_first_charge(ab.id, dates.dt) = trunc(dates.dt)
order by 3
