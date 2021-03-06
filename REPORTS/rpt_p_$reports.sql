create or replace package rpt_p_$reports is
/*
  Author  : V.ERIN
  Created : 01.12.2014 12:00:00
  Version : 1.0.03
  Purpose : ������� ��� �������� ������������� ������� � �������� �� �� �����.
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    01/12/2014     �������� ������
  -------------------------------------------------------------------------------------------------
  V.ERIN    08/02/2015     ������� ����� ��������� �������� email
  -------------------------------------------------------------------------------------------------
  V.ERIN    05/04/2015     �������� ����� ������� � ������� MIS
  -------------------------------------------------------------------------------------------------
  V.ERIN    08/04/2015     ��������� ��������� ������ �� �������� SMS
  -------------------------------------------------------------------------------------------------
*/
  -- ���������
  c_job_name         constant varchar2(50)  := 'REP_';
  c_cr_lf            constant varchar2(10)  := utl_tcp.crlf;
  c_alarm_threshold  constant integer       := rpt_p_$utils.get_param_value('ALARM_THRESHOLD',1000);
  c_alarm_mail       constant varchar2(256) := rpt_p_$utils.get_param_value('ALARM_MAIL','bill@cifra1.ru');
  c_cdr_rep_mail     constant varchar2(256) := rpt_p_$utils.get_param_value('CDR_REP_MAIL');
  c_net_rep_mail     constant varchar2(256) := rpt_p_$utils.get_param_value('NET_REP_MAIL');
  c_req_rep_mail     constant varchar2(256) := rpt_p_$utils.get_param_value('REQ_REP_MAIL');
  c_pay_rep_mail     constant varchar2(256) := rpt_p_$utils.get_param_value('PAY_REP_MAIL');
  c_ora_adm_mail     constant varchar2(256) := rpt_p_$utils.get_param_value('ORA_ADM_MAIL');
  c_sms_rep_mail     constant varchar2(256) := rpt_p_$utils.get_param_value('SMS_REP_MAIL');
  c_req_rep_sms      constant varchar2(256) := rpt_p_$utils.get_param_value('REQ_REP_SMS');
  c_pay_cnt_name     constant varchar2(50)  := 'PAY_CNT';
  c_netflow_name     constant varchar2(50)  := 'NETFLOW_DATE';
  --
  -- ��������� ���������� ������ �� �������� SMS
  --
  procedure sms_stat_rpt;
  --
  -- ��������� ���������� ������ � ������� �������
  --
  procedure mgf_stat_rpt;
  --
  -- ��������� ���������� ������ � �������
  --
  procedure cdr_stat_rpt;
  --
  -- ��������� ���������� ������ � ����������������� ���������� NETFLOW
  --
  procedure net_stat_rpt;
  --
  -- ��������� ���������� ������ � ����������������� ����
  --
  procedure ora_stat_rpt;
  --
  -- ��������� ���������� ��������������� ������ �� ��������
  --
  procedure all_filial_stat_rpt;
  --
  -- ��������� ���������� � �������� ��������������� ������ � ��������� �������
  --
  procedure req_stat_rpt;
  --
  -- ��������� ���������� � �������� ��������������� ������ � ��������
  --
  procedure pay_stat_rpt;
  --
  -- ��������� �������� �������� �������� ������
  --
  procedure create_rpt_jobs(p_rpt_proc_name in varchar2, p_start_date in date, p_interval in varchar2 default null);
  --
  -- ��������� �������� �������� �������� ������
  --
  procedure drop_rpt_jobs(p_rpt_proc_name in varchar2);
  --
