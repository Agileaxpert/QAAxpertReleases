-------------------------------------------------------------------------This part of script is required to be executed only if 11X postgres axdef schema is used

CREATE OR REPLACE VIEW tstructscripts as 
select createdby username,createdby createdby,username modifiedby,stransid,control_type,"type","event" ,name,caption,
case when control_type='T' then exp_editor_fcscript else exp_editor_script end script from axpdef_script;


CREATE OR REPLACE VIEW iviewscripts as 
select createdby username,createdby,username modifiedby,iname,"event",stype type,"name",caption,exp_editor_script script
from dwb_iviewscripts di;

---------------------------Execute the sqls in postgre axdef schema and generate insert script for query result and execute the insert script in Oracle schema

select axvarcoreid,cancel,sourceid,mapname,username,createdby,app_level,app_desc,app_slevel,constant_name,constant_value,isconstant,var_name,exp_editor_varscript,isvariable,db_funtion,db_funtion_params,isdbobj,event_onlogin,event_onformload,forms,event_onreportload,reports,remarks,stransid,constant_value,isconstant,var_name,exp_editor_varscript,event_onformload,axvarname,dbvarname,dbvartype,dbvarval,dbvarsourceid,forms_transid,reports_transid,forms,reports,remarks,stransid,vpvalue,display,readonly,customdatatype,datawidth,isappparam,vpname,isparam,vscript,pcaption,pdatatype,modeofentry,masterdlui,masterdl,source,SQL_editor_psql,constant_name,event_onreportload,isvariable,db_funtion,db_funtion_params,isdbobj,event_onlogin,axvarname,dbvarname,dbvartype,dbvarval,dbvarsourceid,forms_transid,reports_transid,vpvalue,display,readonly,customdatatype,datawidth,isappparam,vpname,isparam,vscript,pcaption,pdatatype,modeofentry,masterdlui,masterdl,source,SQL_editor_psql
from axvarcore;


select axp_customdatatypeid,
cancel,
sourceid,
mapname,
username,
createdby,
app_level,
app_desc,
app_slevel,
typename,
datatype,
width,
dwidth,
isactive from axp_customdatatype;


select axpdef_languageid,
cancel,
sourceid,
mapname,
username,
createdby,
app_level,
app_desc,
app_slevel,
language,
fontcharset,
exportto,
fontname,
fontsize,
exportfiles,
expalltstruct,
expalliview,
tstructcap,
tstructnames,
iviewcap,
iviewnames,
uploadfiletype from axpdef_language



select * from tstructscripts;

select * from iviewscripts;



-------------------------------------------------------------------------This part of script is required to be executed only if 11X postgres axdef schema is used


UPDATE axp_cards SET INHOMEPAGE='T';



INSERT INTO AXP_VP (AXP_VPID, CANCEL, SOURCEID, MAPNAME, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, WKID, APP_LEVEL, APP_DESC, APP_SLEVEL, CANCELREMARKS, WFROLES, VPNAME, ISPARAM, VSCRIPT, PCAPTION, PDATATYPE, MODEOFENTRY, SQL_EDITOR_PSQL, VPVALUE, DISPLAY, READONLY, POSTACCEPT, POSTSELECT, CUSTOMDATATYPE, DATAWIDTH, TTRANSID, DCSELECT, MASTERDL, "SOURCE", MASTERDLUI, ISCONSTANT, ISVARIABLE, ISAPPPARAM, REMARKS) VALUES(1489990000000, 'F', 0, NULL, 'admin', getdate(), 'admin', getdate(), NULL, 1, 1, 0, NULL, NULL, 'AxpDbDirPath', 'F', NULL, NULL, NULL, NULL, NULL, '', 'F', 'F', 'F', 'F', NULL, 10, 'axglo', 'Global Parameters(dc1)', NULL, NULL, NULL, 'T', 'F', 'F', NULL);


