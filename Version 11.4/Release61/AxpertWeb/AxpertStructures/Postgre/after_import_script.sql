<<
CREATE OR REPLACE FUNCTION fn_axi_getstructures_meta(pusername character varying, puserrole character varying, presponsiblity character varying, pmode character varying, pstype character varying)
 RETURNS TABLE(displaydata character varying, caption character varying, name character varying, stype character varying, dimension character varying, permission character varying, createallowed character varying, viewallowed character varying, keyfield character varying, primarytable character varying, keyfieldforedit character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN

RETURN QUERY
with ts as(
SELECT DISTINCT
               (a.caption || ' (' || a.name || ') [form]')::varchar,
               a.caption tcaption,
               a.name transid,'t'::varchar stype,coalesce(g.dimensions,'F')::varchar dimensions,
    coalesce(p.permissions,'F')::varchar,coalesce(p.newrecord,'T')::varchar,coalesce(p.viewctrl,'T')::varchar,
kf.kfld,d.tablename,kf.kfldforedit::varchar 
        FROM tstructs a
join axpdc d on a.name = d.tstruct and d.dname='dc1'
        left JOIN axpages b ON b.pagetype = 't' || a.name
        LEFT JOIN axuseraccess ua ON ua.sname = a.name
left join (SELECT DISTINCT ON (combined_results.name) 
    combined_results.name tstruct,  
    kfld, 
    ord,kfldforedit
FROM (
    SELECT 
        a.name,
        a.keyfield AS kfld,
        1 AS ord ,'T' kfldforedit   
    FROM axp_tstructprops a 
    UNION ALL
    SELECT 
        tstruct AS name,
        fname AS kfld,
        CASE 
            WHEN modeofentry = 'autogenerate' THEN 2
            WHEN LOWER(allowduplicate) = 'f' AND LOWER(allowempty) = 'f' AND datatype = 'c' AND LOWER(hidden) = 'f' THEN 3
            WHEN LOWER(hidden) = 'f' AND datatype = 'c' THEN 4
            ELSE 5
        END AS ord,
     CASE 
            WHEN modeofentry = 'autogenerate' THEN 'T'
            WHEN LOWER(allowduplicate) = 'f' AND LOWER(allowempty) = 'f' AND datatype = 'c' AND LOWER(hidden) = 'f' THEN 'T'
            ELSE 'F' END AS kfldforedit        
    FROM axpflds
    WHERE dcname = 'dc1'
) combined_results
ORDER BY combined_results.name, ord ASC)kf on kf.tstruct = a.name
        left join (select ftransid,'T' dimensions from axgrouptstructs)g on a."name" = g.ftransid
        left join (SELECT DISTINCT ON (formtransid) 
    formtransid, 
    newrecord, 
    permissions,viewctrl
FROM (
    SELECT formtransid, case when allowcreate='Yes' then 'T' else 'F' end newrecord, 'U' as type, 1 as ord ,'T'permissions,case when viewctrl='4' then 'F' else 'T' end viewctrl
    FROM axpermissions
    WHERE axusername = pusername AND comptype = 'Form'
    UNION ALL
    SELECT formtransid, case when allowcreate='Yes' then 'T' else 'F' end newrecord, 'R' as type, 2 as ord ,'T' permissions,case when viewctrl='4' then 'F' else 'T' end viewctrl
    FROM axpermissions
    WHERE axuserrole = ANY(string_to_array(puserrole, ',')) and  comptype = 'Form'
) combined_permissions
ORDER BY formtransid, ord ASC)p on a.name=p.formtransid
        WHERE (pmode = 'dev' OR b.visible = 'T')
          AND (
                'default' = ANY(string_to_array(presponsiblity,','))
                OR (ua.stype = 't' AND ua.rname = ANY(string_to_array(presponsiblity,','))
              ))), 
iv as (SELECT DISTINCT
               (a.caption || ' (' || a.name || ') [report]')::varchar,
               a.caption,
               a.name,'i'::varchar stype,'NA'::varchar,'NA'::varchar,'NA'::varchar,'NA'::varchar,'NA'::varchar,
	'NA'::varchar,'NA'::varchar
        FROM iviews a
        left JOIN axpages b ON b.pagetype = 'i' || a.name
        LEFT JOIN axuseraccess ua ON ua.sname = a.name     
        WHERE (lower(pmode) = 'dev' OR b.visible = 'T')
          AND (
                'default' = ANY(string_to_array(presponsiblity,','))
                OR (ua.stype = 'i' AND ua.rname = ANY(string_to_array(presponsiblity,','))
              ))),
pg as(
 SELECT DISTINCT
               (b.caption || ' [page]')::varchar,
               b.caption,
               b.props::varchar name,'p'::varchar stype,'NA'::varchar,'NA'::varchar,'NA'::varchar,'NA'::varchar,
'NA'::varchar,'NA'::varchar,'NA'::varchar
        FROM  axpages b 
        left JOIN axuseraccess ua ON ua.sname = b.name     
        WHERE b.pagetype='web'
        and (lower(pmode) = 'dev' OR b.visible = 'T')
          AND (
                'default' = ANY(string_to_array(presponsiblity,','))
                OR (ua.rname = ANY(string_to_array(presponsiblity,','))
              ))),
ads as (select (a.sqlname || ' (' || a.sqlsrc || ') [datasource]')::varchar displaydata,sqlname caption,sqlname name,'ads'::varchar stype,'NA'::varchar dimension,
case when a2.axpermissionsid>0 then 'T' else 'NA' end::varchar permission,
'NA'::varchar createallowed,
case when a2.axpermissionsid>0 or a.createdby=pusername or 'default' = ANY(string_to_array(puserrole,',')) then 'T' else 'NA' end::varchar viewallowed,
'NA'::varchar keyfield,'NA'::varchar primarytable,'NA'::varchar
from axdirectsql a
left join axpermissions a2 on a.sqlname =a2.formcap and (a2.axusername = pusername or a2.axuserrole = ANY(string_to_array(puserrole,',')))
where sqlsrccnd !=1),
inbox as(SELECT
               'Inbox'::varchar displaydata,
               'Inbox'::varchar caption,
               'Inbox'::varchar name,'Inbox'::varchar stype,'NA','NA','NA','NA','NA','NA','NA'::varchar)
SELECT * FROM (
    SELECT * FROM ts WHERE pstype IN ('t', 'all', 'analyze')
    UNION ALL
   SELECT * FROM iv  WHERE pstype IN ('i', 'all')
    UNION ALL
    SELECT * FROM pg   WHERE pstype IN ('p', 'all')
    UNION ALL
    SELECT * FROM ads WHERE pstype IN ('ads', 'all', 'analyze')
    UNION ALL
    SELECT * FROM inbox WHERE pstype IN ('all')
) final_result
ORDER BY displaydata;
 
END;
$function$
;
>>

<<
INSERT INTO axdirectsql (axdirectsqlid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, sqlname, ddldatatype, sqltext, paramcal, sqlparams, accessstring, groupname, sqlsrc, sqlsrccnd, sqlquerycols, adsdesc, encryptedflds, cachedata, cacheinterval, smartlistcnd, pagination, applydimensions, fetchsize) VALUES(7639990000000, 'F', 0, NULL, 'admin', '2026-11-13', 'admin', '2026-11-13', NULL, 1, 1, NULL, NULL, NULL, 'data_ing_tstructs', NULL, ' select name value, caption text from fn_axi_getstructures_meta(:pusername,:puserrole,:presponsiblity,''app'',''t'') 
   where createallowed=''T''
   order by 1', 'pusername,puserrole,presponsiblity', 'pusername~Character~,puserrole~Character~,presponsiblity~Character~', 'ALL', NULL, 'Internal', 1, 'value,text', NULL, NULL, 'F', '6 Hr', NULL, 'F', 'F', '100');
>>

<<
INSERT INTO axdirectsql (axdirectsqlid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, sqlname, ddldatatype, sqltext, paramcal, sqlparams, accessstring, groupname, sqlsrc, sqlsrccnd, sqlquerycols, adsdesc, encryptedflds, cachedata, cacheinterval, smartlistcnd, pagination, applydimensions, fetchsize) VALUES(7640660000000, 'F', 0, NULL, 'admin', '2026-11-13', 'admin', '2026-11-13', NULL, 1, 1, NULL, NULL, NULL, 'data_ing_tstruct_dcs', NULL, 'SELECT dname AS value, a.caption AS text, a.asgrid, a.dcno
FROM  axpdc a
WHERE a.tstruct = :transid 
ORDER BY dcno', 'transid', 'transid~Character~', 'ALL', NULL, 'Internal', 1, 'value,text,asgrid,dcno', NULL, NULL, 'F', '6 Hr', NULL, 'F', 'F', '100');
>>

<<
INSERT INTO axdirectsql (axdirectsqlid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, sqlname, ddldatatype, sqltext, paramcal, sqlparams, accessstring, groupname, sqlsrc, sqlsrccnd, sqlquerycols, adsdesc, encryptedflds, cachedata, cacheinterval, smartlistcnd, pagination, applydimensions, fetchsize) VALUES(7640550000002, 'F', 0, NULL, 'admin', '2026-11-13', 'admin', '2026-11-13', NULL, 1, 1, NULL, NULL, NULL, 'data_ing_tstruct_fields', NULL, ' SELECT
    fname AS value,
    caption AS text,
    asgrid,
    frmno,
    datatype
FROM axpflds
WHERE tstruct = :transid
  AND LOWER(TRIM(dcname)) = ANY(string_to_array(LOWER(:dcname), '',''))
  AND savevalue = ''T''
  AND hidden = ''F''
ORDER BY frmno, ordno', 'transid,dcname', 'transid~Character~,dcname~Character~', 'ALL', NULL, 'Internal', 1, 'value,text,asgrid,frmno,datatype', NULL, NULL, 'F', '6 Hr', NULL, 'F', 'F', '100');
>>

<<
INSERT INTO axdirectsql (axdirectsqlid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, sqlname, ddldatatype, sqltext, paramcal, sqlparams, accessstring, groupname, sqlsrc, sqlsrccnd, sqlquerycols, adsdesc, encryptedflds, cachedata, cacheinterval, smartlistcnd, pagination, applydimensions, fetchsize) VALUES(7640110000000, 'F', 0, NULL, 'admin', '2026-11-13', 'admin', '2026-11-13', NULL, 1, 1, NULL, NULL, NULL, 'data_ing_field_mapping', NULL, 'SELECT
    dc2.excelheader AS value,
    dc2.mappedfield AS text,
    dc1.groupfield,
    dc1.keyfield
FROM axpdef_dataing_maphdr dc1
INNER JOIN axpdef_dataing_mapdtls dc2
    ON dc1.axpdef_dataing_maphdrid = dc2.axpdef_dataing_maphdrid
WHERE dc1.form= :transid
ORDER BY dc2.excelheader', 'transid', 'transid~Character~', 'ALL', NULL, 'Internal', 1, 'value,text,groupfield,keyfield', NULL, NULL, 'F', '6 Hr', NULL, 'F', 'F', '100');
>>

<<
INSERT INTO htmlsections (htmlsectionsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, pageno, caption, axpfile_hpimages, axpfilepath_hpimages, addtomenu, isacoretrans, menuposition, menulist, params, "template") VALUES(7640990000000, 'F', 0, NULL, 'admin', '2026-11-13', 'admin', '2026-11-13', NULL, 1, 1, NULL, NULL, NULL, '1794547992681', 'Data Ingestor', NULL, 'D:\qabiz\Axpert11.4Base\AxpertWeb\defschema\HTMLPages\images\*', NULL, 'Yes', 'Default', NULL, NULL, NULL);
>>

<<
INSERT INTO sect2 (sect2id, htmlsectionsid, html_editor_htmlsrc) VALUES(7640990000001, 7640990000000, '<html lang="en"><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Excel Import — T-Struct</title>
<link rel="stylesheet" href="../../UI/axpertUI/style.bundle.css">
<link rel="stylesheet" href="../../UI/axpertUI/plugins.bundle.css">

	
	
		<link type="text/css" rel="stylesheet" href="css/Data_Ingestor_1794547992681.Css?v=1793872064499">
	
	

</head>
<body>

<div class="eip-app eip-app-v2">

  <!-- Page Header -->
  <div class="eip-page-head">
    <h1>Data Ingestor</h1>
    <p class="eip-subtitle">Map and import Excel data directly into T-Structs</p>
  </div>

  <!-- Top bar: single line of controls -->
  <div class="eip-topbar" id="eipTopbar">
    <div class="eip-topbar-item">
      <label>Excel file</label>
      <div class="eip-file-row">
        <input type="file" id="eipFileInput" accept=".xlsx,.xls,.csv" class="eip-hidden">
        <button type="button" class="eip-file-btn" id="eipFileBtn">Upload Excel</button>
        <span class="eip-file-name" id="eipFileName">No file selected</span>
      </div>
    </div>

    <div class="eip-tstruct-dc-group" id="eipTstructDcGroup">
      <div class="eip-topbar-item">
        <label for="eipTstructSelect">T-Struct</label>
        <div class="eip-select eip-select-sm" id="eipTstructSelect"></div>
      </div>

      <div class="eip-topbar-item">
        <label for="eipDcSelect">DC</label>
        <div class="eip-select eip-select-sm" id="eipDcSelect"></div>
      </div>

      <div class="eip-topbar-item">
        <label for="eipKeyFieldSelect">Key field</label>
        <div class="eip-select eip-select-sm" id="eipKeyFieldSelect"></div>
      </div>
    </div>

    <div class="eip-topbar-item eip-checkbox-row" id="eipPriorApiItemWrap">
      <input type="checkbox" id="eipPriorApiCheckbox" checked="">
      <label for="eipPriorApiCheckbox">Use prior version of API</label>
    </div>

    <div class="eip-topbar-jobs">
      <div class="eip-topbar-item">
        <label for="eipJobSelect">Import job</label>
        <div class="eip-select eip-select-sm" id="eipJobSelect"></div>
      </div>
      <button type="button" class="eip-btn" id="eipNewImportBtn">+ New Import</button>
      <button type="button" class="eip-btn eip-btn-danger" id="eipDeleteJobBtn" title="Delete the selected import job and its staged rows">Delete Job</button>
    </div>
  </div>

  <!-- Sheet tabs — shown only when the current upload had multiple sheets -->
  <div class="eip-sheet-tabs eip-hidden" id="eipSheetTabs"></div>

  <!-- T-Struct + DC controls relocate here when sheet tabs are showing,
       since at that point they''re per-tab controls, not page-global -->
  <div class="eip-tab-controls-row eip-hidden" id="eipTabControlsRow"></div>

  <!-- Grid area -->
  <div class="eip-grid-wrapper" id="eipGridWrapper">
    <div class="eip-empty-note" id="eipGridEmptyNote">Upload an Excel file to begin.</div>
    <table class="eip-grid-table eip-hidden" id="eipGridTable">
      <thead>
        <tr id="eipGridMappingRow"></tr>
        <tr id="eipGridHeaderRow"></tr>
      </thead>
      <tbody id="eipGridBody"></tbody>
    </table>
  </div>

  <!-- Bottom toolbar -->
  <div class="eip-bottom-toolbar">
    <div class="eip-summary-group">
      <span class="eip-summary-label" id="eipSummaryLabel">No data loaded.</span>
      <span class="eip-timing-label" id="eipTimingLabel"></span>
    </div>
    <div class="eip-bottom-toolbar-actions">
      <button type="button" class="eip-btn" id="eipRefreshBtn">Refresh status</button>
      <button type="button" class="eip-btn eip-hidden" id="eipDownloadErrorsBtn">Download errors</button>
      <button type="button" class="eip-btn" id="eipSaveMappingBtn">Save Mapping</button>
      <button type="button" class="eip-btn" id="eipValidateBtn">Validate</button>
      <button type="button" class="eip-btn eip-btn-primary" id="eipImportBtn">Import</button>
    </div>
  </div>

</div>

<!-- Progress / log popup -->
<div class="eip-modal-overlay eip-hidden" id="eipProgressModalOverlay">
  <div class="eip-modal eip-progress-modal">
    <div class="eip-modal-title-row">
      <div class="eip-modal-title">Progress</div>
      <button type="button" class="eip-modal-close-btn" id="eipProgressCloseBtn" title="Close">&times;</button>
    </div>
    <div class="eip-progress-bar-track">
      <div class="eip-progress-bar-fill" id="eipProgressBarFill"></div>
    </div>
    <div class="eip-progress-label" id="eipProgressLabel"></div>
    <div class="eip-progress-elapsed" id="eipProgressElapsed"></div>
    <div class="eip-log-list" id="eipLogList"></div>
  </div>
</div>

<!-- Column validation popup -->
<div class="eip-modal-overlay eip-hidden" id="eipValidationModalOverlay">
  <div class="eip-modal">
    <div class="eip-modal-title" id="eipValidationModalTitle">Column validation</div>

    <div class="eip-field">
      <div class="eip-checkbox-row">
        <input type="checkbox" id="eipValMandatory">
        <label for="eipValMandatory">Mandatory</label>
      </div>
    </div>

    <div class="eip-field">
      <label>Range (for date / numeric columns)</label>
      <div class="eip-range-row">
        <input type="text" class="eip-select" id="eipValMin" placeholder="Min">
        <input type="text" class="eip-select" id="eipValMax" placeholder="Max">
      </div>
      <span class="eip-hint">Dates: dd/mm/yyyy. Leave blank to skip a bound.</span>
    </div>

    <div class="eip-field">
      <label for="eipValAllowed">Allowed values</label>
      <textarea class="eip-select eip-textarea" id="eipValAllowed" rows="3" placeholder="Comma-separated, e.g. A,B,C"></textarea>
    </div>

    <div class="eip-btn-row">
      <button type="button" class="eip-btn" id="eipValCancelBtn">Cancel</button>
      <button type="button" class="eip-btn eip-btn-primary" id="eipValSaveBtn">Save</button>
    </div>
  </div>
</div>

<!-- Generic confirm modal (replaces window.confirm for a consistent, in-app look) -->
<div class="eip-modal-overlay eip-hidden" id="eipConfirmModalOverlay">
  <div class="eip-modal eip-confirm-modal">
    <div class="eip-modal-title" id="eipConfirmModalTitle">Are you sure?</div>
    <div class="eip-confirm-message" id="eipConfirmModalMessage"></div>
    <div class="eip-btn-row">
      <button type="button" class="eip-btn" id="eipConfirmCancelBtn">Cancel</button>
      <button type="button" class="eip-btn eip-btn-primary" id="eipConfirmOkBtn">OK</button>
    </div>
  </div>
</div>

<div class="eip-toast" id="eipToast"></div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"></script>
<script>
/* =========================================================
   Excel -> T-Struct Import — Custom Page (Version 2)
   2 classes:
     - ExcelImportDatabase      : IndexedDB (jobs + rows)
     - ExcelImportPageController: everything else

   Naming convention: PascalCase classes, camelCase methods,
   UPPER_SNAKE_CASE constants, "eip" prefix on DOM ids/classes.
   Console logs prefixed "[EIP]".

   ASSUMPTIONS FLAGGED FOR CONFIRMATION (see chat reply):
     1. ax_mode -> action mapping: n/new->create, e/edit->update,
        d/delete->delete. Only literal "create" is confirmed by
        the README; update/delete strings are my best guess.
     2. Per-transaction success/failure isn''t available yet (the
        feedback mechanism hasn''t been released), so a bundled
        push marks ALL its rows uploaded on success / error on
        failure — not per-transaction granularity.
     3. Numeric/date detection for range validation is done by
        inspecting the true Excel cell type / parseability per
        cell, not by trusting data_ing_tstruct_fields.datatype string values
        (same reasoning as the earlier date-format fix).
     4. Grouping only looks at rows that passed validation, in
        their original relative order (an error row does not
        break a group of otherwise-adjacent valid rows).
   ========================================================= */

const EIP_data_ing_tstructs = "data_ing_tstructs";
const EIP_data_ing_tstruct_fields = "data_ing_tstruct_fields";
const EIP_data_ing_tstruct_dcs = "data_ing_tstruct_dcs";
const EIP_data_ing_field_mapping = "data_ing_field_mapping";
const EIP_MAPPING_MEMORY_TSTRUCT = "a__im"; // the T-Struct field mappings are saved to, shared across all users
const AX_MODE_COLUMN_NAME = "ax_mode";
const AX_MODE_ACTION_MAP = {
  n: "create", new: "create",
  e: "edit", edit: "edit",
  d: "delete", delete: "delete",
};
const AX_MODE_ACTION_DISPLAY_LABEL = { create: "Create", edit: "Edit", delete: "Delete" };
const EIP_MAX_PAYLOAD_BYTES = 9 * 1024 * 1024; // 9 MB cap per queue push

/* =========================================================
   ExcelImportDatabase
   Two stores:
     - jobs (keyPath "jobId")       — one record per import job
     - rows (keyPath "id", indexed by "jobId") — staged Excel rows
   ========================================================= */
class ExcelImportDatabase {
  static DB_NAME = "eip_excel_import_db";
  static DB_VERSION = 3;
  static JOBS_STORE = "importJobs";
  static ROWS_STORE = "stagedRows";
  static MAPPING_MEMORY_STORE = "mappingMemory"; // keyPath: transId — remembers header->field mappings per T-Struct

  constructor() {
    this._db = null;
  }

  open() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(ExcelImportDatabase.DB_NAME, ExcelImportDatabase.DB_VERSION);
      request.onupgradeneeded = (event) => {
        const db = event.target.result;
        if (!db.objectStoreNames.contains(ExcelImportDatabase.JOBS_STORE)) {
          db.createObjectStore(ExcelImportDatabase.JOBS_STORE, { keyPath: "jobId" });
        }
        if (!db.objectStoreNames.contains(ExcelImportDatabase.ROWS_STORE)) {
          const store = db.createObjectStore(ExcelImportDatabase.ROWS_STORE, { keyPath: "id" });
          store.createIndex("byJobId", "jobId", { unique: false });
        }
        if (!db.objectStoreNames.contains(ExcelImportDatabase.MAPPING_MEMORY_STORE)) {
          db.createObjectStore(ExcelImportDatabase.MAPPING_MEMORY_STORE, { keyPath: "transId" });
        }
      };
      request.onsuccess = (event) => {
        this._db = event.target.result;
        resolve(this._db);
      };
      request.onerror = (event) => reject(event.target.error);
    });
  }

  putJob(job) {
    return new Promise((resolve, reject) => {
      const tx = this._db.transaction(ExcelImportDatabase.JOBS_STORE, "readwrite");
      tx.objectStore(ExcelImportDatabase.JOBS_STORE).put(job);
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
    });
  }

  getJob(jobId) {
    return new Promise((resolve, reject) => {
      const tx = this._db.transaction(ExcelImportDatabase.JOBS_STORE, "readonly");
      const request = tx.objectStore(ExcelImportDatabase.JOBS_STORE).get(jobId);
      request.onsuccess = () => resolve(request.result || null);
      request.onerror = () => reject(request.error);
    });
  }

  getAllJobs() {
    return new Promise((resolve, reject) => {
      const tx = this._db.transaction(ExcelImportDatabase.JOBS_STORE, "readonly");
      const request = tx.objectStore(ExcelImportDatabase.JOBS_STORE).getAll();
      request.onsuccess = () => resolve(request.result || []);
      request.onerror = () => reject(request.error);
    });
  }

  deleteJob(jobId) {
    return new Promise((resolve, reject) => {
      const tx = this._db.transaction(ExcelImportDatabase.JOBS_STORE, "readwrite");
      tx.objectStore(ExcelImportDatabase.JOBS_STORE).delete(jobId);
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
    });
  }

  // Deletes every staged row belonging to a job, via the byJobId index —
  // used alongside deleteJob so a deleted job doesn''t leave orphaned rows.
  deleteRowsByJobId(jobId) {
    return new Promise((resolve, reject) => {
      const tx = this._db.transaction(ExcelImportDatabase.ROWS_STORE, "readwrite");
      const store = tx.objectStore(ExcelImportDatabase.ROWS_STORE);
      const index = store.index("byJobId");
      const cursorRequest = index.openKeyCursor(jobId);
      cursorRequest.onsuccess = (event) => {
        const cursor = event.target.result;
        if (cursor) {
          store.delete(cursor.primaryKey);
          cursor.continue();
        }
      };
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
    });
  }

  putRows(rows) {
    return new Promise((resolve, reject) => {
      const tx = this._db.transaction(ExcelImportDatabase.ROWS_STORE, "readwrite");
      const store = tx.objectStore(ExcelImportDatabase.ROWS_STORE);
      rows.forEach((row) => store.put(row));
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
    });
  }

  getRowsByJobId(jobId) {
    return new Promise((resolve, reject) => {
      const tx = this._db.transaction(ExcelImportDatabase.ROWS_STORE, "readonly");
      const index = tx.objectStore(ExcelImportDatabase.ROWS_STORE).index("byJobId");
      const request = index.getAll(jobId);
      request.onsuccess = () => resolve(request.result || []);
      request.onerror = () => reject(request.error);
    });
  }

  putMappingMemory(memory) {
    return new Promise((resolve, reject) => {
      const tx = this._db.transaction(ExcelImportDatabase.MAPPING_MEMORY_STORE, "readwrite");
      tx.objectStore(ExcelImportDatabase.MAPPING_MEMORY_STORE).put(memory);
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
    });
  }

  getMappingMemory(transId) {
    return new Promise((resolve, reject) => {
      const tx = this._db.transaction(ExcelImportDatabase.MAPPING_MEMORY_STORE, "readonly");
      const request = tx.objectStore(ExcelImportDatabase.MAPPING_MEMORY_STORE).get(transId);
      request.onsuccess = () => resolve(request.result || null);
      request.onerror = () => reject(request.error);
    });
  }
}

/* =========================================================
   SearchableDropdown
   A trigger-button + floating search panel, replacing native
   <select> everywhere on this page (T-Struct, Key field, Import
   job, and every per-column field-mapping dropdown) — same
   trigger/panel/search-filter pattern as brsv2.html''s
   searchableDropdownHtml/attachSdDropdown.

   The panel is appended to document.body and positioned with
   position:fixed so it always floats above the grid''s sticky
   headers and scroll container, exactly like brsv2''s approach.
   ========================================================= */
class SearchableDropdown {
  static activeInstance = null;

  // options: [{ value, label, group? }]
  constructor(hostElement, { options = [], value = "", placeholder = "— Select —", onChange = () => {}, allowClear = true, multiSelect = false } = {}) {
    this.host = hostElement;
    this.options = options;
    this.multiSelect = multiSelect;
    this.value = multiSelect ? (Array.isArray(value) ? value : []) : (value || "");
    this.placeholder = placeholder;
    this.onChange = onChange;
    this.allowClear = allowClear;
    this.isDisabled = false;
    this.disabledMessage = "";
    this.onBlockedClick = null;

    this._buildDom();
    this._bindEvents();
  }

  static _escapeHtml(s) {
    return String(s ?? "").replace(/&/g, "&amp;").replace(/</g, "<").replace(/>/g, ">").replace(/"/g, "");
  }

  static _highlightTerm(text, term) {
    const safe = SearchableDropdown._escapeHtml(text);
    const lower = safe.toLowerCase();
    const t = term.toLowerCase();
    let result = "", last = 0, cur = lower.indexOf(t);
    while (cur !== -1) {
      result += safe.slice(last, cur) + `<mark class="eip-sd-hl">${safe.slice(cur, cur + t.length)}</mark>`;
      last = cur + t.length;
      cur = lower.indexOf(t, last);
    }
    return result + safe.slice(last);
  }

  _buildDom() {
    this.host.innerHTML = "";
    this.host.classList.add("eip-sd-wrap");

    this.trigger = document.createElement("button");
    this.trigger.type = "button";
    this.trigger.className = "eip-sd-trigger";
    this.triggerLabel = document.createElement("span");
    this.triggerLabel.className = "eip-sd-trigger-label";
    this.trigger.appendChild(this.triggerLabel);
    const arrow = document.createElement("span");
    arrow.className = "eip-sd-trigger-arrow";
    arrow.textContent = "▾";
    this.trigger.appendChild(arrow);
    this.host.appendChild(this.trigger);

    this.panel = document.createElement("div");
    this.panel.className = "eip-sd-panel eip-hidden";
    const searchWrap = document.createElement("div");
    searchWrap.className = "eip-sd-search-wrap";
    this.searchInput = document.createElement("input");
    this.searchInput.type = "text";
    this.searchInput.className = "eip-sd-search";
    this.searchInput.placeholder = "Search…";
    this.searchInput.autocomplete = "off";
    this.searchInput.spellcheck = false;
    searchWrap.appendChild(this.searchInput);
    this.panel.appendChild(searchWrap);

    this.list = document.createElement("div");
    this.list.className = "eip-sd-list";
    this.panel.appendChild(this.list);

    document.body.appendChild(this.panel);

    this._updateTriggerLabel();
    this._renderList("");
  }

  _updateTriggerLabel() {
    if (this.multiSelect) {
      const selectedLabels = this.options.filter((o) => this.value.includes(o.value)).map((o) => o.label);
      const label = selectedLabels.length === 0 ? "" : selectedLabels.length <= 2 ? selectedLabels.join(", ") : `${selectedLabels.length} selected`;
      this.triggerLabel.textContent = label || this.placeholder;
      this.triggerLabel.classList.toggle("eip-sd-placeholder", !label);
      return;
    }
    const match = this.options.find((o) => o.value === this.value);
    const label = match ? match.label : "";
    this.triggerLabel.textContent = label || this.placeholder;
    this.triggerLabel.classList.toggle("eip-sd-placeholder", !label);
  }

  _renderList(term) {
    const t = (term || "").toLowerCase().trim();
    const filtered = t ? this.options.filter((o) => o.label.toLowerCase().includes(t)) : this.options;
    this.list.innerHTML = "";

    if (this.allowClear && !this.multiSelect) {
      const noneOpt = document.createElement("div");
      noneOpt.className = "eip-sd-option eip-sd-none-opt" + (!this.value ? " eip-sd-selected" : "");
      noneOpt.dataset.value = "";
      noneOpt.tabIndex = -1;
      noneOpt.textContent = this.placeholder;
      this.list.appendChild(noneOpt);
    } else if (this.multiSelect && this.value.length > 0) {
      const clearOpt = document.createElement("div");
      clearOpt.className = "eip-sd-option eip-sd-none-opt";
      clearOpt.dataset.value = "__clear__";
      clearOpt.tabIndex = -1;
      clearOpt.textContent = "Clear selection";
      this.list.appendChild(clearOpt);
    }

    if (filtered.length === 0) {
      const empty = document.createElement("div");
      empty.className = "eip-sd-empty";
      empty.textContent = t ? "No matches" : "No options";
      this.list.appendChild(empty);
      return;
    }

    let lastGroup = undefined;
    filtered.forEach((opt) => {
      if (opt.group !== undefined && opt.group !== lastGroup) {
        const heading = document.createElement("div");
        heading.className = "eip-sd-group-heading";
        heading.textContent = opt.group;
        this.list.appendChild(heading);
        lastGroup = opt.group;
      }
      const isSelected = this.multiSelect ? this.value.includes(opt.value) : opt.value === this.value;
      const el = document.createElement("div");
      el.className = "eip-sd-option" + (isSelected ? " eip-sd-selected" : "");
      el.dataset.value = opt.value;
      el.title = opt.label;
      el.tabIndex = -1;
      const labelHtml = t ? SearchableDropdown._highlightTerm(opt.label, t) : SearchableDropdown._escapeHtml(opt.label);
      if (this.multiSelect) {
        el.innerHTML = `<span class="eip-sd-checkbox">${isSelected ? "☑" : "☐"}</span>NULL${opt.badge ? ` <span class="eip-sd-badge">${SearchableDropdown._escapeHtml(opt.badge)}</span>` : ""}`;
      } else {
        el.innerHTML = labelHtml;
      }
      this.list.appendChild(el);
    });
  }

  _bindEvents() {
    this.trigger.addEventListener("click", (e) => {
      e.stopPropagation();
      if (this.isDisabled) {
        if (this.onBlockedClick) this.onBlockedClick();
        return;
      }
      if (this.panel.classList.contains("eip-sd-open")) this.close();
      else this.open();
    });
    this.trigger.addEventListener("keydown", (e) => {
      if (this.isDisabled) return;
      if (e.key === "Enter" || e.key === " ") { e.preventDefault(); this.open(); }
    });

    this.searchInput.addEventListener("input", () => this._renderList(this.searchInput.value));
    this.searchInput.addEventListener("keydown", (e) => {
      if (e.key === "Escape") { this.close(); this.trigger.focus(); }
      if (e.key === "ArrowDown") {
        e.preventDefault();
        const first = this.list.querySelector(".eip-sd-option, .eip-sd-none-opt");
        if (first) first.focus();
      }
    });

    this.list.addEventListener("keydown", (e) => {
      const opts = Array.from(this.list.querySelectorAll(".eip-sd-option, .eip-sd-none-opt"));
      const idx = opts.indexOf(document.activeElement);
      if (e.key === "ArrowDown") { e.preventDefault(); opts[Math.min(idx + 1, opts.length - 1)]?.focus(); }
      else if (e.key === "ArrowUp") {
        e.preventDefault();
        if (idx <= 0) this.searchInput.focus(); else opts[idx - 1]?.focus();
      } else if (e.key === "Escape") { this.close(); this.trigger.focus(); }
      else if (e.key === "Enter") { e.preventDefault(); document.activeElement.click(); }
    });

    this.list.addEventListener("click", (e) => {
      const opt = e.target.closest(".eip-sd-option, .eip-sd-none-opt");
      if (!opt) return;

      if (this.multiSelect) {
        if (opt.dataset.value === "__clear__") {
          this.value = [];
        } else {
          const idx = this.value.indexOf(opt.dataset.value);
          if (idx === -1) this.value.push(opt.dataset.value);
          else this.value.splice(idx, 1);
        }
        this._updateTriggerLabel();
        this._renderList(this.searchInput.value); // stay open — user may pick more
        this.onChange([...this.value]);
        return;
      }

      this.value = opt.dataset.value;
      this._updateTriggerLabel();
      this._renderList(this.searchInput.value);
      this.close();
      this.trigger.focus();
      this.onChange(this.value);
    });
  }

  open() {
    if (SearchableDropdown.activeInstance && SearchableDropdown.activeInstance !== this) {
      SearchableDropdown.activeInstance.close();
    }
    SearchableDropdown.activeInstance = this;
    this.panel.classList.remove("eip-hidden");
    this.panel.classList.add("eip-sd-open");

    const rect = this.trigger.getBoundingClientRect();
    this.panel.style.position = "fixed";
    this.panel.style.top = `${rect.bottom + 4}px`;
    this.panel.style.left = `${rect.left}px`;
    this.panel.style.width = `${Math.max(rect.width, 220)}px`;

    const panelH = this.panel.offsetHeight || 260;
    const maxTop = window.innerHeight - panelH - 8;
    if (parseFloat(this.panel.style.top) > maxTop) this.panel.style.top = `${Math.max(8, maxTop)}px`;

    const panelW = parseFloat(this.panel.style.width) || 220;
    if (rect.left + panelW > window.innerWidth - 8) {
      this.panel.style.left = `${Math.max(8, window.innerWidth - panelW - 8)}px`;
    }

    this.searchInput.value = "";
    this._renderList("");
    this.searchInput.focus();
  }

  close() {
    this.panel.classList.remove("eip-sd-open");
    this.panel.classList.add("eip-hidden");
    if (SearchableDropdown.activeInstance === this) SearchableDropdown.activeInstance = null;
  }

  setOptions(options) {
    this.options = options || [];
    this._updateTriggerLabel();
    this._renderList(this.searchInput ? this.searchInput.value : "");
  }

  setValue(value) {
    this.value = this.multiSelect ? (Array.isArray(value) ? [...value] : []) : (value || "");
    this._updateTriggerLabel();
    this._renderList(this.searchInput ? this.searchInput.value : "");
  }

  setDisabled(isDisabled, message) {
    this.isDisabled = !!isDisabled;
    this.disabledMessage = message || "";
    this.host.classList.toggle("eip-disabled-visual", this.isDisabled);
  }

  destroy() {
    this.close();
    if (this.panel && this.panel.parentNode) this.panel.parentNode.removeChild(this.panel);
  }
}

// Global click-away + scroll close (registered once at module load,
// same as brsv2''s document-level mousedown listener).
document.addEventListener("mousedown", (e) => {
  const active = SearchableDropdown.activeInstance;
  if (active && !active.host.contains(e.target) && !active.panel.contains(e.target)) {
    active.close();
  }
}, true);
document.addEventListener("scroll", (e) => {
  const active = SearchableDropdown.activeInstance;
  if (!active) return;
  // Ignore scrolling inside the panel itself (e.g. the option list) —
  // only close when something outside it (the page, the grid wrapper)
  // scrolls, so the panel doesn''t end up detached from its trigger.
  if (active.panel.contains(e.target)) return;
  active.close();
}, true);

/* =========================================================
   ExcelImportPageController
   ========================================================= */
class ExcelImportPageController {
  constructor() {
    this._database = new ExcelImportDatabase();

    this._currentJobId = null;
    this._currentJob = null;      // full job record (metadata)
    this._rows = [];              // in-memory cache of staged rows for the current job
    this._allFields = [];         // T-Struct field metadata for current job''s transId
    this._dcTypeByName = {};      // dcname -> "Grid" | "Non-Grid", from the last-loaded DC options
    this._keyFieldCandidates = []; // non-grid fields across ALL of the T-Struct''s DCs, independent of the current sheet''s DC selection
    this._uploadedFilesByJobId = new Map(); // jobId -> original File object, in-memory only (for the a__ic attachment push)
    this._currentJobIsFirstSheet = true; // whether the current job is sheet 1 of its T-Struct group — gates the Group field checkbox
    this._validationModalColumnIndex = null;

    this._tstructDropdown = null;
    this._keyFieldDropdown = null;
    this._jobDropdown = null;
    this._columnMappingDropdowns = []; // recreated every _renderGrid() call — destroyed first
    this._isPolling = false; // guards against overlapping poll cycles

    // Elapsed-time tracking for imports (see _onImportClicked /
    // _runCombinedImport / _pollRedisForUpdates): callerId -> { startedAt,
    // totalRows } for every push still awaiting full confirmation, so we
    // can log the real total duration once every row for that callerId
    // reaches a terminal status, and roll it into a small history used to
    // estimate future imports'' duration from their record count.
    this._importStartTimes = new Map();
    this._elapsedTickerInterval = null;

    this._dom = {
      fileInput: document.getElementById("eipFileInput"),
      fileBtn: document.getElementById("eipFileBtn"),
      fileNameLabel: document.getElementById("eipFileName"),
      tstructSelect: document.getElementById("eipTstructSelect"),
      dcSelect: document.getElementById("eipDcSelect"),
      tstructDcGroup: document.getElementById("eipTstructDcGroup"),
      priorApiItemWrap: document.getElementById("eipPriorApiItemWrap"),
      tabControlsRow: document.getElementById("eipTabControlsRow"),
      topbar: document.getElementById("eipTopbar"),
      keyFieldSelect: document.getElementById("eipKeyFieldSelect"),
      priorApiCheckbox: document.getElementById("eipPriorApiCheckbox"),
      jobSelect: document.getElementById("eipJobSelect"),
      newImportBtn: document.getElementById("eipNewImportBtn"),
      deleteJobBtn: document.getElementById("eipDeleteJobBtn"),

      sheetTabs: document.getElementById("eipSheetTabs"),
      gridWrapper: document.getElementById("eipGridWrapper"),
      gridEmptyNote: document.getElementById("eipGridEmptyNote"),
      gridTable: document.getElementById("eipGridTable"),
      gridMappingRow: document.getElementById("eipGridMappingRow"),
      gridHeaderRow: document.getElementById("eipGridHeaderRow"),
      gridBody: document.getElementById("eipGridBody"),

      summaryLabel: document.getElementById("eipSummaryLabel"),
      timingLabel: document.getElementById("eipTimingLabel"),
      validateBtn: document.getElementById("eipValidateBtn"),
      importBtn: document.getElementById("eipImportBtn"),
      refreshBtn: document.getElementById("eipRefreshBtn"),
      saveMappingBtn: document.getElementById("eipSaveMappingBtn"),
      downloadErrorsBtn: document.getElementById("eipDownloadErrorsBtn"),

      progressModalOverlay: document.getElementById("eipProgressModalOverlay"),
      progressCloseBtn: document.getElementById("eipProgressCloseBtn"),
      progressBarFill: document.getElementById("eipProgressBarFill"),
      progressLabel: document.getElementById("eipProgressLabel"),
      progressElapsed: document.getElementById("eipProgressElapsed"),
      logList: document.getElementById("eipLogList"),
      toast: document.getElementById("eipToast"),

      valModalOverlay: document.getElementById("eipValidationModalOverlay"),
      valModalTitle: document.getElementById("eipValidationModalTitle"),
      valMandatory: document.getElementById("eipValMandatory"),
      valMin: document.getElementById("eipValMin"),
      valMax: document.getElementById("eipValMax"),
      valAllowed: document.getElementById("eipValAllowed"),
      valSaveBtn: document.getElementById("eipValSaveBtn"),
      valCancelBtn: document.getElementById("eipValCancelBtn"),

      confirmModalOverlay: document.getElementById("eipConfirmModalOverlay"),
      confirmModalTitle: document.getElementById("eipConfirmModalTitle"),
      confirmModalMessage: document.getElementById("eipConfirmModalMessage"),
      confirmCancelBtn: document.getElementById("eipConfirmCancelBtn"),
      confirmOkBtn: document.getElementById("eipConfirmOkBtn"),
    };
  }

  async init() {
    await this._database.open();
    this._bindEvents();
    await this._loadTStructDropdown();
    await this._refreshJobSelector();

    const jobs = await this._database.getAllJobs();
    if (jobs.length > 0) {
      jobs.sort((a, b) => (b.lastActiveAt || 0) - (a.lastActiveAt || 0));
      await this._loadJob(jobs[0].jobId);
    }

    // Poll Redis for import-progress confirmations every 30s. Runs across
    // ALL jobs (not just the currently-loaded one), so status keeps
    // updating even if the user switches jobs mid-poll — matches the
    // "navigate away and come back" requirement.
    this._redisPollTimer = setInterval(() => this._pollRedisForUpdates(), 30000);
  }

  _bindEvents() {
    this._dom.fileBtn.addEventListener("click", () => this._dom.fileInput.click());
    this._dom.fileInput.addEventListener("change", () => this._onFileSelected());

    this._tstructDropdown = new SearchableDropdown(this._dom.tstructSelect, {
      options: [],
      value: "",
      placeholder: "Select T-Struct…",
      onChange: (transId) => this._onTStructChange(transId),
    });

    this._dcDropdown = new SearchableDropdown(this._dom.dcSelect, {
      options: [],
      value: [],
      placeholder: "Select DC…",
      multiSelect: true,
      onChange: (selectedDcNames) => this._onDcSelectionChanged(selectedDcNames),
    });
    this._dcDropdown.setDisabled(true);
    this._dcDropdown.onBlockedClick = () => {
      this._showToast("Select a T-Struct first.", "error");
    };

    this._keyFieldDropdown = new SearchableDropdown(this._dom.keyFieldSelect, {
      options: [],
      value: "",
      placeholder: "Select key field…",
      onChange: (fieldName) => this._onKeyFieldChanged(fieldName),
    });
    this._keyFieldDropdown.setDisabled(true);
    this._keyFieldDropdown.onBlockedClick = () => {
      this._showToast("Select a T-Struct with header (non-grid) fields first.", "error");
    };

    this._jobDropdown = new SearchableDropdown(this._dom.jobSelect, {
      options: [],
      value: "",
      placeholder: "(no jobs yet)",
      allowClear: false,
      onChange: (jobId) => { if (jobId) this._loadJob(jobId); },
    });

    this._dom.priorApiCheckbox.addEventListener("change", () => {
      if (!this._currentJob) return;
      this._currentJob.useAxPut = !this._dom.priorApiCheckbox.checked;
      this._saveCurrentJob();
    });
    this._dom.newImportBtn.addEventListener("click", () => this._onNewImportClicked());
    this._dom.deleteJobBtn.addEventListener("click", () => this._onDeleteJobClicked());
    this._dom.validateBtn.addEventListener("click", () => this._onValidateClicked());
    this._dom.importBtn.addEventListener("click", () => this._onImportClicked());
    this._dom.refreshBtn.addEventListener("click", () => this._pollRedisForUpdates(true, true));
    this._dom.saveMappingBtn.addEventListener("click", () => this._onSaveMappingClicked());
    this._dom.downloadErrorsBtn.addEventListener("click", () => this._onDownloadErrorsClicked());
    this._dom.progressCloseBtn.addEventListener("click", () => this._closeProgressPopup());

    this._dom.valSaveBtn.addEventListener("click", () => this._onValidationModalSave());
    this._dom.valCancelBtn.addEventListener("click", () => this._closeValidationModal());
  }

  /* ---------------------------------------------------------
     Session params
     --------------------------------------------------------- */
  _resolveSessionParams() {
    const armSessionId = (typeof ARMSessionId !== "undefined" ? ARMSessionId : "") || (parent.ARMSessionId || "");
    const armToken = (typeof ARMToken !== "undefined" ? ARMToken : "") || (parent.ARMToken || "");
    const project = parent.mainProject ? parent.mainProject : "";
    const username = parent.mainUserName ? parent.mainUserName : (parent.gll_userName || "");
    const sessionId = (typeof sessionid !== "undefined" && sessionid) ? sessionid : (parent.sessionid || "");
    return { armSessionId, armToken, project, username, sessionId };
  }

  /* ---------------------------------------------------------
     Data source loading — direct parent.GetDataFromAxList calls.
     --------------------------------------------------------- */
  async _loadTStructDropdown() {
var userResp = getParentWindowValue("userResp");
        var mainUserName = getParentWindowValue("mainUserName");
        var AxUserRoles = getParentWindowValue("AxUserRoles");
    const callParams = {
      adsNames: [EIP_data_ing_tstructs],
      refreshCache: true,
      sqlParams: { pusername: mainUserName, puserrole: AxUserRoles, presponsiblity: userResp },
      props: { ADS: true, getallrecordscount: false, pageno: 1, pagesize: 0 },
    };
    const rows = await new Promise((resolve) => {
      parent.GetDataFromAxList(
        callParams,
        (response) => resolve(this._parseDataSourceResponse(response)),
        (err) => { console.error("[EIP] data_ing_tstructs fetch failed", err); resolve([]); }
      );
    });
    this._tstructDropdown.setOptions(rows.map((row) => ({ value: row.value, label: row.text })));
  }

  // Non-mutating fetch — returns the field list for a given transId/DC
  // selection WITHOUT touching this._allFields (the shared cache scoped to
  // whichever tab is currently active). Combined multi-sheet import needs
  // each sibling sheet''s OWN fields, independent of the active tab, so it
  // calls this directly instead of going through _loadFieldsForTStruct.
  async _fetchFieldsForTStruct(transId, dcNames = []) {
    if (!transId || !dcNames || dcNames.length === 0) return [];
    const callParams = {
      adsNames: [EIP_data_ing_tstruct_fields],
      refreshCache: true,
      sqlParams: { transid: transId, dcname: dcNames.join(",") },
      props: { ADS: true, getallrecordscount: false, pageno: 1, pagesize: 0 },
    };
    const rows = await new Promise((resolve) => {
      parent.GetDataFromAxList(
        callParams,
        (response) => resolve(this._parseDataSourceResponse(response)),
        (err) => { console.error("[EIP] data_ing_tstruct_fields fetch failed", err); resolve([]); }
      );
    });
    return rows.map((row) => ({
      fieldName: row.value,
      caption: row.text,
      isGridField: String(row.asgrid).trim().toUpperCase() === "T",
      formNumber: Number(row.frmno),
      dataType: row.datatype,
    }));
  }

  async _loadFieldsForTStruct(transId, dcNames = []) {
    this._allFields = await this._fetchFieldsForTStruct(transId, dcNames);
    console.log(`[EIP] Loaded ${this._allFields.length} field(s) for T-Struct "${transId}" / DC(s) [${dcNames.join(", ")}]:`, this._allFields);
  }

  // Key Field is a T-Struct-wide concept — it must NOT depend on which
  // DC(s) the current sheet happens to have selected (a sheet might not
  // have any DC chosen yet, or might be scoped to just one grid DC).
  // So this fetches non-grid fields across ALL of the T-Struct''s DCs
  // (using every DC name from data_ing_tstruct_dcs as the :dcname filter, not
  // just the current sheet''s selection), giving the same Key Field
  // choices regardless of which sheet/DC is active.
  async _loadKeyFieldCandidates(transId, allDcNames) {
    if (!transId || !allDcNames || allDcNames.length === 0) {
      this._keyFieldCandidates = [];
      return;
    }
    const callParams = {
      adsNames: [EIP_data_ing_tstruct_fields],
      refreshCache: true,
      sqlParams: { transid: transId, dcname: allDcNames.join(",") },
      props: { ADS: true, getallrecordscount: false, pageno: 1, pagesize: 0 },
    };
    const rows = await new Promise((resolve) => {
      parent.GetDataFromAxList(
        callParams,
        (response) => resolve(this._parseDataSourceResponse(response)),
        (err) => { console.error("[EIP] data_ing_tstruct_fields fetch failed (key field candidates)", err); resolve([]); }
      );
    });
    this._keyFieldCandidates = rows
      .filter((row) => String(row.asgrid).trim().toUpperCase() !== "T")
      .map((row) => ({ fieldName: row.value, caption: row.text }));
    console.log(`[EIP] Loaded ${this._keyFieldCandidates.length} Key Field candidate(s) for T-Struct "${transId}" (all DCs):`, this._keyFieldCandidates);
  }

  // Fetches the list of DCs (data collections) belonging to a T-Struct —
  // each one flagged Grid or Non-Grid — for the DC multiselect.
  async _loadDcOptionsForTStruct(transId) {
    if (!transId) return [];
    const callParams = {
      adsNames: [EIP_data_ing_tstruct_dcs],
      refreshCache: true,
      sqlParams: { transid: transId },
      props: { ADS: true, getallrecordscount: false, pageno: 1, pagesize: 0 },
    };
    const rows = await new Promise((resolve) => {
      parent.GetDataFromAxList(
        callParams,
        (response) => resolve(this._parseDataSourceResponse(response)),
        (err) => { console.error("[EIP] data_ing_tstruct_dcs fetch failed", err); resolve([]); }
      );
    });
    console.log(`[EIP] Loaded ${rows.length} DC(s) for T-Struct "${transId}":`, rows);
    return rows.map((row) => ({
      value: row.value,
      // Show both caption and the underlying DC name, same "Caption(name)"
      // convention used for field mapping dropdowns elsewhere in the page.
      label: row.text ? `${row.text}(${row.value})` : row.value,
      badge: String(row.asgrid).trim().toUpperCase() === "T" ? "Grid" : "Non-Grid",
    }));
  }

  _parseDataSourceResponse(response) {
    let rows = [];
    try {
      let payload = typeof response === "string" ? JSON.parse(response) : response;
      if (payload && payload.d !== undefined) {
        payload = typeof payload.d === "string" ? JSON.parse(payload.d) : payload.d;
      }
      if (Array.isArray(payload)) {
        if (payload.length > 0 && payload[0] !== null && typeof payload[0] === "object") {
          if (payload[0].data_json) {
            const dj = typeof payload[0].data_json === "string" ? JSON.parse(payload[0].data_json) : payload[0].data_json;
            rows = Array.isArray(dj) ? dj : [dj];
          } else if (payload[0].data) {
            rows = Array.isArray(payload[0].data) ? payload[0].data : [payload[0].data];
          } else {
            rows = payload;
          }
        } else {
          rows = payload;
        }
      } else if (payload && typeof payload === "object") {
        if (payload.result && payload.result.data) {
          const d = payload.result.data;
          if (typeof d === "string") rows = JSON.parse(d);
          else if (Array.isArray(d)) rows = d[0] && d[0].data ? d[0].data : d;
        } else if (payload.data) {
          rows = Array.isArray(payload.data) ? payload.data : [payload.data];
        }
      }
    } catch (e) {
      console.error("[EIP] Failed parsing DS response", e);
    }
    return Array.isArray(rows) ? rows : rows ? [rows] : [];
  }

  /* ---------------------------------------------------------
     T-Struct change
     --------------------------------------------------------- */
  async _onTStructChange(transId) {
    const opToken = Symbol("tstructChange");
    this._latestLoadJobToken = opToken;
    const isStale = () => this._latestLoadJobToken !== opToken;

    this._allFields = []; // fields now depend on DC selection too — cleared until a DC is chosen

    if (this._currentJob) {
      this._currentJob.transId = transId;
      // Field set changed -> existing column mappings, key field, and DC
      // selection may no longer be valid, so reset them (the Excel data
      // itself is untouched).
      this._currentJob.keyFieldName = null;
      this._currentJob.selectedDcNames = [];
      if (this._currentJob.columnMappings) {
        this._currentJob.columnMappings = this._currentJob.columnMappings.map(() => ({
          mappedFieldName: null,
          isGroupField: false,
        }));
      }
      this._currentJob.validationRules = {};
      await this._saveCurrentJob();
      if (isStale()) return;
      this._currentJobIsFirstSheet = await this._isFirstSheetOfTStructGroup(this._currentJob);
      if (isStale()) return;
    }

    const dcOptions = await this._loadDcOptionsForTStruct(transId);
    if (isStale()) return;
    this._dcTypeByName = Object.fromEntries(dcOptions.map((o) => [o.value, o.badge]));
    this._dcDropdown.setOptions(dcOptions);
    this._dcDropdown.setValue([]);
    this._dcDropdown.setDisabled(dcOptions.length === 0);
    await this._loadKeyFieldCandidates(transId, dcOptions.map((o) => o.value));
    if (isStale()) return;

    this._renderKeyFieldDropdown();
    if (this._currentJob) this._renderGridHeader();
  }

  // The first sheet (by upload/tab order) targeting a given T-Struct is
  // unrestricted — it can mix grid and non-grid DCs freely. Every OTHER
  // sheet targeting the same T-Struct is restricted to either:
  //   - exactly one grid DC (and no non-grid DCs), or
  //   - one or more non-grid DCs (and no grid DC at all)
  // never a mix of the two, and never more than one grid DC.
  async _isFirstSheetOfTStructGroup(job) {
    const siblings = await this._getTStructGroupSiblings(job);
    if (siblings.length === 0) return true;
    return siblings[0].jobId === job.jobId;
  }

  async _validateDcSelectionForSheet(job, selectedDcNames) {
    const isFirstSheet = await this._isFirstSheetOfTStructGroup(job);
    if (isFirstSheet) return { valid: true };

    const gridSelected = selectedDcNames.filter((name) => this._dcTypeByName[name] === "Grid");
    const nonGridSelected = selectedDcNames.filter((name) => this._dcTypeByName[name] === "Non-Grid");

    if (gridSelected.length > 0 && nonGridSelected.length > 0) {
      return { valid: false, message: "This sheet isn''t the first for this T-Struct — pick either grid DC(s) or non-grid DC(s), not both." };
    }
    if (gridSelected.length > 1) {
      return { valid: false, message: "This sheet isn''t the first for this T-Struct — only one grid DC is allowed here." };
    }
    return { valid: true };
  }

  // DC selection determines which fields are even fetchable (per the
  // updated data_ing_tstruct_fields query, which requires :dcname) — so this is where
  // fields actually get loaded and remembered mappings get applied, not
  // at T-Struct selection time anymore.
  async _onDcSelectionChanged(selectedDcNames) {
    if (!this._currentJob) return;

    const validation = await this._validateDcSelectionForSheet(this._currentJob, selectedDcNames);
    if (!validation.valid) {
      // Revert the widget to the last valid selection and explain why.
      this._dcDropdown.setValue(this._currentJob.selectedDcNames || []);
      this._showToast(validation.message, "error");
      return;
    }

    const opToken = Symbol("dcChange");
    this._latestLoadJobToken = opToken;
    const isStale = () => this._latestLoadJobToken !== opToken;

    this._currentJob.selectedDcNames = selectedDcNames;

    await this._loadFieldsForTStruct(this._currentJob.transId, selectedDcNames);
    if (isStale()) return;

    // Field set changed -> existing column mappings may no longer be
    // valid, so reset before re-applying remembered mappings. Key Field
    // is NOT reset here — it''s a T-Struct-wide choice independent of
    // this sheet''s own DC selection (see _loadKeyFieldCandidates), so
    // changing DC shouldn''t desync it from the other sheets in the group.
    this._currentJob.columnMappings = this._currentJob.columnMappings.map(() => ({
      mappedFieldName: null,
      isGroupField: false,
    }));
    this._currentJob.validationRules = {};
    await this._applyRememberedMappings(this._currentJob);
    if (isStale()) return;
    await this._saveCurrentJob();
    if (isStale()) return;

    this._renderKeyFieldDropdown();
    this._renderGridHeader();
  }

  // Fetches previously-saved mappings for this T-Struct from the shared
  // server-side memory (a__im T-Struct, via data_ing_field_mapping) —
  // this is what makes mappings shared across users/browsers, unlike the
  // IndexedDB-only memory this replaces as the primary source.
  //
  // Query joins a__imheader (dc1: transid, groupfield, keyfield — one
  // row per save) with a__imdetails (dc2: excelheader, mappedfield —
  // one row per mapped column), so every returned row carries the SAME
  // groupfield/keyfield values (from dc1). groupfield holds the Excel
  // HEADER TEXT of whichever column was the group column (not a T/F
  // flag) — a column is the group column iff its header matches that
  // value.
  //
  // No timestamp column exists yet, and every save currently INSERTs
  // (no upsert/edit yet — see chat notes), so if the same transid has
  // been saved more than once over time, rows from multiple saves come
  // back mixed together in excelheader-alphabetical order (NOT recency
  // order), and whichever is processed LAST here wins per header. This
  // is a known rough edge until upsert/edit lands on the write side.
  async _loadServerMappingMemory(transId) {
    const callParams = {
      adsNames: [EIP_data_ing_field_mapping],
      refreshCache: true,
      sqlParams: { transid: transId },
      props: { ADS: true, getallrecordscount: false, pageno: 1, pagesize: 0 },
    };
    const rows = await new Promise((resolve) => {
      parent.GetDataFromAxList(
        callParams,
        (response) => resolve(this._parseDataSourceResponse(response)),
        (err) => { console.error("[EIP] data_ing_field_mapping fetch failed", err); resolve([]); }
      );
    });
    if (rows.length === 0) return null;

    let groupFieldHeader = null;
    let keyFieldName = null;
    rows.forEach((row) => {
      if (row.groupfield) groupFieldHeader = row.groupfield;
      if (row.keyfield) keyFieldName = row.keyfield;
    });

    const columnsByHeader = {};
    rows.forEach((row) => {
      columnsByHeader[row.value] = {
        mappedFieldName: row.text,
        isGroupField: groupFieldHeader !== null && row.value === groupFieldHeader,
      };
    });
    return { transId, columnsByHeader, keyFieldName };
  }

  // Looks up this T-Struct''s remembered header->field mappings (built up
  // from every prior job''s manual choices) and pre-fills any column
  // whose Excel header text matches — matching by header TEXT, not file
  // identity, so it works for "same file re-uploaded" as well as "a
  // different file with the same/similar column headers". Only applies
  // a remembered field if it still exists on the current T-Struct (in
  // case fields changed since). Always fully editable afterward.
  //
  // Prefers the shared server-side memory; falls back to the local
  // IndexedDB memory only if the server has nothing for this T-Struct
  // yet (e.g. offline, or before anyone has saved to the server at all).
  async _applyRememberedMappings(job) {
    if (!job.transId || !job.excelHeaders || !job.columnMappings) return;

    let memory = await this._loadServerMappingMemory(job.transId);
    if (!memory) {
      memory = await this._database.getMappingMemory(job.transId);
    }
    if (!memory) return;

    let appliedCount = 0;
    job.excelHeaders.forEach((header, colIndex) => {
      if (colIndex === job.axModeColumnIndex) return;
      const remembered = memory.columnsByHeader && memory.columnsByHeader[header];
      if (!remembered || !remembered.mappedFieldName) return;
      const fieldStillExists = this._allFields.some((f) => f.fieldName === remembered.mappedFieldName);
      if (!fieldStillExists) return;
      job.columnMappings[colIndex] = {
        mappedFieldName: remembered.mappedFieldName,
        isGroupField: !!remembered.isGroupField,
      };
      appliedCount++;
    });

    if (memory.keyFieldName && !job.keyFieldName) {
      const keyFieldStillValid = this._keyFieldCandidates.some((f) => f.fieldName === memory.keyFieldName);
      if (keyFieldStillValid) job.keyFieldName = memory.keyFieldName;
    }

    if (appliedCount > 0) {
      console.log(`[EIP] Auto-applied ${appliedCount} remembered column mapping(s) for T-Struct "${job.transId}".`);
      this._showToast(`Auto-mapped ${appliedCount} column(s) from a previous import — review and adjust if needed.`, "info");
    }
  }

  // Persists this column''s mapping choice against the current T-Struct,
  // so future uploads (same or different file) with a matching header
  // text get it pre-filled automatically.
  async _rememberColumnMapping(colIndex) {
    if (!this._currentJob || !this._currentJob.transId) return;
    const header = this._currentJob.excelHeaders[colIndex];
    const mapping = this._currentJob.columnMappings[colIndex];
    const memory = (await this._database.getMappingMemory(this._currentJob.transId)) || {
      transId: this._currentJob.transId,
      columnsByHeader: {},
      keyFieldName: null,
    };
    memory.columnsByHeader = memory.columnsByHeader || {};
    if (mapping.mappedFieldName) {
      memory.columnsByHeader[header] = { mappedFieldName: mapping.mappedFieldName, isGroupField: !!mapping.isGroupField };
    } else {
      delete memory.columnsByHeader[header];
    }
    memory.updatedAt = Date.now();
    await this._database.putMappingMemory(memory);
  }

  // Persists the chosen key field against the current T-Struct.
  async _rememberKeyField(keyFieldName) {
    if (!this._currentJob || !this._currentJob.transId) return;
    const memory = (await this._database.getMappingMemory(this._currentJob.transId)) || {
      transId: this._currentJob.transId,
      columnsByHeader: {},
      keyFieldName: null,
    };
    memory.keyFieldName = keyFieldName || null;
    memory.updatedAt = Date.now();
    await this._database.putMappingMemory(memory);
  }

  // Saves the current job''s column mappings to the shared a__im T-Struct
  // — triggered by clicking Import (silent, fire-and-forget) OR by
  // clicking "Save Mapping" directly (showFeedback:true, gives the user
  // a toast either way), letting mappings be shared even before anyone
  // actually runs an import.
  // dc1 (header, single row) holds form/groupfield/keyfield; dc2
  // (grid, one row per mapped column) holds excelheader/mappedfield.
  // groupfield is the Excel HEADER TEXT of whichever column was chosen
  // as the group column (not a per-row flag), or "" if none was chosen.
  // Always inserts a new dc1+dc2 set (no upsert/edit yet, per the team''s
  // current plan — will need revisiting once the write side supports
  // updating an existing record by transid). Always uses the AxPut
  // format regardless of the "Use prior version of API" checkbox, since
  // that setting is about the user''s DATA import, not this internal
  // bookkeeping save.
  async _saveMappingMemoryToServer(job, { showFeedback = false } = {}) {
    if (!job.transId || !job.excelHeaders || !job.columnMappings) return;

    const dc2Rows = [];
    let groupFieldHeader = "";
    job.columnMappings.forEach((mapping, colIndex) => {
      if (colIndex === job.axModeColumnIndex) return;
      if (!mapping.mappedFieldName) return;
      dc2Rows.push({
        "excelheader": job.excelHeaders[colIndex],
        "mappedfield": mapping.mappedFieldName,
      });
      if (mapping.isGroupField) groupFieldHeader = job.excelHeaders[colIndex];
    });
    if (dc2Rows.length === 0) {
      if (showFeedback) this._showToast("Map at least one column before saving.", "error");
      return;
    }

    const { armSessionId, armToken, project, username } = this._resolveSessionParams();
    const dc2 = {};
    dc2Rows.forEach((row, idx) => { dc2[`row${idx + 1}`] = row; });

    const payload = {
      "_parameters": [{
        "ARMSessionId": armSessionId,
        "ARMToken": armToken,
        "isaxput": "true",
        "mobile": "false",
        "project": project,
        "username": username,
        "trace": false,
        "validateonly": false,
        "axclient_dateformat": "dd/MM/yyyy",
        "millisecsintimestamp": true,
        "data": [{
          "transid": EIP_MAPPING_MEMORY_TSTRUCT,
          "action": "create",
          "returnfield": "form",
          "submitdata": {
            "dc1": { "row1": { "form": job.transId, "groupfield": groupFieldHeader, "keyfield": job.keyFieldName || "" } },
            "dc2": dc2,
          },
        }],
      }],
    };
    const jsonDataString = JSON.stringify(payload);
    console.log(`[EIP] Saving ${dc2Rows.length} field mapping(s) to shared memory (a__im) for T-Struct "${job.transId}":`, payload);

    try {
      const res = await this._pushToQueue(jsonDataString);
      console.log("[EIP] Field mapping memory save succeeded:", res);
      if (showFeedback) this._showToast(`Saved ${dc2Rows.length} column mapping(s) for other users to reuse.`, "success");
    } catch (err) {
      console.error("[EIP] Field mapping memory save failed:", err);
      if (showFeedback) this._showToast(`Failed to save mapping: ${err.message || err}`, "error");
    }
  }

  // Reads a File as a base64 string (the part after the data-URL comma),
  // for the a__ic attachment push below.
  _fileToBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => {
        const dataUrl = reader.result || "";
        const base64 = String(dataUrl).split(",")[1] || "";
        resolve(base64);
      };
      reader.onerror = () => reject(reader.error);
      reader.readAsDataURL(file);
    });
  }

  // Pushes the originally-uploaded Excel file itself (as a base64
  // attachment) to the a__ic T-Struct — completely separate from the
  // actual data import and the mapping-memory save. Triggered once per
  // Import click (not per sheet — one physical file, possibly several
  // sheets/jobs). Fire-and-forget: no callerid/sequenceno, no Redis
  // polling, just logs the outcome and never blocks the rest of Import.
  // Silently skipped if the original file isn''t available in memory
  // (e.g. the page was reloaded since upload) — the data import itself
  // still proceeds either way.
  async _pushExcelFileAttachment(job) {
    if (!job) return;
    const file = this._uploadedFilesByJobId.get(job.jobId);
    if (!file) {
      console.warn(`[EIP] No original file in memory for job "${job.jobId}" — skipping a__ic attachment push.`);
      return;
    }

    try {
      const base64Data = await this._fileToBase64(file);
      const { armSessionId, armToken, project, username } = this._resolveSessionParams();

      const now = new Date();
      const docdate = this._formatDdMmYyyy(now.getFullYear(), now.getMonth() + 1, now.getDate());
      const doctime = `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`; // 24h HH:mm — not explicitly specified, flagged for confirmation

      const payload = {
        "_parameters": [{
          "ARMSessionId": armSessionId,
          "ARMToken": armToken,
          "isaxput": "true",
          "project": project,
          "username": username,
          "trace": true,
          "validateonly": false,
          "axclient_dateformat": "dd/MM/yyyy",
          "millisecsintimestamp": true,
          "data": [{
            "transid": "a__ic",
            "action": "create",
            "submitdata": {
              "dc1": {
                "row1": {
                  "importedby": username,
                  "docdate": docdate,
                  "doctime": doctime,
                  "axpfile_bankattachments": JSON.stringify([{
                    FileName: file.name,
                    AttachmentType: "AXPFILE",
                    DataFormat: "BASE64",
                    FileData: base64Data,
                  }]),
                },
              },
            },
          }],
        }],
      };
      const jsonDataString = JSON.stringify(payload);
      console.log(`[EIP] Pushing uploaded Excel file "${file.name}" to a__ic:`, payload);

      const res = await this._pushToQueue(jsonDataString);
      console.log("[EIP] a__ic file attachment push succeeded:", res);
    } catch (err) {
      console.error("[EIP] a__ic file attachment push failed (non-blocking):", err);
    }
  }

  _onSaveMappingClicked() {
    if (!this._currentJob) {
      this._showToast("Upload a file first.", "error");
      return;
    }
    if (!this._currentJob.transId) {
      this._showToast("Select a T-Struct first.", "error");
      return;
    }
    this._saveMappingMemoryToServer(this._currentJob, { showFeedback: true });
  }

  // Downloads every row currently marked "error" (failed validation) or
  // "failed" (Redis-confirmed processing failure), as an .xlsx with the
  // original columns plus Status/Reason — so the user can review, fix,
  // and re-import just the problem rows.
  //
  // When this sheet is joined to sibling sheets by a shared Key Field
  // (the same setup _runCombinedImport pushes as ONE cross-sheet
  // transaction per Key Field value), a single error can only be fully
  // understood by looking at ALL the connected sheets'' data for that Key
  // Field value — not just whichever tab you happen to be sitting on. So
  // in that case we build one combined export with every sibling
  // sheet''s own columns side by side, matched by Key Field value,
  // instead of the naive single-sheet export (which was the bug: it
  // only ever read this._rows / this._currentJob.excelHeaders, i.e.
  // ONLY the active tab, same class of mistake as the old combined-
  // import bug that only carried the active sheet''s dc).
  async _onDownloadErrorsClicked() {
    if (!this._currentJob || this._rows.length === 0) {
      this._showToast("No data loaded.", "error");
      return;
    }

    const siblings = await this._getTStructGroupSiblings(this._currentJob);
    const isCrossSheet = siblings.length > 1 && !!this._currentJob.keyFieldName;

    if (!isCrossSheet) {
      this._downloadSingleSheetErrors(this._currentJob, this._rows);
      return;
    }

    await this._downloadCombinedSheetErrors(siblings);
  }

  // Single-sheet export — unchanged behavior for a sheet that isn''t
  // joined to any siblings by a Key Field.
  _downloadSingleSheetErrors(job, rows) {
    const errorRows = rows.filter((r) => r.status === "error" || r.status === "failed");
    if (errorRows.length === 0) {
      this._showToast("No error rows to download.", "info");
      return;
    }

    const headers = job.excelHeaders;
    const aoa = [[...headers, "Status", "Reason"]];
    errorRows.forEach((row) => {
      aoa.push([...this._rowCellsForExport(row, headers), ...this._rowStatusForExport(row)]);
    });

    const worksheet = XLSX.utils.aoa_to_sheet(aoa);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, "Errors");

    const fileName = this._buildErrorFileName(job.sheetName ? `${job.fileName}_${job.sheetName}` : job.fileName);
    XLSX.writeFile(workbook, fileName);
    this._log("info", `Downloaded ${errorRows.length} error row(s) as "${fileName}".`);
    this._showToast(`Downloaded ${errorRows.length} error row(s).`, "success");
  }

  // Cross-sheet export — one row per Key Field value that errored on
  // ANY connected sheet, with that sheet''s own columns (prefixed with
  // its sheet name so identically-named columns across sheets don''t
  // collide) laid out side by side, in sheet/tab order.
  async _downloadCombinedSheetErrors(siblings) {
    const rowsByJobId = new Map();
    const keyColumnIndexByJobId = new Map();
    const rowsByKeyValueByJobId = new Map(); // jobId -> Map(keyValue -> row)

    for (const job of siblings) {
      const rows = (await this._database.getRowsByJobId(job.jobId)).sort((a, b) => a.rowIndex - b.rowIndex);
      rowsByJobId.set(job.jobId, rows);

      const keyColumnIndex = job.columnMappings.findIndex((m) => m.mappedFieldName === job.keyFieldName);
      keyColumnIndexByJobId.set(job.jobId, keyColumnIndex);

      const byKeyValue = new Map();
      if (keyColumnIndex !== -1) {
        rows.forEach((row) => {
          const keyValue = row.cells[keyColumnIndex];
          if (keyValue !== undefined && keyValue !== null && keyValue !== "") byKeyValue.set(keyValue, row);
        });
      }
      rowsByKeyValueByJobId.set(job.jobId, byKeyValue);
    }

    // Collect every Key Field value that has an error/failed row on AT
    // LEAST ONE sheet — that''s the set of transactions we need to report.
    const erroredKeyValues = [];
    const seenKeyValues = new Set();
    siblings.forEach((job) => {
      const keyColumnIndex = keyColumnIndexByJobId.get(job.jobId);
      if (keyColumnIndex === -1) return;
      (rowsByJobId.get(job.jobId) || []).forEach((row) => {
        if (row.status !== "error" && row.status !== "failed") return;
        const keyValue = row.cells[keyColumnIndex];
        if (keyValue === undefined || keyValue === null || keyValue === "" || seenKeyValues.has(keyValue)) return;
        seenKeyValues.add(keyValue);
        erroredKeyValues.push(keyValue);
      });
    });

    if (erroredKeyValues.length === 0) {
      this._showToast("No error rows to download.", "info");
      return;
    }

    // Header row: each sibling''s own headers, prefixed with its sheet
    // name, followed by one shared Status/Reason pair.
    const headerRow = [];
    siblings.forEach((job) => {
      job.excelHeaders.forEach((h) => headerRow.push(`${job.sheetName || job.fileName}: ${h}`));
    });
    headerRow.push("Status", "Reason");

    const aoa = [headerRow];
    erroredKeyValues.forEach((keyValue) => {
      const dataCells = [];
      const statusParts = [];
      const reasonParts = [];

      siblings.forEach((job) => {
        const row = rowsByKeyValueByJobId.get(job.jobId).get(keyValue);
        dataCells.push(...this._rowCellsForExport(row, job.excelHeaders));
        if (row && (row.status === "error" || row.status === "failed")) {
          const [statusLabel, reasonText] = this._rowStatusForExport(row);
          statusParts.push(`${job.sheetName || job.fileName}: ${statusLabel}`);
          reasonParts.push(`${job.sheetName || job.fileName}: ${reasonText}`);
        }
      });

      aoa.push([...dataCells, statusParts.join(" | "), reasonParts.join(" | ")]);
    });

    const worksheet = XLSX.utils.aoa_to_sheet(aoa);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, "Errors");

    const fileName = this._buildErrorFileName(`${this._currentJob.fileName}_combined`);
    XLSX.writeFile(workbook, fileName);
    this._log("info", `Downloaded ${erroredKeyValues.length} combined error row(s) across ${siblings.length} sheet(s) as "${fileName}".`);
    this._showToast(`Downloaded ${erroredKeyValues.length} error row(s) across ${siblings.length} sheet(s).`, "success");
  }

  // A missing row (this sheet had no row for that Key Field value at
  // all) exports as blank cells rather than being skipped, so columns
  // stay aligned across every key value''s row.
  _rowCellsForExport(row, headers) {
    if (!row) return headers.map(() => "");
    return headers.map((_, colIndex) => (row.cells[colIndex] !== undefined && row.cells[colIndex] !== null ? row.cells[colIndex] : ""));
  }

  _rowStatusForExport(row) {
    const messages = [];
    if (row.validationErrors && row.validationErrors.length > 0) {
      messages.push(...row.validationErrors.map((e) => e.message));
    }
    if (row.errorMessage) messages.push(row.errorMessage);
    const statusLabel = row.status === "error" ? "Validation error" : "Import failed";
    return [statusLabel, messages.join("; ") || statusLabel];
  }

  _buildErrorFileName(baseName) {
    const safeName = baseName.replace(/\.[^/.]+$/, "").replace(/[^a-z0-9_\-]/gi, "_");
    return `${safeName}_errors.xlsx`;
  }

  // Key Field must be identical across every sheet targeting the same
  // T-Struct in this upload — so changing it on ANY one sheet propagates
  // to all its siblings immediately, not just the current tab. Also
  // re-renders the header everywhere relevant, since whether the Group
  // field checkbox shows at all depends on Key Field being set.
  async _onKeyFieldChanged(fieldName) {
    if (!this._currentJob) return;
    const siblings = await this._getTStructGroupSiblings(this._currentJob);
    for (const sibling of siblings) {
      // siblings are FRESH copies read from IndexedDB (_getTStructGroupSiblings ->
      // getAllJobs), not the same object as this._currentJob — mutating a sibling
      // alone leaves this._currentJob.keyFieldName stale in memory even though the
      // DB write succeeds. That stale in-memory value is what every downstream read
      // (Import payload builders, Save Mapping) actually uses, so keep the live
      // this._currentJob object itself in sync when it''s one of the siblings.
      const target = sibling.jobId === this._currentJob.jobId ? this._currentJob : sibling;
      target.keyFieldName = fieldName || null;
      await this._database.putJob(target);
    }
    this._rememberKeyField(fieldName);
    this._renderGridHeader(); // current tab''s Group field checkboxes may need to appear/disappear
  }

  _renderKeyFieldDropdown() {
    const nonGridFields = this._keyFieldCandidates;
    this._keyFieldDropdown.setOptions(nonGridFields.map((f) => ({ value: f.fieldName, label: f.caption || f.fieldName })));
    this._keyFieldDropdown.setDisabled(nonGridFields.length === 0);
    if (this._currentJob && this._currentJob.keyFieldName) {
      this._keyFieldDropdown.setValue(this._currentJob.keyFieldName);
    } else {
      this._keyFieldDropdown.setValue("");
    }
  }

  /* ---------------------------------------------------------
     File upload -> new job, staged rows, grid render
     --------------------------------------------------------- */
  async _onFileSelected() {
    const file = this._dom.fileInput.files[0];
    if (!file) return;

    let sheets;
    try {
      sheets = await this._readExcelWorkbook(file);
    } catch (err) {
      console.error("[EIP] Failed to parse Excel file", err);
      this._showToast(`Could not read "${file.name}" — check it''s a valid Excel/CSV file.`, "error");
      return;
    }

    if (sheets.length === 0) {
      this._showToast(`"${file.name}" has no data rows in any sheet.`, "error");
      return;
    }

    const uploadBatchId = `batch_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
    const jobIds = [];
    let totalRowsStaged = 0;

    for (const parsedSheet of sheets) {
      const jobId = `job_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
      const now = Date.now();
      const axModeColumnIndex = parsedSheet.headers.findIndex(
        (h) => String(h).trim().toLowerCase() === AX_MODE_COLUMN_NAME
      );

      this._uploadedFilesByJobId.set(jobId, file); // in-memory only, for the a__ic attachment push at Import time — not persisted (same limitation as _parsedExcelSheet)

      const job = {
        jobId,
        uploadBatchId,
        sheetName: parsedSheet.sheetName,
        fileName: file.name,
        createdAt: now,
        lastActiveAt: now,
        transId: this._tstructDropdown.value || null,
        selectedDcNames: [],
        keyFieldName: null,
        useAxPut: !this._dom.priorApiCheckbox.checked,
        excelHeaders: parsedSheet.headers,
        columnMappings: parsedSheet.headers.map(() => ({ mappedFieldName: null, isGroupField: false })),
        validationRules: {},
        axModeColumnIndex: axModeColumnIndex === -1 ? null : axModeColumnIndex,
      };

      await this._database.putJob(job);

      this._parsedExcelSheet = parsedSheet.sheet; // set per-sheet so _getTrueCellDate below uses the right sheet

      const stagedRows = parsedSheet.dataRows.map((cells, rowIndex) => {
        const sheetRowIndex = parsedSheet.dataRowSheetIndices[rowIndex];
        // Normalize any cell Excel itself stored as a true date type — done
        // once, here, so the grid, validation, and import all see the same
        // clean "dd/MM/yyyy" string from this point on (no re-detection or
        // ambiguity later, including after the page is reloaded and the
        // original sheet object is no longer available).
        const normalizedCells = cells.map((cellValue, colIndex) => {
          const originalColIndex = parsedSheet.columnInda__im ? parsedSheet.columnInda__im[colIndex] : colIndex;
          const trueCellDate = this._getTrueCellDate(sheetRowIndex, originalColIndex);
          if (trueCellDate === null) return cellValue;
          const normalized = this._normalizeDateValue(trueCellDate);
          return normalized !== null ? normalized : cellValue;
        });
        return {
          id: `${jobId}__${rowIndex}`,
          jobId,
          rowIndex,
          cells: normalizedCells,
          sheetRowIndex,
          status: "pending",
          errorMessage: null,
          validationErrors: [],
        };
      });
      await this._database.putRows(stagedRows);

      jobIds.push(jobId);
      totalRowsStaged += stagedRows.length;
    }

    await this._refreshJobSelector();
    await this._loadJob(jobIds[0]);

    if (sheets.length > 1) {
      this._showToast(`Staged ${totalRowsStaged} row(s) across ${sheets.length} sheet(s) from "${file.name}".`, "success");
    } else {
      this._showToast(`Staged ${totalRowsStaged} row(s) from "${file.name}".`, "success");
    }
  }

  // Reads every non-empty sheet in the workbook (not just the first),
  // so a multi-sheet upload can become one job per sheet.
  _readExcelWorkbook(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (event) => {
        try {
          const data = new Uint8Array(event.target.result);
          const workbook = XLSX.read(data, { type: "array", cellDates: true });
          const sheets = workbook.SheetNames.map((sheetName) => {
            const sheet = workbook.Sheets[sheetName];
            const rowsAsArrays = XLSX.utils.sheet_to_json(sheet, { header: 1, raw: false, defval: "" });
            if (!rowsAsArrays || rowsAsArrays.length === 0) {
              return { sheetName, headers: [], dataRows: [], dataRowSheetIndices: [], sheet: null, columnInda__im: [] };
            }
            let headers = rowsAsArrays[0];
            let dataRows = [];
            const dataRowSheetIndices = [];
            rowsAsArrays.slice(1).forEach((row, idx) => {
              if (row.some((cell) => cell !== "" && cell !== null && cell !== undefined)) {
                dataRows.push(row);
                dataRowSheetIndices.push(idx + 1);
              }
            });

            // Strip "Status"/"Reason" columns (added by our own "Download
            // errors" export) so re-uploading that file for a retry
            // doesn''t offer them as mappable columns. columnInda__im keeps
            // track of each remaining column''s TRUE position in the sheet
            // (needed for true-cell-date lookups below, which read
            // directly from the raw sheet by column index).
            let columnInda__im = headers.map((_, idx) => idx);
            const stripIndices = new Set(
              headers
                .map((h, idx) => ({ h: String(h).trim().toLowerCase(), idx }))
                .filter((o) => o.h === "status" || o.h === "reason")
                .map((o) => o.idx)
            );
            if (stripIndices.size > 0) {
              headers = headers.filter((_, idx) => !stripIndices.has(idx));
              dataRows = dataRows.map((row) => row.filter((_, idx) => !stripIndices.has(idx)));
              columnInda__im = columnInda__im.filter((originalIdx) => !stripIndices.has(originalIdx));
            }

            return { sheetName, headers, dataRows, dataRowSheetIndices, sheet, columnInda__im };
          }).filter((s) => s.dataRows.length > 0); // skip genuinely empty sheets entirely
          resolve(sheets);
        } catch (err) {
          reject(err);
        }
      };
      reader.onerror = () => reject(reader.error);
      reader.readAsArrayBuffer(file);
    });
  }

  _getTrueCellDate(sheetRowIndex, columnIndex) {
    if (!this._parsedExcelSheet) return null;
    const cellAddress = XLSX.utils.encode_cell({ r: sheetRowIndex, c: columnIndex });
    const cell = this._parsedExcelSheet[cellAddress];
    if (cell && cell.t === "d" && cell.v instanceof Date) return cell.v;
    return null;
  }

  _getTrueCellType(sheetRowIndex, columnIndex) {
    if (!this._parsedExcelSheet) return null;
    const cellAddress = XLSX.utils.encode_cell({ r: sheetRowIndex, c: columnIndex });
    const cell = this._parsedExcelSheet[cellAddress];
    return cell ? cell.t : null; // ''n'' numeric, ''s'' string, ''d'' date, ''b'' boolean
  }

  /* ---------------------------------------------------------
     Date normalization (dd/MM/yyyy output) — see chat notes.
     --------------------------------------------------------- */
  static MONTH_NAMES = { jan: 1, feb: 2, mar: 3, apr: 4, may: 5, jun: 6, jul: 7, aug: 8, sep: 9, oct: 10, nov: 11, dec: 12 };

  _isValidYmd(year, month, day) {
    const dt = new Date(year, month - 1, day);
    return dt.getFullYear() === year && dt.getMonth() === month - 1 && dt.getDate() === day;
  }

  _formatDdMmYyyy(year, month, day) {
    return `${String(day).padStart(2, "0")}/${String(month).padStart(2, "0")}/${year}`;
  }

  _normalizeDateValue(val) {
    if (val === null || val === undefined || val === "") return null;

    if (val instanceof Date) {
      if (isNaN(val.getTime())) return null;
      const y = val.getUTCFullYear();
      const m = val.getUTCMonth() + 1;
      const d = val.getUTCDate();
      return this._isValidYmd(y, m, d) ? this._formatDdMmYyyy(y, m, d) : null;
    }

    if (typeof val === "number") {
      const parsed = XLSX.SSF.parse_date_code(val);
      if (parsed) {
        return this._isValidYmd(parsed.y, parsed.m, parsed.d) ? this._formatDdMmYyyy(parsed.y, parsed.m, parsed.d) : null;
      }
      return null;
    }

    let s = String(val).trim();
    if (!s) return null;

    let m = s.match(/^(\d{4})-(\d{2})-(\d{2})$/);
    if (m) {
      const year = parseInt(m[1], 10), month = parseInt(m[2], 10), day = parseInt(m[3], 10);
      return this._isValidYmd(year, month, day) ? this._formatDdMmYyyy(year, month, day) : null;
    }

    m = s.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/);
    if (m) {
      const a = parseInt(m[1], 10), b = parseInt(m[2], 10), year = parseInt(m[3], 10);
      if (this._isValidYmd(year, b, a)) return this._formatDdMmYyyy(year, b, a);
      if (this._isValidYmd(year, a, b)) return this._formatDdMmYyyy(year, a, b);
      return null;
    }

    m = s.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2})$/);
    if (m) {
      const a = parseInt(m[1], 10), b = parseInt(m[2], 10), year = 2000 + parseInt(m[3], 10);
      if (this._isValidYmd(year, b, a)) return this._formatDdMmYyyy(year, b, a);
      if (this._isValidYmd(year, a, b)) return this._formatDdMmYyyy(year, a, b);
      return null;
    }

    m = s.match(/^(\d{1,2})[\/\-]([A-Za-z]{3,})(?:[\/\-](\d{2,4}))?$/);
    if (m) {
      const monthNum = ExcelImportPageController.MONTH_NAMES[m[2].slice(0, 3).toLowerCase()];
      if (monthNum && m[3]) {
        const year = m[3].length === 2 ? 2000 + parseInt(m[3], 10) : parseInt(m[3], 10);
        const day = parseInt(m[1], 10);
        return this._isValidYmd(year, monthNum, day) ? this._formatDdMmYyyy(year, monthNum, day) : null;
      }
      return null;
    }

    return null;
  }

  /* ---------------------------------------------------------
     Job management
     --------------------------------------------------------- */
  async _refreshJobSelector() {
    const jobs = await this._database.getAllJobs();
    jobs.sort((a, b) => (b.lastActiveAt || 0) - (a.lastActiveAt || 0));
    const options = jobs.map((job) => {
      const when = new Date(job.createdAt).toLocaleString();
      const fileLabel = job.sheetName ? `${job.fileName} (${job.sheetName})` : job.fileName;
      return { value: job.jobId, label: `${fileLabel} â†'' ${job.transId || "(no T-Struct)"} — ${when}` };
    });
    this._jobDropdown.setOptions(options);
    if (this._currentJobId) this._jobDropdown.setValue(this._currentJobId);
  }

  async _loadJob(jobId) {
    const job = await this._database.getJob(jobId);
    if (!job) return;

    // Guards against rapid tab/job switching: several DS calls below are
    // awaited in sequence, and without this, a slower older call could
    // resolve AFTER a newer one and silently clobber the correct state
    // with stale data — this was the likely cause of the Key Field
    // dropdown occasionally showing wrong/blank ("glitchy").
    const loadToken = Symbol(jobId);
    this._latestLoadJobToken = loadToken;
    const isStale = () => this._latestLoadJobToken !== loadToken;

    this._currentJobId = jobId;
    this._currentJob = job;
    job.lastActiveAt = Date.now();
    await this._database.putJob(job);
    if (isStale()) return;

    this._currentJobIsFirstSheet = await this._isFirstSheetOfTStructGroup(job);
    if (isStale()) return;

    this._jobDropdown.setValue(jobId);
    this._dom.priorApiCheckbox.checked = !job.useAxPut;

    if (job.transId) {
      this._tstructDropdown.setValue(job.transId);

      const dcOptions = await this._loadDcOptionsForTStruct(job.transId);
      if (isStale()) return;
      this._dcTypeByName = Object.fromEntries(dcOptions.map((o) => [o.value, o.badge]));
      this._dcDropdown.setOptions(dcOptions);
      this._dcDropdown.setDisabled(dcOptions.length === 0);
      const selectedDcNames = job.selectedDcNames || [];
      this._dcDropdown.setValue(selectedDcNames);

      await this._loadKeyFieldCandidates(job.transId, dcOptions.map((o) => o.value));
      if (isStale()) return;

      await this._loadFieldsForTStruct(job.transId, selectedDcNames);
      if (isStale()) return;

      // If a sibling sheet targeting the same T-Struct already has a Key
      // Field set, adopt it here too — it''s required to be identical
      // across the whole group.
      if (!job.keyFieldName) {
        const siblings = await this._getTStructGroupSiblings(job);
        if (isStale()) return;
        const siblingWithKeyField = siblings.find((s) => s.jobId !== job.jobId && s.keyFieldName);
        if (siblingWithKeyField) {
          job.keyFieldName = siblingWithKeyField.keyFieldName;
          await this._database.putJob(job);
          if (isStale()) return;
        }
      }
    } else {
      this._tstructDropdown.setValue("");
      this._dcDropdown.setOptions([]);
      this._dcDropdown.setValue([]);
      this._dcDropdown.setDisabled(true);
      this._allFields = [];
      this._keyFieldCandidates = [];
    }
    this._renderKeyFieldDropdown();

    this._rows = (await this._database.getRowsByJobId(jobId)).sort((a, b) => a.rowIndex - b.rowIndex);
    if (isStale()) return;
    this._parsedExcelSheet = null; // sheet object isn''t persisted; true-cell-date lookups only work in the session that uploaded the file

    await this._renderSheetTabs();
    if (isStale()) return;
    this._renderGrid();
    this._updateSummaryLabel();
  }

  // Shows a tab per sheet belonging to the same upload as the current
  // job (matched by uploadBatchId) — only rendered when there''s more
  // than one, so a plain single-sheet upload looks exactly as before.
  async _renderSheetTabs() {
    this._dom.sheetTabs.innerHTML = "";
    if (!this._currentJob || !this._currentJob.uploadBatchId) {
      this._dom.sheetTabs.classList.add("eip-hidden");
      this._relocateTStructDcControls(false);
      return;
    }

    const allJobs = await this._database.getAllJobs();
    const siblingJobs = allJobs
      .filter((j) => j.uploadBatchId === this._currentJob.uploadBatchId)
      .sort((a, b) => a.createdAt - b.createdAt);

    if (siblingJobs.length <= 1) {
      this._dom.sheetTabs.classList.add("eip-hidden");
      this._relocateTStructDcControls(false);
      return;
    }

    siblingJobs.forEach((j) => {
      const tab = document.createElement("button");
      tab.type = "button";
      tab.className = "eip-sheet-tab" + (j.jobId === this._currentJobId ? " eip-sheet-tab-active" : "");
      tab.textContent = j.sheetName || j.fileName;
      tab.title = `${j.fileName} — ${j.sheetName || ""}`;
      tab.addEventListener("click", () => {
        if (j.jobId !== this._currentJobId) this._loadJob(j.jobId);
      });
      this._dom.sheetTabs.appendChild(tab);
    });

    this._dom.sheetTabs.classList.remove("eip-hidden");
    this._relocateTStructDcControls(true);
  }

  // Moves the T-Struct + DC control group between its default spot (top
  // bar) and a dedicated row below the sheet tabs — below the tabs is
  // where it belongs once multiple sheets are showing, since at that
  // point T-Struct/DC are per-tab choices, not page-global ones. Moves
  // the actual DOM node (not a rebuild), so the live SearchableDropdown
  // instances keep working exactly as before, just visually relocated.
  _relocateTStructDcControls(showBelowTabs) {
    if (showBelowTabs) {
      this._dom.tabControlsRow.appendChild(this._dom.tstructDcGroup);
      this._dom.tabControlsRow.classList.remove("eip-hidden");
    } else {
      this._dom.topbar.insertBefore(this._dom.tstructDcGroup, this._dom.priorApiItemWrap);
      this._dom.tabControlsRow.classList.add("eip-hidden");
    }
  }

  // Sibling sheets from the SAME upload that target the SAME T-Struct —
  // when a Key Field is set on any of them, this whole set gets combined
  // into cross-sheet transactions at Import time (see
  // _onImportClicked / _buildCombinedTransactions below). With no Key
  // Field set, sheets stay independent even if this returns more than
  // one — that''s the deliberate toggle.
  async _getTStructGroupSiblings(job) {
    if (!job || !job.uploadBatchId || !job.transId) return [job].filter(Boolean);
    const allJobs = await this._database.getAllJobs();
    return allJobs
      .filter((j) => j.uploadBatchId === job.uploadBatchId && j.transId === job.transId)
      .sort((a, b) => a.createdAt - b.createdAt);
  }

  async _saveCurrentJob() {
    if (!this._currentJob) return;
    this._currentJob.lastActiveAt = Date.now();
    await this._database.putJob(this._currentJob);
    await this._refreshJobSelector();
  }

  _onNewImportClicked() {
    this._currentJobId = null;
    this._currentJob = null;
    this._rows = [];
    this._allFields = [];
    this._keyFieldCandidates = [];
    this._parsedExcelSheet = null;
    this._tstructDropdown.setValue("");
    this._dcDropdown.setOptions([]);
    this._dcDropdown.setValue([]);
    this._dcDropdown.setDisabled(true);
    this._keyFieldDropdown.setOptions([]);
    this._keyFieldDropdown.setValue("");
    this._keyFieldDropdown.setDisabled(true);
    this._dom.priorApiCheckbox.checked = true; // "Use prior version of API" (ASBRest) is the default
    this._dom.fileNameLabel.textContent = "No file selected";
    this._dom.fileNameLabel.classList.remove("eip-has-file");
    this._jobDropdown.setValue("");
    this._dom.gridTable.classList.add("eip-hidden");
    this._dom.gridEmptyNote.classList.remove("eip-hidden");
    this._dom.gridEmptyNote.textContent = "Upload an Excel file to begin a new import.";
    this._dom.sheetTabs.classList.add("eip-hidden");
    this._dom.sheetTabs.innerHTML = "";
    this._relocateTStructDcControls(false);
    this._updateSummaryLabel();
  }

  // Deletes the currently-selected import job AND its staged rows
  // (IndexedDB has no cascade, so both stores are cleaned up explicitly
  // via deleteRowsByJobId + deleteJob). Only removes THIS job/sheet —
  // sibling sheets sharing the same upload+T-Struct+Key Field are left
  // untouched, but the confirm prompt says so when there are any, since
  // deleting one sheet out of a connected group is easy to do by mistake.
  async _onDeleteJobClicked() {
    const jobId = this._currentJobId;
    const job = this._currentJob;
    if (!jobId || !job) {
      this._showToast("No import job selected to delete.", "error");
      return;
    }

    const rowCount = this._rows.length;
    const siblings = await this._getTStructGroupSiblings(job);
    const label = job.sheetName ? `"${job.fileName}" (sheet "${job.sheetName}")` : `"${job.fileName}"`;
    const siblingWarning = siblings.length > 1
      ? ` This sheet is joined to ${siblings.length - 1} other sheet(s) in this upload by a shared Key Field — only this sheet''s ${rowCount} staged row(s) will be deleted; the other sheet(s) are unaffected.`
      : "";

    const confirmed = await this._confirmDialog({
      title: "Delete import job?",
      message: `Delete import job ${label} and its ${rowCount} staged row(s)? This cannot be undone.${siblingWarning}`,
      okLabel: "Delete",
      danger: true,
    });
    if (!confirmed) return;

    await this._database.deleteRowsByJobId(jobId);
    await this._database.deleteJob(jobId);
    this._uploadedFilesByJobId.delete(jobId);

    this._log("info", `Deleted import job ${label} (${rowCount} row(s)).`);
    this._showToast(`Deleted ${label}.`, "success");

    // Load the next most-recently-active remaining job, if any; otherwise
    // reset to the same empty state "+ New Import" produces.
    const remainingJobs = await this._database.getAllJobs();
    if (remainingJobs.length > 0) {
      remainingJobs.sort((a, b) => (b.lastActiveAt || 0) - (a.lastActiveAt || 0));
      await this._loadJob(remainingJobs[0].jobId);
    } else {
      this._onNewImportClicked();
    }

    await this._refreshJobSelector();
  }

  /* ---------------------------------------------------------
     Grid rendering
     --------------------------------------------------------- */
  static ROW_HEIGHT = 28; // px — must match the fixed row height set in CSS (trimmed
    // from 32 so more rows fit in the same grid height)
  static ROW_BUFFER = 10; // extra rows rendered above/below the visible window

  // Full rebuild: header (mapping dropdowns) + body (data rows). Used
  // whenever the actual ROW SET changes — file upload, validate, import,
  // Redis poll updates, job switch. NOT used for mapping/group-field
  // changes, which only need _renderGridHeader() (see below) — rebuilding
  // thousands of data rows on every dropdown change is what was making
  // the whole page feel slow.
  _renderGrid() {
    this._columnMappingDropdowns.forEach((dd) => dd.destroy());
    this._columnMappingDropdowns = [];

    if (!this._currentJob || this._rows.length === 0) {
      this._dom.gridTable.classList.add("eip-hidden");
      this._dom.gridEmptyNote.classList.remove("eip-hidden");
      return;
    }
    this._dom.gridEmptyNote.classList.add("eip-hidden");
    this._dom.gridTable.classList.remove("eip-hidden");
    this._dom.fileNameLabel.textContent = this._currentJob.sheetName
      ? `${this._currentJob.fileName} (${this._currentJob.sheetName})`
      : this._currentJob.fileName;
    this._dom.fileNameLabel.classList.add("eip-has-file");

    this._renderGridHeader();
    this._renderGridBody();
  }

  // Rebuilds ONLY the mapping row + header text row — fast regardless of
  // row count, since it''s bounded by column count, not row count.
  _renderGridHeader() {
    this._columnMappingDropdowns.forEach((dd) => dd.destroy());
    this._columnMappingDropdowns = [];

    const headers = this._currentJob.excelHeaders;
    const mappings = this._currentJob.columnMappings;
    const axModeIdx = this._currentJob.axModeColumnIndex;

    // --- Mapping row (dropdown + group-field checkbox + validation gear) ---
    this._dom.gridMappingRow.innerHTML = "";
    const statusHeaderCell = document.createElement("th");
    statusHeaderCell.className = "eip-grid-status-col";
    statusHeaderCell.textContent = "";
    this._dom.gridMappingRow.appendChild(statusHeaderCell);

    headers.forEach((header, colIndex) => {
      const th = document.createElement("th");
      th.className = "eip-col-mapping-cell";

      if (colIndex === axModeIdx) {
        const label = document.createElement("div");
        label.className = "eip-col-ax-mode-label";
       label.innerHTML = "ax_mode — action control<span class=\"eip-col-ax-mode-sublabel\">n=Create · e=Edit · d=Delete · blank=Create(Delete not supported with prior version API)</span>";
        th.appendChild(label);
        this._dom.gridMappingRow.appendChild(th);
        return;
      }

      const selectHost = document.createElement("div");
      selectHost.className = "eip-select";
      const fieldOptions = this._allFields.map((field) => ({
        value: field.fieldName,
        label: field.caption || field.fieldName,
        group: field.isGridField ? "Grid fields" : "Header fields",
      }));

      // The shared Key Field must always be mappable here, even if it
      // belongs to a DC this sheet didn''t select for its own field
      // mapping — otherwise this sheet has no way to satisfy the
      // "every sheet needs a column mapped to the Key Field" requirement.
      const keyFieldName = this._currentJob.keyFieldName;
      if (keyFieldName && !fieldOptions.some((o) => o.value === keyFieldName)) {
        const keyFieldMeta = this._keyFieldCandidates.find((f) => f.fieldName === keyFieldName);
        if (keyFieldMeta) {
          fieldOptions.push({
            value: keyFieldMeta.fieldName,
            label: keyFieldMeta.caption || keyFieldMeta.fieldName,
            group: "Key field",
          });
        }
      }

      // Header fields first, then the Key field (if injected separately),
      // then grid fields.
      const groupRank = { "Header fields": 0, "Key field": 1, "Grid fields": 2 };
      fieldOptions.sort((a, b) => groupRank[a.group] - groupRank[b.group]);

      const mappingDropdown = new SearchableDropdown(selectHost, {
        options: fieldOptions,
        value: mappings[colIndex].mappedFieldName || "",
        placeholder: "— Not mapped —",
        onChange: (fieldName) => this._onColumnMappingChanged(colIndex, fieldName),
      });
      this._columnMappingDropdowns.push(mappingDropdown);
      th.appendChild(selectHost);

      const controlsRow = document.createElement("div");
      controlsRow.className = "eip-col-mapping-controls";

      const mappedField = this._allFields.find((f) => f.fieldName === mappings[colIndex].mappedFieldName);
      const isNonGridMapped = mappedField && !mappedField.isGridField;
      const keyFieldIsSet = !!this._currentJob.keyFieldName;

      if (isNonGridMapped && !keyFieldIsSet && this._currentJobIsFirstSheet) {
        const groupLabel = document.createElement("label");
        const groupCheckbox = document.createElement("input");
        groupCheckbox.type = "checkbox";
        groupCheckbox.checked = !!mappings[colIndex].isGroupField;
        groupCheckbox.addEventListener("change", () => this._onGroupFieldToggled(colIndex, groupCheckbox.checked));
        groupLabel.appendChild(groupCheckbox);
        groupLabel.appendChild(document.createTextNode(" Group field"));
        controlsRow.appendChild(groupLabel);
      } else if (isNonGridMapped && keyFieldIsSet && mappedField.fieldName === this._currentJob.keyFieldName) {
        const badge = document.createElement("span");
        badge.className = "eip-key-field-badge";
        badge.textContent = "Key field (join column)";
        controlsRow.appendChild(badge);
      }

      const gearBtn = document.createElement("button");
      gearBtn.type = "button";
      gearBtn.className = "eip-col-gear-btn";
      gearBtn.textContent = "⚙";
      gearBtn.title = "Set validation rules for this column";
      if (this._currentJob.validationRules[colIndex]) gearBtn.classList.add("eip-has-rules");
      gearBtn.addEventListener("click", () => this._openValidationModal(colIndex));
      controlsRow.appendChild(gearBtn);

      th.appendChild(controlsRow);
      this._dom.gridMappingRow.appendChild(th);
    });

    // Trailing filler column — see _renderVisibleRows for why: it''s what
    // makes the grid fill the full width when there are few columns,
    // without stretching the real (content-sized) columns themselves.
    const mappingFillerTh = document.createElement("th");
    mappingFillerTh.className = "eip-grid-filler-col";
    this._dom.gridMappingRow.appendChild(mappingFillerTh);

    // --- Excel header text row ---
    this._dom.gridHeaderRow.innerHTML = "";
    const statusHeaderCell2 = document.createElement("th");
    statusHeaderCell2.className = "eip-grid-status-col";
    this._dom.gridHeaderRow.appendChild(statusHeaderCell2);
    headers.forEach((header) => {
      const th = document.createElement("th");
      const span = document.createElement("span");
      span.className = "eip-col-header-text";
      span.textContent = header;
      th.appendChild(span);
      this._dom.gridHeaderRow.appendChild(th);
    });
    const headerFillerTh = document.createElement("th");
    headerFillerTh.className = "eip-grid-filler-col";
    this._dom.gridHeaderRow.appendChild(headerFillerTh);
  }

  // Virtualized body: only the rows actually visible in the scroll
  // viewport (plus a small buffer) ever exist in the DOM — with 4000+
  // rows, building all of them as real <tr> elements is what was making
  // every re-render (and, by extension, the whole page — including
  // opening dropdowns) feel slow. Two spacer rows account for the
  // height of the rows above/below the rendered window so the native
  // scrollbar still reflects the true total size.
  _renderGridBody() {
    this._bindGridScrollOnce();
    this._renderVisibleRows();
  }

  _bindGridScrollOnce() {
    if (this._gridScrollBound) return;
    this._gridScrollBound = true;
    let ticking = false;
    this._dom.gridWrapper.addEventListener("scroll", () => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(() => {
        this._renderVisibleRows();
        ticking = false;
      });
    });
  }

  _renderVisibleRows() {
    const headers = this._currentJob.excelHeaders;
    const axModeIdx = this._currentJob.axModeColumnIndex;
    const rowHeight = ExcelImportPageController.ROW_HEIGHT;
    const totalRows = this._rows.length;

    const wrapper = this._dom.gridWrapper;
    const theadEl = this._dom.gridTable.querySelector("thead");
    const headerHeight = theadEl ? theadEl.offsetHeight : 0;
    const adjustedScrollTop = Math.max(0, wrapper.scrollTop - headerHeight);
    const viewportHeight = wrapper.clientHeight;

    let startIndex = Math.floor(adjustedScrollTop / rowHeight) - ExcelImportPageController.ROW_BUFFER;
    let endIndex = Math.ceil((adjustedScrollTop + viewportHeight) / rowHeight) + ExcelImportPageController.ROW_BUFFER;
    startIndex = Math.max(0, startIndex);
    endIndex = Math.min(totalRows, endIndex);

    const topSpacerHeight = startIndex * rowHeight;
    const bottomSpacerHeight = (totalRows - endIndex) * rowHeight;

    this._dom.gridBody.innerHTML = "";

    if (topSpacerHeight > 0) {
      const topSpacer = document.createElement("tr");
      topSpacer.style.height = `${topSpacerHeight}px`;
      const td = document.createElement("td");
      td.colSpan = headers.length + 2; // status col + data cols + trailing filler col
      td.style.padding = "0";
      td.style.border = "none";
      topSpacer.appendChild(td);
      this._dom.gridBody.appendChild(topSpacer);
    }

    for (let i = startIndex; i < endIndex; i++) {
      const row = this._rows[i];
      if (!row) continue;
      const tr = document.createElement("tr");
      tr.className = "eip-grid-row";

      const statusCell = document.createElement("td");
      statusCell.className = "eip-grid-status-col";
      statusCell.appendChild(this._buildStatusIcon(row));
      tr.appendChild(statusCell);

      headers.forEach((header, colIndex) => {
        const td = document.createElement("td");
        const cellValue = row.cells[colIndex];
        const displayValue = cellValue !== undefined && cellValue !== null ? String(cellValue) : "";

        if (colIndex === axModeIdx) {
          const normalized = displayValue.trim().toLowerCase();
          const action = AX_MODE_ACTION_MAP[normalized] || "create";
          // Create/Edit are honored under both AxPut and prior version (ASBRest) API —
          // ASBRest just has no way to represent Delete (no keyfield/keyvalue path for it yet).
          const isIgnored = !this._currentJob.useAxPut && action === "delete";
          const badge = document.createElement("span");
          badge.className = `eip-ax-mode-badge eip-ax-mode-${action}` + (isIgnored ? " eip-ax-mode-ignored" : "");
          badge.textContent = AX_MODE_ACTION_DISPLAY_LABEL[action] || "Create";
          td.appendChild(badge);
          const rawNote = displayValue ? `Raw value: "${displayValue}"` : "Blank — defaults to Create";
          td.title = isIgnored ? `${rawNote} (delete not supported — using prior version API)` : rawNote;
        } else {
          td.textContent = displayValue;
          if (displayValue) td.title = displayValue;
        }
        tr.appendChild(td);
      });

      // Trailing filler cell — matches the filler <th> added in
      // _renderGridHeader, so every real row''s zebra stripe/hover
      // background and bottom border extend all the way to the edge of
      // the grid instead of stopping at the last real data column.
      const fillerTd = document.createElement("td");
      fillerTd.className = "eip-grid-filler-col";
      tr.appendChild(fillerTd);

      this._dom.gridBody.appendChild(tr);
    }

    if (bottomSpacerHeight > 0) {
      const bottomSpacer = document.createElement("tr");
      bottomSpacer.style.height = `${bottomSpacerHeight}px`;
      const td = document.createElement("td");
      td.colSpan = headers.length + 2; // status col + data cols + trailing filler col
      td.style.padding = "0";
      td.style.border = "none";
      bottomSpacer.appendChild(td);
      this._dom.gridBody.appendChild(bottomSpacer);
    }
  }

  _buildStatusIcon(row) {
    const icon = document.createElement("span");
    icon.className = "eip-status-icon";
    if (row.status === "uploaded") {
      icon.classList.add("eip-status-uploaded");
      icon.textContent = "✓";
      icon.title = "Uploaded";
    } else if (row.status === "submitted") {
      icon.classList.add("eip-status-submitted");
      icon.textContent = "…";
      icon.title = "Submitted — awaiting confirmation";
    } else if (row.status === "failed") {
      icon.classList.add("eip-status-failed");
      icon.textContent = "!";
      icon.title = row.errorMessage ? `Processing failed: ${row.errorMessage}` : "Processing failed";
    } else if (row.status === "error") {
      icon.classList.add("eip-status-error");
      icon.textContent = "✕";
      const messages = (row.validationErrors || []).map((e) => e.message);
      if (row.errorMessage) messages.push(row.errorMessage);
      icon.title = messages.length > 0 ? messages.join("; ") : "Error";
    } else {
      icon.classList.add("eip-status-pending");
      icon.textContent = "•";
      icon.title = "Pending upload";
    }
    return icon;
  }

  _updateSummaryLabel() {
    if (!this._currentJob || this._rows.length === 0) {
      this._dom.summaryLabel.textContent = "No data loaded.";
      this._dom.downloadErrorsBtn.classList.add("eip-hidden");
      if (this._dom.timingLabel) this._dom.timingLabel.textContent = "";
      return;
    }
    const uploaded = this._rows.filter((r) => r.status === "uploaded").length;
    const submitted = this._rows.filter((r) => r.status === "submitted").length;
    const failed = this._rows.filter((r) => r.status === "failed").length;
    const errored = this._rows.filter((r) => r.status === "error").length;
    const pending = this._rows.length - uploaded - submitted - failed - errored;
    this._dom.summaryLabel.textContent =
      `${this._rows.length} row(s) — ${pending} pending, ${submitted} submitted, ${errored} error(s), ${failed} failed, ${uploaded} uploaded.`;

    // Only worth showing once nothing is still in-flight (no rows
    // awaiting Redis confirmation) and there''s actually something to
    // download — not mid-import, not when everything''s clean.
    const hasErrors = errored > 0 || failed > 0;
    const hasInFlight = submitted > 0;
    this._dom.downloadErrorsBtn.classList.toggle("eip-hidden", !(hasErrors && !hasInFlight));

    this._updateTimingLabel(submitted);
  }

  // Shows elapsed/estimated/last-import timing right next to the row
  // status counts, so it''s visible without opening the progress popup —
  // three states:
  //   1. Still in flight (submitted > 0): live elapsed time + an
  //      estimated total, projected from import history.
  //   2. Nothing in flight but this job has a recorded last import:
  //      the REAL time that import took.
  //   3. Neither: blank (nothing to show yet for this job).
  _updateTimingLabel(submittedCount) {
    const el = this._dom.timingLabel;
    if (!el) return;

    if (submittedCount > 0) {
      const submittedRow = this._rows.find((r) => r.status === "submitted" && r.callerId);
      const tracking = submittedRow ? this._importStartTimes.get(submittedRow.callerId) : null;
      if (tracking) {
        const elapsedMs = Date.now() - tracking.startedAt;
        const estimate = this._estimateImportDuration(tracking.totalRows);
        el.textContent = estimate
          ? `⏱ ${this._formatDuration(elapsedMs)} elapsed — est. ~${this._formatDuration(estimate.estimatedMs)} total for ${tracking.totalRows} record(s)`
          : `⏱ ${this._formatDuration(elapsedMs)} elapsed (${tracking.totalRows} record(s), awaiting confirmation)`;
      } else {
        el.textContent = "⏱ Awaiting confirmation…";
      }
      return;
    }

    if (this._currentJob.lastImportDurationMs && this._currentJob.lastImportTotalRows) {
      const msPerRecord = this._currentJob.lastImportDurationMs / this._currentJob.lastImportTotalRows;
      const perRecordLabel = msPerRecord < 1000 ? `${Math.round(msPerRecord)}ms` : `${(msPerRecord / 1000).toFixed(2)}s`;
      el.textContent = `â± Last import: ${this._currentJob.lastImportTotalRows} record(s) in ${this._formatDuration(this._currentJob.lastImportDurationMs)} (~${perRecordLabel}/record)`;
      return;
    }

    el.textContent = "";
  }

  /* ---------------------------------------------------------
     Column mapping / group-field interactions
     --------------------------------------------------------- */
  async _onColumnMappingChanged(colIndex, fieldName) {
    this._currentJob.columnMappings[colIndex].mappedFieldName = fieldName || null;
    const field = this._allFields.find((f) => f.fieldName === fieldName);
    if (!field || field.isGridField) {
      this._currentJob.columnMappings[colIndex].isGroupField = false;
    }
    await this._saveCurrentJob();
    await this._rememberColumnMapping(colIndex);
    this._renderGridHeader(); // header only — rebuilding all data rows here was the main perf problem
  }

  async _onGroupFieldToggled(colIndex, isChecked) {
    if (isChecked) {
      // Only one column may be the group column — clear any other selection.
      this._currentJob.columnMappings.forEach((mapping, idx) => {
        if (idx !== colIndex) mapping.isGroupField = false;
      });
    }
    this._currentJob.columnMappings[colIndex].isGroupField = isChecked;
    await this._saveCurrentJob();
    await this._rememberColumnMapping(colIndex);
    this._renderGridHeader(); // other columns'' checkboxes may have just been cleared
  }

  /* ---------------------------------------------------------
     Validation popup
     --------------------------------------------------------- */
  _openValidationModal(colIndex) {
    this._validationModalColumnIndex = colIndex;
    const rules = this._currentJob.validationRules[colIndex] || {};
    this._dom.valModalTitle.textContent = `Validation — ${this._currentJob.excelHeaders[colIndex]}`;
    this._dom.valMandatory.checked = !!rules.mandatory;
    this._dom.valMin.value = rules.minValue !== undefined && rules.minValue !== null ? rules.minValue : "";
    this._dom.valMax.value = rules.maxValue !== undefined && rules.maxValue !== null ? rules.maxValue : "";
    this._dom.valAllowed.value = Array.isArray(rules.allowedValues) ? rules.allowedValues.join(", ") : "";
    this._dom.valModalOverlay.classList.remove("eip-hidden");
  }

  _closeValidationModal() {
    this._dom.valModalOverlay.classList.add("eip-hidden");
    this._validationModalColumnIndex = null;
  }

  async _onValidationModalSave() {
    const colIndex = this._validationModalColumnIndex;
    if (colIndex === null) return;

    const mandatory = this._dom.valMandatory.checked;
    const minValue = this._dom.valMin.value.trim() || null;
    const maxValue = this._dom.valMax.value.trim() || null;
    const allowedValues = this._dom.valAllowed.value
      .split(",")
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    const hasAnyRule = mandatory || minValue || maxValue || allowedValues.length > 0;
    if (hasAnyRule) {
      this._currentJob.validationRules[colIndex] = { mandatory, minValue, maxValue, allowedValues };
    } else {
      delete this._currentJob.validationRules[colIndex];
    }

    await this._saveCurrentJob();
    this._closeValidationModal();
    this._renderGridHeader(); // only the gear icon''s highlight changes here
  }

  /* ---------------------------------------------------------
     Validate
     --------------------------------------------------------- */
  _onValidateClicked() {
    if (!this._currentJob || this._rows.length === 0) {
      this._showToast("No data to validate.", "error");
      return;
    }
    this._validateRowsForJob(this._currentJob, this._rows);
    this._database.putRows(this._rows);
    this._renderGrid();
    this._updateSummaryLabel();
    const errorCount = this._rows.filter((r) => r.status === "error").length;
    this._showToast(errorCount === 0 ? "All rows passed validation." : `${errorCount} row(s) have validation errors.`, errorCount === 0 ? "success" : "error");
  }

  // Pure validation logic, reusable for any (job, rows) pair — needed so
  // combined multi-sheet imports can validate every sibling sheet, not
  // just whichever one is currently the active tab. Mutates rows in
  // place (status/errorMessage/validationErrors); caller is responsible
  // for persisting and re-rendering.
  _validateRowsForJob(job, rows) {
    const headers = job.excelHeaders;
    const rules = job.validationRules;

    rows.forEach((row) => {
      if (row.status === "uploaded" || row.status === "submitted") return; // already confirmed or in-flight, leave as-is

      const errors = [];
      headers.forEach((header, colIndex) => {
        const rule = rules[colIndex];
        if (!rule) return; // no validation rule configured for this column
        const rawValue = row.cells[colIndex];
        const stringValue = rawValue !== undefined && rawValue !== null ? String(rawValue).trim() : "";
        const columnLabel = header || `column ${colIndex + 1}`;

        if (rule && rule.mandatory && stringValue === "") {
          errors.push({ columnIndex: colIndex, message: `"${columnLabel}" is mandatory` });
          return; // skip further checks on an empty mandatory field
        }
        if (stringValue === "") return; // nothing more to check on a blank, non-mandatory cell

        // Detect the value''s type from the actual cell/parseability, not
        // from data_ing_tstruct_fields.datatype (see class-level assumptions note).
        const trueCellDate = this._getTrueCellDate(row.sheetRowIndex, colIndex);
        const normalizedDate = trueCellDate !== null ? this._normalizeDateValue(trueCellDate) : this._normalizeDateValue(stringValue);
        const numericValue = parseFloat(stringValue);
        const looksNumeric = !isNaN(numericValue) && /^-?\d+(\.\d+)?$/.test(stringValue);

        if (rule && (rule.minValue || rule.maxValue)) {
          if (normalizedDate !== null) {
            const [d, m, y] = normalizedDate.split("/").map(Number);
            const cellDate = new Date(y, m - 1, d);
            if (rule.minValue) {
              const minNorm = this._normalizeDateValue(rule.minValue);
              if (minNorm) {
                const [md, mm, my] = minNorm.split("/").map(Number);
                if (cellDate < new Date(my, mm - 1, md)) errors.push({ columnIndex: colIndex, message: `"${columnLabel}" is before the allowed minimum date` });
              }
            }
            if (rule.maxValue) {
              const maxNorm = this._normalizeDateValue(rule.maxValue);
              if (maxNorm) {
                const [xd, xm, xy] = maxNorm.split("/").map(Number);
                if (cellDate > new Date(xy, xm - 1, xd)) errors.push({ columnIndex: colIndex, message: `"${columnLabel}" is after the allowed maximum date` });
              }
            }
          } else if (looksNumeric) {
            if (rule.minValue && !isNaN(parseFloat(rule.minValue)) && numericValue < parseFloat(rule.minValue)) {
              errors.push({ columnIndex: colIndex, message: `"${columnLabel}" is below the allowed minimum` });
            }
            if (rule.maxValue && !isNaN(parseFloat(rule.maxValue)) && numericValue > parseFloat(rule.maxValue)) {
              errors.push({ columnIndex: colIndex, message: `"${columnLabel}" is above the allowed maximum` });
            }
          }
        }

        if (rule && rule.allowedValues && rule.allowedValues.length > 0) {
          const match = rule.allowedValues.some((v) => v.toLowerCase() === stringValue.toLowerCase());
          if (!match) errors.push({ columnIndex: colIndex, message: `"${columnLabel}" is not in the allowed value list` });
        }
      });

      row.validationErrors = errors;
      row.status = errors.length > 0 ? "error" : "pending";
      row.errorMessage = null;
    });
  }

  /* ---------------------------------------------------------
     Import — group, build payload(s), push
     --------------------------------------------------------- */
  async _onImportClicked() {
    if (!this._currentJob || this._rows.length === 0) {
      this._showToast("No data to import.", "error");
      return;
    }
    if (!this._currentJob.transId) {
      this._showToast("Select a T-Struct first.", "error");
      return;
    }

    this._pushExcelFileAttachment(this._currentJob); // fire-and-forget — separate from data import, logs only, never blocks Import

    // Multiple sheets targeting the same T-Struct + a shared Key Field
    // set -> combine them into cross-sheet transactions instead of
    // importing this sheet alone. No Key Field -> sheets stay
    // independent, exactly like a single-sheet import.
    const siblings = await this._getTStructGroupSiblings(this._currentJob);
    if (siblings.length > 1 && this._currentJob.keyFieldName) {
      await this._runCombinedImport(siblings);
      return;
    }

    this._saveMappingMemoryToServer(this._currentJob); // fire-and-forget — logs only, never blocks Import

    const axModeIdx = this._currentJob.axModeColumnIndex;
    const unmappedColumns = this._currentJob.columnMappings
      .map((mapping, colIndex) => ({ mapping, colIndex }))
      .filter(({ mapping, colIndex }) => colIndex !== axModeIdx && !mapping.mappedFieldName);
    if (unmappedColumns.length > 0) {
      const names = unmappedColumns.map(({ colIndex }) => this._currentJob.excelHeaders[colIndex]).join(", ");
      this._showToast(`Every column must be mapped before importing. Not mapped: ${names}`, "error");
      return;
    }

    // Re-run validation so status reflects the current rules exactly.
    this._onValidateClicked();

    const errorRows = this._rows.filter((r) => r.status === "error");
    if (errorRows.length > 0) {
      this._showToast(`${errorRows.length} row(s) have validation errors — fix them before importing.`, "error");
      return;
    }

    const eligibleRows = this._rows.filter((r) => r.status === "pending");
    if (eligibleRows.length === 0) {
      this._showToast("No rows to import.", "error");
      return;
    }

    const mappings = this._currentJob.columnMappings;
    const useAxPut = this._currentJob.useAxPut;

    const fieldsByFormNumber = new Map();
    mappings.forEach((mapping, colIndex) => {
      if (!mapping.mappedFieldName) return;
      const field = this._allFields.find((f) => f.fieldName === mapping.mappedFieldName);
      if (!field) return;
      if (!fieldsByFormNumber.has(field.formNumber)) fieldsByFormNumber.set(field.formNumber, []);
      fieldsByFormNumber.get(field.formNumber).push({ ...field, columnIndex: colIndex });
    });

    const groupColumnIndices = mappings
      .map((m, idx) => ({ ...m, colIndex: idx }))
      .filter((m) => m.isGroupField && m.mappedFieldName)
      .map((m) => m.colIndex);

    // Resolve each eligible row''s per-column value (with date normalization
    // applied where relevant), skipping any row that throws during this step.
    const resolvedRows = [];
    eligibleRows.forEach((row) => {
      try {
        const values = {};
        fieldsByFormNumber.forEach((fields) => {
          fields.forEach((field) => {
            const rawValue = row.cells[field.columnIndex];
            const trueCellDate = this._getTrueCellDate(row.sheetRowIndex, field.columnIndex);
            const fieldSuggestsDate = field.dataType && String(field.dataType).toLowerCase().includes("date");
            const shouldTreatAsDate = trueCellDate !== null || fieldSuggestsDate;
            if (shouldTreatAsDate && rawValue !== "" && rawValue !== undefined && rawValue !== null) {
              const normalized = this._normalizeDateValue(trueCellDate !== null ? trueCellDate : rawValue);
              values[field.fieldName] = normalized !== null ? normalized : String(rawValue);
            } else {
              values[field.fieldName] = rawValue !== undefined && rawValue !== null ? String(rawValue) : "";
            }
          });
        });
        const axModeValue = axModeIdx !== null && axModeIdx !== undefined ? String(row.cells[axModeIdx] || "").trim().toLowerCase() : "";
        resolvedRows.push({ row, values, axModeValue });
      } catch (err) {
        console.error(`[EIP] Row ${row.rowIndex} failed to resolve — marking as error`, err);
        row.status = "error";
        row.errorMessage = `Processing error: ${err.message || err}`;
      }
    });

    // Group consecutive (among eligible/resolved rows only) by composite key.
    const groups = [];
    let currentGroup = [];
    let currentKey;
    resolvedRows.forEach((resolved) => {
      const key = groupColumnIndices.map((colIndex) => resolved.row.cells[colIndex]).join("␟");
      if (currentGroup.length === 0) {
        currentGroup = [resolved];
        currentKey = key;
        return;
      }
      if (groupColumnIndices.length > 0 && key === currentKey) {
        currentGroup.push(resolved);
      } else {
        groups.push(currentGroup);
        currentGroup = [resolved];
        currentKey = key;
      }
    });
    if (currentGroup.length > 0) groups.push(currentGroup);

    if (groups.length === 0) {
      this._showToast("Nothing to post after grouping.", "error");
      return;
    }

    const importStartedAt = Date.now();
    this._openProgressPopup();
    this._startElapsedTicker(importStartedAt);
    this._setProgress(20, `Building payload for ${groups.length} transaction(s)…`);

    const totalRowsAttempted = resolvedRows.length;
    const estimate = this._estimateImportDuration(totalRowsAttempted);
    if (estimate) {
      this._log("info", `Estimated time: ~${this._formatDuration(estimate.estimatedMs)} for ${totalRowsAttempted} record(s), based on ${estimate.sampleCount} previous import(s) (~${estimate.msPerRecord.toFixed(0)}ms/record).`);
    }

    const callerId = this._generateCallerId();
    // sequenceNo = the 1-indexed starting grid row of each transaction''s
    // first row (rowIndex is stored 0-indexed, hence +1).
    const groupsWithSequence = groups.map((group) => ({
      group,
      sequenceNo: group[0].row.rowIndex + 1,
    }));

    const buildFn = (subset) =>
      useAxPut
        ? this._buildAxPutPayload(this._currentJob.transId, subset, fieldsByFormNumber, callerId)
        : this._buildAsbRestPayload(this._currentJob.transId, subset, fieldsByFormNumber, callerId);

    const chunks = this._chunkGroupsBySize(groupsWithSequence, buildFn);
    console.log(`[EIP] ${groups.length} transaction(s) split into ${chunks.length} push(es) (9MB cap per push, no transaction split across pushes).`);

    let successCount = 0;
    let failureCount = 0;
    let submittedRowCount = 0; // only rows that actually reached "submitted" — these are the ones Redis will eventually confirm

    for (let i = 0; i < chunks.length; i++) {
      const chunkGroupsWithSequence = chunks[i];
      const payload = buildFn(chunkGroupsWithSequence);
      const jsonDataString = JSON.stringify(payload);
      const involvedRows = chunkGroupsWithSequence.flatMap(({ group }) => group.map((r) => r.row));

      console.log(`[EIP] Push ${i + 1}/${chunks.length}: ${chunkGroupsWithSequence.length} transaction(s), ${(new Blob([jsonDataString]).size / (1024 * 1024)).toFixed(2)} MB (object):`, payload);
      console.log(`[EIP] Push ${i + 1}/${chunks.length} (stringified):`, jsonDataString);

      this._setProgress(20 + Math.round(((i + 1) / chunks.length) * 60), `Posting push ${i + 1} of ${chunks.length} (${chunkGroupsWithSequence.length} transaction(s))…`);

      try {
        const res = await this._pushToQueue(jsonDataString);
        console.log(`[EIP] Push ${i + 1}/${chunks.length} succeeded:`, res);
        // Pushed to the queue successfully — this does NOT mean Axpert has
        // processed it yet. Mark "submitted" and record callerId/sequenceNo
        // so the Redis poll can later confirm success/failure per row.
        chunkGroupsWithSequence.forEach(({ group, sequenceNo }) => {
          group.forEach((resolved) => {
            resolved.row.status = "submitted";
            resolved.row.callerId = callerId;
            resolved.row.sequenceNo = sequenceNo;
            resolved.row.errorMessage = null;
          });
        });
        this._log("success", `Push ${i + 1}/${chunks.length}: posted ${chunkGroupsWithSequence.length} transaction(s) (${involvedRows.length} row(s)) — awaiting confirmation.`);
        successCount += chunkGroupsWithSequence.length;
        submittedRowCount += involvedRows.length;
      } catch (err) {
        console.error(`[EIP] Push ${i + 1}/${chunks.length} failed:`, err);
        involvedRows.forEach((row) => { row.status = "error"; row.errorMessage = `Push failed: ${err.message || err}`; });
        this._log("error", `Push ${i + 1}/${chunks.length} failed: ${err.message || err}`);
        failureCount += chunkGroupsWithSequence.length;
      }
    }

    this._setProgress(100, `Done — ${successCount} transaction(s) submitted, ${failureCount} failed to push.`);
    if (failureCount === 0) {
      this._showToast(`Submitted ${successCount} transaction(s) across ${chunks.length} push(es) — awaiting confirmation.`, "success");
    } else {
      this._showToast(`${successCount} submitted, ${failureCount} failed to push — check the log.`, "error");
    }

    if (submittedRowCount > 0) this._trackImportStart(callerId, importStartedAt, submittedRowCount);

    await this._database.putRows(this._rows);
    this._renderGrid();
    this._updateSummaryLabel();

    if (successCount > 0) {
      this._setProgress(100, "Awaiting confirmation…");
      this._log("info", "Checking for confirmation…");
      await this._pollRedisForUpdates(false, true); // popup stays open until the first result lands
    } else {
      this._closeProgressPopup();
    }
  }

  // Greedily packs whole transactions into size-capped chunks — never
  // splits a single transaction across two pushes. If one transaction''s
  // own payload (with envelope) already exceeds the cap by itself, it''s
  // still pushed alone (best effort, logged as a warning) since it can''t
  // be split further without cutting the transaction in half.
  _chunkGroupsBySize(groupsWithSequence, buildPayloadFn) {
    const chunks = [];
    let current = [];

    groupsWithSequence.forEach((g) => {
      const candidate = [...current, g];
      const candidateSize = new Blob([JSON.stringify(buildPayloadFn(candidate))]).size;

      if (candidateSize > EIP_MAX_PAYLOAD_BYTES && current.length > 0) {
        chunks.push(current);
        current = [g];
      } else {
        current = candidate;
      }
    });
    if (current.length > 0) chunks.push(current);

    // Warn (but still send) any single-transaction chunk that alone
    // exceeds the cap.
    chunks.forEach((chunk, idx) => {
      if (chunk.length === 1) {
        const size = new Blob([JSON.stringify(buildPayloadFn(chunk))]).size;
        if (size > EIP_MAX_PAYLOAD_BYTES) {
          console.warn(`[EIP] Push ${idx + 1}: a single transaction''s payload is ${(size / (1024 * 1024)).toFixed(2)}MB, over the 9MB cap — sending it alone since it can''t be split.`);
        }
      }
    });

    return chunks;
  }

  /* ---------------------------------------------------------
     Payload builders (AxPut + ASBRest), bundling all groups.
     --------------------------------------------------------- */
  _resolveActionForGroup(group) {
    const firstRowAxMode = group[0].axModeValue;
    if (!firstRowAxMode) return "create";
    return AX_MODE_ACTION_MAP[firstRowAxMode] || "create";
  }

  // axRowAction (when passed, currently only "edit") is stamped onto EVERY
  // row of EVERY dc in submitdata — as its own "axrow_action" key, first in
  // the row — in addition to the entry-level "action" field, per confirmed
  // example.
  _buildSubmitDataForGroup(group, fieldsByFormNumber, axRowAction) {
    const submitData = {};
    const formNumbers = Array.from(fieldsByFormNumber.keys()).sort((a, b) => a - b);
    formNumbers.forEach((formNumber) => {
      const fields = fieldsByFormNumber.get(formNumber);
      const isGrid = fields.some((f) => f.isGridField);
      const dcKey = `dc${formNumber}`;
      if (isGrid) {
        const rows = {};
        group.forEach((resolved, idx) => {
          const columns = {};
          if (axRowAction) columns.axrow_action = axRowAction;
          fields.forEach((f) => { columns[f.fieldName] = resolved.values[f.fieldName] !== undefined ? resolved.values[f.fieldName] : ""; });
          rows[`row${idx + 1}`] = columns;
        });
        submitData[dcKey] = rows;
      } else {
        const columns = {};
        if (axRowAction) columns.axrow_action = axRowAction;
        fields.forEach((f) => { columns[f.fieldName] = group[0].values[f.fieldName] !== undefined ? group[0].values[f.fieldName] : ""; });
        submitData[dcKey] = { row1: columns };
      }
    });
    return submitData;
  }

  _buildAxPutPayload(transId, groupsWithSequence, fieldsByFormNumber, callerId) {
    const { armSessionId, armToken, project, username } = this._resolveSessionParams();
    const keyFieldName = this._currentJob.keyFieldName;
    const data = groupsWithSequence.map(({ group, sequenceNo }) => {
      const action = this._resolveActionForGroup(group);
      const entry = {
        "transid": transId,
        "action": action,
        "sequenceno": sequenceNo,
        ...(keyFieldName ? { "returnfield": keyFieldName } : {}),
        "submitdata": this._buildSubmitDataForGroup(group, fieldsByFormNumber, action === "edit" ? "edit" : null),
      };
      // edit/delete need to identify an EXISTING record — pass the
      // selected Key Field and this transaction''s own value for it.
      if ((action === "edit" || action === "delete") && keyFieldName) {
        entry.keyfield = keyFieldName;
        entry.keyvalue = group[0].values[keyFieldName] !== undefined ? group[0].values[keyFieldName] : "";
      }
      return entry;
    });
    return {
      "_parameters": [{
        "ARMSessionId": armSessionId,
        "ARMToken": armToken,
        "isaxput": "true",
        "project": project,
        "username": username,
        "trace": false,
        "validateonly": false,
        "axclient_dateformat": "dd/MM/yyyy",
        "millisecsintimestamp": true,
        "callerid": callerId,
        "data": data,
      }],
    };
  }

  _buildRecdataForGroup(group, fieldsByFormNumber) {
    const formNumbers = Array.from(fieldsByFormNumber.keys()).sort((a, b) => a - b);
    const recdata = [];
    const changedrows = {};
    formNumbers.forEach((formNumber) => {
      const fields = fieldsByFormNumber.get(formNumber);
      const isGrid = fields.some((f) => f.isGridField);
      const recIdKey = `axp_recid${formNumber}`;
      if (isGrid) {
        changedrows[`dc${formNumber}`] = "*";
        const rows = group.map((resolved, idx) => {
          const columns = {};
          fields.forEach((f) => { columns[f.fieldName] = resolved.values[f.fieldName] !== undefined ? resolved.values[f.fieldName] : ""; });
          return { rowno: String(idx + 1).padStart(3, "0"), text: idx === 0 ? "0" : "", columns };
        });
        recdata.push({ [recIdKey]: rows });
      } else {
        const columns = {};
        fields.forEach((f) => { columns[f.fieldName] = group[0].values[f.fieldName] !== undefined ? group[0].values[f.fieldName] : ""; });
        recdata.push({ [recIdKey]: [{ rowno: "001", text: "0", columns }] });
      }
    });
    return { recdata, changedrows };
  }

  _buildAsbRestPayload(transId, groupsWithSequence, fieldsByFormNumber, callerId) {
    const { armSessionId, project, username, sessionId } = this._resolveSessionParams();
    const keyFieldName = this._currentJob.keyFieldName;
    const parameters = {
      "ARMSessionId": armSessionId,
      "isaxput": "false",
      "project": project,
      "username": username,
      "sessionid": sessionId,
      "trace": "true",
      "callerid": callerId,
    };
    groupsWithSequence.forEach(({ group, sequenceNo }, groupIndex) => {
      const { recdata, changedrows } = this._buildRecdataForGroup(group, fieldsByFormNumber);
      const action = this._resolveActionForGroup(group);
      // ASBRest has no "action" field, so edit/delete are only knowable via
      // ax_mode. We only have a confirmed payload for edit — keyfield/keyvalue
      // sit right after recordid (sibling to recdata), not inside columns.
      const isEdit = action === "edit" && keyFieldName;
      const transaction = {
        "transid": transId,
        "afiles": "",
        "recordid": "0",
        ...(isEdit ? {
          "keyfield": keyFieldName,
          "keyvalue": group[0].values[keyFieldName] !== undefined ? group[0].values[keyFieldName] : "",
        } : {}),
        "sequenceno": sequenceNo,
        ...(keyFieldName ? { "returnfield": keyFieldName } : {}),
        "changedrows": changedrows,
        "recdata": recdata,
      };
      parameters[`transaction${groupIndex + 1}`] = transaction;
    });
    return { "_parameters": [parameters] };
  }

  // Fresh, unique ID for this import run — same value on every transaction
  // submitted in this one Import click.
  _generateCallerId() {
    return `imp${Date.now()}${Math.random().toString(36).slice(2, 8)}`;
  }

  /* ---------------------------------------------------------
     Combined (multi-sheet) import — used when several sheets in the
     same upload target the same T-Struct AND a shared Key Field is
     set. Each sheet only maps the columns for the dc(s) it''s
     responsible for; the Key Field''s mapped column in each sheet is
     the join column tying rows across sheets into one transaction.
     --------------------------------------------------------- */

  // Resolves one sheet''s eligible rows into {row, values, axModeValue} —
  // same per-cell resolution (date normalization etc.) as the
  // single-sheet flow, just parameterized by job/rows/fieldsByFormNumber
  // so it can run once per sibling sheet.
  _resolveSheetRows(job, rows, fieldsByFormNumber) {
    const axModeIdx = job.axModeColumnIndex;
    const resolvedRows = [];
    rows.forEach((row) => {
      try {
        const values = {};
        fieldsByFormNumber.forEach((fields) => {
          fields.forEach((field) => {
            const rawValue = row.cells[field.columnIndex];
            const trueCellDate = this._getTrueCellDate(row.sheetRowIndex, field.columnIndex);
            const fieldSuggestsDate = field.dataType && String(field.dataType).toLowerCase().includes("date");
            const shouldTreatAsDate = trueCellDate !== null || fieldSuggestsDate;
            if (shouldTreatAsDate && rawValue !== "" && rawValue !== undefined && rawValue !== null) {
              const normalized = this._normalizeDateValue(trueCellDate !== null ? trueCellDate : rawValue);
              values[field.fieldName] = normalized !== null ? normalized : String(rawValue);
            } else {
              values[field.fieldName] = rawValue !== undefined && rawValue !== null ? String(rawValue) : "";
            }
          });
        });
        const axModeValue = axModeIdx !== null && axModeIdx !== undefined ? String(row.cells[axModeIdx] || "").trim().toLowerCase() : "";
        resolvedRows.push({ row, values, axModeValue });
      } catch (err) {
        console.error(`[EIP] Row ${row.rowIndex} in sheet "${job.sheetName}" failed to resolve — marking as error`, err);
        row.status = "error";
        row.errorMessage = `Processing error: ${err.message || err}`;
      }
    });
    return resolvedRows;
  }

  // Groups one sheet''s resolved rows by consecutive same-value-in-the-
  // key-column — same rule as the single-sheet grouping algorithm,
  // applied per sheet before merging across sheets.
  _groupResolvedRowsByKeyColumn(resolvedRows, keyColumnIndex) {
    const groups = [];
    let current = [];
    let currentKey;
    resolvedRows.forEach((resolved) => {
      const key = resolved.row.cells[keyColumnIndex];
      if (current.length === 0) {
        current = [resolved];
        currentKey = key;
        return;
      }
      if (key === currentKey) {
        current.push(resolved);
      } else {
        groups.push(current);
        current = [resolved];
        currentKey = key;
      }
    });
    if (current.length > 0) groups.push(current);
    return groups;
  }

  // Builds submitdata for ONE merged (cross-sheet) transaction, keyed by
  // the shared Key Field''s value. For each dc/formNumber, only the
  // sheet(s) that actually mapped fields for that formNumber contribute
  // rows — this avoids blending unrelated sheets'' rows into the wrong
  // dc (e.g. a header sheet''s single row leaking into a grid dc it
  // never mapped anything for).
  // axRowAction: same "axrow_action" stamp as _buildSubmitDataForGroup,
  // applied to every contributing row across all merged sheets/dcs.
  _buildMergedSubmitDataForKeyValue(mergedFieldsByFormNumber, perSheet, keyValue, axRowAction) {
    const submitData = {};
    const formNumbers = Array.from(mergedFieldsByFormNumber.keys()).sort((a, b) => a - b);
    formNumbers.forEach((formNumber) => {
      const fields = mergedFieldsByFormNumber.get(formNumber);
      const isGrid = fields.some((f) => f.isGridField);
      const dcKey = `dc${formNumber}`;

      const contributingRows = [];
      perSheet.forEach((sheetInfo) => {
        if (!sheetInfo.fieldsByFormNumber.has(formNumber)) return;
        const matchingLocalGroup = sheetInfo.localGroups.find((g) => g[0].row.cells[sheetInfo.keyColumnIndex] === keyValue);
        if (matchingLocalGroup) contributingRows.push(...matchingLocalGroup);
      });
      if (contributingRows.length === 0) return; // no sheet in this group has data for this dc/transaction

      if (isGrid) {
        const rows = {};
        contributingRows.forEach((resolved, idx) => {
          const columns = {};
          if (axRowAction) columns.axrow_action = axRowAction;
          fields.forEach((f) => { columns[f.fieldName] = resolved.values[f.fieldName] !== undefined ? resolved.values[f.fieldName] : ""; });
          rows[`row${idx + 1}`] = columns;
        });
        submitData[dcKey] = rows;
      } else {
        const columns = {};
        if (axRowAction) columns.axrow_action = axRowAction;
        fields.forEach((f) => { columns[f.fieldName] = contributingRows[0].values[f.fieldName] !== undefined ? contributingRows[0].values[f.fieldName] : ""; });
        submitData[dcKey] = { row1: columns };
      }
    });
    return submitData;
  }

  // ASBRest equivalent of the above — same contributing-sheet logic,
  // just building recdata/changedrows instead of submitdata.
  _buildMergedRecdataForKeyValue(mergedFieldsByFormNumber, perSheet, keyValue) {
    const formNumbers = Array.from(mergedFieldsByFormNumber.keys()).sort((a, b) => a - b);
    const recdata = [];
    const changedrows = {};
    formNumbers.forEach((formNumber) => {
      const fields = mergedFieldsByFormNumber.get(formNumber);
      const isGrid = fields.some((f) => f.isGridField);
      const recIdKey = `axp_recid${formNumber}`;

      const contributingRows = [];
      perSheet.forEach((sheetInfo) => {
        if (!sheetInfo.fieldsByFormNumber.has(formNumber)) return;
        const matchingLocalGroup = sheetInfo.localGroups.find((g) => g[0].row.cells[sheetInfo.keyColumnIndex] === keyValue);
        if (matchingLocalGroup) contributingRows.push(...matchingLocalGroup);
      });
      if (contributingRows.length === 0) return;

      if (isGrid) {
        changedrows[`dc${formNumber}`] = "*";
        const rows = contributingRows.map((resolved, idx) => {
          const columns = {};
          fields.forEach((f) => { columns[f.fieldName] = resolved.values[f.fieldName] !== undefined ? resolved.values[f.fieldName] : ""; });
          return { rowno: String(idx + 1).padStart(3, "0"), text: idx === 0 ? "0" : "", columns };
        });
        recdata.push({ [recIdKey]: rows });
      } else {
        const columns = {};
        fields.forEach((f) => { columns[f.fieldName] = contributingRows[0].values[f.fieldName] !== undefined ? contributingRows[0].values[f.fieldName] : ""; });
        recdata.push({ [recIdKey]: [{ rowno: "001", text: "0", columns }] });
      }
    });
    return { recdata, changedrows };
  }

  _resolveActionForKeyValue(perSheet, keyValue) {
    for (const sheetInfo of perSheet) {
      const matchingLocalGroup = sheetInfo.localGroups.find((g) => g[0].row.cells[sheetInfo.keyColumnIndex] === keyValue);
      if (matchingLocalGroup && matchingLocalGroup[0].axModeValue) {
        return AX_MODE_ACTION_MAP[matchingLocalGroup[0].axModeValue] || "create";
      }
    }
    return "create";
  }

  _buildCombinedAxPutPayload(transId, mergedGroupsWithSequence, mergedFieldsByFormNumber, perSheet, callerId, keyFieldName) {
    const { armSessionId, armToken, project, username } = this._resolveSessionParams();
    const data = mergedGroupsWithSequence.map(({ keyValue, sequenceNo }) => {
      const action = this._resolveActionForKeyValue(perSheet, keyValue);
      const entry = {
        "transid": transId,
        "action": action,
        "sequenceno": sequenceNo,
        ...(keyFieldName ? { "returnfield": keyFieldName } : {}),
        "submitdata": this._buildMergedSubmitDataForKeyValue(mergedFieldsByFormNumber, perSheet, keyValue, action === "edit" ? "edit" : null),
      };
      // edit/delete need to identify an EXISTING record. keyValue here
      // already IS the value of the shared Key Field (that''s what the
      // cross-sheet merge grouped by), so no extra lookup is needed.
      if ((action === "edit" || action === "delete") && keyFieldName) {
        entry.keyfield = keyFieldName;
        entry.keyvalue = keyValue;
      }
      return entry;
    });
    return {
      "_parameters": [{
        "ARMSessionId": armSessionId,
        "ARMToken": armToken,
        "isaxput": "true",
        "project": project,
        "username": username,
        "trace": false,
        "validateonly": false,
        "axclient_dateformat": "dd/MM/yyyy",
        "millisecsintimestamp": true,
        "callerid": callerId,
        "data": data,
      }],
    };
  }

  _buildCombinedAsbRestPayload(transId, mergedGroupsWithSequence, mergedFieldsByFormNumber, perSheet, callerId, keyFieldName) {
    const { armSessionId, project, username, sessionId } = this._resolveSessionParams();
    const parameters = {
      "ARMSessionId": armSessionId,
      "isaxput": "false",
      "project": project,
      "username": username,
      "sessionid": sessionId,
      "trace": "true",
      "callerid": callerId,
    };
    mergedGroupsWithSequence.forEach(({ keyValue, sequenceNo }, groupIndex) => {
      const { recdata, changedrows } = this._buildMergedRecdataForKeyValue(mergedFieldsByFormNumber, perSheet, keyValue);
      const action = this._resolveActionForKeyValue(perSheet, keyValue);
      // keyValue here already IS the shared Key Field''s value (that''s what
      // the cross-sheet merge grouped by) — same rule as the combined AxPut
      // builder, just placed right after recordid for this format.
      const isEdit = action === "edit" && keyFieldName;
      const transaction = {
        "transid": transId,
        "afiles": "",
        "recordid": "0",
        ...(isEdit ? { "keyfield": keyFieldName, "keyvalue": keyValue } : {}),
        "sequenceno": sequenceNo,
        ...(keyFieldName ? { "returnfield": keyFieldName } : {}),
        "changedrows": changedrows,
        "recdata": recdata,
      };
      parameters[`transaction${groupIndex + 1}`] = transaction;
    });
    return { "_parameters": [parameters] };
  }

  // Orchestrates a combined multi-sheet import: validates every sibling
  // sheet, resolves + locally-groups each sheet''s rows by its Key
  // Field column, merges local groups across sheets by matching Key
  // Field VALUE (primary/first sheet''s group order drives sequencing),
  // builds one bundled payload, pushes it, and updates row status
  // across ALL involved sheets/jobs (not just the current tab).
  async _runCombinedImport(siblings) {
    // 1. Every sheet must be fully mapped and have the shared Key Field
    //    mapped to one of its own columns (the join column).
    for (const job of siblings) {
      const axModeIdx = job.axModeColumnIndex;
      const unmapped = job.columnMappings
        .map((m, colIndex) => ({ m, colIndex }))
        .filter(({ m, colIndex }) => colIndex !== axModeIdx && !m.mappedFieldName);
      if (unmapped.length > 0) {
        const names = unmapped.map(({ colIndex }) => job.excelHeaders[colIndex]).join(", ");
        this._showToast(`Sheet "${job.sheetName}": every column must be mapped before importing. Not mapped: ${names}`, "error");
        return;
      }
      const keyColIdx = job.columnMappings.findIndex((m) => m.mappedFieldName === job.keyFieldName);
      if (keyColIdx === -1) {
        this._showToast(`Sheet "${job.sheetName}" needs a column mapped to the shared Key Field ("${job.keyFieldName}") to join it with the other sheets.`, "error");
        return;
      }
    }

    // 2. Save mapping memory for every sheet, and validate every sheet''s rows.
    const rowsByJobId = new Map();
    for (const job of siblings) {
      this._saveMappingMemoryToServer(job); // fire-and-forget, per sheet
      const rows = (await this._database.getRowsByJobId(job.jobId)).sort((a, b) => a.rowIndex - b.rowIndex);
      this._validateRowsForJob(job, rows);
      await this._database.putRows(rows);
      rowsByJobId.set(job.jobId, rows);
    }

    const anySheetHasErrors = siblings.some((job) => rowsByJobId.get(job.jobId).some((r) => r.status === "error"));
    if (anySheetHasErrors) {
      this._showToast("Some sheets have validation errors — fix them before importing.", "error");
      if (this._currentJob) {
        this._rows = rowsByJobId.get(this._currentJobId) || this._rows;
        this._renderGrid();
        this._updateSummaryLabel();
      }
      return;
    }

    // 3. Per-sheet: build fieldsByFormNumber (only that sheet''s OWN
    //    mapped fields), resolve eligible rows, and locally group by
    //    the join column.
    //
    // IMPORTANT: each sheet''s fields must come from THAT sheet''s own
    // T-Struct/DC selection, fetched independently here — this._allFields
    // is a single shared cache that only reflects whichever tab happens to
    // be active when Import is clicked. Reusing it here was the bug that
    // made a combined import only carry the ACTIVE sheet''s dc: every other
    // sibling''s columnMappings failed the `this._allFields.find(...)`
    // lookup (wrong field list), so their fieldsByFormNumber came back
    // empty and they silently contributed nothing to the merged payload.
    const fieldsBySheetJobId = new Map();
    for (const job of siblings) {
      const sheetFields = await this._fetchFieldsForTStruct(job.transId, job.selectedDcNames || []);
      fieldsBySheetJobId.set(job.jobId, sheetFields);
    }

    const perSheet = siblings.map((job) => {
      const sheetFields = fieldsBySheetJobId.get(job.jobId) || [];
      const fieldsByFormNumber = new Map();
      job.columnMappings.forEach((mapping, colIndex) => {
        if (!mapping.mappedFieldName) return;
        const field = sheetFields.find((f) => f.fieldName === mapping.mappedFieldName);
        if (!field) return;
        if (!fieldsByFormNumber.has(field.formNumber)) fieldsByFormNumber.set(field.formNumber, []);
        fieldsByFormNumber.get(field.formNumber).push({ ...field, columnIndex: colIndex });
      });
      const keyColumnIndex = job.columnMappings.findIndex((m) => m.mappedFieldName === job.keyFieldName);
      const eligibleRows = rowsByJobId.get(job.jobId).filter((r) => r.status === "pending");
      const resolvedRows = this._resolveSheetRows(job, eligibleRows, fieldsByFormNumber);
      const localGroups = this._groupResolvedRowsByKeyColumn(resolvedRows, keyColumnIndex);
      return { job, fieldsByFormNumber, keyColumnIndex, localGroups };
    });

    if (perSheet.every((s) => s.localGroups.length === 0)) {
      this._showToast("Nothing to post after grouping.", "error");
      return;
    }

    // 4. Merge fieldsByFormNumber across all sheets (union) for payload building.
    const mergedFieldsByFormNumber = new Map();
    perSheet.forEach(({ fieldsByFormNumber }) => {
      fieldsByFormNumber.forEach((fields, formNumber) => {
        if (!mergedFieldsByFormNumber.has(formNumber)) mergedFieldsByFormNumber.set(formNumber, []);
        mergedFieldsByFormNumber.get(formNumber).push(...fields);
      });
    });

    // 5. Primary sheet = first sibling (sheet/tab order) that actually
    //    has local groups — drives transaction order/sequenceno. Other
    //    sheets'' matching groups (by Key Field value) are merged in.
    const primary = perSheet.find((s) => s.localGroups.length > 0);
    const mergedGroupsWithSequence = primary.localGroups.map((primaryGroupRows) => {
      const keyValue = primaryGroupRows[0].row.cells[primary.keyColumnIndex];
      return { keyValue, sequenceNo: primaryGroupRows[0].row.rowIndex + 1 };
    });

    const involvedRowsByKeyValue = new Map();
    mergedGroupsWithSequence.forEach(({ keyValue }) => {
      const rows = [];
      perSheet.forEach((sheetInfo) => {
        const matchingLocalGroup = sheetInfo.localGroups.find((g) => g[0].row.cells[sheetInfo.keyColumnIndex] === keyValue);
        if (matchingLocalGroup) rows.push(...matchingLocalGroup.map((r) => r.row));
      });
      involvedRowsByKeyValue.set(keyValue, rows);
    });

    const useAxPut = this._currentJob.useAxPut;
    const callerId = this._generateCallerId();
    const keyFieldName = this._currentJob.keyFieldName;
    const transId = this._currentJob.transId;

    const buildFn = (subset) =>
      useAxPut
        ? this._buildCombinedAxPutPayload(transId, subset, mergedFieldsByFormNumber, perSheet, callerId, keyFieldName)
        : this._buildCombinedAsbRestPayload(transId, subset, mergedFieldsByFormNumber, perSheet, callerId, keyFieldName);

    const chunks = this._chunkGroupsBySize(
      mergedGroupsWithSequence, // _chunkGroupsBySize is fully generic, just needs an array + a buildPayloadFn
      buildFn
    );
    console.log(`[EIP] Combined import: ${mergedGroupsWithSequence.length} transaction(s) across ${siblings.length} sheet(s), split into ${chunks.length} push(es).`);

    const importStartedAt = Date.now();
    this._openProgressPopup();
    this._startElapsedTicker(importStartedAt);
    this._setProgress(20, `Building payload for ${mergedGroupsWithSequence.length} transaction(s)…`);

    const totalRowsAttempted = Array.from(involvedRowsByKeyValue.values()).reduce((sum, rows) => sum + rows.length, 0);
    const estimate = this._estimateImportDuration(totalRowsAttempted);
    if (estimate) {
      this._log("info", `Estimated time: ~${this._formatDuration(estimate.estimatedMs)} for ${totalRowsAttempted} record(s) across ${siblings.length} sheet(s), based on ${estimate.sampleCount} previous import(s) (~${estimate.msPerRecord.toFixed(0)}ms/record).`);
    }

    let successCount = 0;
    let failureCount = 0;
    let submittedRowCount = 0; // only rows that actually reached "submitted" — these are the ones Redis will eventually confirm
    const allInvolvedRows = [];

    for (let i = 0; i < chunks.length; i++) {
      const chunk = chunks[i];
      const payload = buildFn(chunk);
      const jsonDataString = JSON.stringify(payload);
      const involvedRows = chunk.flatMap(({ keyValue }) => involvedRowsByKeyValue.get(keyValue) || []);

      console.log(`[EIP] Combined push ${i + 1}/${chunks.length}: ${chunk.length} transaction(s), ${(new Blob([jsonDataString]).size / (1024 * 1024)).toFixed(2)} MB (object):`, payload);
      console.log(`[EIP] Combined push ${i + 1}/${chunks.length} (stringified):`, jsonDataString);

      this._setProgress(20 + Math.round(((i + 1) / chunks.length) * 60), `Posting push ${i + 1} of ${chunks.length} (${chunk.length} transaction(s))…`);

      try {
        const res = await this._pushToQueue(jsonDataString);
        console.log(`[EIP] Combined push ${i + 1}/${chunks.length} succeeded:`, res);
        chunk.forEach(({ keyValue, sequenceNo }) => {
          (involvedRowsByKeyValue.get(keyValue) || []).forEach((row) => {
            row.status = "submitted";
            row.callerId = callerId;
            row.sequenceNo = sequenceNo;
            row.errorMessage = null;
          });
        });
        this._log("success", `Push ${i + 1}/${chunks.length}: posted ${chunk.length} transaction(s) (${involvedRows.length} row(s) across ${siblings.length} sheet(s)) — awaiting confirmation.`);
        successCount += chunk.length;
        submittedRowCount += involvedRows.length;
      } catch (err) {
        console.error(`[EIP] Combined push ${i + 1}/${chunks.length} failed:`, err);
        involvedRows.forEach((row) => { row.status = "error"; row.errorMessage = `Push failed: ${err.message || err}`; });
        this._log("error", `Push ${i + 1}/${chunks.length} failed: ${err.message || err}`);
        failureCount += chunk.length;
      }
      allInvolvedRows.push(...involvedRows);
    }

    this._setProgress(100, `Done — ${successCount} transaction(s) submitted, ${failureCount} failed to push.`);
    if (failureCount === 0) {
      this._showToast(`Submitted ${successCount} transaction(s) across ${siblings.length} sheet(s) — awaiting confirmation.`, "success");
    } else {
      this._showToast(`${successCount} submitted, ${failureCount} failed to push — check the log.`, "error");
    }

    if (submittedRowCount > 0) this._trackImportStart(callerId, importStartedAt, submittedRowCount);

    // Persist every involved row, across every sheet''s own row set.
    await this._database.putRows(allInvolvedRows);
    this._rows = (await this._database.getRowsByJobId(this._currentJobId)).sort((a, b) => a.rowIndex - b.rowIndex);
    this._renderGrid();
    this._updateSummaryLabel();

    if (successCount > 0) {
      this._setProgress(100, "Awaiting confirmation…");
      this._log("info", "Checking for confirmation…");
      await this._pollRedisForUpdates(false, true);
    } else {
      this._closeProgressPopup();
    }
  }

  _pushToQueue(jsonDataString) {
    return new Promise((resolve, reject) => {
      parent.AxPushtoQueueAPI(jsonDataString, (res) => resolve(res), (err) => reject(err));
    });
  }

  /* ---------------------------------------------------------
     Redis progress polling.
     ONE wildcard read per callerid — InMemoryKey =
     "project-callerid-*" — returns every sequenceno''s key for that
     import in a single call, instead of one call per outstanding
     transaction. Response shape (confirmed): {"success":true,
     "message":"N key(s) found","result":"{\"<fullKey>\":<value>,...}"}
     — result is a JSON-STRING of an object keyed by the full key name
     ("project-callerid-sequenceno"); sequenceno is recovered by
     stripping the known "project-callerid-" prefix off each key.
     A "not found"/no-keys-yet response just means nothing has landed
     for this callerid yet — not an error — so it''s retried next poll.

     Each individual value, once located, is triple-nested
     JSON-as-string (see _parseRedisTransactionResult below) — same
     parsing regardless of whether it came from a wildcard or a
     single-key read.
     --------------------------------------------------------- */
  _redisWildcardRead(callerId) {
    return new Promise((resolve) => {
      const { project } = this._resolveSessionParams();
      const keyPrefix = `${project}-${callerId}-`;
      const wildcardKey = `${keyPrefix}*`;
      const handleResponse = (response) => {
        console.log(`[EIP] Raw AxRedisReadAPI response for callerid="${callerId}":`, response);

        let parsed = response;
        try {
          parsed = typeof response === "string" ? JSON.parse(response) : response;
        } catch (e) {
          console.warn("[EIP] Could not JSON.parse the outer AxRedisReadAPI response:", e);
        }
        // Some Axpert API responses arrive wrapped in a ".d" envelope
        // (same pattern already handled for GetDataFromAxList) — unwrap
        // it here too if present.
        if (parsed && parsed.d !== undefined) {
          try {
            parsed = typeof parsed.d === "string" ? JSON.parse(parsed.d) : parsed.d;
          } catch (e) {
            console.warn("[EIP] Could not JSON.parse the .d-wrapped AxRedisReadAPI response:", e);
          }
        }
        console.log("[EIP] Parsed outer response:", parsed);

        if (parsed && parsed.success === true && parsed.result) {
          let resultObj = parsed.result;
          try {
            resultObj = typeof parsed.result === "string" ? JSON.parse(parsed.result) : parsed.result;
          } catch (e) {
            console.warn("[EIP] Could not parse wildcard Redis result object:", e, parsed.result);
            resolve({ found: false, bySequenceNo: {} });
            return;
          }
          console.log("[EIP] Parsed result object (fullKey -> value):", resultObj);

          const bySequenceNo = {};
          Object.entries(resultObj || {}).forEach(([fullKey, value]) => {
            if (!fullKey.startsWith(keyPrefix)) return; // defensive — shouldn''t happen given the prefix query
            // Real keys carry a trailing suffix after the sequenceno (e.g.
            // "...-1-♣"), so pull out just the LEADING digits rather than
            // trusting everything after the prefix to be a clean number.
            const remainder = fullKey.slice(keyPrefix.length);
            const digitsMatch = remainder.match(/^\d+/);
            const sequenceNo = digitsMatch ? digitsMatch[0] : remainder;
            bySequenceNo[sequenceNo] = value;
          });
          console.log("[EIP] Extracted bySequenceNo map:", bySequenceNo);
          resolve({ found: Object.keys(bySequenceNo).length > 0, bySequenceNo });
        } else {
          console.log(`[EIP] Wildcard read for callerid="${callerId}" -> no usable result (success=${parsed && parsed.success}, hasResult=${!!(parsed && parsed.result)}).`);
          resolve({ found: false, bySequenceNo: {} }); // no keys yet, or a transient error — try again next poll
        }
      };
      try {
        parent.AxRedisReadAPI(project, wildcardKey, "", "false", handleResponse, handleResponse);
      } catch (err) {
        console.error("[EIP] AxRedisReadAPI (wildcard) call failed", err);
        resolve({ found: false, bySequenceNo: {} });
      }
    });
  }

  // Unpacks the triple-nested JSON-as-string value described above.
  // Any parsing failure is treated conservatively as a failure (not a
  // silent success) — surfacing the raw text rather than guessing.
  //
  // layer3.result has appeared in TWO shapes from the backend so far:
  //   NEW: a plain object with an explicit boolean "success" flag —
  //        { message, success, data? } — data[0].message is the
  //        human-readable confirmation text on success.
  //   OLD: an array, each entry having EITHER an "error" key (failure)
  //        or a "message" key (an array, success).
  // Both are handled here so a backend format change doesn''t silently
  // break parsing again — the shape is detected per-response, not
  // assumed.
  _parseRedisTransactionResult(layer1Result) {
    try {
      const layer2 = typeof layer1Result === "string" ? JSON.parse(layer1Result) : layer1Result;
      const layer3 = typeof layer2.msg === "string" ? JSON.parse(layer2.msg) : layer2.msg;
      const result = layer3 && layer3.result;

      if (!result) {
        return { isSuccess: false, message: "Unrecognized response (no result entry)." };
      }

      // NEW shape: plain object with an explicit success flag.
      if (!Array.isArray(result) && typeof result === "object" && "success" in result) {
        if (result.success) {
          const dataEntry = Array.isArray(result.data) ? result.data[0] : null;
          return { isSuccess: true, message: (dataEntry && dataEntry.message) || result.message || "Saved." };
        }
        return { isSuccess: false, message: result.message || "Unknown error." };
      }

      // OLD shape: array of entries, each with an "error" or "message" key.
      const entry = Array.isArray(result) ? result[0] : null;
      if (entry) {
        if (entry.error) {
          return { isSuccess: false, message: entry.error.msg || "Unknown error." };
        }
        if (entry.message) {
          const msgEntry = Array.isArray(entry.message) ? entry.message[0] : entry.message;
          return { isSuccess: true, message: (msgEntry && msgEntry.msg) || "Saved." };
        }
      }

      return { isSuccess: false, message: "Unrecognized response shape (no error or message key)." };
    } catch (err) {
      console.warn("[EIP] Could not parse nested Redis transaction result:", err, layer1Result);
      return { isSuccess: false, message: `Could not parse result: ${String(layer1Result).slice(0, 200)}` };
    }
  }

  // Scans every job''s "submitted" (awaiting confirmation) rows, grouped by
  // callerid (a single Import click''s callerid may cover several
  // transactions/sequencenos, and a transaction can itself span multiple
  // grid rows), reads ALL of a callerid''s outstanding transactions in
  // ONE wildcard call, and updates row status accordingly:
  //   success -> uploaded (terminal, confirmed)
  //   failure -> failed (processing error — does NOT block future
  //              imports; re-validating will move it back to "pending"
  //              so the next Import retries it)
  // A key not yet present -> its rows stay "submitted", checked again
  // next poll.
  //
  // Wildcard reads for every distinct callerid in a job run CONCURRENTLY
  // (Promise.all) rather than one-at-a-time. An in-progress guard also
  // skips a whole cycle if the previous one hasn''t finished yet, so
  // cycles never stack up.
  //
  // showPopup: if true, opens the progress popup (if not already open)
  // and — importantly — closes it the INSTANT the first individual
  // transaction result comes back found (success or failure) within a
  // wildcard response, without waiting for other callerids'' reads (or
  // other keys within the same response) to finish.
  async _pollRedisForUpdates(isManualRefresh = false, showPopup = false) {
    if (this._isPolling) {
      console.log("[EIP] Redis poll skipped — previous cycle still in progress.");
      if (isManualRefresh) this._showToast("Already checking — try again in a moment.", "info");
      return;
    }
    this._isPolling = true;
    if (showPopup) this._openProgressPopup();

    try {
      if (isManualRefresh) this._showToast("Checking import status…", "info");
      console.log(`[EIP] Redis poll starting${isManualRefresh ? " (manual refresh)" : " (30s interval)"}…`);

      const allJobs = await this._database.getAllJobs();
      let anyUpdated = false;
      let totalCallerIdsChecked = 0;

      for (const job of allJobs) {
        const rows = await this._database.getRowsByJobId(job.jobId);
        const submittedRows = rows.filter((r) => r.status === "submitted" && r.callerId && r.sequenceNo !== undefined);
        if (submittedRows.length === 0) continue;

        // Group by callerId first (usually just one per job, but a job
        // could have multiple if Import was clicked more than once),
        // then by sequenceNo within each callerId.
        const rowsByCallerId = new Map();
        submittedRows.forEach((r) => {
          if (!rowsByCallerId.has(r.callerId)) rowsByCallerId.set(r.callerId, []);
          rowsByCallerId.get(r.callerId).push(r);
        });

        console.log(`[EIP] Job "${job.fileName}" (${job.jobId}): checking ${rowsByCallerId.size} callerid(s) via wildcard read.`);
        totalCallerIdsChecked += rowsByCallerId.size;

        const updatedRows = [];

        await Promise.all(
          Array.from(rowsByCallerId.entries()).map(async ([callerId, callerRows]) => {
            const wildcardResult = await this._redisWildcardRead(callerId);
            if (!wildcardResult.found) {
              console.log(`[EIP] Redis: callerid="${callerId}" -> no keys found yet (still awaiting confirmation).`);
              return;
            }

            const rowsBySequenceNo = new Map();
            callerRows.forEach((r) => {
              const seq = String(r.sequenceNo);
              if (!rowsBySequenceNo.has(seq)) rowsBySequenceNo.set(seq, []);
              rowsBySequenceNo.get(seq).push(r);
            });

            let poppedThisCaller = false;
            Object.entries(wildcardResult.bySequenceNo).forEach(([sequenceNo, rawValue]) => {
              const groupRows = rowsBySequenceNo.get(String(sequenceNo));
              if (!groupRows) return; // a key for a sequenceno we''re not (or no longer) waiting on

              const outcome = this._parseRedisTransactionResult(rawValue);
              console.log(`[EIP] Redis: callerid="${callerId}" sequenceno=${sequenceNo} -> ${outcome.isSuccess ? "SUCCESS" : "FAILURE"}: "${outcome.message}" (${groupRows.length} row(s) marked ${outcome.isSuccess ? "uploaded" : "failed"}).`);
              groupRows.forEach((r) => {
                r.status = outcome.isSuccess ? "uploaded" : "failed";
                r.errorMessage = outcome.isSuccess ? null : outcome.message;
                updatedRows.push(r);
              });

              if (!poppedThisCaller && showPopup) {
                this._closeProgressPopup();
                poppedThisCaller = true;
              }
            });
          })
        );

        if (updatedRows.length > 0) {
          await this._database.putRows(updatedRows);
          anyUpdated = true;
        }
      }

      console.log(`[EIP] Redis poll finished — ${totalCallerIdsChecked} callerid(s) checked, ${anyUpdated ? "some" : "no"} status update(s) applied.`);

      // Any callerId we''re tracking for elapsed-time purposes that no
      // longer has ANY row left at "submitted" (anywhere, not just in
      // this poll''s results) is fully done — log and record its real
      // total duration now.
      await this._finalizeCompletedImportTimings();

      if (this._currentJobId) {
        this._rows = (await this._database.getRowsByJobId(this._currentJobId)).sort((a, b) => a.rowIndex - b.rowIndex);
        this._renderGrid();
        this._updateSummaryLabel();
      }

      if (isManualRefresh) {
        this._showToast(anyUpdated ? "Status updated." : "No new updates yet.", anyUpdated ? "success" : "info");
      }

      // If the popup is still open at this point, nothing was found this
      // whole pass (a manual refresh that came up empty, or an
      // import-triggered poll where confirmation hasn''t landed yet) —
      // close it so it doesn''t sit open indefinitely; the grid''s own
      // status icons remain the source of truth, and the 30s background
      // poll will keep checking regardless of popup state.
      if (showPopup && this._isProgressPopupOpen()) this._closeProgressPopup();
    } finally {
      this._isPolling = false;
    }
  }

  /* ---------------------------------------------------------
     UI feedback helpers
     --------------------------------------------------------- */
  _openProgressPopup() {
    this._dom.progressModalOverlay.classList.remove("eip-hidden");
  }

  _closeProgressPopup() {
    this._dom.progressModalOverlay.classList.add("eip-hidden");
    this._stopElapsedTicker(); // belt-and-suspenders — any path that closes the popup also stops the ticker
  }

  _isProgressPopupOpen() {
    return !this._dom.progressModalOverlay.classList.contains("eip-hidden");
  }

  _setProgress(percent, label) {
    this._dom.progressBarFill.style.width = `${percent}%`;
    this._dom.progressLabel.textContent = label;
  }

  _log(level, message) {
    const entry = document.createElement("div");
    entry.className = `eip-log-entry eip-log-${level}`;
    const timestamp = new Date().toLocaleTimeString();
    entry.textContent = `[${timestamp}] ${message}`;
    this._dom.logList.appendChild(entry);
    this._dom.logList.scrollTop = this._dom.logList.scrollHeight;
  }

  /* ---------------------------------------------------------
     Elapsed-time tracking for imports.

     Two layers:
     1. A live ticking "Elapsed: Xs" readout in the progress popup while
        an import''s push phase is running (_startElapsedTicker /
        _stopElapsedTicker) — just UI feedback, discarded on close.
     2. The REAL total duration of an import — from the moment Import
        was clicked to the moment every one of its rows has a terminal
        status (uploaded/failed), which can span several 30s background
        poll cycles — tracked per callerId in this._importStartTimes and
        finalized from _pollRedisForUpdates (see
        _finalizeCompletedImportTimings below). That total is what feeds
        the "estimated time for N records" shown on the next import.
     --------------------------------------------------------- */
  _startElapsedTicker(startedAt) {
    this._stopElapsedTicker();
    const tick = () => {
      this._dom.progressElapsed.textContent = `Elapsed: ${this._formatDuration(Date.now() - startedAt)}`;
      this._updateSummaryLabel(); // keeps the inline ⏱ readout next to the row-status summary live too, not just the popup
    };
    tick();
    this._elapsedTickerInterval = setInterval(tick, 1000);
  }

  _stopElapsedTicker() {
    if (this._elapsedTickerInterval) {
      clearInterval(this._elapsedTickerInterval);
      this._elapsedTickerInterval = null;
    }
    if (this._dom.progressElapsed) this._dom.progressElapsed.textContent = "";
  }

  _formatDuration(ms) {
    if (ms < 1000) return `${Math.max(0, Math.round(ms))}ms`;
    const totalSeconds = Math.round(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    if (minutes === 0) return `${seconds}s`;
    const hours = Math.floor(minutes / 60);
    if (hours === 0) return `${minutes}m ${seconds}s`;
    return `${hours}h ${minutes % 60}m`;
  }

  // Registers a just-submitted push for total-duration tracking. Only
  // call with rows that actually made it to "submitted" (i.e. the push
  // succeeded) — rows that failed to push are never going to show up in
  // Redis, so including them would leave this callerId waiting forever.
  _trackImportStart(callerId, startedAt, totalRows) {
    if (!totalRows || totalRows <= 0) return;
    this._importStartTimes.set(callerId, { startedAt, totalRows });
  }

  // Called at the end of every _pollRedisForUpdates cycle. Re-checks,
  // across ALL jobs (an import''s rows may span several jobs/sheets for a
  // combined import), whether any row is still sitting at "submitted"
  // for each callerId we''re tracking; once none are left, the import is
  // truly done and we can log + record its real total duration.
  async _finalizeCompletedImportTimings() {
    if (this._importStartTimes.size === 0) return;

    const stillOutstanding = new Set();
    const jobsByCallerId = new Map(); // callerId -> [job, ...] — every job (sheet) that had rows pushed under this callerId, so a combined import''s timing lands on every sheet involved, not just the one active when it finished
    const allJobs = await this._database.getAllJobs();
    for (const job of allJobs) {
      const rows = await this._database.getRowsByJobId(job.jobId);
      const callerIdsInThisJob = new Set();
      rows.forEach((r) => {
        if (!r.callerId) return;
        if (r.status === "submitted") stillOutstanding.add(r.callerId);
        callerIdsInThisJob.add(r.callerId);
      });
      callerIdsInThisJob.forEach((callerId) => {
        if (!jobsByCallerId.has(callerId)) jobsByCallerId.set(callerId, []);
        jobsByCallerId.get(callerId).push(job);
      });
    }

    for (const [callerId, info] of Array.from(this._importStartTimes.entries())) {
      if (stillOutstanding.has(callerId)) continue;
      this._importStartTimes.delete(callerId);
      const elapsedMs = Date.now() - info.startedAt;
      this._recordImportTiming(info.totalRows, elapsedMs);

      // Persist onto every job this push touched, so the inline summary
      // label can show "last import" timing for a job even after a
      // reload or switching tabs and back — see _updateTimingLabel.
      const touchedJobs = jobsByCallerId.get(callerId) || [];
      for (const job of touchedJobs) {
        job.lastImportAt = Date.now();
        job.lastImportDurationMs = elapsedMs;
        job.lastImportTotalRows = info.totalRows;
        await this._database.putJob(job);
        // Keep the live in-memory copy in sync too — a fresh DB read is a
        // DIFFERENT object than this._currentJob (same class of staleness
        // bug fixed earlier in _onKeyFieldChanged), so update it directly
        // when it''s the job currently loaded.
        if (this._currentJob && this._currentJob.jobId === job.jobId) {
          this._currentJob.lastImportAt = job.lastImportAt;
          this._currentJob.lastImportDurationMs = job.lastImportDurationMs;
          this._currentJob.lastImportTotalRows = job.lastImportTotalRows;
        }
      }
    }

    if (this._currentJob) this._updateSummaryLabel();
  }

  // Logs the real duration and rolls it into a small rolling history
  // (capped at 30 entries) in localStorage, which _estimateImportDuration
  // reads to project a rough time for the NEXT import based on its record
  // count — "approximate time consumption based on no of records", per
  // the request.
  _recordImportTiming(totalRows, elapsedMs) {
    const msPerRecord = elapsedMs / totalRows;
    const perRecordLabel = msPerRecord < 1000 ? `${Math.round(msPerRecord)}ms` : `${(msPerRecord / 1000).toFixed(2)}s`;
    this._log("success", `Import completed: ${totalRows} record(s) in ${this._formatDuration(elapsedMs)} (~${perRecordLabel}/record).`);

    let history = [];
    try {
      history = JSON.parse(localStorage.getItem("eip_import_timings") || "[]");
      if (!Array.isArray(history)) history = [];
    } catch (e) {
      history = [];
    }
    history.push({ at: Date.now(), totalRows, elapsedMs });
    if (history.length > 30) history = history.slice(history.length - 30);
    try {
      localStorage.setItem("eip_import_timings", JSON.stringify(history));
    } catch (e) {
      console.warn("[EIP] Could not save import timing history to localStorage (non-critical):", e);
    }
  }

  // Weighted average (total ms / total rows, across history) rather than
  // a plain average of per-import rates, so a couple of very small test
  // imports don''t skew the estimate as much as the larger, more
  // representative ones.
  _estimateImportDuration(recordCount) {
    if (!recordCount || recordCount <= 0) return null;
    let history = [];
    try {
      history = JSON.parse(localStorage.getItem("eip_import_timings") || "[]");
      if (!Array.isArray(history)) history = [];
    } catch (e) {
      return null;
    }
    if (history.length === 0) return null;

    const totalRows = history.reduce((sum, h) => sum + (h.totalRows || 0), 0);
    const totalMs = history.reduce((sum, h) => sum + (h.elapsedMs || 0), 0);
    if (totalRows === 0) return null;

    const msPerRecord = totalMs / totalRows;
    return { msPerRecord, estimatedMs: msPerRecord * recordCount, sampleCount: history.length };
  }

  _showToast(message, type = "info") {
    const toast = this._dom.toast;
    toast.textContent = message;
    toast.className = "eip-toast eip-visible" + (type === "error" ? " eip-toast-error" : type === "success" ? " eip-toast-success" : "");
    setTimeout(() => toast.classList.remove("eip-visible"), 3200);
  }

  // In-app replacement for window.confirm — same modal look as the rest
  // of the page (title bar, Cancel/OK buttons) instead of the browser''s
  // own "<site> says" dialog. Returns a Promise<boolean>; only one can be
  // open at a time (Delete Job is the only caller today).
  _confirmDialog({ title = "Are you sure?", message = "", okLabel = "OK", danger = false } = {}) {
    return new Promise((resolve) => {
      this._dom.confirmModalTitle.textContent = title;
      this._dom.confirmModalMessage.textContent = message;
      this._dom.confirmOkBtn.textContent = okLabel;
      this._dom.confirmOkBtn.classList.toggle("eip-btn-danger", danger);
      this._dom.confirmOkBtn.classList.toggle("eip-btn-primary", !danger);
      this._dom.confirmModalOverlay.classList.remove("eip-hidden");

      const cleanup = (result) => {
        this._dom.confirmModalOverlay.classList.add("eip-hidden");
        this._dom.confirmOkBtn.removeEventListener("click", onOk);
        this._dom.confirmCancelBtn.removeEventListener("click", onCancel);
        resolve(result);
      };
      const onOk = () => cleanup(true);
      const onCancel = () => cleanup(false);
      this._dom.confirmOkBtn.addEventListener("click", onOk);
      this._dom.confirmCancelBtn.addEventListener("click", onCancel);
    });
  }
}

