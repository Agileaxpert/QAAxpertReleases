<<
CREATE OR REPLACE FUNCTION fn_get_axpertcomps_name (
    pinput IN varchar2
) RETURN CLOB 
IS
    v_result CLOB;
BEGIN
    IF pinput IS NULL OR LENGTH(pinput) <= 2 THEN
        RETURN NULL;
    END IF;

   SELECT
	listagg(rtrim(SUBSTR(split_value, INSTR(split_value, '-(')+ 2), ')'), ',') WITHIN GROUP(
	ORDER BY 1) INTO v_result
FROM
	(
	SELECT
		DISTINCT TRIM(REGEXP_SUBSTR( pinput, '[^,]+', 1, LEVEL)) AS split_value
	FROM
		dual
	CONNECT BY
		REGEXP_SUBSTR ( pinput,
		'[^,]+',
		1,
		LEVEL) IS NOT NULL);

    RETURN v_result;
END;
>>

<<
CREATE OR REPLACE FUNCTION fn_permissions_getadssql (
    ptransid   VARCHAR2,
    padsname   VARCHAR2,
    pcond      CLOB
) RETURN CLOB
IS 
    v_adssql        CLOB;
    v_filtersql     CLOB;
    v_primarydctable VARCHAR2(2000);
    v_filtercnd     CLOB;
   v_addpagination varchar2(1);
v_dimensions varchar2(1);
BEGIN

    SELECT sqltext,coalesce(pagination,'T') pagination,applydimensions
      INTO v_adssql,v_addpagination,v_dimensions
      FROM axdirectsql
     WHERE sqlname = padsname;


    v_adssql := ('select --ax_select_columns 
from(
'||v_adssql||'
)wpc
'||case when v_dimensions='T' then ' --ax_permission_filter
' end||
'--ax_ui_filter_withwhere
'||
'--ax_groupby
'||
'--ax_orderby
'||
case when v_addpagination='T' then '--ax_pagination
'end);
    
    
    IF pcond <> 'NA' THEN
    SELECT tablename INTO v_primarydctable from    
    (SELECT tablename FROM axpdc WHERE tstruct = ptransid AND dname = 'dc1');

        v_filtercnd := ' and (' || REPLACE(pcond, '{primarytable.}', v_primarydctable || '.') || ')';

        
        v_filtersql := REPLACE(v_adssql, '--ax_permission_filter', v_filtercnd);
    END IF;

    
    RETURN CASE
               WHEN pcond = 'NA' THEN v_adssql
               WHEN  pcond <> 'NA' AND v_primarydctable IS NOT NULL then v_filtersql
               ELSE v_adssql
           END;
        
    
END;
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