end rpt_p_$reports;
/
create or replace package body rpt_p_$reports is
  --
  -- ��������� ���������� ������ �� �������� SMS
  --
  procedure sms_stat_rpt is
    v_rep_sql  varchar2(2000) := '';
    v_ret      number;
    v_subject  varchar2(256)   := '����� �� �������� SMS �� '||to_char(sysdate-1, 'dd.mm.yyyy');
  begin
    v_rep_sql := 'select decode(grouping(sl.sms_name),1,''�����'',sl.sms_name) "��� SMS", '||
                 '       count(1) "���������� SMS",'||
                 '       to_char(sum(sl.sms_parts))||'' �.'' "���������"  '||
                 '  from sms_log$ sl '||
                 ' where trunc(sl.sms_date,''MM'') = trunc(sysdate-1,''MM'')'||
                 ' group by rollup(sl.sms_name)';
    v_ret := reqmon.utl_p_$mail_reports.send_report(p_mail_receiver => c_sms_rep_mail,
                                                    p_rep_name      => v_subject,
                                                    p_rep_sql       => v_rep_sql);
    if v_ret <> 0 then
      raise_application_error(-20000, 'Not sent. Error : '||to_char(v_ret));
    end if;
  end;
  --
  -- ��������� ���������� ������ � ������� �������
  --
  procedure mgf_stat_rpt is
    v_rep_sql   varchar2(2000) := '';
    v_ret       number;
    v_rep_data  reqmon.utl_p_$send_messages.text_table_t := reqmon.utl_p_$send_messages.text_table_t(null); 
    v_data      utl_p_$send_reports.text_table_t@dbl_mis := utl_p_$send_reports.text_table_t@dbl_mis(null);
    v_subject   varchar2(256)   := '����� � ������� ������� �� '||to_char(sysdate, 'dd.mm.yyyy hh24:mi');
  begin
    v_rep_sql := 'select to_char(trunc(m.dt), ''dd.mm.yyyy'') dat, count(1) cnt_calls, round(sum(m.real_duration/60), 2) duration  '||
                 '  from mis_cdr m '||
                 '  join information@dbl_bill i on trunc(sysdate-1) between INF_BDATE and nvl(INF_EDATE, to_date(''01.01.2099'',''dd.mm.yyyy''))'||
                 ' where m.period_id = i.inf_num and station_id =100 and m.out_TRANK_ID=22121 '||
                 ' group by trunc(m.dt) order by trunc(m.dt)';
    v_ret := utl_p_$send_reports.make_report_data@dbl_mis(v_rep_sql, v_data, ';');
    if v_ret <> 0 then
      raise_application_error(-20000, 'Not sent. Error : '||to_char(v_ret));
    else
      for i in 1..v_data.last loop
         v_rep_data.extend;
         v_rep_data(v_rep_data.last) :=  v_data(i);
      end loop;
      v_ret := reqmon.utl_p_$send_messages.send_mail(c_cdr_rep_mail, v_subject, v_subject, v_subject||'.csv' , v_rep_data);
      if v_ret <> 0 then
         raise_application_error(-20000, 'Not sent. Error : '||to_char(v_ret));
      end if;
    end if;
    rollback;
  end;
  --
  -- ��������� ���������� ������ � �������
  --
  procedure cdr_stat_rpt is
    v_rep_sql  varchar2(2000) := '';
    v_ret      number;
    v_subject  varchar2(256)   := '����� � ������� �� '||to_char(sysdate, 'dd.mm.yyyy hh24:mi');
  begin
    v_rep_sql := 'select to_char(trunc(m.dt), ''dd.mm.yyyy'') dat, count(1) cnt_calls, round(sum(m.real_duration/60), 2) duration '||
                 '  from mis.mis_cdr m '||
                 '  join cifra.information i on trunc(sysdate-1) between INF_BDATE and nvl(INF_EDATE, to_date(''01.01.2099'',''dd.mm.yyyy'')) '||
                 ' where i.inf_num = m.period_id and m.station_id = ''13''' ||
                 '   and ( regexp_like(m.out_trank, ''C12700[7,8]'') or regexp_like(m.out_trank, ''C12702[6,7]'') )'||
                 ' group by trunc(m.dt) order by trunc(m.dt)';
    v_ret := reqmon.utl_p_$mail_reports.send_report(p_mail_receiver => c_cdr_rep_mail,
                                                    p_rep_name      => v_subject,
                                                    p_rep_sql       => v_rep_sql);
    if v_ret <> 0 then
      raise_application_error(-20000, 'Not sent. Error : '||to_char(v_ret));
    end if;
  end;
  --
  -- ��������� ���������� ������ � ����������������� ���������� NETFLOW
  --
  procedure net_stat_rpt is
    v_msg_body  varchar2(32767) := '';
    v_ret       reqmon.utl_p_$send_messages.http_resp_t;
    v_subject   varchar2(256)   := '����� � �������� ������� NETFLOW �� '||to_char(sysdate, 'dd.mm.yyyy hh24:mi');
  begin
    for tbspce_rec in (select count(1) cnt, 
                              to_char(trunc(t.bdate,'hh24'),'dd.mm.yyyy hh24:mi')||' - '||to_char(trunc(t.edate,'hh24'),'hh24:mi') dt 
                        from cifra.m3_traf_flows t  
                       where t.bdate > trunc(sysdate)-1/86400 group by trunc(t.bdate,'hh24'), trunc(t.edate,'hh24') order by 2 desc) loop
        v_msg_body := v_msg_body||'����: '||tbspce_rec.dt||' ��������� �������: '||tbspce_rec.cnt||c_cr_lf;
    end loop;
      -- ���������� ����� ���� ���� ����������.
    if (c_net_rep_mail is not null) then
       if (v_msg_body is null) then
         v_msg_body := '�� ������ ���� �� ���������� ������� NETFLOW.';  
       end if;
       v_ret.resp_code := reqmon.utl_p_$send_messages.send_mail(p_mail_receiver => c_net_rep_mail,
                                                                p_mail_subject  => v_subject,
                                                                p_mail_message  => v_msg_body); 
    end if;
  end;
  --
  -- ��������� ���������� ������ � ����������������� ����
  --
  procedure ora_stat_rpt is
    v_usage_table_thr integer := 95;
    v_msg_body  varchar2(32767) := '';
    v_ret       reqmon.utl_p_$send_messages.http_resp_t;
    v_subject   varchar2(256)   := '����� � ������������� ���������� ������������ �� '||to_char(sysdate, 'dd.mm.yyyy');
  begin
    for tbspce_rec in (select tum.tablespace_name tblspace_name, round(tum.used_percent,2) usage  
                         from dba_tablespace_usage_metrics tum 
                        where round(tum.used_percent) > v_usage_table_thr) loop
        v_msg_body := v_msg_body||'TABLESPACE: '||tbspce_rec.tblspace_name||' usage (%) '||tbspce_rec.usage;
    end loop;
    -- ���������� ����� ���� ���� ����������.
    if (v_msg_body is not null) then
       v_ret.resp_code := reqmon.utl_p_$send_messages.send_mail(p_mail_receiver => c_ora_adm_mail,
                                                                p_mail_subject  => v_subject,
                                                                p_mail_message  => v_msg_body); 
    end if;
  end;
  --
  -- ��������� ���������� ��������������� ������ �� ��������
  --
  procedure all_filial_stat_rpt is
  begin
    execute immediate 'truncate table stat_all_filial_t$';
    execute immediate 'insert into stat_all_filial_t$ select * from stat_all_filial_v$';
    commit;
  end;
  --
  -- ��������� ���������� � �������� ��������������� ������ � ��������� �������
  --
  procedure req_stat_rpt is
    v_msg_body  varchar2(32767) := '����� �� '||to_char(sysdate, 'dd.mm.yyyy hh24:mi')||c_cr_lf||c_cr_lf;
    v_ret       reqmon.utl_p_$send_messages.http_resp_t;
    v_subject   varchar2(256)   := '����� �� �������� ��������� �� '||to_char(sysdate, 'dd.mm.yyyy');
    v_alrm_msg  varchar2(256);
    v_new_cnt   integer;
    v_ok_cnt    integer;
    -- ������� �������� ���������� ������ ��� �������� ���
    function get_req_err_count return integer is
      v_req_cnt   integer;
    begin
      select count(1) cnt into v_req_cnt 
        from reqmon.requests$ rq 
       where trunc(rq.rqst_dt_status) = trunc(sysdate)
         and rq.rqst_type in (reqmon.req_p_$process.c_sms_req, reqmon.req_p_$process.c_mail_req) 
         and rq.rqst_status < 0;
      return v_req_cnt;
    end;
    -- ������� �������� ���������� ������ ��������� ����
    function get_req_count(p_rqst_status in integer) return integer is
      v_req_cnt   integer;
    begin
      select count(1) cnt into v_req_cnt 
        from reqmon.requests$ rq 
       where trunc(rq.rqst_dt_status) = trunc(sysdate)
         and rq.rqst_type in (reqmon.req_p_$process.c_sms_req, reqmon.req_p_$process.c_mail_req) 
         and rq.rqst_status = p_rqst_status;
      return v_req_cnt;
    end;
  begin
    v_new_cnt := get_req_count(reqmon.req_p_$process.c_new_req);
    v_ok_cnt  := get_req_count(reqmon.req_p_$process.c_ok_req);
    -- ���� "�����" ��������� - ���� alarm
    if ( v_new_cnt > c_alarm_threshold ) then
       v_alrm_msg := '���������� ����� ������ : '||to_char(v_new_cnt);
       v_subject  := '��������! �������� �������� � ������ �������� ��������� ���������.';       
       v_ret := reqmon.utl_p_$send_messages.send_sms(p_sms_receiver => c_req_rep_sms,
                                                     p_sms_message  => v_alrm_msg );
       -- ���������� ������ �� ���������� ��������
       v_ret.resp_code := reqmon.utl_p_$send_messages.send_mail(p_mail_receiver => c_alarm_mail,
                                                                p_mail_subject  => v_subject,
                                                                p_mail_message  => v_alrm_msg); 
    end if;
    -- ��������� ������
    v_msg_body := v_msg_body||'����� ������ � ������� "�������" : '||v_new_cnt||c_cr_lf||c_cr_lf;
    v_msg_body := v_msg_body||'����� ������ � ������� "����������" : '||v_ok_cnt||c_cr_lf||c_cr_lf;
    v_msg_body := v_msg_body||'����� ������ ��� ��������� ������ : '||get_req_err_count||c_cr_lf||c_cr_lf;
    v_msg_body := v_msg_body||'�������� �� ����� � �������� ������. '||c_cr_lf;
    -- ��������� ������ ������
    for rpt_rec in (select count(1) cnt, rq.rqst_name rqnm, reqmon.req_p_$process.get_reqst_name(rq.rqst_status) rqst 
                      from reqmon.requests$ rq 
                     where trunc(rq.rqst_dt_status) = trunc(sysdate)
                       and rq.rqst_type in (reqmon.req_p_$process.c_sms_req, reqmon.req_p_$process.c_mail_req)
                     group by rq.rqst_name, rq.rqst_status
                     order by rqst) loop
      v_msg_body := v_msg_body||c_cr_lf||'( ������: '||rpt_rec.rqst||' ) - ��� ��������� : '||rpt_rec.rqnm||' - ����������: '||rpt_rec.cnt||c_cr_lf;
    end loop;
    -- ���������� ����� �� �����
    v_ret.resp_code := reqmon.utl_p_$send_messages.send_mail(p_mail_receiver => c_req_rep_mail,
                                                             p_mail_subject  => v_subject||' (����������: '||v_ok_cnt||')',
                       	                                     p_mail_message  => v_msg_body); 
    if v_ret.resp_code <> 0 then
       raise_application_error(-20000, 'Not sent. Error : '||to_char(v_ret.resp_code)); 
    end if;
  end;
  --
  -- ��������� ���������� � �������� ��������������� ������ � ��������
  --
  procedure pay_stat_rpt is
    v_msg_body   varchar2(32767) := '����� �� '||to_char(sysdate, 'dd.mm.yyyy hh24:mi')||c_cr_lf||c_cr_lf;
    v_ret        reqmon.utl_p_$send_messages.http_resp_t;
    v_subject    varchar2(256)   := '����� �� ����������� �������� �� '||to_char(sysdate,'dd.mm.yyyy');
    v_alrm_msg   varchar2(256)   := '��������! ���������� ����������� �������� �� ���������� �� ������ ����������. ��������� ��������� ����.';
    v_pay_cnt    number := 0;
    v_ptotal_cnt number := rpt_p_$utils.get_param_value(c_pay_cnt_name, 0);
    v_ctotal_cnt number := 0;
    v_rec_num    number := 1;
    -- ������� �������� ���������� ��������
    function get_pay_count return integer is
      v_cnt   integer;
    begin
      select count(1) cnt into v_cnt 
       from payments.pay_log$ t 
      where t.plog_req_type = 'PAY';
      return v_cnt;
    end;
  begin
    v_ctotal_cnt := get_pay_count;
    rpt_p_$utils.set_param_value(c_pay_cnt_name,v_ctotal_cnt);
   -- ���� ������� �� �������� - ���� alarm
    if ( v_ptotal_cnt = v_ctotal_cnt ) then
       v_subject  := '��������! �������� �������� � ������ ���������� �����.';       
       v_ret := reqmon.utl_p_$send_messages.send_sms(p_sms_receiver => c_req_rep_sms,
                                                     p_sms_message  => v_alrm_msg );
       -- ���������� ������ �� ���������� ��������
       v_ret.resp_code := reqmon.utl_p_$send_messages.send_mail(p_mail_receiver => c_alarm_mail,
                                                                p_mail_subject  => v_subject,
                                                                p_mail_message  => v_alrm_msg); 
    end if;
    -- ��������� ������
    v_msg_body := v_msg_body||'����������� �������� �� ������ (��) � ������� �������� ���. '||c_cr_lf;
    -- ��������� ������ ������
    for pay_rec in (select count(1) cnt, 
                           trim(to_char(sum(t.plog_pay_sum),'999999990.00')) amount,
                           t.plog_paysys_name bank
                      from payments.pay_log_v$ t 
                     where t.plog_req_type = 'PAY'
                       and t.plog_result = 'OK' 
                       and trunc(t.plog_log_date) = trunc(sysdate) 
                     group by t.plog_paysys_name 
                     order by 2) loop
      v_msg_body := v_msg_body||c_cr_lf||to_char(v_rec_num,'09')||' ( ����: '||pay_rec.bank||' ) - ����������: '||pay_rec.cnt||' - �����: '||pay_rec.amount||c_cr_lf;
      v_rec_num  := v_rec_num + 1;
      v_pay_cnt  := v_pay_cnt + pay_rec.cnt;
    end loop;
    v_msg_body := v_msg_body||c_cr_lf||'�����: '||v_pay_cnt||c_cr_lf;
    -- ���������� ����� �� �����
    v_ret.resp_code := reqmon.utl_p_$send_messages.send_mail(p_mail_receiver => c_pay_rep_mail,
                                                             p_mail_subject  => v_subject||' (�����: '||v_pay_cnt||')',
                       	                                     p_mail_message  => v_msg_body); 
    if v_ret.resp_code <> 0 then
       raise_application_error(-20000, 'Not sent. Error : '||to_char(v_ret.resp_code)); 
    end if;
  end;
  --
  -- ��������� �������� �������� �������� ������
  --
  procedure create_rpt_jobs(p_rpt_proc_name in varchar2, p_start_date in date, p_interval in varchar2) is
    v_interval varchar2(256);
  begin
    if p_interval is null then
      v_interval := 'freq=hourly;byhour=0,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23';
    else
      v_interval := p_interval;
    end if;
    -- ������� ������� 
    dbms_scheduler.create_job(job_name            => c_job_name||upper(p_rpt_proc_name),
                              job_type            => 'PLSQL_BLOCK',
                              job_action          => 'begin rpt_p_$reports.'||p_rpt_proc_name||'; end; ',
                              start_date          => p_start_date,
                              repeat_interval     => v_interval,
                              end_date            => to_date(null),
                              job_class           => 'DEFAULT_JOB_CLASS',
                              enabled             => false,
                              auto_drop           => false,
                              comments            => '������� ������� �������� ������ '||upper(p_rpt_proc_name));
    commit;
  end;
  --
  -- ��������� �������� �������� �������� ������
  --
  procedure drop_rpt_jobs(p_rpt_proc_name in varchar2) is
  begin  
    dbms_scheduler.drop_job(c_job_name||upper(p_rpt_proc_name));
  end;
begin
  null;
end rpt_p_$reports;
/