/* =========================================================
   Bootstrap
   ========================================================= */
document.addEventListener("DOMContentLoaded", () => {
  const controller = new ExcelImportPageController();
  controller.init().catch((err) => {
    console.error("[EIP] Failed to initialize Excel Import page", err);
  });
});
function getParentWindowValue(propName) {
        var currentWindow = window;

        try {
            while (currentWindow) {

                if (typeof currentWindow[propName] !== "undefined") {
                    return currentWindow[propName];
                }

                if (currentWindow === currentWindow.parent) {
                    break;
                }

                currentWindow = currentWindow.parent;
            }
        }
        catch (e) {
            console.warn("Unable to access parent window:", e);
        }

        return undefined;
    }
</script>









</body></html>
');
>>

<<
INSERT INTO sect4 (sect4id, htmlsectionsid, sect4row, filename, filetype, css_js_src) VALUES(7640990000002, 7640990000000, 1, 'Data_Ingestor', 'Css', '/* =========================================================
   Excel → T-Struct Import — Custom Page Styles
   Follows the same visual conventions as other Axpert custom
   pages (brsv2.html): plain panels, hairline borders, a single
   primary accent color, no heavy shadows/gradients.
   ========================================================= */

:root {
  --eip-color-bg: #f5f6f8;
  --eip-color-panel: #ffffff;
  --eip-color-border: #e0e3e8;
  --eip-color-border-strong: #c7cbd3;
  --eip-color-text: #1f2430;
  --eip-color-text-muted: #6b7280;
  --eip-color-primary: #2563eb;
  --eip-color-primary-hover: #1d4ed8;
  --eip-color-danger: #d64545;
  --eip-color-success: #1a8f5e;
  --eip-color-success-bg: #e8f7f0;
  --eip-color-danger-bg: #fdecec;
  --eip-radius: 6px;
  --eip-shadow-sm: 0 1px 2px rgba(16, 24, 40, 0.06);
  --eip-font: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
}

* { box-sizing: border-box; }

html, body {
  height: 100%;
}

body {
  margin: 0;
  font-family: var(--eip-font);
  background: var(--eip-color-bg);
  color: var(--eip-color-text);
  font-size: 14px;
  line-height: 1.45;
  overflow: hidden; /* no outer page scroll — the grid area scrolls internally instead */
}

.eip-app {
  max-width: 960px;
  margin: 0 auto;
  padding: 24px 20px 60px;
}

.eip-page-head h1 {
  font-size: 20px;
  font-weight: 600;
  margin: 0 0 4px;
}

.eip-page-head .eip-subtitle {
  color: var(--eip-color-text-muted);
  font-size: 13px;
  margin: 0 0 20px;
}

/* ---------- Panels ---------- */
.eip-panel {
  background: var(--eip-color-panel);
  border: 1px solid var(--eip-color-border);
  border-radius: var(--eip-radius);
  box-shadow: var(--eip-shadow-sm);
  margin-bottom: 16px;
}

.eip-panel-body {
  padding: 20px;
}

.eip-panel-title {
  font-size: 13px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  color: var(--eip-color-text-muted);
  margin: 0 0 16px;
}

/* ---------- Form fields ---------- */
.eip-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-bottom: 16px;
}