INSERT INTO AXP_VP (AXP_VPID, CANCEL, SOURCEID, MAPNAME, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, WKID, APP_LEVEL, APP_DESC, APP_SLEVEL, CANCELREMARKS, WFROLES, VPNAME, ISPARAM, VSCRIPT, PCAPTION, PDATATYPE, MODEOFENTRY, SQL_EDITOR_PSQL, VPVALUE, DISPLAY, READONLY, POSTACCEPT, POSTSELECT, CUSTOMDATATYPE, DATAWIDTH, TTRANSID, DCSELECT, MASTERDL, "SOURCE", MASTERDLUI, ISCONSTANT, ISVARIABLE, ISAPPPARAM, REMARKS) VALUES(1490770000000, 'F', 0, NULL, 'admin',getdate(), 'admin', getdate(), NULL, 1, 1, 0, NULL, NULL, 'AxFCMSendMsgURL', 'F', NULL, NULL, NULL, NULL, NULL, '', 'F', 'F', 'F', 'F', NULL, 10, 'axglo', 'Global Parameters(dc1)', NULL, NULL, NULL, 'T', 'F', 'F', NULL);


INSERT INTO AXP_VP (AXP_VPID, CANCEL, SOURCEID, MAPNAME, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, WKID, APP_LEVEL, APP_DESC, APP_SLEVEL, CANCELREMARKS, WFROLES, VPNAME, ISPARAM, VSCRIPT, PCAPTION, PDATATYPE, MODEOFENTRY, SQL_EDITOR_PSQL, VPVALUE, DISPLAY, READONLY, POSTACCEPT, POSTSELECT, CUSTOMDATATYPE, DATAWIDTH, TTRANSID, DCSELECT, MASTERDL, "SOURCE", MASTERDLUI, ISCONSTANT, ISVARIABLE, ISAPPPARAM, REMARKS) VALUES(1492010000000, 'F', 0, NULL, 'admin', getdate(), 'admin', getdate(), NULL, 1, 1, 0, NULL, NULL, 'AxRMQAPIURL', 'F', NULL, NULL, NULL, NULL, NULL, '', 'F', 'F', 'F', 'F', NULL, 10, 'axglo', 'Global Parameters(dc1)', NULL, NULL, NULL, 'T', 'F', 'F', NULL);


INSERT INTO AXP_VP (AXP_VPID, CANCEL, SOURCEID, MAPNAME, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, WKID, APP_LEVEL, APP_DESC, APP_SLEVEL, CANCELREMARKS, WFROLES, VPNAME, ISPARAM, VSCRIPT, PCAPTION, PDATATYPE, MODEOFENTRY, SQL_EDITOR_PSQL, VPVALUE, DISPLAY, READONLY, POSTACCEPT, POSTSELECT, CUSTOMDATATYPE, DATAWIDTH, TTRANSID, DCSELECT, MASTERDL, "SOURCE", MASTERDLUI, ISCONSTANT, ISVARIABLE, ISAPPPARAM, REMARKS) VALUES(1491880000000, 'F', 0, NULL, 'admin', getdate(), 'admin',getdate(), NULL, 1, 1, 0, NULL, NULL, 'AxSignalRapiURL', 'F', NULL, NULL, NULL, NULL, NULL, '', 'F', 'F', 'F', 'F', NULL, 10, 'axglo', 'Global Parameters(dc1)', NULL, NULL, NULL, 'T', 'F', 'F', NULL);


INSERT INTO AXP_VP (AXP_VPID, CANCEL, SOURCEID, MAPNAME, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, WKID, APP_LEVEL, APP_DESC, APP_SLEVEL, CANCELREMARKS, WFROLES, VPNAME, ISPARAM, VSCRIPT, PCAPTION, PDATATYPE, MODEOFENTRY, SQL_EDITOR_PSQL, VPVALUE, DISPLAY, READONLY, POSTACCEPT, POSTSELECT, CUSTOMDATATYPE, DATAWIDTH, TTRANSID, DCSELECT, MASTERDL, "SOURCE", MASTERDLUI, ISCONSTANT, ISVARIABLE, ISAPPPARAM, REMARKS) VALUES(1491660000002, 'F', 0, NULL, 'admin', getdate(), 'admin', getdate(), NULL, 1, 1, 0, NULL, NULL, 'AxScriptsAPIURL', 'F', NULL, NULL, NULL, NULL, NULL, '', 'F', 'F', 'F', 'F', NULL, 10, 'axglo', 'Global Parameters(dc1)', NULL, NULL, NULL, 'T', 'F', 'F', NULL);


