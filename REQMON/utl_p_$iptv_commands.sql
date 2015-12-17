create or replace package utl_p_$iptv_commands is
/*
  Author  : V.ERIN
  Created : 21.09.2014 12:00:00
  Purpose : ������� ��� �������� ���������� ������� �� ����� 
  Version : 1.1.04
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    17/10/2014     �������� ������
  -------------------------------------------------------------------------------------------------
  V.ERIN    01/01/2015     �������������� ������ � middleware
  -------------------------------------------------------------------------------------------------
  V.ERIN    01/05/2015     ��������� ������ � ���������� ������ (0 - ��������� 1- ��������)
  -------------------------------------------------------------------------------------------------
  V.ERIN    15/07/2015     ��������� ������ � ������� � ��������� ��������
  -------------------------------------------------------------------------------------------------
  V.ERIN    12/10/2015     ��������� ������ � ��������
  -------------------------------------------------------------------------------------------------
*/
  -- ���������
  c_iptv_req_name constant varchar2(50) := 'IPTV_REQ_CMD';
  c_iptv_msg_num  constant number       := 50;
  c_iptv_msg_param_num  constant number := 52;
  c_state_msg_num constant number       := 51;
  c_job_name      constant varchar2(50) := 'IPTV_SCAN';
  -- ���� ������
  c_create_iptv_abonent        constant number := 1;
  c_ch_type_iptv_abonent       constant number := 2;
  c_ch_name_iptv_abonent       constant number := 3;
  c_delete_iptv_abonent        constant number := 4;
  c_ch_maxterm_iptv_abonent    constant number := 5;
  c_set_disabled_iptv_abonent  constant number := 6;
  c_set_enabled_iptv_abonent   constant number := 7;
  c_ch_address_iptv_abonent    constant number := 8;
  c_ch_segment_iptv_abonent    constant number := 9;
  c_add_pack_iptv_abonent      constant number := 10;
  c_del_pack_iptv_abonent      constant number := 11;
  -- ��������� ������
  c_param_id      constant number       := 64;
  c_state_on_txt  constant varchar2(50) := 'ENABLED';
  c_state_off_txt constant varchar2(50) := 'DISABLED';
  c_st_on_param   constant varchar2(50) := '����������';
  c_st_off_param  constant varchar2(50) := '�� ����������';
  c_branch        constant varchar2(50) := 'M2000';
  c_state_on      constant number := 1;
  c_state_off     constant number := 0;
  -- IPTV
  iptv_url        varchar2(50)  := '10.15.5.19/iptv/iptv.php';
  --
  -- ������� �������� ������ �� �������� ������� IPTV
  --
  function req_iptv_create(p_account     in varchar2,
                           p_reqtype     in number,
                           p_password    in varchar2,
                           p_name        in varchar2,
                           p_branch      in varchar2,
                           p_state       in varchar2,
                           p_packages    in varchar2,
                           p_type        in number,
                           p_maxterm     in number) return number;
  --
  -- ��������� ������������ ��������� iptv
  --
  procedure scan;
  --
  -- ��������� "�������" ������������ ��������� 
  --
  procedure scan_forward;
  --
  -- ��������� "���������" ������������ ���������
  --
  procedure scan_backward;
  --
  -- ��������� "�������" ������������ ������� ���������� ��������� iptv
  --
  procedure scan_pack_forward;
  --
  -- ��������� "���������" ������������ ������� ���������� ��������� iptv
  --
  procedure scan_pack_backward;
  --
  -- ��������� �������� �������� ������������ ������
  --
  procedure create_scan_jobs;
  --
  -- ��������� �������� �������� ������������ ������
  --
  procedure drop_scan_jobs;
  --
  -- ��������� ��������� ��������������� ��������� ��������
  --
  procedure set_add_param(p_account in varchar2, p_reqtype in number);
  --