.eip-field:last-child { margin-bottom: 0; }

.eip-field label {
  font-size: 12.5px;
  font-weight: 600;
  color: var(--eip-color-text);
}

.eip-field .eip-hint {
  font-size: 12px;
  color: var(--eip-color-text-muted);
  margin-top: -2px;
}

.eip-select,
.eip-file-input-visible {
  appearance: none;
  border: 1px solid var(--eip-color-border-strong);
  border-radius: var(--eip-radius);
  padding: 8px 32px 8px 10px;
  font-size: 13.5px;
  font-family: inherit;
  color: var(--eip-color-text);
  background-color: #fff;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 24 24'' fill=''none'' stroke=''%236b7280'' stroke-width=''2''><path d=''M6 9l6 6 6-6''/></svg>");
  background-repeat: no-repeat;
  background-position: right 8px center;
  background-size: 16px;
  width: 100%;
  max-width: 420px;
  cursor: pointer;
}

.eip-select:disabled {
  background-color: #f2f3f5;
  color: var(--eip-color-text-muted);
  cursor: not-allowed;
}

.eip-select:focus-visible,
.eip-btn:focus-visible,
.eip-file-btn:focus-visible,
.eip-multiselect-option:focus-visible {
  outline: 2px solid var(--eip-color-primary);
  outline-offset: 2px;
}