INSERT INTO AXP_VP (AXP_VPID, CANCEL, SOURCEID, MAPNAME, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, WKID, APP_LEVEL, APP_DESC, APP_SLEVEL, CANCELREMARKS, WFROLES, VPNAME, ISPARAM, VSCRIPT, PCAPTION, PDATATYPE, MODEOFENTRY, SQL_EDITOR_PSQL, VPVALUE, DISPLAY, READONLY, POSTACCEPT, POSTSELECT, CUSTOMDATATYPE, DATAWIDTH, TTRANSID, DCSELECT, MASTERDL, "SOURCE", MASTERDLUI, ISCONSTANT, ISVARIABLE, ISAPPPARAM, REMARKS) VALUES(1491330000000, 'F', 0, NULL, 'admin', getdate(), 'admin', getdate(), NULL, 1, 1, 0, NULL, NULL, 'axpegemailactionurl', 'F', NULL, NULL, NULL, NULL, NULL, '', 'F', 'F', 'F', 'F', NULL, 10, 'axglo', 'Global Parameters(dc1)', NULL, NULL, NULL, 'T', 'F', 'F', NULL);


INSERT INTO AXP_VP (AXP_VPID, CANCEL, SOURCEID, MAPNAME, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, WKID, APP_LEVEL, APP_DESC, APP_SLEVEL, CANCELREMARKS, WFROLES, VPNAME, ISPARAM, VSCRIPT, PCAPTION, PDATATYPE, MODEOFENTRY, SQL_EDITOR_PSQL, VPVALUE, DISPLAY, READONLY, POSTACCEPT, POSTSELECT, CUSTOMDATATYPE, DATAWIDTH, TTRANSID, DCSELECT, MASTERDL, "SOURCE", MASTERDLUI, ISCONSTANT, ISVARIABLE, ISAPPPARAM, REMARKS) VALUES(1491110000000, 'F', 0, NULL, 'admin', getdate(), 'admin', getdate(), NULL, 1, 1, 0, NULL, NULL, 'AxPEGMailFrom', 'F', NULL, NULL, NULL, NULL, NULL, '', 'F', 'F', 'F', 'F', NULL, 10, 'axglo', 'Global Parameters(dc1)', NULL, NULL, NULL, 'T', 'F', 'F', NULL);


INSERT INTO AXP_VP (AXP_VPID, CANCEL, SOURCEID, MAPNAME, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, WKID, APP_LEVEL, APP_DESC, APP_SLEVEL, CANCELREMARKS, WFROLES, VPNAME, ISPARAM, VSCRIPT, PCAPTION, PDATATYPE, MODEOFENTRY, SQL_EDITOR_PSQL, VPVALUE, DISPLAY, READONLY, POSTACCEPT, POSTSELECT, CUSTOMDATATYPE, DATAWIDTH, TTRANSID, DCSELECT, MASTERDL, "SOURCE", MASTERDLUI, ISCONSTANT, ISVARIABLE, ISAPPPARAM, REMARKS) VALUES(1490990000000, 'F', 0, NULL, 'admin', getdate(), 'admin',getdate(), NULL, 1, 1, 0, NULL, NULL, 'AxMailFrom', 'F', NULL, NULL, NULL, NULL, NULL, '', 'F', 'F', 'F', 'F', NULL, 10, 'axglo', 'Global Parameters(dc1)', NULL, NULL, NULL, 'T', 'F', 'F', NULL);


