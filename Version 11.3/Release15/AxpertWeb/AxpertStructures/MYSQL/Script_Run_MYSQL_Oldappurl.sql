<<

alter table axpages add oldappurl varchar(500);

>>

<<

create or replace
algorithm = UNDEFINED view `axp_appsearch_data_new` as
select
    2 as `SLNO`,
    `axp_appsearch_data_v2`.`HLTYPE` as `HLTYPE`,
    `axp_appsearch_data_v2`.`STRUCTNAME` as `STRUCTNAME`,
    replace(`axp_appsearch_data_v2`.`SEARCHTEXT`, 'View', ' ') as `SEARCHTEXT`,
    `axp_appsearch_data_v2`.`PARAMS` as `PARAMS`,a.oldappurl
from
    axp_appsearch_data_v2 join axpages a on    
   case axp_appsearch_data_v2.hltype when 'iview' then concat('i',axp_appsearch_data_v2.structname) 
   when 'tstruct' then concat('t',axp_appsearch_data_v2.structname) 
   else axp_appsearch_data_v2.structname end = case when axp_appsearch_data_v2.hltype ='Page' then a.name else a.pagetype end 
where
    (not((lower(`axp_appsearch_data_v2`.`PARAMS`) like '%sysdate%')))    
union all
select
    2 as `2`,
    `axp_appsearch_data_v2`.`HLTYPE` as `hltype`,
    `axp_appsearch_data_v2`.`STRUCTNAME` as `structname`,
    trim(replace(`axp_appsearch_data_v2`.`SEARCHTEXT`, 'View', ' ')) as `searchtext`,
    replace(replace(replace(replace(replace(replace(replace(replace(replace(`axp_appsearch_data_v2`.`PARAMS`, 'trunc(add_months(sysdate,0-1),\' MM\')', trim(date_format(((cast((now() + interval (0 - 1) month) as date) - interval dayofmonth((now() + interval (0 - 1) month)) day) + interval 1 day), '%d/%m/%Y'))), 'last_day(add_months(trunc(sysdate),0-1))', trim(date_format(last_day(((cast((now() + interval (0 - 1) month) as date) - interval dayofmonth((now() + interval (0 - 1) month)) day) + interval 1 day)), '%d/%m/%Y'))), 'trunc(sysdate)-1', trim(date_format(cast((now() - interval 1 day) as date), '%d/%m/%Y'))), 'trunc(sysdate)', trim(date_format(cast(now() as date), '%d/%m/%Y'))), 'trunc(sysdate,\' IW\')', trim(date_format(cast((now() - interval weekday(now()) day) as date), '%d/%m/%Y'))), 'trunc(sysdate-7,\' IW\')+6', trim(date_format(cast((((now() - interval 7 day) - interval weekday(now()) day) + interval 6 day) as date), '%d/%m/%Y'))), 'trunc(sysdate-7,\' IW\')', trim(date_format(cast(((now() - interval 7 day) - interval weekday(now()) day) as date), '%d/%m/%Y'))), 'trunc(sysdate,\' MM\')', trim(date_format(cast(((last_day(now()) + interval 1 day) + interval -(1) month) as date), '%d/%m/%Y'))), ' &', '&') as `params`,
	a.oldappurl    
from
    axp_appsearch_data_v2 join axpages a on    
   case axp_appsearch_data_v2.hltype when 'iview' then concat('i',axp_appsearch_data_v2.structname) 
   when 'tstruct' then concat('t',axp_appsearch_data_v2.structname) 
   else axp_appsearch_data_v2.structname end = case when axp_appsearch_data_v2.hltype ='Page' then a.name else a.pagetype end 
where    (lower(`axp_appsearch_data_v2`.`PARAMS`) like '%sysdate%')
union all
select
    1 as `ord`,
    'tstruct' as `hltype`,
    `t`.`name` as `structname`,
    `t`.`caption` as `searchtext`,
    null as `params`,p.oldappurl
from
    tstructs t join axpages p on concat('t',t.name) = p.pagetype 
where
    ((`t`.`blobno` = 1)
        and exists(
        select
            'x'
        from
            axp_vw_menu x
        where
            ((`x`.`PAGETYPE` like 't%')
                and (substr(trim(`x`.`PAGETYPE`), 2, 20) = `t`.`name`)
                    and (not((`x`.`VISIBLE` like '%F%'))))))
union all
select
    0 as `ord`,
    'iview' as `hltype`,
    `i`.`name` as `structname`,
    `i`.`caption` as `searchtext`,
    null as `params`, p.oldappurl
from
    `iviews` `i` join axpages p on concat('i',i.name) = p.pagetype
where
    ((`i`.`blobno` = 1)
        and exists(
        select
            'x'
        from
            `axp_vw_menu` `x`
        where
            ((`x`.`PAGETYPE` like 'i%')
                and (substr(trim(`x`.`PAGETYPE`), 2, 20) = `i`.`name`)
                    and (not((`x`.`VISIBLE` like '%F%'))))))                    
order by
    `SLNO`;
    
   
>> 

<<

   create or replace
algorithm = UNDEFINED view `axp_appsearch` as
select
    distinct `a`.`searchtext` as `SEARCHTEXT`,
    concat(`a`.`params`,(case when ((`a`.`params` is not null) and (not((lower(`a`.`params`) like '%~act%')))) then '~act=load' else null end)) as `PARAMS`,
    `a`.`hltype` as `HLTYPE`,
    `a`.`structname` as `STRUCTNAME`,
    `a`.`username` as `USERNAME`,a.oldappurl
from
    (
    select
        `s`.`SLNO` as `slno`,
        `s`.`SEARCHTEXT` as `searchtext`,
        `s`.`PARAMS` as `params`,
        `s`.`HLTYPE` as `hltype`,
        `s`.`STRUCTNAME` as `structname`,
        `lg`.`username` as `username`,s.oldappurl
    from
        (((`axp_appsearch_data_new` `s`
    join `axuseraccess` `a`)
    join `axusergroups` `g`)
    join `axuserlevelgroups` `lg`)
    where
        ((`a`.`sname` = `s`.`STRUCTNAME`)
            and (`a`.`rname` = `g`.`userroles`)
                and (`g`.`groupname` = `lg`.`usergroup`)
                    and (`a`.`stype` in ('t', 'i')))
    group by
        `s`.`SEARCHTEXT`,
        `s`.`PARAMS`,
        `s`.`HLTYPE`,
        `s`.`STRUCTNAME`,
        `lg`.`username`,
        `s`.`SLNO`,s.oldappurl
union
    select
        `b`.`slno` as `slno`,
        `b`.`searchtext` as `searchtext`,
        `b`.`params` as `params`,
        `b`.`hltype` as `hltype`,
        `b`.`structname` as `structname`,
        `lg`.`username` as `username`,b.oldappurl
    from
        (`axuserlevelgroups` `lg`
    join (
        select
            distinct `s`.`SEARCHTEXT` as `searchtext`,
            `s`.`PARAMS` as `params`,
            `s`.`HLTYPE` as `hltype`,
            `s`.`STRUCTNAME` as `structname`,
            `s`.`SLNO` as `slno`,s.oldappurl
        from
            (`axp_appsearch_data_new` `s`
        left join `axuseraccess` `a` on
            (((`a`.`sname` = `s`.`STRUCTNAME`)
                and (`a`.`stype` in ('t', 'i')))))) `b`)
    where
        (`lg`.`usergroup` = 'default')
    order by
        `slno`,
        `username`) `a`;
        
>>     
       