/* ---------- File upload ---------- */
.eip-file-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.eip-file-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  border: 1px solid var(--eip-color-border-strong);
  background: #fff;
  border-radius: var(--eip-radius);
  padding: 8px 14px;
  font-size: 13.5px;
  font-weight: 500;
  cursor: pointer;
}

.eip-file-btn:hover { background: #f7f8fa; }

.eip-file-name {
  font-size: 13px;
  color: var(--eip-color-text-muted);
}

.eip-file-name.eip-has-file {
  color: var(--eip-color-text);
  font-weight: 500;
}

.eip-hidden { display: none !important; }

/* ---------- Multi-select field mapper ---------- */
.eip-multiselect {
  border: 1px solid var(--eip-color-border-strong);
  border-radius: var(--eip-radius);
  max-height: 220px;
  overflow-y: auto;
  background: #fff;
}

.eip-multiselect-option {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 10px;
  border-bottom: 1px solid var(--eip-color-border);
  cursor: pointer;
  font-size: 13.5px;
}

.eip-multiselect-option:last-child { border-bottom: none; }

.eip-multiselect-option:hover { background: #f7f8fa; }

.eip-multiselect-option input[type="checkbox"] {
  margin: 0;
}

.eip-multiselect-order-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 20px;
  height: 20px;
  border-radius: 999px;
  background: var(--eip-color-primary);
  color: #fff;
  font-size: 11px;
  font-weight: 700;
  padding: 0 5px;
}

.eip-multiselect-caption { flex: 1; }

.eip-multiselect-meta {
  font-size: 11px;
  color: var(--eip-color-text-muted);
}

/* ---------- Checkbox row ---------- */
.eip-checkbox-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.eip-checkbox-row input[type="checkbox"] {
  width: 16px;
  height: 16px;
  margin: 0;
}

.eip-checkbox-row label {
  font-size: 13.5px;
  font-weight: 500;
  cursor: pointer;
}

/* ---------- Buttons ---------- */
.eip-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  border: 1px solid var(--eip-color-border-strong);
  background: #fff;
  color: var(--eip-color-text);
  border-radius: var(--eip-radius);
  padding: 9px 18px;
  font-size: 13.5px;
  font-weight: 600;
  cursor: pointer;
}

