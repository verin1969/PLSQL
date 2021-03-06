              select dld.service_id, pt.id
                from (select dd.service_id
                        from cifra.m3_service_dialup_details dd
                       where dd.is_used_vsa = 'Y') dld,
                     (select vv.service_id, vv.value
                        from cifra.m3_vsa_values vv 
                       where vv.vsa_type_id = 71) vsv,
                      cifra.m3_services srv,
                      cifra.m3_plan_types pt,
                      cifra.ao_abonent ab
               where dld.service_id = vsv.service_id(+)
                 and vsv.value is null
                 and srv.id = dld.service_id
                 and srv.edate is null
                 and ab.edate is null
                 and srv.plan_id = pt.id
                 and ab.id = srv.abonent_id
                 and ab.telzone_id in (15, 17)
                 and srv.type_id not in (44)

