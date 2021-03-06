drop table rpt_parameters$;

create table rpt_parameters$
(
  rppm_id        varchar2(50)   primary key,
  rppm_value     varchar2(256)  not null,
  rppm_text      varchar2(2000) not null
);

insert into rpt_parameters$ values ('ORA_ADM_MAIL','v.erin@cifra1.ru','������� ��� �������� ��������� ��������� � ������ ORACLE.'); 
insert into rpt_parameters$ values ('PAY_REP_MAIL','v.erin@cifra1.ru','������� ��� �������� ��������� ��������� � ������ ��������� �����.'); 
insert into rpt_parameters$ values ('REQ_REP_MAIL','v.erin@cifra1.ru','������� ��� �������� ��������� ��������� � ������ �������� ��������� ������.'); 
insert into rpt_parameters$ values ('NET_REP_MAIL','v.erin@cifra1.ru','������� ��� �������� ��������� ��������� � ������ ������� ���������.'); 
insert into rpt_parameters$ values ('REQ_REP_SMS','+79262005433','������� ��� �������� SMS ��������� � �������� � ������ �������� ��������� ������.'); 
insert into rpt_parameters$ values ('ALARM_MAIL','bill@cifra1.ru','������� ��� �������� ��������� ��������� � ��������� � ������ �������������� ���������.'); 
insert into rpt_parameters$ values ('ALARM_THRESHOLD','1000','���������� ��������� �������� ��������� ������, ������ �������� ���������� ��������������.'); 
insert into rpt_parameters$ values ('CDR_REP_MAIL','v.erin@cifra1.ru','������� ��� �������� ��������� ��������� � �������.'); 