.eip-btn:hover { background: #f7f8fa; }

.eip-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.eip-btn-primary {
  background: var(--eip-color-primary);
  border-color: var(--eip-color-primary);
  color: #fff;
}

.eip-btn-primary:hover:not(:disabled) { background: var(--eip-color-primary-hover); }

.eip-btn-danger {
  background: #fff;
  border-color: var(--eip-color-danger);
  color: var(--eip-color-danger);
}

.eip-btn-danger:hover:not(:disabled) { background: var(--eip-color-danger-bg); }

.eip-btn-row {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}

/* ---------- Status / log panel ---------- */
.eip-status-panel { display: none; }
.eip-status-panel.eip-visible { display: block; }

.eip-progress-bar-track {
  height: 8px;
  border-radius: 999px;
  background: #eceff2;
  overflow: hidden;
  margin-bottom: 10px;
}

.eip-progress-bar-fill {
  height: 100%;
  background: var(--eip-color-primary);
  width: 0%;
  transition: width 0.2s ease;
}

.eip-progress-label {
  font-size: 12.5px;
  color: var(--eip-color-text-muted);
  margin-bottom: 4px;
}

.eip-progress-elapsed {
  font-size: 12px;
  color: var(--eip-color-text-muted);
  font-weight: 600;
  margin-bottom: 12px;
}

.eip-progress-elapsed:empty { display: none; }

.eip-log-list {
  max-height: 240px;
  overflow-y: auto;
  border: 1px solid var(--eip-color-border);
  border-radius: var(--eip-radius);
  font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
  font-size: 12px;
}

.eip-log-entry {
  padding: 6px 10px;
  border-bottom: 1px solid var(--eip-color-border);
  white-space: pre-wrap;
  word-break: break-word;
}

.eip-log-entry:last-child { border-bottom: none; }

.eip-log-entry.eip-log-success { color: var(--eip-color-success); }
.eip-log-entry.eip-log-error { color: var(--eip-color-danger); background: var(--eip-color-danger-bg); }
.eip-log-entry.eip-log-info { color: var(--eip-color-text-muted); }

/* ---------- Toast ---------- */
.eip-toast {
  position: fixed;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%) translateY(10px);
  background: #1f2430;
  color: #fff;
  padding: 10px 18px;
  border-radius: var(--eip-radius);
  font-size: 13px;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.2s ease, transform 0.2s ease;
  z-index: 1000;
  max-width: 480px;
  text-align: center;
}

