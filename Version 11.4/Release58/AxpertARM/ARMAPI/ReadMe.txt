# Release Notes

**Date:** 09/09/2026

This patch includes fixes and enhancements for the following issues:

### 1. TSK-0668 – Additional Details to be Returned by AxGet API

The **AxGet API** now returns the following additional nodes:

* `createdon`
* `createdby`
* `modifiedon`
* `modifiedby`

### 2. TKT-1066 – GetDataFromAxList Function Not Working as Expected

**Customer:** GI Staffing Services Private Limited

* Fixed the issue with the `GetDataFromAxList` function.

### 3. TSK-0688 – Provision to Update an Existing Record Without Using Record ID in AXPUT = true API

The **AXPUT API** has been enhanced to support updating existing records without requiring `axp_recid`.

* `keyfield`, `keyvalue`, and `axrow_action` are mandatory for each row.
* `axp_recid` is now optional.
* If `axp_recid` is provided, it must be valid; otherwise, it should be excluded.
* When `axp_recid` is not provided, `keyfield` and `keyvalue` are used to identify the existing record.
* The same `axp_recid` approach must be followed consistently across all DCSs and rows.

### 4. TSK-0698 – Data Not Saving with AXPUT = true Due to Validation Errors

The issue was reported when using the **CachedSave Consumer Worker Service**, where `AXPUT = true` invokes the ARM AxPut API.

The following issues have been fixed:

* **Date Validation:** Handled date validation using `ClientDateFormat` when fetching date values.
* **Numeric / ID Fields:** Handled Numeric and ID fields properly during MDMap execution for SQL-related operations.
* **Duplicate Check:** Fixed the Duplicate Check issue by handling the conditions properly.
* **Picklist Validation:** Fixed Picklist execution where valid data was incorrectly reported as an invalid selection.
* **Normalized Fields:** Reset `IDValue` properly during normalized field processing.
* **Multiple Picklist Fields:** Fixed the **"A command is already in progress"** error when multiple Picklist fields are processed sequentially by properly handling asynchronous execution using `await`.