INSERT INTO axvarcore (axvarcoreid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, vpname, isparam, vscript, pcaption, pdatatype, modeofentry, masterdlui, masterdl, source, sql_editor_psql, vpvalue, display, readonly, customdatatype, datawidth, isappparam, constant_name, constant_value, isconstant, var_name, exp_editor_varscript, isvariable, db_funtion, db_funtion_params, isdbobj, event_onlogin, event_onformload, forms, event_onreportload, reports, remarks, stransid, axvarname, dbvarname, dbvartype, dbvarval, dbvarsourceid, forms_transid, reports_transid) VALUES(1489990000001, 'F', 1489990000000, 'axvar3', 'admin', getdate(), 'admin', getdate(), NULL, 1, 1, NULL, NULL, NULL, 'AxpDbDirPath', 'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', 'F', 'F', NULL, 10, 'F', NULL, NULL, 'T', NULL, NULL, 'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'axvar', 'AxpDbDirPath', NULL, NULL, NULL, 0, NULL, NULL);


INSERT INTO axvarcore (axvarcoreid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, vpname, isparam, vscript, pcaption, pdatatype, modeofentry, masterdlui, masterdl, source, sql_editor_psql, vpvalue, display, readonly, customdatatype, datawidth, isappparam, constant_name, constant_value, isconstant, var_name, exp_editor_varscript, isvariable, db_funtion, db_funtion_params, isdbobj, event_onlogin, event_onformload, forms, event_onreportload, reports, remarks, stransid, axvarname, dbvarname, dbvartype, dbvarval, dbvarsourceid, forms_transid, reports_transid) VALUES(1490770000001, 'F', 1490770000000, 'axvar3', 'admin', getdate(), 'admin', getdate(), NULL, 1, 1, NULL, NULL, NULL, 'AxFCMSendMsgURL', 'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', 'F', 'F', NULL, 10, 'F', NULL, NULL, 'T', NULL, NULL, 'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'axvar', 'AxFCMSendMsgURL', NULL, NULL, NULL, 0, NULL, NULL);


INSERT INTO axvarcore (axvarcoreid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, vpname, isparam, vscript, pcaption, pdatatype, modeofentry, masterdlui, masterdl, source, sql_editor_psql, vpvalue, display, readonly, customdatatype, datawidth, isappparam, constant_name, constant_value, isconstant, var_name, exp_editor_varscript, isvariable, db_funtion, db_funtion_params, isdbobj, event_onlogin, event_onformload, forms, event_onreportload, reports, remarks, stransid, axvarname, dbvarname, dbvartype, dbvarval, dbvarsourceid, forms_transid, reports_transid) VALUES(1490990000001, 'F', 1490990000000, 'axvar3', 'admin', getdate() ,'admin', getdate(), NULL, 1, 1, NULL, NULL, NULL, 'AxMailFrom', 'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', 'F', 'F', NULL, 10, 'F', NULL, NULL, 'T', NULL, NULL, 'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'axvar', 'AxMailFrom', NULL, NULL, NULL, 0, NULL, NULL);


INSERT INTO axvarcore (axvarcoreid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, vpname, isparam, vscript, pcaption, pdatatype, modeofentry, masterdlui, masterdl, source, sql_editor_psql, vpvalue, display, readonly, customdatatype, datawidth, isappparam, constant_name, constant_value, isconstant, var_name, exp_editor_varscript, isvariable, db_funtion, db_funtion_params, isdbobj, event_onlogin, event_onformload, forms, event_onreportload, reports, remarks, stransid, axvarname, dbvarname, dbvartype, dbvarval, dbvarsourceid, forms_transid, reports_transid) VALUES(1491110000001, 'F', 1491110000000, 'axvar3', 'admin', getdate(), 'admin', getdate(), NULL, 1, 1, NULL, NULL, NULL, 'AxPEGMailFrom', 'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', 'F', 'F', NULL, 10, 'F', NULL, NULL, 'T', NULL, NULL, 'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'axvar', 'AxPEGMailFrom', NULL, NULL, NULL, 0, NULL, NULL);


INSERT INTO axvarcore (axvarcoreid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, vpname, isparam, vscript, pcaption, pdatatype, modeofentry, masterdlui, masterdl, source, sql_editor_psql, vpvalue, display, readonly, customdatatype, datawidth, isappparam, constant_name, constant_value, isconstant, var_name, exp_editor_varscript, isvariable, db_funtion, db_funtion_params, isdbobj, event_onlogin, event_onformload, forms, event_onreportload, reports, remarks, stransid, axvarname, dbvarname, dbvartype, dbvarval, dbvarsourceid, forms_transid, reports_transid) VALUES(1491330000001, 'F', 1491330000000, 'axvar3', 'admin', getdate(), 'admin', getdate(), NULL, 1, 1, NULL, NULL, NULL, 'axpegemailactionurl', 'F', '', '', '', '', '', '', '', '', '', 'F', 'F', '', 10, 'F', '', '', 'T', '', '', 'F', '', '', '', '', '', '', '', '', '', 'axvar', 'axpegemailactionurl', '', '', '', 0, '', '');


INSERT INTO axvarcore (axvarcoreid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, vpname, isparam, vscript, pcaption, pdatatype, modeofentry, masterdlui, masterdl, source, sql_editor_psql, vpvalue, display, readonly, customdatatype, datawidth, isappparam, constant_name, constant_value, isconstant, var_name, exp_editor_varscript, isvariable, db_funtion, db_funtion_params, isdbobj, event_onlogin, event_onformload, forms, event_onreportload, reports, remarks, stransid, axvarname, dbvarname, dbvartype, dbvarval, dbvarsourceid, forms_transid, reports_transid) VALUES(1491660000003, 'F', 1491660000002, 'axvar3', 'admin', getdate(), 'admin', getdate(), NULL, 1, 1, NULL, NULL, NULL, 'AxScriptsAPIURL', 'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', 'F', 'F', NULL, 10, 'F', NULL, NULL, 'T', NULL, NULL, 'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'axvar', 'AxScriptsAPIURL', NULL, NULL, NULL, 0, NULL, NULL);


INSERT INTO axvarcore (axvarcoreid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, vpname, isparam, vscript, pcaption, pdatatype, modeofentry, masterdlui, masterdl, source, sql_editor_psql, vpvalue, display, readonly, customdatatype, datawidth, isappparam, constant_name, constant_value, isconstant, var_name, exp_editor_varscript, isvariable, db_funtion, db_funtion_params, isdbobj, event_onlogin, event_onformload, forms, event_onreportload, reports, remarks, stransid, axvarname, dbvarname, dbvartype, dbvarval, dbvarsourceid, forms_transid, reports_transid) VALUES(1491880000001, 'F', 1491880000000, 'axvar3', 'admin', getdate(), 'admin', getdate(), NULL, 1, 1, NULL, NULL, NULL, 'AxSignalRapiURL', 'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', 'F', 'F', NULL, 10, 'F', NULL, NULL, 'T', NULL, NULL, 'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'axvar', 'AxSignalRapiURL', NULL, NULL, NULL, 0, NULL, NULL);


INSERT INTO axvarcore (axvarcoreid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, vpname, isparam, vscript, pcaption, pdatatype, modeofentry, masterdlui, masterdl, source, sql_editor_psql, vpvalue, display, readonly, customdatatype, datawidth, isappparam, constant_name, constant_value, isconstant, var_name, exp_editor_varscript, isvariable, db_funtion, db_funtion_params, isdbobj, event_onlogin, event_onformload, forms, event_onreportload, reports, remarks, stransid, axvarname, dbvarname, dbvartype, dbvarval, dbvarsourceid, forms_transid, reports_transid) VALUES(1492010000001, 'F', 1492010000000, 'axvar3', 'admin', getdate(), 'admin', getdate(), NULL, 1, 1, NULL, NULL, NULL, 'AxRMQAPIURL', 'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', 'F', 'F', NULL, 10, 'F', NULL, NULL, 'T', NULL, NULL, 'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'axvar', 'AxRMQAPIURL', NULL, NULL, NULL, 0, NULL, NULL);