.eip-toast.eip-visible {
  opacity: 1;
  transform: translateX(-50%) translateY(0);
  pointer-events: auto;
}

.eip-toast.eip-toast-error { background: var(--eip-color-danger); }
.eip-toast.eip-toast-success { background: var(--eip-color-success); }

/* ---------- Misc ---------- */
.eip-empty-note {
  font-size: 12.5px;
  color: var(--eip-color-text-muted);
  padding: 10px;
}

/* =========================================================
   Version 2 additions — top bar, grid table, status icons,
   validation popup, job selector, bottom toolbar.
   ========================================================= */

.eip-app-v2 {
  max-width: 100%;
  height: 100%;
  padding: 6px 12px 8px; /* trimmed from 10px/14px — every bit of chrome height
                             reclaimed here goes straight to the grid, since it''s
                             the only flex child that stretches (flex:1 1 auto) */
  display: flex;
  flex-direction: column;
  min-height: 0;
}

.eip-app-v2 > * {
  flex-shrink: 0; /* header, topbar, toolbar keep their natural height */
  min-width: 0; /* same fix as .eip-grid-wrapper — prevents ANY direct child (topbar, tab
                   controls row, etc.) from blowing out the page width if its own content
                   ever gets wide (e.g. many DC names, a long file name) */
}

