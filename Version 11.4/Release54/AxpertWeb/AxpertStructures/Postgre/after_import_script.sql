<<
CREATE OR REPLACE FUNCTION fn_get_axpertcomps_name(pinput text)
RETURNS text
LANGUAGE sql
AS $function$
    SELECT string_agg(pout, ',')
    FROM (
        SELECT 
            substring(
                val, 
                position('-(' in val) + 2, 
                length(val) - (position('-(' in val) + 1) - 1
            ) AS pout
        FROM unnest(string_to_array(pinput, ',')) AS val
        WHERE length(pinput) > 2
    ) a;
$function$
;
>> 

<<
CREATE OR REPLACE FUNCTION fn_permissions_getadssql(ptransid character varying, padsname character varying, pcond text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare 
rec record;
v_adssql text;
v_filtersql text;
v_primarydctable varchar;
v_filtercnd text;
v_addpagination varchar;
v_dimensions varchar;
begin




select sqltext,coalesce(pagination,'T') pagination,applydimensions
into v_adssql,v_addpagination,v_dimensions 
from axdirectsql 
where sqlname = padsname;




v_adssql := concat('select --ax_select_columns 
from(
',v_adssql,'
)wpc
',case when v_dimensions='T' then ' --ax_permission_filter
' end,
'--ax_ui_filter_withwhere
',
'--ax_groupby
',
'--ax_orderby
',
case when v_addpagination='T' then '--ax_pagination
'end);

if pcond !='NA' then 


v_filtercnd := concat(' and (',replace(pcond,'{primarytable.}',''),')');
	
v_filtersql := replace(v_adssql,'--ax_permission_filter',concat(' where 1=1 ',v_filtercnd));


end if;

return case when pcond ='NA' then  v_adssql else v_filtersql end;
	
	
END; 
$function$
;
>>

<<
update axdirectsql set sqlsrc ='For developers',sqlsrccnd =2 where sqlsrc ='Internal';
>>

<<
update axdirectsql set sqlsrc='For developers',sqlsrccnd=2  where sqlname in('axcalendarsource','ds_homepage_banner',
'ds_homepage_events',
'ds_homepage_kpicards');
>>

<<
update axdirectsql set sqlsrc='Internal',sqlsrccnd=1  where sqlname in(
'axi_actorlist',
'axi_adscolumnlist',
'axi_adsdropdowntokens',
'axi_adsfilteroperators',
'axi_adslist',
'axi_analyticslist',
'axi_apinameslist',
'axi_cardlist',
'axi_dimensionlist',
'axi_fieldlist',
'axi_fieldvaluelist',
'axi_fieldvalueswithkeysuffixlist',
'axi_firesql',
'axi_formnotifylist',
'Axi_getmetadata',
'axi_iviewlist',
'axi_jobnameslist',
'axi_keyfieldlist',
'axi_keyvalueswithfieldnameslist',
'Axi_metadata_struct_obj',
'axi_pagelist',
'axi_peglist',
'axi_pegnotifylist',
'axi_printformlist',
'axi_rolelist',
'axi_rulenameslist',
'axi_schedulenotifylist',
'axi_servernamelist',
'axi_setfieldlist',
'axi_smartlist_ads_metadata',
'axi_tstructlist',
'axi_tstructprops_insupd',
'axi_usergrouplist',
'axi_userlist',
'axi_userpwd',
'axi_viewlist',
'ds_getsmartlists','Text_Field_Intelligence','ds_smartlist_filters','ds_smartlist_ads_metadata');
>>

<<
update axdirectsql set sqlsrc ='Internal',sqlsrccnd =1 where sqlsrc ='Metadata';
>>

<<
update axdirectsql set sqlsrc ='For users',sqlsrccnd =3 where sqlsrc ='Application';
>>