end utl_p_$iptv_commands;
/
create or replace package body utl_p_$iptv_commands is
  --
  -- ��������� ��������� ��������������� ��������� ��������
  --
  procedure set_add_param(p_account in varchar2, p_reqtype in number) is
    v_abonent_id   number := null;
    v_add_param_id number := null;
    v_state        varchar2(50) := null;
    -- �������� �� ��������
    procedure get_abonent_id is
    begin
      select id into v_abonent_id from cifra.ao_abonent ab where ab.card_num = p_account;
    exception 
      when no_data_found or too_many_rows then  null;
    end;
    -- �������� �� ���������
    procedure get_abonent_param_id is
    begin
      select id into v_add_param_id from cifra.ao_attrib_values av where av.attrib_type_id = c_param_id and av.rec_id = v_abonent_id;
    exception 
      when no_data_found or too_many_rows then  null;
    end;
  begin
    if (p_reqtype in (c_create_iptv_abonent, c_set_enabled_iptv_abonent)) then
      v_state := c_st_on_param;
    elsif (p_reqtype in (c_delete_iptv_abonent, c_set_disabled_iptv_abonent)) then
      v_state := c_st_off_param;
    end if;
    get_abonent_id;
    if (v_abonent_id is not null) and (v_state is not null) then
      get_abonent_param_id;
      if v_add_param_id is null then
        insert into cifra.ao_attrib_values (id, attrib_type_id, rec_id, value)
                                    values (cifra.ao_attrib_values_seq.nextval, c_param_id, v_abonent_id, v_state);
      else
        update cifra.ao_attrib_values av set av.value = v_state where av.id = v_add_param_id; 
      end if;
    end if;
  end;
  --
  -- ������� �������� ������ �� �������� ������� IPTV
  --
  function req_iptv_create(p_account     in varchar2,
                           p_reqtype     in number,
                           p_password    in varchar2,
                           p_name        in varchar2,
                           p_branch      in varchar2,
                           p_state       in varchar2,
                           p_packages    in varchar2,
                           p_type        in number,
                           p_maxterm     in number) return number is
    v_account  varchar2(50):= p_account;
    v_params   varchar2(2000); 
    v_req      number      := req_p_$process.c_new_req_id;
  begin
    -- ������ �� ��������� IPTV
    v_params := 'reqtype:'||p_reqtype||';account:'||v_account||';password:'||p_password||';name:'||p_name||';branch:'||p_branch||';state:'||p_state||
                ';packages:'||p_packages||';type:'||p_type||';maxterm:'||p_maxterm; 
    v_req := req_p_$process.req_create( p_rqst_name       => c_iptv_req_name,
                                        p_rqst_id         => v_req,
                                        p_rqst_num        => 1,
                                        p_rqst_rqtm_id    => c_iptv_msg_num,
                                        p_rqst_type       => req_p_$process.c_iptv_req,
                                        p_rqst_dst        => iptv_url,
                                        p_rqst_account    => v_account,
                                        p_rqst_add_params => v_params,
                                        p_rqst_priority   => req_p_$process.c_prty_hi);
    if p_reqtype in (c_create_iptv_abonent, c_delete_iptv_abonent, c_set_enabled_iptv_abonent, c_set_disabled_iptv_abonent) then
      -- ������ �� ��������� ������������
      v_params := 'reqtype:'||p_reqtype||';account:'||v_account; 
      v_req := req_p_$process.req_create( p_rqst_name       => c_iptv_req_name,
                                          p_rqst_id         => v_req,
                                          p_rqst_num        => 2,
                                          p_rqst_rqtm_id    => c_state_msg_num,
                                          p_rqst_type       => req_p_$process.c_plsql_req,
                                          p_rqst_dst        => 'PLSQL',
                                          p_rqst_account    => v_account,
                                          p_rqst_add_params => v_params,
                                          p_rqst_priority   => req_p_$process.c_prty_hi);
    end if;
    return v_req;
  end;
  --
  -- ������� �������� ������ �� ��������� ���������� �������� IPTV
  --
  function req_iptv_change(p_account     in varchar2,
                           p_reqtype     in number,
                           p_param       in varchar2) return number is
    v_account  varchar2(50):= p_account;
    v_params   varchar2(2000); 
    v_req      number      := req_p_$process.c_new_req_id;
  begin
    -- ������ �� ��������� IPTV
    v_params := 'reqtype:'||p_reqtype||';account:'||v_account||';param:'||p_param; 
    v_req := req_p_$process.req_create( p_rqst_name       => c_iptv_req_name,
                                        p_rqst_id         => v_req,
                                        p_rqst_num        => 1,
                                        p_rqst_rqtm_id    => c_iptv_msg_param_num,
                                        p_rqst_type       => req_p_$process.c_iptv_req,
                                        p_rqst_dst        => iptv_url,
                                        p_rqst_account    => v_account,
                                        p_rqst_add_params => v_params,
                                        p_rqst_priority   => req_p_$process.c_prty_hi);
    return v_req;
  end;
  --
  -- ��������� ������������ ��������� iptv
  --
  procedure scan is
  begin
    -- ��������� ��������� �� ��������
    scan_forward;
    -- ��������� ��������� �� midleware
    scan_backward;
    -- ��������� ���������
    scan_pack_forward;
    scan_pack_backward;
  end;
  --
  -- ��������� "���������" ������������ ������� ���������� ��������� iptv
  --
  procedure scan_pack_backward is
    v_req number;
    --  ������� �����
    procedure del_pack(p_abon_num in varchar2, p_pack_num in varchar2) is
    begin
      delete from req_iptv_abon_packages$ 
            where abon_num = p_abon_num 
              and package = p_pack_num;
    end;
    -- ����������, ��� �� ����� �������� �����
    function is_pack_exist(p_abon_num in varchar2, p_pack_num in varchar2) return boolean is
      v_cnt number := 0;
    begin
     select count(1) into v_cnt 
       from iptv_abon_packages$ ap 
      where ap.abon_num = p_abon_num
        and ap.package = p_pack_num; 
      return v_cnt > 0; 
    end;
  begin
    -- �������� �� ���� ������� ���������
    for iptv_pack_rec in ( select rap.abon_num      abon_num, 
                                  rap.package       package
                             from req_iptv_abon_packages$ rap ) loop
        if (not is_pack_exist(iptv_pack_rec.abon_num, iptv_pack_rec.package)) then
             -- ������� ������ �� �������� ������
          v_req := req_iptv_change(p_account     => iptv_pack_rec.abon_num,
                                   p_reqtype     => c_del_pack_iptv_abonent, 
                                   p_param       => iptv_pack_rec.package);
          del_pack(iptv_pack_rec.abon_num, iptv_pack_rec.package);
          commit;
        end if;
    end loop;
  end;
  --
  -- ��������� "���������" ������������ ��������� iptv
  --
  procedure scan_backward is
    v_req      number;
    curr_state varchar2(256);
    --  ������� ��������
    procedure del_abonent(p_abon_num in varchar2) is
    begin
      delete from req_iptv_abonents$ ra where ra.abon_num = p_abon_num;
    end;
    -- �������� ������� ��������� ������
    function get_curr_state(p_abon_num in varchar2) return varchar2 is
      v_state varchar2(256) := null;
    begin
      begin
        select ra.params into v_state 
          from iptv_abonents$ ra 
         where ra.abon_num = p_abon_num; 
      exception
        when no_data_found or too_many_rows then null;
      end;
      return v_state; 
    end;
  begin
    -- �������� �� ���� ��������� ������� �� ������ � ���� ���������
    for iptv_rec in ( select ab.abon_num      abon_num, 
                             ab.pswd          pswd, 
                             ab.params        params,
                             'na'             name,
                             'na'             branch,
                             'na'             state,
                             ab.type          atype,
                             ab.maxterm       maxterm
                        from req_iptv_abonents$ ab ) loop
        --  ���������� ��������� ������
        curr_state := get_curr_state(iptv_rec.abon_num);
        if curr_state is null then
           -- ������� ��������
           del_abonent(iptv_rec.abon_num);
           -- ������� ������ �� ��������
           v_req := req_iptv_create(p_account     => iptv_rec.abon_num,
                                    p_reqtype     => c_delete_iptv_abonent,
                                    p_password    => iptv_rec.pswd,
                                    p_name        => iptv_rec.name,
                                    p_branch      => iptv_rec.branch,
                                    p_state       => iptv_rec.state,
                                    p_packages    => iptv_rec.params,
                                    p_type        => iptv_rec.atype,
                                    p_maxterm     => iptv_rec.maxterm);
        end if;
        commit;
    end loop;
  end;
  --
  -- ��������� "�������" ������������ ������� ���������� ��������� iptv
  --
  procedure scan_pack_forward is
    v_req number;
    --  ��������� �����
    procedure add_pack(p_abon_num in varchar2, p_pack_num in varchar2) is
    begin
      insert into req_iptv_abon_packages$(abon_num, package)
                                   values(p_abon_num, p_pack_num);
    end;
    -- ����������, ��� �� ����� �������� �����
    function is_pack_exist(p_abon_num in varchar2, p_pack_num in varchar2) return boolean is
      v_cnt number := 0;
    begin
     select count(1) into v_cnt 
       from req_iptv_abon_packages$ rap 
      where rap.abon_num = p_abon_num
        and rap.package = p_pack_num; 
      return v_cnt > 0; 
    end;
  begin
    -- �������� �� ���� ������� ���������
    for iptv_pack_rec in ( select abp.abon_num      abon_num, 
                                  abp.package       package
                             from iptv_abon_packages$ abp ) loop
        if (not is_pack_exist(iptv_pack_rec.abon_num, iptv_pack_rec.package)) then
             -- ������� ������ �� ���������� ������
          v_req := req_iptv_change(p_account     => iptv_pack_rec.abon_num,
                                   p_reqtype     => c_add_pack_iptv_abonent, 
                                   p_param       => iptv_pack_rec.package);
          add_pack(iptv_pack_rec.abon_num, iptv_pack_rec.package);
          commit;
        end if;
    end loop;
  end;
  --
  -- ��������� "�������" ������������ ��������� iptv
  --
  procedure scan_forward is
    v_req       number;
    last_state req_iptv_abonents$%rowtype;
    v_state_req number := null;
    --  ��������� ��������
    procedure add_abonent(p_abon_num in varchar2, 
                          p_pswd     in varchar2, 
                          p_params   in varchar2, 
                          p_name     in varchar2,
                          p_type     in number,
                          p_maxterm  in number,
                          p_state    in number) is
    begin
      insert into req_iptv_abonents$ (abon_num, pswd, params, name, type, maxterm, state) 
                              values (p_abon_num, p_pswd, p_params, p_name, p_type, p_maxterm, p_state);
    end;
    --  �������� �� ������
    procedure set_params(p_abon_num in varchar2, p_params in varchar2) is
    begin
      update req_iptv_abonents$ rqa 
         set rqa.params = p_params 
       where rqa.abon_num = p_abon_num; 
    end;
    --  �������� ��� ������
    procedure set_type(p_abon_num in varchar2, p_type in number) is
    begin
      update req_iptv_abonents$ rqa 
         set rqa.type = p_type 
       where rqa.abon_num = p_abon_num; 
    end;
    --  �������� ��� ��������
    procedure set_name(p_abon_num in varchar2, p_name in varchar2) is
    begin
      update req_iptv_abonents$ rqa 
         set rqa.name = p_name 
       where rqa.abon_num = p_abon_num; 
    end;
    --  �������� ���������� ����������
    procedure set_maxterm(p_abon_num in varchar2, p_maxterm in number) is
    begin
      update req_iptv_abonents$ rqa 
         set rqa.maxterm = p_maxterm 
       where rqa.abon_num = p_abon_num; 
    end;
    --  �������� �������� ������
    procedure set_state(p_abon_num in varchar2, p_state in number) is
    begin
      update req_iptv_abonents$ rqa 
         set rqa.state = p_state 
       where rqa.abon_num = p_abon_num; 
    end;
    --  �������� ������� ��������
    procedure set_segment(p_abon_num in varchar2, p_segment in varchar2) is
    begin
      update req_iptv_abonents$ rqa 
         set rqa.segment = p_segment 
       where rqa.abon_num = p_abon_num; 
    end;
    --  �������� ������ ��������
    procedure set_address(p_abon_num in varchar2, p_address in varchar2) is
    begin
      update req_iptv_abonents$ rqa 
         set rqa.address = p_address 
       where rqa.abon_num = p_abon_num; 
    end;
    -- �������� ���������� ��������� ������
    function get_last_state(p_abon_num in varchar2) return req_iptv_abonents$%rowtype is
      v_state req_iptv_abonents$%rowtype;
    begin
      v_state.abon_num := null;
      begin
        select rqa.* into v_state 
          from req_iptv_abonents$ rqa 
         where rqa.abon_num = p_abon_num; 
      exception
        when no_data_found then null;
      end;
      return v_state; 
    end;
  begin
    -- �������� �� ���� ��������� � ������� ���������� ������ iptv
    for iptv_rec in ( select ab.abon_num, 
                             ab.pswd,
                             ab.params, 
                             ab.name,
                             ab.branch,
                             decode(ab.state, c_state_on, c_state_on_txt, c_state_off_txt) txtstate,
                             ab.atype,
                             ab.maxterm,
                             ab.state,
                             ab.address,
                             ab.segment
                        from iptv_abonents$ ab ) loop
        --  ���������� ������� ��������� ������
        last_state := get_last_state(iptv_rec.abon_num);
        if last_state.abon_num is null then
           -- ������� ������ �� ����������
           v_req := req_iptv_create(p_account     => iptv_rec.abon_num,
                                    p_reqtype     => c_create_iptv_abonent,
                                    p_password    => iptv_rec.pswd,
                                    p_name        => iptv_rec.name,
                                    p_branch      => iptv_rec.branch,
                                    p_state       => iptv_rec.txtstate,
                                    p_packages    => iptv_rec.params,
                                    p_type        => iptv_rec.atype,
                                    p_maxterm     => iptv_rec.maxterm);
           -- ��������� ��������
           add_abonent(iptv_rec.abon_num, iptv_rec.pswd, iptv_rec.params, iptv_rec.name, iptv_rec.atype, iptv_rec.maxterm, iptv_rec.state);
        else
          if (last_state.params <> iptv_rec.state) then
             -- �������� ��������� ��������
             set_params(iptv_rec.abon_num, iptv_rec.params);
          end if;
          --
          if (last_state.type is null) or (last_state.type <> iptv_rec.atype) then
             -- ������� ������ �� ��������� ����
             v_req := req_iptv_create(p_account     => iptv_rec.abon_num,
                                      p_reqtype     => c_ch_type_iptv_abonent,
                                      p_password    => iptv_rec.pswd,
                                      p_name        => iptv_rec.name,
                                      p_branch      => iptv_rec.branch,
                                      p_state       => iptv_rec.txtstate,
                                      p_packages    => iptv_rec.params,
                                      p_type        => iptv_rec.atype,
                                      p_maxterm     => iptv_rec.maxterm);
             -- �������� ��� ��������
             set_type(iptv_rec.abon_num, iptv_rec.atype);
          end if;
          --
          if (last_state.name <> iptv_rec.name) then
             -- ������� ������ �� ��������� �����
             v_req := req_iptv_create(p_account     => iptv_rec.abon_num,
                                      p_reqtype     => c_ch_name_iptv_abonent,
                                      p_password    => iptv_rec.pswd,
                                      p_name        => iptv_rec.name,
                                      p_branch      => iptv_rec.branch,
                                      p_state       => iptv_rec.txtstate,
                                      p_packages    => iptv_rec.params,
                                      p_type        => iptv_rec.atype,
                                      p_maxterm     => iptv_rec.maxterm);
             -- �������� ��� ��������
             set_name(iptv_rec.abon_num, iptv_rec.name);
          end if;
          --
          if (last_state.maxterm is null) or (last_state.maxterm <> iptv_rec.maxterm) then
             -- ������� ������ �� ��������� ���������� ����������
             v_req := req_iptv_create(p_account     => iptv_rec.abon_num,
                                      p_reqtype     => c_ch_maxterm_iptv_abonent,
                                      p_password    => iptv_rec.pswd,
                                      p_name        => iptv_rec.name,
                                      p_branch      => iptv_rec.branch,
                                      p_state       => iptv_rec.txtstate,
                                      p_packages    => iptv_rec.params,
                                      p_type        => iptv_rec.atype,
                                      p_maxterm     => iptv_rec.maxterm);
             -- �������� ���������� ���������� ��������
             set_maxterm(iptv_rec.abon_num, iptv_rec.maxterm);
          end if;
          --
          if (last_state.state is null) or (last_state.state <> iptv_rec.state) then
             if (iptv_rec.state = c_state_off) then
               v_state_req := c_set_disabled_iptv_abonent;
             elsif (iptv_rec.state = c_state_on) then
               v_state_req := c_set_enabled_iptv_abonent;
             end if;
             -- ������� ������ �� ��������� ��������� �������
             if (last_state.state is not null) then
               v_req := req_iptv_create(p_account     => iptv_rec.abon_num,
                                        p_reqtype     => v_state_req,
                                        p_password    => iptv_rec.pswd,
                                        p_name        => iptv_rec.name,
                                        p_branch      => iptv_rec.branch,
                                        p_state       => iptv_rec.txtstate,
                                        p_packages    => iptv_rec.params,
                                        p_type        => iptv_rec.atype,
                                        p_maxterm     => iptv_rec.maxterm);
             end if;
             -- �������� ��������� �������
             set_state(iptv_rec.abon_num, iptv_rec.state);
          end if;
          --
          if (last_state.address is null) then
             -- ������� ������ �� ��������� ������
             v_req := req_iptv_change(p_account     => iptv_rec.abon_num,
                                      p_reqtype     => c_ch_address_iptv_abonent, 
                                      p_param       => iptv_rec.address);
             -- �������� ������
             set_address(iptv_rec.abon_num, iptv_rec.address);
          end if;
          --
          if (last_state.segment is null) then
             -- ������� ������ �� ��������� ��������
             v_req := req_iptv_change(p_account     => iptv_rec.abon_num,
                                      p_reqtype     => c_ch_segment_iptv_abonent, 
                                      p_param       => iptv_rec.segment);
             -- �������� �������
             set_segment(iptv_rec.abon_num, iptv_rec.segment);
          end if;
        end if;
        commit;
    end loop;
  end;
  --
  -- ��������� �������� �������� ������������ ������
  --
  procedure create_scan_jobs is
    v_job_start_date date;
  begin
    -- ������� ������� 
    v_job_start_date := sysdate+((1/(24*60)));
    dbms_scheduler.create_job(job_name            => c_job_name,
                              job_type            => 'PLSQL_BLOCK',
                              job_action          => 'begin utl_p_$iptv_commands.scan; end; ',
                              start_date          => v_job_start_date,
                              repeat_interval     => 'freq=minutely;interval=1',
                              end_date            => to_date(null),
                              job_class           => 'DEFAULT_JOB_CLASS',
                              enabled             => true,
                              auto_drop           => false,
                              comments            => '������� �������� ������ �� ��������� IPTV');
    commit;
  end;
  --
  -- ��������� �������� �������� ������������ ������
  --
  procedure drop_scan_jobs is
  begin  
    dbms_scheduler.drop_job(c_job_name);
  end;
  --
end utl_p_$iptv_commands;
/