/* ---------- Top bar (single line of controls) ---------- */
.eip-topbar {
  display: flex;
  align-items: center;
  gap: 22px;
  flex-wrap: wrap;
  background: var(--eip-color-panel);
  border: 1px solid var(--eip-color-border);
  border-radius: 8px;
  box-shadow: var(--eip-shadow-sm);
  padding: 10px 20px;
  margin-bottom: 6px;
}

.eip-topbar-item {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.eip-topbar-item label {
  font-size: 10.5px;
  font-weight: 700;
  color: var(--eip-color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.06em;
}

/* Uniform control height across the whole bar (buttons, selects, file row) */
.eip-topbar .eip-file-btn,
.eip-topbar .eip-select,
.eip-topbar .eip-btn {
  height: 34px;
  box-sizing: border-box;
}

.eip-select-sm {
  width: 190px;
  max-width: 190px;
  padding: 0 30px 0 10px;
  font-size: 13px;
}

.eip-topbar-item.eip-checkbox-row {
  flex-direction: row;
  align-items: center;
  gap: 8px;
  height: 34px;
  padding-top: 15px;
}

.eip-topbar-item.eip-checkbox-row label {
  text-transform: none;
  font-size: 13px;
  font-weight: 500;
  color: var(--eip-color-text);
  letter-spacing: 0;
}

.eip-topbar-jobs {
  display: flex;
  flex-direction: row;
  align-items: flex-end;
  gap: 8px;
  margin-left: auto;
}

.eip-topbar-jobs .eip-select-sm { width: 240px; max-width: 240px; }

/* ---------- Grid area ---------- */
.eip-grid-wrapper {
  background: var(--eip-color-panel);
  border: 1px solid var(--eip-color-border);
  border-radius: 8px;
  box-shadow: var(--eip-shadow-sm);
  overflow: auto;
  flex: 1 1 auto; /* always stretch to fill available width/height, regardless of column count */
  min-height: 0;
  min-width: 0; /* CRITICAL: flex items default to min-width:auto, which refuses to shrink below
                   the table''s full un-scrolled content width (white-space:nowrap cells) — that
                   was blowing out this box (and everything above it, up to the page root) wider
                   on tabs with more columns, instead of letting overflow:auto scroll internally.
                   This is what caused the whole page to visibly grow/shrink between tabs. */
  max-height: 100%;
  width: 100%;
  margin-bottom: 6px; /* trimmed from 10px to give the grid more height */
}

.eip-grid-table {
  border-collapse: separate;
  border-spacing: 0;
  width: 100%; /* claim full width when few columns — the trailing .eip-grid-filler-col
                  column (not the real data columns) is what actually absorbs the extra
                  space, so real columns keep their natural content width either way.
                  With many columns, the real columns'' own nowrap content width still
                  wins over this 100% floor, so the table grows past the wrapper and
                  the wrapper''s own overflow:auto kicks in exactly as before. */
  min-width: 100%;
  font-size: 12.5px;
}

.eip-grid-table th,
.eip-grid-table td {
  border-bottom: 1px solid var(--eip-color-border);
  border-right: 1px solid var(--eip-color-border);
  padding: 6px 12px;
  text-align: left;
  white-space: nowrap;
}

/* Fixed row height for virtualized data rows — must match
   ExcelImportPageController.ROW_HEIGHT (28) in the JS exactly, since
   the scroll-position math depends on every row being this height. */
.eip-grid-table tbody tr.eip-grid-row td {
  height: 28px;
  box-sizing: border-box;
  padding-top: 0;
  padding-bottom: 0;
  vertical-align: middle;
  background: #ffffff; /* opaque — prevents the wrapper''s continuation-stripe background from showing through behind real rows */
}

.eip-grid-table th:last-child,
.eip-grid-table td:last-child {
  border-right: none;
}

.eip-grid-table thead tr:first-child th {
  background: #f7f8fa;
  position: sticky;
  top: 0;
  z-index: 2;
  vertical-align: top;
  padding-top: 10px;
  padding-bottom: 8px;
  border-bottom: 1px solid var(--eip-color-border-strong);
}

.eip-grid-table thead tr:last-child th {
  background: #fbfbfc;
  position: sticky;
  top: 65px; /* sits directly under the mapping row when scrolling */
  z-index: 2;
  padding-top: 6px;
  padding-bottom: 8px;
}

.eip-grid-table tbody tr:nth-child(even) td {
  background: #fafbfd;
}

.eip-grid-table tbody tr:hover td {
  background: #eef4ff;
}

.eip-grid-status-col {
  width: 36px;
  min-width: 36px;
  max-width: 36px;
  text-align: center !important;
  position: sticky;
  left: 0;
  z-index: 3;
  background: #f7f8fa;
  box-shadow: 1px 0 0 var(--eip-color-border-strong);
}

/* Trailing filler column — a blank <th>/<td> appended after the real
   last data column (see _renderGridHeader / _renderVisibleRows). Giving
   JUST this one column width:100% is what makes the table fill the full
   grid width when there are few columns, since auto table layout treats
   it as "take whatever space the real columns don''t need" — the real
   columns themselves stay at their natural content width, so they never
   get stretched into the "huge empty column" look. With enough columns
   to already exceed the available width, this column simply has nothing
   left to claim and collapses to 0 width, same as if it weren''t there. */
.eip-grid-filler-col {
  width: 100%;
  padding: 0 !important;
  border-right: none !important;
}

.eip-grid-table tbody td.eip-grid-status-col {
  background: #fff;
  position: sticky;
  left: 0;
  z-index: 1;
}

.eip-grid-table tbody tr:nth-child(even) td.eip-grid-status-col { background: #fafbfd; }
.eip-grid-table tbody tr:hover td.eip-grid-status-col { background: #eef4ff; }

.eip-col-mapping-cell {
  width: 168px;
  min-width: 168px;
  max-width: 168px;
  white-space: normal;
}

.eip-col-mapping-cell .eip-select {
  width: 100%;
  max-width: none;
  padding: 5px 24px 5px 6px;
  font-size: 12px;
  margin-bottom: 4px;
}

.eip-col-mapping-controls {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
}

.eip-col-mapping-controls label {
  display: flex;
  align-items: center;
  gap: 3px;
  cursor: pointer;
  font-weight: 500;
  color: var(--eip-color-text-muted);
}

.eip-col-mapping-controls input[type="checkbox"] {
  margin: 0;
  width: 13px;
  height: 13px;
}

.eip-col-gear-btn {
  border: 1px solid var(--eip-color-border-strong);
  background: #fff;
  border-radius: 4px;
  width: 22px;
  height: 22px;
  line-height: 1;
  cursor: pointer;
  font-size: 12px;
  padding: 0;
}

.eip-col-gear-btn:hover { background: #f0f1f3; }
.eip-col-gear-btn.eip-has-rules { border-color: var(--eip-color-primary); color: var(--eip-color-primary); }

.eip-col-header-text {
  font-weight: 600;
  color: var(--eip-color-text-muted);
  font-size: 11.5px;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.eip-grid-table tbody td:not(.eip-grid-status-col) {
  max-width: 240px;
  overflow: hidden;
  text-overflow: ellipsis;
}

.eip-col-ax-mode-label {
  font-style: italic;
  color: var(--eip-color-text);
  font-size: 12px;
  font-weight: 600;
  line-height: 1.5;
}

.eip-col-ax-mode-sublabel {
  font-style: normal;
  font-weight: 500;
  font-size: 10.5px;
  color: var(--eip-color-text-muted);
}

.eip-ax-mode-badge {
  display: inline-block;
  font-size: 11px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 999px;
}

.eip-ax-mode-create { background: var(--eip-color-success-bg); color: var(--eip-color-success); }
.eip-ax-mode-edit { background: #e6edfd; color: var(--eip-color-primary); }
.eip-ax-mode-delete { background: var(--eip-color-danger-bg); color: var(--eip-color-danger); }

.eip-ax-mode-badge.eip-ax-mode-ignored {
  opacity: 0.45;
  filter: grayscale(1);
}

/* ---------- Status icons ---------- */
.eip-status-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  font-size: 11px;
  font-weight: 700;
  cursor: default;
}

.eip-status-pending { background: #eceff2; color: var(--eip-color-text-muted); }
.eip-status-uploaded { background: var(--eip-color-success-bg); color: var(--eip-color-success); }
.eip-status-error { background: var(--eip-color-danger-bg); color: var(--eip-color-danger); }
.eip-status-submitted { background: #e6edfd; color: var(--eip-color-primary); }
.eip-status-failed { background: #fff2e0; color: #b45f06; }

/* ---------- Bottom toolbar ---------- */
.eip-bottom-toolbar {
  position: sticky;
  bottom: 0;
  background: var(--eip-color-panel);
  border: 1px solid var(--eip-color-border);
  border-radius: var(--eip-radius);
  box-shadow: var(--eip-shadow-sm);
  padding: 8px 18px; /* trimmed from 12px to give the grid more height */
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 14px;
}

.eip-summary-group {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 4px 12px;
  min-width: 0;
}

.eip-summary-label {
  font-size: 13px;
  color: var(--eip-color-text-muted);
}

.eip-timing-label {
  font-size: 12.5px;
  color: var(--eip-color-primary);
  font-weight: 600;
  white-space: nowrap;
}

.eip-timing-label:empty { display: none; }

.eip-bottom-toolbar-actions {
  display: flex;
  gap: 10px;
}

/* ---------- Validation popup modal ---------- */
.eip-modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 18, 26, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
}

.eip-modal {
  background: #fff;
  border-radius: var(--eip-radius);
  padding: 22px;
  width: 340px;
  max-width: calc(100vw - 40px);
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.25);
}

.eip-modal-title {
  font-size: 15px;
  font-weight: 700;
  margin-bottom: 16px;
}

.eip-range-row {
  display: flex;
  gap: 8px;
}

.eip-range-row .eip-select { max-width: none; }

.eip-textarea {
  resize: vertical;
  font-family: inherit;
}

.eip-modal .eip-btn-row {
  justify-content: space-between;
  margin-top: 18px;
}
/* =========================================================
   UI Polish Overrides (Append to import.css)
   ========================================================= */

/* 1. Fix the top bar alignment so all inputs sit on the same baseline */
.eip-topbar {
  align-items: flex-end; /* Aligns the bottom of the inputs */
  padding: 10px 20px; /* trimmed from 16px to give the grid more height */
  background: #ffffff;
}

/* Add a subtle separation for the Job section if it wraps */
.eip-topbar-jobs {
  margin-left: auto;
  align-items: flex-end;
}

/* Fix the floating checkbox alignment */
.eip-topbar-item.eip-checkbox-row {
  padding-top: 0; 
  height: 34px;
  margin-bottom: 2px; /* Slight nudge to align with the text inputs */
}

/* 2. Fill the full grid width even with few columns, WITHOUT stretching
      the real data columns themselves — a trailing .eip-grid-filler-col
      (see base rules above) absorbs the extra space instead, so this no
      longer reintroduces the old "huge empty stretched columns" look.
      table-layout:auto (not fixed) is still required so real columns
      keep sizing to content, and so horizontal scroll still kicks in
      normally once real columns alone exceed the available width. */
.eip-grid-table {
  width: 100%;
  table-layout: auto;
}

/* 3. Give the mapping controls room to breathe — fixed width so columns
      stay consistent and the grid wrapper''s horizontal scrollbar kicks
      in predictably once total column width exceeds the viewport. */
.eip-col-mapping-cell {
  width: 200px;
  min-width: 200px;
  max-width: 200px;
  padding: 12px 16px !important;
}

.eip-col-mapping-controls {
  margin-top: 8px; /* Push controls down slightly from the select box */
  gap: 12px; /* More space between the checkbox and gear icon */
}

/* 4. Soften the overall container presentation */
.eip-grid-wrapper {
  border: 1px solid var(--eip-color-border);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03); /* Softer, more modern shadow */
}

/* 5. Polish the Bottom Toolbar */
.eip-bottom-toolbar {
  padding: 8px 20px;
  background: #ffffff;
}

/* 6. Clean up the header text row to match the new spacing */
.eip-grid-table thead tr:last-child th {
  padding: 10px 16px;
  background: #f1f3f5; /* Slightly darker gray to separate headers from mapping */
  border-bottom: 2px solid var(--eip-color-border-strong);
}

/* =========================================================
   Data Injestor — UI Polish & Alignment Fixes
   ========================================================= */

/* --- Header Styling --- */
.eip-page-head {
  margin-bottom: 4px; /* trimmed from 10px to give the grid more height */
  padding: 0 4px;
}

.eip-page-head h1 {
  font-size: 22px;
  font-weight: 700;
  color: var(--eip-color-text);
  margin: 0 0 4px 0;
  letter-spacing: -0.02em;
}

.eip-page-head .eip-subtitle {
  color: var(--eip-color-text-muted);
  font-size: 13.5px;
  margin: 0;
}

/* --- Top Bar Alignment --- */
.eip-topbar {
  display: flex;
  align-items: flex-end; /* Forces all inputs to sit on the same bottom baseline */
  gap: 20px;
  padding: 10px 20px; /* trimmed from 16px to give the grid more height */
  background: var(--eip-color-panel);
  border: 1px solid var(--eip-color-border);
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(16, 24, 40, 0.04); /* Softer shadow */
}

/* Ensure the checkbox aligns perfectly with the text inputs */
.eip-topbar-item.eip-checkbox-row {
  height: 34px;
  padding-top: 0;
  margin-bottom: 2px; 
}

/* Push the job selector to the right */
.eip-topbar-jobs {
  margin-left: auto;
  align-items: flex-end;
}

/* --- Mapping Grid Refinements --- */
/* Give the mapping cells more breathing room */
.eip-col-mapping-cell {
  width: auto;
  min-width: 210px; /* Prevents the dropdowns from getting squished */
  padding: 12px 16px !important;
  background: #fbfbfc; /* Slight contrast from the main grid */
}

/* Align the checkbox and gear icon nicely under the select box */
.eip-col-mapping-controls {
  margin-top: 10px;
  gap: 14px;
}

/* Modernize the grid borders */
.eip-grid-wrapper {
  border: 1px solid var(--eip-color-border);
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(16, 24, 40, 0.04);
}

.eip-grid-table thead tr:last-child th {
  background: #f4f5f7; /* Distinct header color for the actual data columns */
  border-bottom: 2px solid var(--eip-color-border-strong);
  padding: 10px 16px;
  font-size: 12px;
}

.eip-grid-table td {
  padding: 10px 16px;
}

/* --- Input & Button Polish --- */
/* Softer borders for a cleaner look */
.eip-select,
.eip-file-btn,
.eip-btn {
  border: 1px solid #d1d5db;
  transition: all 0.2s ease;
}

.eip-select:hover,
.eip-file-btn:hover {
  border-color: #9ca3af;
}

.eip-select:focus-visible,
.eip-btn:focus-visible {
  border-color: var(--eip-color-primary);
  outline: 3px solid rgba(37, 99, 235, 0.15); /* Modern, soft focus ring */
  outline-offset: 0;
}
/* =========================================================
   Visually-disabled (but still interactive so a blocking
   toast can fire) controls
   ========================================================= */
.eip-disabled-visual {
  opacity: 0.45;
  cursor: not-allowed;
}

.eip-disabled-visual select,
select.eip-disabled-visual {
  cursor: not-allowed;
  background-color: #f2f3f5;
}

.eip-disabled-visual input[type="checkbox"] {
  cursor: not-allowed;
}

/* =========================================================
   SearchableDropdown widget (replaces native <select>)
   ========================================================= */
.eip-sd-wrap {
  position: relative;
  width: 100%;
}

.eip-sd-trigger {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 6px;
  background: #fff;
  border: none;
  padding: 8px 10px;
  font: inherit;
  font-size: inherit;
  color: var(--eip-color-text);
  cursor: pointer;
  text-align: left;
}

/* The host (.eip-select) still carries the plain-<select> look (border,
   padding, a background-image chevron) for the native <select> elements
   it''s also used for elsewhere. For a SearchableDropdown, though, that
   padding and chevron sit OUTSIDE the <button> above (which is sized to
   fill the host, inset by that same padding) — so the visible arrow was
   actually dead space, not part of the clickable button, which is why
   clicking exactly on it did nothing while clicking the label text (over
   the button) worked. Strip both here so the button covers the host
   edge-to-edge and owns 100% of the clickable surface, and give the
   button its own matching padding (above) so the look doesn''t change. */
.eip-select.eip-sd-wrap,
.eip-select-sm.eip-sd-wrap {
  padding: 0;
  background-image: none;
}

.eip-col-mapping-cell .eip-sd-wrap.eip-select .eip-sd-trigger {
  padding: 5px 8px;
}

.eip-sd-trigger-label {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.eip-sd-trigger-label.eip-sd-placeholder {
  color: var(--eip-color-text-muted);
}

.eip-sd-trigger-arrow {
  flex-shrink: 0;
  font-size: 10px;
  color: var(--eip-color-text-muted);
}

/* Host element (.eip-select) supplies the visible border/box; the
   trigger button itself is borderless and fills it. */
.eip-select.eip-sd-wrap {
  display: flex;
  align-items: center;
  cursor: pointer;
}


.eip-sd-panel {
  position: fixed;
  z-index: 4000;
  background: #fff;
  border: 1px solid var(--eip-color-border-strong);
  border-radius: var(--eip-radius);
  box-shadow: 0 8px 24px rgba(16, 24, 40, 0.18);
  max-height: 300px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.eip-sd-panel.eip-hidden { display: none; }

.eip-sd-search-wrap {
  padding: 8px;
  border-bottom: 1px solid var(--eip-color-border);
  flex-shrink: 0;
}

.eip-sd-search {
  width: 100%;
  border: 1px solid var(--eip-color-border-strong);
  border-radius: 4px;
  padding: 6px 8px;
  font-size: 13px;
  box-sizing: border-box;
}

.eip-sd-search:focus-visible {
  outline: 2px solid var(--eip-color-primary);
  outline-offset: -1px;
}

.eip-sd-list {
  overflow-y: auto;
  padding: 4px 0;
}

.eip-sd-group-heading {
  padding: 6px 12px 4px;
  font-size: 10.5px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--eip-color-text-muted);
}

.eip-sd-option,
.eip-sd-none-opt {
  padding: 7px 12px;
  font-size: 13px;
  cursor: pointer;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.eip-sd-none-opt {
  color: var(--eip-color-text-muted);
  font-style: italic;
  border-bottom: 1px solid var(--eip-color-border);
}

.eip-sd-option:hover,
.eip-sd-none-opt:hover,
.eip-sd-option:focus,
.eip-sd-none-opt:focus {
  background: #eef4ff;
  outline: none;
}

.eip-sd-option.eip-sd-selected {
  background: var(--eip-color-primary);
  color: #fff;
}

.eip-sd-option.eip-sd-selected:hover { background: var(--eip-color-primary-hover); }

.eip-sd-empty {
  padding: 12px;
  font-size: 12.5px;
  color: var(--eip-color-text-muted);
  text-align: center;
}

.eip-sd-hl {
  background: #fff2a8;
  color: inherit;
  border-radius: 2px;
}

/* =========================================================
   Progress popup (was an inline panel — now a modal, matching
   the validation popup''s overlay pattern)
   ========================================================= */
.eip-progress-modal {
  width: 480px;
}

.eip-modal-title-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.eip-modal-title-row .eip-modal-title {
  margin-bottom: 0;
}

.eip-modal-close-btn {
  border: none;
  background: none;
  font-size: 22px;
  line-height: 1;
  color: var(--eip-color-text-muted);
  cursor: pointer;
  padding: 0 4px;
}

.eip-modal-close-btn:hover {
  color: var(--eip-color-text);
}

/* =========================================================
   Sheet tabs (shown for multi-sheet uploads)
   ========================================================= */
.eip-sheet-tabs {
  display: flex;
  align-items: flex-end;
  gap: 2px;
  padding: 0 4px;
  margin-bottom: -1px; /* let the active tab visually merge into the grid''s top border */
  overflow-x: auto;
  flex-shrink: 0;
}

.eip-sheet-tab {
  border: 1px solid var(--eip-color-border);
  border-bottom: none;
  background: #eceff2;
  color: var(--eip-color-text-muted);
  padding: 7px 16px;
  font-size: 12.5px;
  font-weight: 600;
  border-radius: 6px 6px 0 0;
  cursor: pointer;
  white-space: nowrap;
}

.eip-sheet-tab:hover {
  background: #e2e6eb;
  color: var(--eip-color-text);
}

.eip-sheet-tab-active {
  background: var(--eip-color-panel);
  color: var(--eip-color-primary);
  border-bottom: 1px solid var(--eip-color-panel);
  position: relative;
  z-index: 1;
}

.eip-key-field-badge {
  display: inline-flex;
  align-items: center;
  font-size: 10.5px;
  font-weight: 700;
  color: var(--eip-color-primary);
  background: #e6edfd;
  padding: 2px 8px;
  border-radius: 999px;
}

/* =========================================================
   T-Struct + DC control group (relocates below sheet tabs
   when multiple sheets are present)
   ========================================================= */
.eip-tstruct-dc-group {
  display: flex;
  gap: 20px;
}

.eip-tab-controls-row {
  display: flex;
  gap: 20px;
  align-items: flex-end;
  background: var(--eip-color-panel);
  border: 1px solid var(--eip-color-border);
  border-radius: 8px;
  box-shadow: var(--eip-shadow-sm);
  padding: 10px 20px;
  margin-bottom: 10px;
  width: fit-content;
  max-width: 100%;
}

.eip-sd-checkbox {
  display: inline-block;
  width: 16px;
  margin-right: 4px;
}

.eip-sd-badge {
  float: right;
  font-size: 10px;
  color: var(--eip-color-text-muted);
  background: #eceff2;
  padding: 1px 6px;
  border-radius: 999px;
}

/* ---------- Confirm modal (replaces window.confirm) ---------- */
.eip-confirm-modal {
  width: 420px;
}

.eip-confirm-message {
  font-size: 13.5px;
  color: var(--eip-color-text);
  line-height: 1.5;
  margin-bottom: 4px;
  white-space: pre-line;
}


/* Keep the entire page at a consistent width */
html,
body {
    width: 100%;
    height: 100%;
    min-width: 0;
}

.eip-app-v2 {
    width: 100%;
    max-width: none;
    min-width: 0;
    height: 100%;
    box-sizing: border-box;
    margin: 0;
    overflow: hidden;
}

/* Keep the grid within the available page width */
.eip-grid-wrapper {
    width: 100%;
    max-width: 100%;
    min-width: 0;
    flex: 1 1 0;
    overflow: auto;
    box-sizing: border-box;
}

/* Allow the table to grow internally, not the page */
.eip-grid-table {
    width: 100%;
    min-width: 100%;
    table-layout: auto;
}


/* Subtle background for unused grid space */
.eip-grid-table .eip-grid-filler-col {
    background: #f4f5f7 !important;
    border-right: none !important;
    border-bottom: none !important;
    padding: 0 !important;
}

/* Keep the filler visually consistent on all rows */
.eip-grid-table tbody tr:nth-child(even)
.eip-grid-filler-col,
.eip-grid-table tbody tr:hover
.eip-grid-filler-col {
    background: #f4f5f7 !important;
}

/* Match the header background */
.eip-grid-table thead .eip-grid-filler-col {
    background: #f4f5f7 !important;
    border-bottom: none !important;
}







');
>>

<<
INSERT INTO axpages ("name", caption, props, blobno, img, visible, "type", parent, ordno, levelno, updatedon, createdon, importedon, createdby, updatedby, importedby, readonly, updusername, category, pagetype, intview, webenable, shortcut, icon, websubtype, workflow, oldappurl) VALUES('HP1794547992681', 'Data Ingestor', 'htmlPages.aspx?load=1794547992681', 1, NULL, 'F', 'p', NULL, 287, 0, '13/11/2026 11:19:00 AM', '13/11/2026 10:55:53 AM', NULL, 'admin', 'admin', NULL, NULL, NULL, NULL, 'web', NULL, NULL, NULL, NULL, 'htmlpage', NULL, NULL);
>>