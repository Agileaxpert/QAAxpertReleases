<<
alter table axpstructconfig add purpose varchar(1000)
>>
<<
ALTER TABLE AXUSERS ADD axusersid numeric(15)
>>
<<
ALTER TABLE AXUSERS ADD cancelremarks  VARCHAR(300) 
>>
<<
alter table ax_widget add is_public varchar(1) DEFAULT 'N'
>>
<<
ALTER TABLE AXUSERS ADD cancel  VARCHAR(10)
>>
<<
ALTER TABLE AXUSERS ADD sourceid numeric(15)
>>
<<
alter table axusers ALTER COLUMN pwd varchar(20)
>>
<<
DECLARE @SQL VARCHAR(4000)
SET @SQL = 'ALTER TABLE axusers DROP CONSTRAINT |ConstraintName| '
SET @SQL = REPLACE(@SQL, '|ConstraintName|', ( SELECT name FROM sysobjects WHERE xtype = 'PK' AND 
parent_obj = OBJECT_ID('axusers')))
EXEC (@SQL)
>>
<<
ALTER TABLE axusers ADD constraint u1_axusers UNIQUE (pusername)
>>
<<
ALTER TABLE axusergroups ADD axusergroupsid NUMERIC(15)
>>
<<
ALTER TABLE AXUSERGROUPS ADD cancel  VARCHAR(10)
>>
<<
ALTER TABLE AXUSERGROUPS ADD sourceid  numeric(15)
>>
<<
ALTER TABLE AXUSERGROUPS ADD cancelremarks  VARCHAR(300)
>>
<<
ALTER TABLE AXUSERLEVELGROUPS ADD axusersid NUMERIC(15)
>>
<<
ALTER TABLE AXUSERLEVELGROUPS ADD axuserlevelgroupsid NUMERIC(15)
>>
<<
ALTER TABLE  AXDSIGNCONFIG add rolename varchar(60)
>>
<<
update  axuserlevelgroups set axusersid=1,AXUSERLEVELGROUPSID=12345555  where username='admin' 
>>
<<
update axusers set axusersid=1,pusername=username,ppassword=password where username='admin'
>>
<<
update  axuserlevelgroups set axusername='admin',axusergroup='default'  where AXUSERLEVELGROUPSID=12345555
>>
<<
CREATE TRIGGER t1_axusers
   ON  axusers
   AFTER INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
	declare @usr nvarchar(50), @pwd nvarchar(50)
	
	set @usr=(select pusername from inserted)
	set @pwd=(select ppassword from inserted)
	
	IF EXISTS(SELECT * FROM INSERTED)  AND NOT EXISTS(SELECT * FROM DELETED)
		update axusers set username=@usr, password=@pwd where pusername=@usr
	ELSE
		update axusers set username=@usr where pusername=@usr
    
END
>>
<<
CREATE TRIGGER t1_AXUSERLEVELGROUPS
   ON  axuserlevelgroups
   AFTER INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
	declare @usr nvarchar(50), @ugp nvarchar(50),@axid numeric(15)
	set @usr=(select axusername from inserted)
	set @ugp=(select axusergroup from inserted)
	set @axid=(select AXUSERLEVELGROUPSid from inserted)
update AXUSERLEVELGROUPS set username=@usr,usergroup = @ugp  where AXUSERLEVELGROUPSid = @axid
    
END
>>
<<
DROP TABLE [AXP_MAILJOBS]
>>
<<
CREATE TABLE [AXP_MAILJOBS](
	[MAILTO] [varchar](1000) NULL,
	[MAILCC] [varchar](1000) NULL,
	[SUBJECT] [varchar](1000) NULL,
	[BODY] [varchar](max) NULL,
	[RECIPIENTCATEGORY] [varchar](500) NULL,
	[ENQUIRYNO] [varchar](30) NULL,
	[ATTACHMENTS] [varchar](1000) NULL,
	[IVIEWNAME] [varchar](10) NULL,
	[IVIEWPARAMS] [varchar](500) NULL,
	[TRANSID] [varchar](10) NULL,
	[RECORDID] [numeric](16, 0) NULL,
	[STATUS] [numeric](2, 0) NULL,
	[ERRORMESSAGE] [varchar](500) NULL,
	[SENTON] [date] NULL,
	[JOBID] [smallint] IDENTITY(1,1) NOT NULL,
	[jobdate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[JOBID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
>>
<<
drop table axsms
>>
<<
CREATE TABLE [AXSMS](
	[RECORDID] [smallint] IDENTITY(1,1) NOT NULL,
	[MOBILENO] [varchar](10) NULL,
	[MSG] [varchar](250) NULL,
	[STATUS] [numeric](1, 0) NULL,
	[SENTON] [date] NULL,
	[REMARKS] [varchar](1000) NULL,
	[CREATEDON] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[RECORDID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
>>
<<
CREATE TABLE USAGEDTL
(
  EXECUTEDDATE  DATE,
  CODE           VARCHAR(20),
  TITLE          VARCHAR(50),
  CNT           NUMERIC(18)
)
>>
<<
CREATE TABLE AXPEXCEPTION
(
  EXP_DATE       DATE,
  STRUCTNAME      VARCHAR(16),
  SERVICENAME     VARCHAR(50),
  SERVICERESULT   VARCHAR(500),
  [COUNT]          NUMERIC
)
>>
<<
CREATE TABLE ut_timetaken
(
   executed_date   DATE,
   object_type      VARCHAR (10),
   service_name     VARCHAR (100),
   [object_name]      VARCHAR (100),
   tot_count       NUMERIC (10),
   count_8s        NUMERIC (10),
   count_30s       NUMERIC (10),
   count_90s       NUMERIC (10),
   min_time        NUMERIC (10, 2),
   max_time        NUMERIC (10, 2),
   avg_time        NUMERIC (10, 2)
)
>>
<<
CREATE VIEW AX_OUTBOUND_STATUS
(
   FILENAME,
   SENTON,
   OUTDATE,
   TRANSID,
   TSTRUCTNAME,
   OUTSTATUS
)
AS
SELECT a.recordid filename,
         convert (date,a.senton,101) senton,
   convert (date,a.senton,101) outdate,
          a.transid,
          b.caption tstructname,
          CASE WHEN senton IS NULL THEN 'Pending' ELSE 'Sent' END outstatus
     FROM outbound a, tstructs b
    WHERE a.transid = b.name
>>
<<
CREATE  VIEW AX_INBOUND_STATUS
(
   FILENAME,
   RECDON,
   INDATE,
   TRANSID,
   TSTRUCTNAME,
   INSTATUS
)
AS
   SELECT filename,
          convert (date,a.recdon,101) recdon,
          convert (date,recdon,101) indate,
          transid,
          caption tstructname,
          instatus
     FROM inbound a, tstructs b
    WHERE a.transid = b.name
>>
<<
CREATE PROCEDURE pro_axplogstatextract (@fdate DATE)
AS
BEGIN
   ------ usage details
   delete from usagedtl  where convert(date,executeddate)=@fdate;
   INSERT INTO usagedtl (executeddate,
                         code,
                         title,
                         cnt)
        SELECT convert(date,calledon) cdate,
               'NOT' CODE,
               'Total No. of Transactions' title,
               COUNT (*) cnt
          FROM axpertlog
         WHERE convert(date,calledon) = @fdate
      GROUP BY convert(date,calledon)
      UNION ALL
        SELECT convert(date,calledon) cdate,
               'NOL' CODE,
               'Total No. of Logins' title,
               COUNT (*) cnt
          FROM axpertlog
         WHERE convert(date,calledon) = @fdate AND servicename = 'Login'
      GROUP BY convert(date,calledon)
      UNION ALL
        SELECT convert(date,calledon) cdate,
               'NOU' CODE,
               'Total No. of Users' title,
               COUNT (DISTINCT username) cnt
          FROM axpertlog
         WHERE convert(date,calledon) = @fdate AND servicename = 'Login'
      GROUP BY convert(date,calledon)
      UNION ALL
        SELECT convert(date,calledon) cdate,
               'NOD' CODE,
               'Total No. of Deadlock Execptions' title,
               COUNT (*) cnt
          FROM axpertlog
         WHERE convert(date,calledon) = @fdate
               AND serviceresult LIKE 'trans%dead%'
      GROUP BY convert(date,calledon)
      UNION ALL
        SELECT convert(date,calledon) cdate,
               'MTJ' CODE,
               'More time taken Saves (> 8 Sec)' title,
               COUNT (*) cnt
          FROM axpertlog
         WHERE     convert(date,calledon) = @fdate
               AND servicename = 'saving data'
               AND serviceresult = 'success'
               AND recordid = 0
               AND (timetaken / 1000) > 8
      GROUP BY convert(date,calledon)
      UNION ALL
        SELECT convert(date,calledon) cdate,
               'MTL' CODE,
               'More time taken Loads (> 8 Sec)' title,
               COUNT (*) cnt
          FROM axpertlog
         WHERE     convert(date,calledon) = @fdate
               AND servicename = 'load data'
               AND serviceresult = 'success'
               AND (timetaken / 1000) > 8
      GROUP BY convert(date,calledon)
      UNION ALL
      SELECT convert(date,calledon) cdate,
             'MTL' CODE,
             'More time taken reports (> 8 Sec)' title,
             COUNT (*) cnt
        FROM axpertlog
       WHERE     convert(date,calledon) = @fdate
             AND servicename = 'Get IView'
             AND serviceresult = 'success'
             AND (timetaken / 1000) > 8
GROUP BY convert(date,calledon);

   ----- exceptions
    delete from axpexception   where convert(date,exp_date)=@fdate;
   INSERT INTO axpexception (EXP_DATE,
                             STRUCTNAME,
                             SERVICENAME,
                             SERVICERESULT,
                             COUNT)
        SELECT convert(date,calledon),
               structname,
               servicename,
               serviceresult,
               COUNT (*)
          FROM axpertlog
         WHERE SERVICERESULT <> 'success' AND convert(date,calledon) = @fdate
      GROUP BY convert(date,calledon),
               structname,
               servicename,
               serviceresult;

   ----- time taken
    delete from ut_timetaken  where convert(date,executed_date)=@fdate;
   INSERT INTO ut_timetaken (executed_date,
                             object_type,
                             service_name,
                             object_name,
                             tot_count,
                             count_8s,
                             count_30s,
                             count_90s,
                             min_time,
                             max_time,
                             avg_time)
        SELECT convert(date,getdate()) exec_date,
               'tstruct' obj_type,
               'Saving Data' service_name,
               b.caption,
               COUNT (*) cnt,
               SUM (CASE WHEN timetaken > 8000 THEN 1 ELSE 0 END) cnt8,
               SUM (CASE WHEN timetaken > 30000 THEN 1 ELSE 0 END) cnt30,
               SUM (CASE WHEN timetaken > 90000 THEN 1 ELSE 0 END) cnt90,
               MIN (timetaken) / 1000 mintime,
               MAX (timetaken) / 1000 maxtime,
               AVG (timetaken) / 1000 avgtime
          FROM    axpertlog a
               JOIN
                  (  SELECT name, caption
                       FROM tstructs
                   GROUP BY name, caption) b
               ON a.structname = b.name
         WHERE     LOWER (servicename) = 'saving data'
               AND serviceresult = 'success'
               AND a.recordid = 0
               AND convert(date,calledon) = @fdate
      GROUP BY b.caption;

   INSERT INTO ut_timetaken (executed_date,
                             object_type,
                             service_name,
                             object_name,
                             tot_count,
                             count_8s,
                             count_30s,
                             count_90s,
                             min_time,
                             max_time,
                             avg_time)
        SELECT convert(date,getdate()) exec_date,
               'tstruct' obj_type,
               'Load Data' service_name,
               b.caption,
               COUNT (*) cnt,
               SUM (CASE WHEN timetaken > 8000 THEN 1 ELSE 0 END) cnt8,
               SUM (CASE WHEN timetaken > 30000 THEN 1 ELSE 0 END) cnt30,
               SUM (CASE WHEN timetaken > 90000 THEN 1 ELSE 0 END) cnt90,
               MIN (timetaken) / 1000 mintime,
               MAX (timetaken) / 1000 maxtime,
               AVG (timetaken) / 1000 avgtime
          FROM    axpertlog a
               JOIN
                  (  SELECT name, caption
                       FROM tstructs
                   GROUP BY name, caption) b
               ON a.structname = b.name
         WHERE     LOWER (servicename) = 'load data'
               AND serviceresult = 'success'
               AND convert(date,calledon) = @fdate
      GROUP BY b.caption;

   INSERT INTO ut_timetaken (executed_date,
                             object_type,
                             service_name,
                             object_name,
                             tot_count,
                             count_8s,
                             count_30s,
                             count_90s,
                             min_time,
                             max_time,
                             avg_time)
        SELECT convert(date,getdate()) exec_date,
               'tstruct' obj_type,
               'Load Report' service_name,
               b.caption,
               COUNT (*) cnt,
               SUM (CASE WHEN timetaken > 8000 THEN 1 ELSE 0 END) cnt8,
               SUM (CASE WHEN timetaken > 30000 THEN 1 ELSE 0 END) cnt30,
               SUM (CASE WHEN timetaken > 90000 THEN 1 ELSE 0 END) cnt90,
               MIN (timetaken) / 1000 mintime,
               MAX (timetaken) / 1000 maxtime,
               AVG (timetaken) / 1000 avgtime
          FROM    axpertlog a
               JOIN
                  (  SELECT name, caption
                       FROM iviews
                   GROUP BY name, caption) b
               ON a.structname = b.name
         WHERE     LOWER (servicename) = 'get iview'
               AND serviceresult = 'success'
               AND convert(date,calledon) = @fdate
      GROUP BY b.caption;
END
>>
<<
CREATE FUNCTION fnSplit(
    @sInputList VARCHAR(8000) -- List of delimited items
       ) RETURNS @List TABLE (item VARCHAR(8000))

BEGIN
DECLARE @sItem VARCHAR(8000)
declare  @sDelimiter VARCHAR(8000) = '^'  -- delimiter that separates items
WHILE CHARINDEX(@sDelimiter,@sInputList,0) <> 0
 BEGIN
 SELECT
  @sItem=RTRIM(LTRIM(SUBSTRING(@sInputList,1,CHARINDEX(@sDelimiter,@sInputList,0)-1))),
  @sInputList=RTRIM(LTRIM(SUBSTRING(@sInputList,CHARINDEX(@sDelimiter,@sInputList,0)+LEN(@sDelimiter),LEN(@sInputList))))
 
 IF LEN(@sItem) > 0
  INSERT INTO @List SELECT @sItem
 END

IF LEN(@sInputList) > 0
 INSERT INTO @List SELECT @sInputList -- Put the last item in
RETURN
END
>>
<<
CREATE PROCEDURE pro_emailformat(@ptemplate nvarchar(100) ,@pkeyword nvarchar(3000),@ptype nvarchar(100),@psendto nvarchar(1000),@psendcc nvarchar(1000) ) as
	DECLARE 
	@v_subject nvarchar(3500),
	@v_body nvarchar(3500),
	@v_sms  nvarchar(3500),
	@v_count numeric(5),
	@v_keyword nvarchar(350),
	@v_keyvalue nvarchar(1000),
	@vkeyword nvarchar(1000)

	DECLARE cursor_kword CURSOR FOR select item from fnssplit(@pkeyword)

begin

	set @v_count=(select count(*)  from  sendmsg
	 where lower(template) = lower( @ptemplate))
	 
	if @v_count=1 
	begin
		select  @v_subject = MSGSUBJECT, @v_body = MSGCONTENT, @v_sms = SMSMSG  
		from sendmsg
		where lower(template) = lower(@ptemplate)
 
		open cursor_kword 
		FETCH NEXT FROM cursor_kword into @vkeyword
		WHILE @@FETCH_STATUS = 0   
		BEGIN  

			set @v_keyword = SUBSTRing(@vkeyword, 1 ,CHARINDEX('=',@vkeyword,1)-1);
			set @v_keyvalue =  SUBSTRing( @vkeyword,CHARINDEX('=',@vkeyword,1)+1,len(@vkeyword));
			set @v_subject = replace(@v_subject,@v_keyword,@v_keyvalue);

			set @v_body = replace(@v_body,@v_keyword,@v_keyvalue);

			set @v_sms = replace(@v_sms,@v_keyword,@v_keyvalue);
		end

		CLOSE cursor_kword 
		DEALLOCATE cursor_kword 
	end

	if @ptype='S' 

		insert into axsms(createdon,mobileno,msg,status) values (convert(date,getdate()),@psendto,@v_sms,0)
	

	if @ptype='E' 

		INSERT INTO AXP_MAILJOBS (MAILTO,
								  MAILCC,
								  SUBJECT,
								  BODY,
								  ATTACHMENTS,
								  IVIEWNAME,
								  IVIEWPARAMS,
								  STATUS,
								  ERRORMESSAGE,
								  SENTON,JOBDATE)
			 VALUES (@psendto,@psendcc,@v_subject,@v_body,null,null,null,0,null,null,convert(date,getdate()));

End
>>
<<
CREATE TRIGGER trg_AXPSCRIPTRUNNER
   ON  AXPSCRIPTRUNNER
   AFTER INSERT
AS 
BEGIN
	SET NOCOUNT ON;
	declare @v_trgdis nvarchar(500),
			@v_trgena nvarchar(500),
			@vpintrg  nvarchar(500),
			@vpintext nvarchar(1000)
	
	set @vpintrg = (select ISNULL(trg_name,'NA')  from inserted)
	set @vpintext  = (select SCRIPT_TEXT  from inserted)
	set @v_trgdis = 'ALTER TRIGGER '+ @vpintrg +'  DISABLE'
	set @v_trgena = 'ALTER TRIGGER '+ @vpintrg +'  ENABLE'
	
	if @vpintrg = 'NA' 
		EXECUTE sp_executesql @vpintext
		
	if @vpintrg <> 'NA'
	begin
		EXECUTE sp_executesql @v_trgdis
		EXECUTE sp_executesql @vpintext
		EXECUTE sp_executesql @v_trgena
	end
    
END
>>
<<
CREATE TRIGGER TRG_UPDATDSIGN 
   ON  AXDSIGNCONFIG 
   AFTER INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
	declare @usr nvarchar(50), @prole nvarchar(50)
	
	set @usr=(select pusername from inserted)
	set @prole=(select prolename from inserted)
	
	update AXDSIGNCONFIG  set username=@usr, rolename=@prole where pusername=@usr
    
END
>>
<< 
delete from axpages
>>

<< axpages script for aligning menu >> 
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('Head14','Configuration','<root img="" visible="F" name="Head14" caption="Configuration" createdon="11-06-2015" createdby="admin" importedon="12-19-2019 12:20:01" importedby="admin" updatedon="11-06-2015" updatedby="admin" type="h" ordno="2" levelno="1" parent="Head19" ptype="h" pgtype="" dbtype="oracle"></root>
',1,'','F','h','Head19',5,1,'2019-12-19','2019-12-19','12-19-2019 12:20:01','admin','admin','admin',NULL,NULL,NULL,'',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES
('Head16','Data Setup','<root img="" visible="T" name="Head16" caption="Data Setup" createdon="11-06-2015" createdby="admin" importedon="12-19-2019 12:20:01" importedby="admin" updatedon="11-06-2015" updatedby="admin" type="h" ordno="14" levelno="1" parent="Head19" ptype="h" pgtype="" dbtype="oracle"></root>
',1,'','T','h','Head19',23,1,'2019-12-19','2019-12-19','12-19-2019 12:20:01','admin','admin','admin',NULL,NULL,NULL,'',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES
('Head17','Admin Utilities','<root img="" visible="F" name="Head17" caption="Admin Utilities" createdon="11-06-2015" createdby="admin" importedon="12-19-2019 12:20:01" importedby="admin" updatedon="11-06-2015" updatedby="admin" type="h" ordno="17" levelno="1" parent="Head19" ptype="h" pgtype="" dbtype="oracle"></root>
',1,'','F','h','Head19',28,1,'2019-12-19','2019-12-19','12-19-2019 12:20:01','admin','admin','admin',NULL,NULL,NULL,'',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES
('Head18','Admin Reports','<root img="" visible="T" name="Head18" caption="Admin Reports" createdon="11-06-2015" createdby="admin" importedon="12-19-2019 12:20:01" importedby="admin" updatedon="11-06-2015" updatedby="admin" type="h" ordno="19" levelno="1" parent="Head19" ptype="h" pgtype="" dbtype="oracle"></root>
',1,'','T','h','Head19',14,1,'2019-12-19','2019-12-19','12-19-2019 12:20:01','admin','admin','admin',NULL,NULL,NULL,'',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES
('Head19','Admin Setup','<root img="" visible="T" name="Head19" caption="Admin Setup" createdon="11-12-2015" createdby="admin" importedon="12-19-2019 12:20:01" importedby="admin" updatedon="11-12-2015" updatedby="admin" type="h" ordno="1" levelno="0" parent="" ptype="h" pgtype="" dbtype="oracle"></root>
',1,'','T','h','',1,0,'2019-12-19','2019-12-19','12-19-2019 12:20:01','admin','admin','admin',NULL,NULL,NULL,'',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES
('Head21','Settings','<root img="" visible="F" name="Head21" caption="Settings" createdon="21/12/2018 12:05:50" createdby="admin" importedon="" importedby="" updatedon="21/12/2018 12:05:50" updatedby="admin"></root>',1,NULL,'F','h','Head19',26,1,'21/12/2018 12:05:50','21/12/2018 12:05:50',NULL,'admin','admin',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES
('Head248','User Credentials','<root img="" visible="F" name="Head248" caption="User Credentials" createdon="12/19/2019 12:55:16" createdby="admin" importedon="" importedby="" updatedon="12/19/2019 12:55:16" updatedby="admin"></root>
',1,'','F','h','Head19',2,1,'12/19/2019 12:55:16','12/19/2019 12:55:16',NULL,'admin','admin',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES
('Head249','Mobile','<root img="" visible="F" name="Head249" caption="Mobile" createdon="12/19/2019 15:00:57" createdby="admin" importedon="" importedby="" updatedon="12/19/2019 15:00:57" updatedby="admin"></root>
',1,'','F','h','Head19',32,1,'12/19/2019 15:00:57','12/19/2019 15:00:57',NULL,'admin','admin',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES
('Page245','Mobile Configuration','<root cat="page" name="Page245" caption="Mobile Configuration" visible="T" type="p" img="" parent="" pagetype="Normal" serpath="" defpath="" fileext="" fileopt="" variables="" action="" createdon="11-18-2015" createdby="admin" importedon="12-19-2019 12:19:56" importedby="admin" updatedon="11-18-2015" updatedby="admin" ordno="41" levelno="0" updusername="" ptype="p" pgtype="taxmme" dbtype="oracle"><relations cat="rel"/><Container21 paged="False" align="Client" cat="cntr" parent="ClientPanel" font=",,," tlhw="0,0,647,1131" color="$00FAF7F1" st="tstruct__axmme"/><tstruct__axmme cat="tstruct" transid="axmme" parent="Container21" align="Client" tlhw="0,0,647,1131"/></root>
',1,'','T','p','Head249',33,2,'2019-12-19','2019-12-19','12-19-2019 12:19:56','admin','admin','admin',NULL,NULL,NULL,'taxmme',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES
('PageIvadxconfv','ADX Configuration','<root visible="T" type="p" defpage="T" name="PageIvadxconfv" caption="ADX Configuration" createdon="03/07/2015 14:42:41" createdby="admin" importedon="12-19-2019 12:19:56" importedby="admin" updatedon="11/15/2018 18:49:51" updatedby="admin" img="" ordno="5" levelno="2" parent="" updusername="" cat="page" pagetype="Normal" serpath="" defpath="" fileext="" fileopt="" variables="" action="" ptype="p" pgtype="iadxconfv" dbtype="ms sql"><Container21 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,659,1129" st="view__adxconfv" font="Tahoma,,,clBlack" color="$00FAF7F1"/><view__adxconfv cat="iview" name="adxconfv" parent="Container21" align="Client"/></root>
',1,'','T','p','Head14',11,2,'2019-12-19','2019-12-19','12-19-2019 12:19:56','admin','admin','admin',NULL,NULL,NULL,'iadxconfv',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvadxinlog','ADX Inbound Log','<root visible="T" type="p" defpage="T" name="PageIvadxinlog" caption="ADX Inbound Log" createdon="07-02-2015" createdby="admin" importedon="12-19-2019 12:19:56" importedby="admin" updatedon="07-02-2015" updatedby="admin" img="" ordno="23" levelno="2" parent="" updusername="" ptype="p" pgtype="iadxinlog" dbtype="oracle"><Container16 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,0,0" st="view__adxinlog"/><view__adxinlog cat="iview" name="adxinlog" parent="Container16" align="Client"/></root>
',1,'','T','p','Head18',19,2,'2019-12-19','2019-12-19','12-19-2019 12:19:56','admin','admin','admin',NULL,NULL,NULL,'iadxinlog',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvadxoutlo','ADX Outbound Log','<root visible="T" type="p" defpage="T" name="PageIvadxoutlo" caption="ADX Outbound Log" createdon="07-02-2015" createdby="admin" importedon="12-19-2019 12:19:56" importedby="admin" updatedon="07-02-2015" updatedby="admin" img="" ordno="22" levelno="2" parent="" updusername="" ptype="p" pgtype="iadxoutlo" dbtype="oracle"><Container15 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,0,0" st="view__adxoutlo"/><view__adxoutlo cat="iview" name="adxoutlo" parent="Container15" align="Client"/></root>
',1,'','T','p','Head18',18,2,'2019-12-19','2019-12-19','12-19-2019 12:19:56','admin','admin','admin',NULL,NULL,NULL,'iadxoutlo',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvapplogsm','Application Usage Statistics','<root visible="T" type="p" defpage="T" updatedon="10-29-2015" name="PageIvapplogsm" caption="Application Usage Statistics" img="" ordno="25" levelno="2" parent="" updusername="" ptype="p" pgtype="iapplogsm" importedon="12-19-2019 12:19:56" importedby="admin" cat="page" pagetype="Normal" serpath="" defpath="" fileext="" fileopt="" variables="" action="" updatedby="admin" dbtype="oracle" createdon="12-19-2019 12:19:56"><Container187 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,647,1131" st="view__applogsm" font="Tahoma,,,clBlack" color="$00FAF7F1"/><view__applogsm cat="iview" name="applogsm" parent="Container187" align="Client"/></root>
',1,'','T','p','Head18',21,2,'2019-12-19','2019-12-19','12-19-2019 12:19:56',NULL,'admin','admin',NULL,NULL,NULL,'iapplogsm',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvaxchtdtl','Dashboard Configuration','<root visible="T" type="p" defpage="T" name="PageIvaxchtdtl" caption="Dashboard Configuration" createdon="07-03-2015" createdby="admin" importedon="12-19-2019 12:19:55" importedby="admin" updatedon="11-16-2015" updatedby="admin" img="" ordno="11" levelno="2" parent="" updusername="" cat="page" pagetype="Normal" serpath="" defpath="" fileext="" fileopt="" variables="" action="" ptype="p" pgtype="iaxchtdtl" dbtype="oracle"><Container39 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,647,1131" st="view__axchtdtl" font="Tahoma,,,clBlack" color="$00FAF7F1"/><view__axchtdtl cat="iview" name="axchtdtl" parent="Container39" align="Client"/></root>
',1,'','T','p','Head14',7,2,'2019-12-19','2019-12-19','12-19-2019 12:19:55','admin','admin','admin',NULL,NULL,NULL,'iaxchtdtl',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvaxemllog','Email Log','<root visible="T" type="p" defpage="T" name="PageIvaxemllog" caption="Email Log" createdon="07-02-2015" createdby="admin" importedon="12-19-2019 12:19:55" importedby="admin" updatedon="07-02-2015" updatedby="admin" img="" ordno="20" levelno="2" parent="" updusername="" ptype="p" pgtype="iaxemllog" dbtype="oracle"><Container14 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,0,0" st="view__axemllog"/><view__axemllog cat="iview" name="axemllog" parent="Container14" align="Client"/></root>
',1,'','T','p','Head18',15,2,'2019-12-19','2019-12-19','12-19-2019 12:19:55','admin','admin','admin',NULL,NULL,NULL,'iaxemllog',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvaxfinyrs','Year','<root visible="T" type="p" defpage="T" name="PageIvaxfinyrs" caption="Year" createdon="07-22-2015" createdby="admin" importedon="12-19-2019 12:19:55" importedby="admin" updatedon="11-16-2015" updatedby="admin" img="" ordno="16" levelno="2" parent="" updusername="" cat="page" pagetype="Normal" serpath="" defpath="" fileext="" fileopt="" variables="" action="" ptype="p" pgtype="iaxfinyrs" dbtype="oracle"><Container55 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,647,1131" st="view__axfinyrs" font="Tahoma,,,clBlack" color="$00FAF7F1"/><view__axfinyrs cat="iview" name="axfinyrs" parent="Container55" align="Client"/></root>
',1,'','T','p','Head16',24,2,'2019-12-19','2019-12-19','12-19-2019 12:19:55','admin','admin','admin',NULL,NULL,NULL,'iaxfinyrs',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvaxnxtlst','Intelliview Configuration','<root visible="T" type="p" defpage="T" name="PageIvaxnxtlst" caption="Intelliview Configuration" createdon="07-21-2015" createdby="admin" importedon="12-19-2019 12:19:55" importedby="admin" updatedon="07-21-2015" updatedby="admin" img="" ordno="10" levelno="2" parent="" updusername="" ptype="p" pgtype="iaxnxtlst" dbtype="oracle"><Container47 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,0,0" st="view__axnxtlst"/><view__axnxtlst cat="iview" name="axnxtlst" parent="Container47" align="Client"/></root>
',1,'','T','p','Head14',8,2,'2019-12-19','2019-12-19','12-19-2019 12:19:55','admin','admin','admin',NULL,NULL,NULL,'iaxnxtlst',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvaxroles','User Roles','<root visible="T" type="p" defpage="T" name="PageIvaxroles" caption="User Roles" createdon="21/07/2015 12:26:56" createdby="admin" importedon="12-19-2019 12:19:55" importedby="admin" updatedon="11/15/2018 18:50:19" updatedby="admin" img="" ordno="3" levelno="2" parent="" updusername="" ptype="p" pgtype="iaxroles" dbtype="ms sql"><Container50 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,0,0" st="view__axroles"/><view__axroles cat="iview" name="axroles" parent="Container50" align="Client"/></root>
',1,'','T','p','Head248',3,2,'2019-12-19','2019-12-19','12-19-2019 12:19:55','admin','admin','admin',NULL,NULL,NULL,'iaxroles',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvaxusers','User Logins','<root visible="T" type="p" defpage="T" name="PageIvaxusers" caption="User Logins" createdon="21/07/2015 12:32:11" createdby="admin" importedon="12-19-2019 12:19:54" importedby="admin" updatedon="11/15/2018 18:48:11" updatedby="admin" img="" ordno="4" levelno="2" parent="" updusername="" ptype="p" pgtype="iaxusers" dbtype="ms sql"><Container51 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,0,0" st="view__axusers"/><view__axusers cat="iview" name="axusers" parent="Container51" align="Client"/></root>
',1,'','T','p','Head248',4,2,'2019-12-19','2019-12-19','12-19-2019 12:19:54','admin','admin','admin',NULL,NULL,NULL,'iaxusers',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvaxusracc','User Access Report','<root visible="T" type="p" defpage="T" name="PageIvaxusracc" caption="User Access Report" createdon="07-29-2015" createdby="admin" importedon="12-19-2019 12:19:54" importedby="admin" updatedon="10-29-2015" updatedby="admin" img="" ordno="24" levelno="2" parent="" updusername="" cat="page" pagetype="Normal" serpath="" defpath="" fileext="" fileopt="" variables="" action="" ptype="p" pgtype="iaxusracc" dbtype="oracle"><Container59 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,647,1131" st="view__axusracc" font="Tahoma,,,clBlack" color="$00FAF7F1"/><view__axusracc cat="iview" name="axusracc" parent="Container59" align="Client"/></root>
',1,'','T','p','Head18',20,2,'2019-12-19','2019-12-19','12-19-2019 12:19:54','admin','admin','admin',NULL,NULL,NULL,'iaxusracc',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvcerrm','Custom Error Messages','<root visible="T" type="p" defpage="T" name="PageIvcerrm" caption="Custom Error Messages" createdon="11-18-2015" createdby="admin" importedon="12-19-2019 12:19:54" importedby="admin" updatedon="11-18-2015" updatedby="admin" img="" ordno="9" levelno="2" parent="" updusername="" ptype="p" pgtype="icerrm" dbtype="oracle"><Container3 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,0,0" st="view__cerrm"/><view__cerrm cat="iview" name="cerrm" parent="Container3" align="Client"/></root>
',1,'','T','p','Head14',9,2,'2019-12-19','2019-12-19','12-19-2019 12:19:54','admin','admin','admin',NULL,NULL,NULL,'icerrm',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvdmlscrpt','Script Runner','<root visible="T" type="p" defpage="T" updatedon="07-21-2015" name="PageIvdmlscrpt" caption="Script Runner" img="" ordno="18" levelno="2" parent="" updusername="" ptype="p" pgtype="idmlscrpt" importedon="12-19-2019 12:19:54" importedby="admin" cat="page" pagetype="Normal" serpath="" defpath="" fileext="" fileopt="" variables="" action="" updatedby="admin" dbtype="oracle" createdon="12-19-2019 12:19:54"><Container538 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,648,1131" st="view__dmlscrpt" font="Tahoma,,,clBlack" color="$00FAF7F1"/><view__dmlscrpt cat="iview" name="dmlscrpt" parent="Container538" align="Client"/></root>
',1,'','T','p','Head17',29,2,'2019-12-19','2019-12-19','12-19-2019 12:19:54',NULL,'admin','admin',NULL,NULL,NULL,'idmlscrpt',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvesmsco','Email/SMS Configuration','<root visible="T" type="p" defpage="T" name="PageIvesmsco" caption="Email/SMS Configuration" createdon="16/11/2015 12:54:29" createdby="admin" importedon="12-19-2019 12:19:54" importedby="admin" updatedon="11/15/2018 18:52:59" updatedby="admin" img="" ordno="8" levelno="2" parent="" updusername="" ptype="p" pgtype="iesmsco" dbtype="ms sql"><Container5 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,0,0" st="view__esmsco"/><view__esmsco cat="iview" name="esmsco" parent="Container5" align="Client"/></root>
',1,'','T','p','Head14',10,2,'2019-12-19','2019-12-19','12-19-2019 12:19:54','admin','admin','admin',NULL,NULL,NULL,'iesmsco',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIviaxex','Application Exceptions','<root visible="T" type="p" defpage="T" name="PageIviaxex" caption="Application Exceptions" createdon="11-17-2015" createdby="admin" importedon="12-19-2019 12:19:54" importedby="admin" updatedon="11-17-2015" updatedby="admin" img="" ordno="27" levelno="2" parent="" updusername="" ptype="p" pgtype="iiaxex" dbtype="oracle"><Container13 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,0,0" st="view__iaxex"/><view__iaxex cat="iview" name="iaxex" parent="Container13" align="Client"/></root>
',1,'','T','p','Head18',22,2,'2019-12-19','2019-12-19','12-19-2019 12:19:54','admin','admin','admin',NULL,NULL,NULL,'iiaxex',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIviaxpscon','Axpstruct Configuration','<root visible="T" type="p" defpage="T" name="PageIviaxpscon" caption="Axpstruct Configuration" createdon="04/12/2018 15:28:54" createdby="admin" importedon="21/12/2018 12:03:28" importedby="admin" updatedon="19/12/2018 15:17:54" updatedby="admin" img="" ordno="114" levelno="0" parent="" pgtype="iiaxpscon" updusername="" ptype="p" dbtype="oracle"><Container388 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,0,0" st="view__iaxpscon"/><view__iaxpscon cat="iview" name="iaxpscon" parent="Container388" align="Client"/></root>',1,NULL,'T','p','Head14',12,2,'19/12/2018 15:17:54','04/12/2018 15:28:54','21/12/2018 12:03:28','admin','admin','admin',NULL,NULL,NULL,'iiaxpscon',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvidsco','DSign Configuration','<root visible="T" type="p" defpage="T" name="PageIvidsco" caption="DSign Configuration" createdon="11-16-2015" createdby="admin" importedon="12-19-2019 12:19:53" importedby="admin" updatedon="11-16-2015" updatedby="admin" img="" ordno="12" levelno="2" parent="" updusername="" cat="page" pagetype="Normal" serpath="" defpath="" fileext="" fileopt="" variables="" action="" ptype="p" pgtype="iidsco" dbtype="oracle"><Container11 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,647,1131" st="view__idsco" font="Tahoma,,,clBlack" color="$00FAF7F1"/><view__idsco cat="iview" name="idsco" parent="Container11" align="Client"/></root>
',1,'','T','p','Head14',6,2,'2019-12-19','2019-12-19','12-19-2019 12:19:53','admin','admin','admin',NULL,NULL,NULL,'iidsco',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvikywd','Keyword Template','<root visible="T" type="p" defpage="T" name="PageIvikywd" caption="Keyword Template" createdon="11-16-2015" createdby="admin" importedon="12-19-2019 12:19:53" importedby="admin" updatedon="11-16-2015" updatedby="admin" img="" ordno="7" levelno="2" parent="" updusername="" cat="page" pagetype="Normal" serpath="" defpath="" fileext="" fileopt="" variables="" action="" ptype="p" pgtype="iikywd" dbtype="oracle"><Container9 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,647,1131" st="view__ikywd" font="Tahoma,,,clBlack" color="$00FAF7F1"/><view__ikywd cat="iview" name="ikywd" parent="Container9" align="Client"/></root>
',1,'','T','p','Head17',30,2,'2019-12-19','2019-12-19','12-19-2019 12:19:53','admin','admin','admin',NULL,NULL,NULL,'iikywd',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvimobc','Mobile Configuration','<root visible="T" type="p" defpage="T" name="PageIvimobc" caption="Mobile Configuration" createdon="11-12-2015" createdby="admin" importedon="12-19-2019 12:19:53" importedby="admin" updatedon="06-26-2018" updatedby="admin" img="" ordno="6" levelno="2" parent="" updusername="" cat="page" pagetype="Normal" serpath="" defpath="" fileext="" fileopt="" variables="" action="" ptype="p" pgtype="iimobc" dbtype="oracle"><Container2 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,647,1131" st="view__imobc" font="Tahoma,,,clBlack" color="$00FAF7F1"/><view__imobc cat="iview" name="imobc" parent="Container2" align="Client"/></root>
',1,'','T','p','Head249',35,2,'2019-12-19','2019-12-19','12-19-2019 12:19:53','admin','admin','admin',NULL,NULL,NULL,'iimobc',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvitimtk','Time Taken Analysis','<root visible="T" type="p" defpage="T" name="PageIvitimtk" caption="Time Taken Analysis" createdon="11-17-2015" createdby="admin" importedon="12-19-2019 12:19:53" importedby="admin" updatedon="11-17-2015" updatedby="admin" img="" ordno="26" levelno="2" parent="" updusername="" ptype="p" pgtype="iitimtk" dbtype="oracle"><Container12 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,0,0" st="view__itimtk"/><view__itimtk cat="iview" name="itimtk" parent="Container12" align="Client"/></root>
',1,'','T','p','Head18',17,2,'2019-12-19','2019-12-19','12-19-2019 12:19:53','admin','admin','admin',NULL,NULL,NULL,'iitimtk',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvloview1','List of Values','<root visible="T" type="p" defpage="T" name="PageIvloview1" caption="List of Values" createdon="08-21-2015" createdby="admin" importedon="12-19-2019 12:19:53" importedby="admin" updatedon="12-19-2019 12:56:16" updatedby="admin" img="" ordno="5" levelno="2" parent="Head14" updusername="" cat="page" pagetype="Normal" serpath="" defpath="" fileext="" fileopt="" variables="" action="" ptype="p" pgtype="iloview1" dbtype="oracle"><Container74 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,647,1131" st="view__loview1" font="Tahoma,,,clBlack" color="$00FAF7F1"/><view__loview1 cat="iview" name="loview1" parent="Container74" align="Client"/></root>
',1,NULL,'T','p','Head16',25,2,'12-19-2019 12:56:16','08-21-2015','12-19-2019 12:19:53','admin','admin','admin',NULL,NULL,NULL,'iloview1',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvsmslog','SMS Log','<root visible="T" type="p" defpage="T" updatedon="05/17/2012 11:04:42" name="PageIvsmslog" caption="SMS Log" img="" ordno="18" levelno="2" parent="" updusername="" cat="page" pagetype="Normal" serpath="" defpath="" fileext="" fileopt="" variables="" action="" ptype="p" pgtype="ismslog" importedon="17/11/2015 19:32:18" importedby="admin" dbtype="oracle"><Container179 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,676,1045" st="view__smslog" font=",,," color="$00FAF7F1"/><view__smslog cat="iview" name="smslog" parent="Container179" align="Client"/></root>',1,NULL,'T','p','Head18',16,2,'2019-12-19','2019-12-19','17/11/2015 19:32:18',NULL,NULL,'admin',NULL,NULL,NULL,'ismslog',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageIvthint','Transaction Hint','<root visible="T" type="p" defpage="T" name="PageIvthint" caption="Transaction Hint" createdon="11-19-2015" createdby="admin" importedon="12-19-2019 12:19:53" importedby="admin" updatedon="11-19-2015" updatedby="admin" img="" ordno="13" levelno="2" parent="" updusername="" ptype="p" pgtype="ithint" dbtype="oracle"><Container4 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,0,0" st="view__thint"/><view__thint cat="iview" name="thint" parent="Container4" align="Client"/></root>
',1,'','T','p','Head17',31,2,'2019-12-19','2019-12-19','12-19-2019 12:19:53','admin','admin','admin',NULL,NULL,NULL,'ithint',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageTsastcp','Configuration Property','<root visible="T" type="p" defpage="T" name="PageTsastcp" caption="Configuration Property" createdon="04/12/2018 13:19:32" createdby="admin" importedon="21/12/2018 12:03:28" importedby="admin" updatedon="18/12/2018 15:43:36" updatedby="admin" img="" ordno="112" levelno="0" parent="" updusername="" ptype="p" pgtype="tastcp" dbtype="oracle"><Container386 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,0,0" st="tstruct__astcp"/><tstruct__astcp cat="tstruct" transid="astcp" parent="Container386" align="Client"/></root>',1,NULL,'T','p','Head14',13,2,'18/12/2018 15:43:36','04/12/2018 13:19:32','21/12/2018 12:03:28','admin','admin','admin',NULL,NULL,NULL,'tastcp',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageTsaxstc','Advance Settings','<root visible="T" type="p" defpage="T" name="PageTsaxstc" caption="Advance Settings" createdon="04/12/2018 13:36:37" createdby="admin" importedon="21/12/2018 12:03:28" importedby="admin" updatedon="18/12/2018 18:36:55" updatedby="admin" img="" ordno="113" levelno="0" parent="" updusername="" ptype="p" pgtype="taxstc" dbtype="oracle"><Container387 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,0,0" st="tstruct__axstc"/><tstruct__axstc cat="tstruct" transid="axstc" parent="Container387" align="Client"/></root>',1,NULL,'T','p','Head21',27,2,'18/12/2018 18:36:55','04/12/2018 13:36:37','21/12/2018 12:03:28','admin','admin','admin',NULL,NULL,NULL,'taxstc',NULL,NULL,NULL)
>>
<<
INSERT INTO  axpages (name,caption,props,blobno,img,visible,type,parent,ordno,levelno,updatedon,CreatedOn,ImportedOn,CreatedBy,UpdatedBy,ImportedBy,readonly,updusername,category,pagetype,INTVIEW,webenable,shortcut) VALUES 
('PageTsofcon','Offline Table Configuration','<root visible="T" type="p" defpage="T" name="PageTsofcon" caption="Offline Table Configuration" createdon="12-25-2015" createdby="admin" importedon="12-19-2019 12:19:52" importedby="admin" updatedon="12-30-2015" updatedby="admin" img="" ordno="16" levelno="0" parent="" updusername="" cat="page" pagetype="Normal" serpath="" defpath="" fileext="" fileopt="" variables="" action="" ptype="p" pgtype="tofcon" dbtype="oracle"><Container32 paged="False" align="Client" cat="cntr" parent="ClientPanel" defpage="T" tlhw="0,0,647,1131" st="tstruct__ofcon" font="Tahoma,,,clBlack" color="$00FAF7F1"/><tstruct__ofcon cat="tstruct" transid="ofcon" parent="Container32" align="Client"/></root>
',1,'','T','p','Head249',34,2,'2019-12-19','2019-12-19','12-19-2019 12:19:52','admin','admin','admin',NULL,NULL,NULL,'tofcon',NULL,NULL,NULL)
>>
<<
update axpages set UPDATEDON = CONVERT(date,getdate()),CREATEDON= CONVERT(date,getdate())
>>
<<
CREATE PROCEDURE SP_RAPIDDEFINITION(@ITid varchar(100)) 
AS 

BEGIN

	
SELECT a.context, a.fieldname, c.expression, a.fldsql as fldsql, ISNULL(b.paramname,'') as paramname 
	FROM axp_formload a 
	LEFT JOIN axp_params b on b.tstruct = @ITid and a.fieldname = b.childfield and 
a.context = b.context and b.active = 'T' 
INNER JOIN axpflds c on c.tstruct = @ITid and a.fieldname=c.fname 
WHERE a.tstruct = @ITid and a.active='T' and a.context = 'new';    
   
	
SELECT a.parentfield, a.childfield, a.dependenttype, ISNULL(b.paramname,'') as paramname,    
	ISNULL(b.allrows,'F') as allrows, ISNULL(b.dirparam,'F') as dirparam, c.frmno, c.ordno FROM axp_dependent a 
	LEFT JOIN axp_params b on b.tstruct = @ITid and a.parentfield = b.childfield and b.context = 'dep' and b.active = 'T'
	JOIN axpflds c on c.tstruct = @ITid and a.childfield=c.fname 
WHERE a.tstruct = @ITid
	
UNION
	
SELECT distinct par.paramname parentfield, dep1.childfield, 'g' as dependenttype, ISNULL(b.paramname,'') as paramname, 'F' as allrows, 'F' as dirparam, flds.frmno,flds.ordno  
	FROM axp_dependent dep1
	JOIN (select paramname, childfield from axp_params par where par.tstruct = @ITid and par.context = 'fg') par on par.childfield = dep1.parentfield
	JOIN axp_dependent dep2 on dep2.tstruct = @ITid  and dep2.parentfield = par.paramname and dep2.dependenttype = 'g'
	JOIN axp_params b on b.tstruct = @ITid and par.childfield = b.childfield and b.context = 'fg' and b.active = 'T'
 JOIN axpflds flds on flds.tstruct = @ITid and dep1.childfield = flds.fname
 
WHERE dep1.tstruct = @ITid
	ORDER BY frmno asc, ordno asc;

END
>>
<<
IF EXISTS (SELECT * FROM sysobjects WHERE name='GetIview') 
BEGIN
	DROP PROCEDURE GetIview;
END;
>>
<<
CREATE PROCEDURE GetIview(@ISql VARCHAR(max), @INoofRec INT, @IpageNo INT, @ICountFlag INT) 
AS 
BEGIN 
  DECLARE @pos1 INT, @pos2 INT, @pos3 INT; 
  DECLARE @Qry VARCHAR(max); 
  DECLARE @orderby VARCHAR(1000); 

  SET @pos1 = 0; 
  SET @pos2 = 0; 
  SET @Qry = @ISql; 
  SET @orderby = ''; 

  SELECT @pos1 = Charindex('from', @Qry, 1); 

  SELECT @pos2 = Charindex('order by', Substring(@Qry, @pos1 + 1, Len(@Qry)) 
				 , 
				 1); 

  IF @pos2 > 0 
	BEGIN 
		SET @orderby = Rtrim(Ltrim(Substring(@Qry, @pos1 + @pos2 + 8, Len(@Qry)))) ; 
		SET @Qry = Substring(@Qry, 1, @pos1 + @pos2 - 1); 
	END; 

  SET @orderby = Replace(@orderby, ',', ', '); 
  SET @orderby = Replace(@orderby, '  ', ' '); 
  SET @orderby = ' @' + Replace(@orderby, ', ', '@'); 

  WHILE Charindex('.', @orderby, 1) > 0 
	BEGIN 
		SET @pos1= Charindex('.', @orderby, 1); 
		SET @pos2= Charindex('@', @orderby, 2); 
		SET @pos3= Charindex('@', @orderby, @pos2 + 1); 

		IF @pos1 > 0 
		   AND @pos3 < @pos1 
		   AND @pos2 < @pos1 
		  BEGIN 
			  SET @orderby = Substring(@orderby, 1, @pos2) + 'a.' 
							 + Substring(@orderby, @pos2+1, Len(@orderby)); 
			  SET @pos1= Charindex('.', @orderby, 1); 
			  SET @pos2= Charindex('@', @orderby, 2); 
		  END; 

		SET @orderby= Replace(@orderby, Substring(@orderby, @pos2, @pos1 - @pos2 + 1), ','); 
		SET @orderby=Ltrim(@orderby); 
	END; 

  SET @orderby = Replace(Substring(@orderby, 2, Len(@orderby)), '@', ','); 

  WHILE Charindex(',,', @orderby, 1) > 0 
	BEGIN 
		SET @orderby = Replace(@orderby, ',,', ','); 
	END; 

  IF Charindex(',', @orderby, 1) = 1 
	BEGIN 
		SET @orderby = Substring(@orderby, 2, Len(@orderby)); 
	END; 

  IF ( @INoofRec > 0 AND @IpageNo > 0 ) 
	BEGIN 
		SELECT @ISql = 'select * from (select row_number() over ( ORDER BY ' 
					   + @orderby 
					   + ' ) as rowno, '''' as axrowtype, a.* from ( ' 
					   + @Qry + ') as a ) xy where rowno between ' 
					   + Cast(((@INoofRec * (@IpageNo-1))+1) AS VARCHAR(50)) 
					   + ' and ' 
					   + Cast((@INoofRec * (@IpageNo)) AS VARCHAR(50) ) 
					   + ' order by rowno '; 
	END 
  ELSE 
	SELECT @ISql = 'select row_number() over ( ORDER BY ' 
				   + @orderby 
				   + ' ) as rowno, '''' as axrowtype, a.* from ( ' 
				   + @Qry + ') as a ORDER by ' + @orderby; 

  EXECUTE (@ISql); 

  IF ( @ICountFlag = 1 
	   AND @IpageNo <= 1 ) 
	BEGIN 
		SET @Qry = 'select count(*) as IviewCount from (' 
				   + @Qry + ')a'; 

		EXECUTE (@Qry); 
	END; 
END; 
>>
<<
CREATE TABLE AX_NOTIFY(
    NOTIFICATION_ID INT IDENTITY(1,1) PRIMARY KEY,
    TITLE VARCHAR(255),
    MESSAGE text,
    ACTIONS text,
    FROMUSER VARCHAR(255),
    BROADCAST VARCHAR(1) DEFAULT 'N',
    STATUS VARCHAR(255),
    CREATED_BY VARCHAR(255),
    CREATED_ON datetime DEFAULT CURRENT_TIMESTAMP,
    UPDATED_ON datetime DEFAULT CURRENT_TIMESTAMP,
    WORKFLOW_ID VARCHAR(255),
    PROJECT_ID VARCHAR(255),
    PURGE_ON_FIRST_ACTION VARCHAR(1) DEFAULT 'N',
    NOTIFICATION_SENT_DATETIME datetime DEFAULT CURRENT_TIMESTAMP,
    RECORDID VARCHAR(255),
    lno VARCHAR(255),
    elno VARCHAR(255)
)
>>
<<
CREATE TABLE AX_MOBILE_RESPONSE(
    NOTIFICATION_ID INT REFERENCES AX_NOTIFY(NOTIFICATION_ID) ON DELETE CASCADE,
    USER_ID VARCHAR(255),
    RESPONSE TEXT, 
    PROJECT_ID VARCHAR(255)
)
>>
<<
CREATE TABLE AX_NOTIFY_WORKFLOW(
    NOTIFICATION_ID INT,
    RECORDID VARCHAR(255),
    APP_LEVEL VARCHAR(2),
    APP_DESC VARCHAR(2),
    CREATED_ON datetime  DEFAULT CURRENT_TIMESTAMP,
    WORKFLOW_ID VARCHAR(255),
    PROJECT_ID VARCHAR(255),
    lno VARCHAR(255),
    elno VARCHAR(255)
)
>>
<<
CREATE TABLE AX_MOBILE_USER(
    IMEI VARCHAR(255),
    USER_ID VARCHAR(255),
    PROJECT_ID VARCHAR(255),
    FIREBASE_ID VARCHAR(255),
    GROUPNAME VARCHAR(255),
    ACTIVE VARCHAR(1)
)
>>
<<
CREATE TABLE AX_NOTIFY_USERS(    
    NOTIFICATION_ID INT REFERENCES AX_NOTIFY(NOTIFICATION_ID) ON DELETE CASCADE,
    USER_ID VARCHAR(255),
    STATUS VARCHAR(255),
    PROJECT_ID VARCHAR(255)
)
>>
<<
CREATE TABLE AX_LAYOUTDESIGN(
    DESIGN_ID INT IDENTITY(1,1) PRIMARY KEY,
    TRANSID VARCHAR(255),
    MODULE VARCHAR(255),
    CONTENT text,
    CREATED_BY VARCHAR(255),
    UPDATED_BY VARCHAR(255),
    IS_DELETED VARCHAR(1) DEFAULT 'N',
    IS_PRIVATE VARCHAR(1) DEFAULT 'N',
    CREATED_ON datetime DEFAULT CURRENT_TIMESTAMP,
    UPDATED_ON datetime DEFAULT CURRENT_TIMESTAMP, 
    IS_MIGRATED VARCHAR(1) DEFAULT 'N'
)
>>
<<
CREATE TABLE AX_LAYOUTDESIGN_SAVED(
    DESIGN_ID INT IDENTITY(1,1) PRIMARY KEY,
    TRANSID VARCHAR(255),
    MODULE VARCHAR(255),
    CONTENT text,
    CREATED_BY VARCHAR(255),
    UPDATED_BY VARCHAR(255),
    IS_DELETED VARCHAR(1) DEFAULT 'N',
    CREATED_ON datetime DEFAULT CURRENT_TIMESTAMP,
    UPDATED_ON datetime DEFAULT CURRENT_TIMESTAMP,
    IS_MIGRATED VARCHAR(1) DEFAULT 'N',
    IS_PUBLISH VARCHAR(1) DEFAULT 'N',
    IS_PRIVATE VARCHAR(1) DEFAULT 'N',
    PARENT_DESIGN_ID INT,
    RESPONSIBILITY text,
    ORDER_BY INT
)
>>
<<
alter table axtasks add notify_status VARCHAR(1) DEFAULT 'N'
>>
<<
update ax_homebuild_saved set target = replace(target,'Wrapper','')
>>
<<
update ax_widget set widget_type='kpi' where widget_type='table'
>>
<<
CREATE TABLE AX_PAGES(
    PAGE_ID INT IDENTITY(1,1) PRIMARY KEY,
    TITLE VARCHAR(255),
    TYPE VARCHAR(255),
    MODULE VARCHAR(255),
    TEMPLATE VARCHAR(255),
    PAGE_MENU VARCHAR(255),
    CONTENT TEXT,
    CREATED_BY VARCHAR(255),
    UPDATED_BY VARCHAR(255),
    IS_DELETED VARCHAR(1) DEFAULT 'N',
    IS_DEFAULT VARCHAR(1) DEFAULT 'N',
    IS_PRIVATE VARCHAR(1) DEFAULT 'N',
    CREATED_ON DATETIME DEFAULT CURRENT_TIMESTAMP,
    UPDATED_ON DATETIME DEFAULT CURRENT_TIMESTAMP,  
    IS_MIGRATED VARCHAR(1) DEFAULT 'N',
    ORDER_BY INT
)
>>
<<
CREATE TABLE AX_PAGE_SAVED(
    PAGE_ID INT IDENTITY(1,1) PRIMARY KEY,
    TITLE VARCHAR(255),
    TYPE VARCHAR(255),
    MODULE VARCHAR(255),
    TEMPLATE VARCHAR(255),
    PAGE_MENU VARCHAR(255),
    CONTENT TEXT,
    CREATED_BY VARCHAR(255),
    UPDATED_BY VARCHAR(255),
    IS_DELETED VARCHAR(1) DEFAULT 'N',
    IS_DEFAULT VARCHAR(1) DEFAULT 'N',
    CREATED_ON DATETIME DEFAULT CURRENT_TIMESTAMP,
    UPDATED_ON DATETIME DEFAULT CURRENT_TIMESTAMP,  
    IS_MIGRATED VARCHAR(1) DEFAULT 'N',
    IS_PUBLISH VARCHAR(1) DEFAULT 'N',
    IS_PRIVATE VARCHAR(1) DEFAULT 'N',
    PARENT_PAGE_ID INT,
    RESPONSIBILITY TEXT,
    ORDER_BY INT
)
>>
<<
CREATE TABLE AX_PAGE_RESPONSIBILITY(     
    PAGE_ID INT REFERENCES AX_PAGES(PAGE_ID) ON DELETE CASCADE,
    RESPONSIBILITY VARCHAR(255),
    RESPONSIBILITY_ID INT
)
>>
<<
CREATE TABLE AX_PAGE_SD_RESPONSIBILITY(  
    PAGE_ID INT REFERENCES AX_PAGE_SAVED(PAGE_ID) ON DELETE CASCADE,
    RESPONSIBILITY VARCHAR(255),
    RESPONSIBILITY_ID INT
)
>>
<<
CREATE TABLE AX_WIDGET_SAVED (
    WIDGET_ID INT IDENTITY(1,1) PRIMARY KEY,
    TITLE VARCHAR(255),
    WIDGET_TYPE VARCHAR(255),
    CONTENT TEXT,
    TARGET VARCHAR(255),
    IS_PRIVATE VARCHAR(1) DEFAULT 'N',
    CREATED_BY VARCHAR(255),
    UPDATED_BY VARCHAR(255),
    IS_DELETED VARCHAR(1) DEFAULT 'N',
    IS_LOCK VARCHAR(1) DEFAULT 'N',
    ORDER_BY INT,
    is_publish VARCHAR(1) DEFAULT 'N',
    PARENT_WIDGET_ID INT,
    PAGE_ID INT REFERENCES AX_PAGE_SAVED(PAGE_ID) ON DELETE CASCADE,
    CREATED_ON DATETIME DEFAULT CURRENT_TIMESTAMP,
    UPDATED_ON DATETIME DEFAULT CURRENT_TIMESTAMP, 
    IS_MIGRATED VARCHAR(1) DEFAULT 'N'
)
>>
<<
CREATE TABLE AX_WIDGET_PUBLISHED (
    WIDGET_ID INT IDENTITY(1,1) PRIMARY KEY,
    TITLE VARCHAR(255),
    WIDGET_TYPE VARCHAR(255),
    CONTENT TEXT,
    TARGET VARCHAR(255),
    IS_PRIVATE VARCHAR(1) DEFAULT 'N',
    CREATED_BY VARCHAR(255),
    UPDATED_BY VARCHAR(255),
    IS_DELETED VARCHAR(1) DEFAULT 'N',
    IS_LOCK VARCHAR(1) DEFAULT 'N',
    ORDER_BY INT,
    is_publish VARCHAR(1) DEFAULT 'N',
    PARENT_WIDGET_ID INT REFERENCES AX_WIDGET_SAVED(WIDGET_ID) ON DELETE CASCADE,
    PAGE_ID INT REFERENCES AX_PAGES(PAGE_ID) ON DELETE CASCADE,
    CREATED_ON DATETIME DEFAULT CURRENT_TIMESTAMP,
    UPDATED_ON DATETIME DEFAULT CURRENT_TIMESTAMP, 
    IS_MIGRATED VARCHAR(1) DEFAULT 'N'
)
>>
<<
CREATE TABLE AX_HP_USER_LEVEL_WIDGET(
    PAGE_ID INT REFERENCES AX_PAGES(PAGE_ID) ON DELETE CASCADE,    
    WIDGETS  TEXT,
    USERNAME VARCHAR(255),
    IS_DELETED VARCHAR(1) DEFAULT 'N',
    CREATED_ON DATETIME DEFAULT CURRENT_TIMESTAMP,
    UPDATED_ON DATETIME DEFAULT CURRENT_TIMESTAMP,
)
>>
<<
CREATE TABLE AX_PAGE_TEMPLATES(
    TEMPLATE_ID INT IDENTITY(1,1) PRIMARY KEY,
    TITLE VARCHAR(255),
    MODULE VARCHAR(255),
    CONTENT TEXT,
    CREATED_BY VARCHAR(255),
    UPDATED_BY VARCHAR(255),
    IS_DELETED VARCHAR(1) DEFAULT 'N',
    CREATED_ON DATETIME DEFAULT CURRENT_TIMESTAMP,
    UPDATED_ON DATETIME DEFAULT CURRENT_TIMESTAMP
)
>>
<<
INSERT INTO AX_PAGE_TEMPLATES (TITLE,CONTENT,CREATED_BY) values ('basic','{"cc":1,"img":"basic.png","name":"basic","cf":[{"ht":"225px","isResp":true,"wd":"m3 l3","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}}]}','admin')
>>
<<
INSERT INTO AX_PAGE_TEMPLATES (TITLE,CONTENT,CREATED_BY) values ('modern','{"cc":1,"img":"modern.png","name":"modern","cf":[{"ht":"225px","isResp":true,"wd":"m3 l3","ms":"classic","br":"14px","tr":{"p":"top","h":"70px","html":"<span style=\"float:left;font-size:45px;\">#TITLE_ICON#</span><span style=\"text-align: right;padding-top: 14px;position: relative;top: 16px;right: 5px;\">#TITLE_NAME#</span>"}}]}','admin')
>>
<<
INSERT INTO AX_PAGE_TEMPLATES (TITLE,CONTENT,CREATED_BY) values ('mainCard','{"cc":7,"img":"mainCard.png","name":"mainCard","cf":[{"ht":"225px","isResp":true,"wd":"m12 l12","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"225px","isResp":true,"wd":"m4 l4","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"225px","isResp":true,"wd":"m4 l4","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"225px","isResp":true,"wd":"m4 l4","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"225px","isResp":true,"wd":"m4 l4","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"225px","isResp":true,"wd":"m4 l4","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"225px","isResp":true,"wd":"m4 l4","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}}]}','admin')
>>
<<
INSERT INTO AX_PAGE_TEMPLATES (TITLE,CONTENT,CREATED_BY) values ('topaz','{"cc":5,"img":"topaz.png","name":"topaz","cf":[{"ht":"225px","isResp":true,"wd":"m12 l12","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"225px","isResp":true,"wd":"m8 l8","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"225px","isResp":true,"wd":"m4 l4","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"225px","isResp":true,"wd":"m8 l8","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"225px","isResp":true,"wd":"m4 l4","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}}]}','admin')
>>
<<
INSERT INTO AX_PAGE_TEMPLATES (TITLE,CONTENT,CREATED_BY) values ('list','{"cc":1,"img":"list.png","name":"list","cf":[{"ht":"225px","isResp":true,"wd":"m12 l12","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}}]}','admin')
>>
<<
INSERT INTO AX_PAGE_TEMPLATES (TITLE,CONTENT,CREATED_BY) values ('flow','{"cc":3,"img":"flow.png","name":"flow","repeatLastWidget":true,"cf":[{"ht":"500px","isResp":true,"wd":"m6 l6","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"500px","isResp":true,"wd":"m6 l6","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"225px","isResp":true,"wd":"m3 l3","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}}]}','admin')
>>
<<
INSERT INTO AX_PAGE_TEMPLATES (TITLE,CONTENT,CREATED_BY) values ('checkered','{"cc":1,"img":"checkered.png","name":"checkered","cf":[{"ht":"300px","isResp":true,"wd":"m6 l6","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}}]}','admin')
>>
<<
INSERT INTO AX_PAGE_TEMPLATES (TITLE,CONTENT,CREATED_BY) values ('flow main','{"cc":3,"img":"flow_main.png","name":"flow main","repeatLastWidget":true,"cf":[{"ht":"300px","isResp":true,"wd":"m12 l12","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"300px","isResp":true,"wd":"m12 l12","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"225px","isResp":true,"wd":"m3 l3","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}}]}','admin')
>>
<<
INSERT INTO AX_PAGE_TEMPLATES (TITLE,CONTENT,CREATED_BY) values ('random','{"cc":7,"img":"random.png","name":"random","cf":[{"ht":"130px","isResp":true,"wd":"m3 l3","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"130px","isResp":true,"wd":"m3 l3","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"130px","isResp":true,"wd":"m3 l3","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"130px","isResp":true,"wd":"m3 l3","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"300px","isResp":true,"wd":"m6 l6","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"300px","isResp":true,"wd":"m6 l6","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}},{"ht":"200px","isResp":true,"wd":"m12 l12","ms":"classic","tr":{"p":"top","h":"35px","html":"#TITLE_ICON# #TITLE_NAME#"}}]}','admin')
>>
<<
DROP PROCEDURE [axp_pr_page_creation]
>>
<<
CREATE PROCEDURE [axp_pr_page_creation](
        @pname VARCHAR(100),            -- New Page Name/Delete Page Name
        @pcaption VARCHAR(100),     -- New Page Caption
        @ppagetype VARCHAR(100),    -- New Page Type
        @pparentname VARCHAR(100),  -- Parent Name
        @paction VARCHAR(100),      -- Before/After inserting or delete
        @props varchar(100)         -- props
          ) 
AS
BEGIN
        DECLARE @orderno as int 
        DECLARE @level   as int
        DECLARE @sysdate as VARCHAR(100) 
        
        IF @paction <> 'delete'
            BEGIN
                SELECT @pparentname=parent, @orderno= ordno, @level=levelno FROM 
                (
                SELECT 
                        parent, 
                         CASE 
                                WHEN LOWER (@paction) = 'before' THEN ordno 
                                ELSE ordno + 1 
                        END ordno,
                          levelno
                FROM axpages
                WHERE name = @pparentname AND TYPE = 'p'
                
                UNION ALL
                
                SELECT A.NAME, 
                       MAX(B.ORDNO) + 1 AS ORDNO, 
                       A.LEVELNO + 1 AS LEVELNO
                FROM AXPAGES AS A
                        LEFT OUTER JOIN AXPAGES AS B ON A.NAME = B.PARENT
                        WHERE A.NAME = @pparentname AND A.TYPE = 'h'
                        GROUP BY A.NAME, A.LEVELNO
                ) AS s
              
              IF @orderno is null
                 SELECT 'Page not found' as Result
                ELSE
                  BEGIN
                      -- date format 'dd/mm/yyyy hh24:mi:ss'
                    SET @sysdate = convert(varchar, getdate(), 103) +' '+ convert(VARCHAR(10), GETDATE(), 108) 
                                     
                    UPDATE axpages SET ordno = ordno + 1 WHERE ordno >= @orderno;
                    
                    INSERT INTO axpages (name, caption, blobno, visible, TYPE, parent, ordno, levelno, pagetype, props, createdon, updatedon, importedon) 
                     VALUES (@pname, @pcaption, 1, 'T', 'p', @pparentname, @orderno, @level, @ppagetype, @props, @sysdate, @sysdate, @sysdate);
                        
                      SELECT 'Page created' as Result
                  END        
            END
        ELSE
            BEGIN
                SELECT @orderno= ordno FROM axpages WHERE name=@pname AND TYPE='p';
                
                IF @orderno is null
                 SELECT 'Page not found' as Result
                ELSE
                 BEGIN
                    DELETE FROM axpages WHERE name = @pname;
                
                    UPDATE axpages SET ordno = ordno - 1 WHERE ordno >= @orderno;
                
                    SELECT 'Page deleted' as Result
                 END
            END  
END
>>
<<
CREATE PROCEDURE PR_BULK_PAGE_DELETE
AS
BEGIN
    DECLARE @I$NAME varchar(max)
    DECLARE DB_IMPLICIT_CURSOR_FOR_I CURSOR LOCAL FORWARD_ONLY FOR
    
    SELECT AXPAGES.NAME
        FROM AXPAGES
        WHERE AXPAGES.PAGETYPE = 'web' AND AXPAGES.BLOBNO = 1

    OPEN DB_IMPLICIT_CURSOR_FOR_I
    WHILE 1 = 1
        BEGIN
            FETCH DB_IMPLICIT_CURSOR_FOR_I
            INTO @I$NAME

            IF @@FETCH_STATUS = -1
            BREAK

            BEGIN
                BEGIN TRY
                    EXECUTE AXP_PR_PAGE_CREATION
                        @PNAME = @I$NAME,
                        @PCAPTION = NULL,
                        @PPAGETYPE = NULL,
                        @PPARENTNAME = NULL,
                        @PACTION = 'delete',
                        @PROPS = NULL
                END TRY
                BEGIN CATCH
                    BEGIN
                        DECLARE
                        @db_null_statement int
                    END
                END CATCH
            END
        END
    CLOSE DB_IMPLICIT_CURSOR_FOR_I
    DEALLOCATE DB_IMPLICIT_CURSOR_FOR_I
END
>>
<<
exec PR_BULK_PAGE_DELETE
>>
<<
delete from axpages where pagetype='web'
>>
--AxpertWebDev13-10.3.0.0
<<
ALTER table AX_PAGES add IS_DEFAULT VARCHAR(1) DEFAULT 'N'
>>
<<
INSERT INTO ax_page_saved (title,TEMPLATE,module,page_menu,IS_DEFAULT) values('Homepage',1,'PAGE','Head19','Y')
>>
<<
INSERT INTO ax_widget_saved (title,widget_type,content,target,order_by) select title,widget_type,content,target,order_by from ax_homebuild_master
>>
<<
update ax_widget_saved set created_by ='admin', page_id=1
>>
<<
 create unique index  ui_AXCTX1 on AXCTX1 (axcontext,atype)
>>
<<
 Insert into AXCTX1
   (AXCONTEXT, ATYPE)
 Values
   ('GridEdit', 'Property')
>>
<<
Insert into AXPSTRUCTCONFIGPROPS
   (AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, PROPCODE, DUPCHK, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS)
Values
   (1040440000000, 'F', 0, 'admin',
    GETDATE(), 'admin',  GETDATE(), 1,
    1, 'Tstruct Grid edit option',
    'GridEdit', 'configtypeTstruct Grid edit option', 'Tstruct', 'F', 'F', 'T', 'F') 
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Autosplit')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Disablesplit')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Navigation')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'FetchSize')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'General')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Text')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Lds')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'ApplicationTemplate')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'mainPageTemplate')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Trim IView Data')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Excel Export')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'ExportVerticalAlign')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Autocomplete Search Pattern')
>>
<<  
  Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Autosplit')
  >>
  <<
   Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Disablesplit')
   >>
  <<
    Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Navigation')
	>>
  <<
     insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property','FetchSize')
	>>
  <<
     insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property','General')
	>>
  <<
   Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'SaveImage')
	>>
  <<
   Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Autosplit')
	>>
  <<
      Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Disablesplit')
	>>
  <<
     Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Navigation')
	>>
  <<
      Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'FetchSize')
	>>
  <<
     Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'General')
	>>
  <<
     Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Text')
	>>
  <<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Lds')
>>
<<
Insert into AXCTX1
   (AXCONTEXT, ATYPE)
 Values
   ('File Upload Limit', 'Property')
>>
<<
Insert into AXCTX1
   (AXCONTEXT, ATYPE)
 Values
   ('camera option', 'Property')
>>
<<
 Insert into AXCTX1
   (AXCONTEXT, ATYPE)
 Values ('Date format','Property')
>>
<<
commit
>>
<<
Insert into AXPSTRUCTCONFIGPROPS(AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, DUPCHK, PROPCODE, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS)Values(1000550000003, 'F', 0, 'admin',GETDATE(), 'admin', GETDATE(), 1, 1, 'Load forms along with list', 'configtypeLoad forms along with list', 'Autosplit', 'Tstruct', 'F', 'F', 'T', 'F')
>>
<<
Insert into AXPSTRUCTCONFIGPROPS(AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, DUPCHK, PROPCODE, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS)Values(1000550000006, 'F', 0, 'admin', GETDATE(), 'admin', GETDATE(), 1, 1, 'Load reports/lists along with form', 'configtypeLoad reports/lists along with form', 'Autosplit', 'Iview', 'F', 'F', 'F', 'T')
>>
<<
Insert into AXPSTRUCTCONFIGPROPS(AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, DUPCHK, PROPCODE, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS)Values(1000550000009, 'F', 0, 'admin', GETDATE(), 'admin', GETDATE(), 1, 1, 'Disablesplit', 'configtypeDisablesplit', 'Disablesplit', 'All', 'F', 'F', 'T', 'T')
>>
<<
Insert into AXPSTRUCTCONFIGPROPS(AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, DUPCHK, PROPCODE, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS)Values(1000550000012, 'F', 0, 'admin', GETDATE(), 'admin',GETDATE(), 1, 1, 'Open Window mode', 'configtypeOpen Window mode', 'Navigation', 'All', 'T', 'T', 'F', 'F')
>>
<<
Insert into AXPSTRUCTCONFIGPROPS(AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, DUPCHK, PROPCODE, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS) Values(1000550000015, 'F', 0, 'admin', GETDATE(), 'admin',GETDATE(), 1, 1, 'Align Text', 'configtypeText', 'Text', 'All', 'T', 'T', 'F', 'F')
  >>
<<
Insert into AXPSTRUCTCONFIGPROPS(AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, DUPCHK, PROPCODE, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS) Values(1000550000018, 'F', 0, 'admin', GETDATE(), 'admin',GETDATE(), 1, 1, 'Main Page Reload', 'configtypeMain Page Reload', 'General', 'All', 'T', 'T', 'F', 'F')
  >>  
<<
Insert into AXPSTRUCTCONFIGPROPS(AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, DUPCHK, PROPCODE, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS) Values(1000550000021, 'F', 0, 'admin', GETDATE(), 'admin',GETDATE(), 1, 1, 'Change Password', 'configtypeChange Password', 'General', 'All', 'T', 'T', 'F', 'F')
  >>  
  <<
  Insert into AXPSTRUCTCONFIGPROPS(AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, DUPCHK, PROPCODE, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS) Values(1000550000024, 'F', 0, 'admin', GETDATE(), 'admin',GETDATE(), 1, 1, 'Landing Structure', 'configtypeLanding Structure', 'General', 'All', 'T', 'T', 'F', 'F')
  >>
  <<
  Insert into AXPSTRUCTCONFIGPROPS(AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, DUPCHK, PROPCODE, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS) Values(1000550000027, 'F', 0, 'admin', GETDATE(), 'admin',GETDATE(), 1, 1, 'FetchSize', 'configtypeFetchSize', 'FetchSize', 'All', 'T', 'T', 'F', 'F')
  >>
  <<
  Insert into AXPSTRUCTCONFIGPROPS(AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, DUPCHK, PROPCODE, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS) Values(1000550000030, 'F', 0, 'admin', GETDATE(), 'admin',GETDATE(), 1, 1, 'Local Dataset', 'configtypeLocal Dataset', 'Lds', 'All', 'T', 'T', 'F', 'F')
  >>
<<
Insert into AXPSTRUCTCONFIGPROVAL(AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)Values(1000550000004, 1000550000003, 1, 'True')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL(AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)Values(1000550000005, 1000550000003, 2, 'False')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL(AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)Values(1000550000007, 1000550000006, 1, 'True')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL(AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)Values(1000550000008, 1000550000006, 2, 'False')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL(AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)Values(1000550000010, 1000550000009, 1, 'True')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL(AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)Values(1000550000011, 1000550000009, 2, 'False')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL(AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)Values(1000550000013, 1000550000012, 1, 'Default')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL(AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)Values(1000550000014, 1000550000012, 2, 'Popup')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL(AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)Values(1000550000015, 1000550000012, 3, 'Newpage')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL(AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)Values(1000550000016, 1000550000012, 4,'Split')
>>
<<
 insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000003, 1742550000002, 1, 'Disable')
   >>
<< 
insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000004, 1742550000002, 2, 'Enable')
   >>
<< 
 insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000007, 1742550000005, 2, 'iview')
   >>
<<
insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000006, 1742550000005, 1, 'tstruct')
   >>
<< 
insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000010, 1742550000008, 2, '30')
   >>
<<
 insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000028, 1742550000008, 20, '5000')
   >>
<<
 insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000027, 1742550000008, 19, '2000')
   >>
<< 
insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000026, 1742550000008, 18, '1000')
   >>
<<
 insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000009, 1742550000008, 1, '25')
   >>
<<
 insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000029, 1742550000008, 21, 'ALL')
   >>
<<
insert  into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000011, 1742550000008, 3, '35')
   >>
<< 
insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000012, 1742550000008, 4, '40')
   >>
<<
 insert  into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000013, 1742550000008, 5, '45')
   >>
<<
 insert  into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000014, 1742550000008, 6, '50')
   >>
<<
 insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000015, 1742550000008, 7, '55')
   >>
<<
 insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000016, 1742550000008, 8, '60')
   >>
<< 
insert  into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000017, 1742550000008, 9, '65')
   >>
<< 
insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000018, 1742550000008, 10, '70')
   >>
<<
insert  into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000019, 1742550000008, 11, '75')
   >>
<<
 insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000020, 1742550000008, 12, '80')
   >>
<<
insert  into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000021, 1742550000008, 13, '85')
   >>
<<
 insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000022, 1742550000008, 14, '90')
   >>
<<
insert  into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000023, 1742550000008, 15, '95')
   >>
<<
insert  into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000024, 1742550000008, 16, '100')
   >>
<<
insert  into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1742550000025, 1742550000008, 17, '500')
   >>
<<
insert  into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1751880000001, 1751880000000, 1, 'true')
   >>
<< 
insert  into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1751880000002, 1751880000000, 2, 'false')
   >>
<< 
insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1903990000001, 1903990000000, 1, 'Right')
   >>
<<
insert  into AXPSTRUCTCONFIGPROVAL   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES) Values
   (1903990000002, 1903990000000, 2, 'Left')
   >> 
   << 
Insert into AXPSTRUCTCONFIGPROVAL   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES) Values   (1790770000001, 1790770000000, 1, 'true')
   >>
<<
Insert into AXPSTRUCTCONFIGPROVAL    (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES) Values   (1790770000002, 1790770000000, 2, 'false')
   >>
<< 
Insert into axpstructconfigproval (AXPSTRUCTCONFIGPROVALID,AXPSTRUCTCONFIGPROPSID,AXPSTRUCTCONFIGPROVALROW,CONFIGVALUES) values (1040440000001,1040440000000,1,'Inline')
>>
<< 
Insert into axpstructconfigproval (AXPSTRUCTCONFIGPROVALID,AXPSTRUCTCONFIGPROPSID,AXPSTRUCTCONFIGPROVALROW,CONFIGVALUES) values (1040440000002,1040440000000,2,'Popup')
>>



<<
Insert into AXCTX1
   (AXCONTEXT, ATYPE)
 Values
   ('FormLoad', 'Property')
>>
<<
alter table AXPSTRUCTCONFIGPROPS add ALLUSERROLES char(100) 
>>
<<
Insert into AXPSTRUCTCONFIGPROPS
   (AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, PROPCODE, DUPCHK, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS, ALLUSERROLES)
 Values
   (1104220000000, 'F', 0, 'admin', 
    GETDATE(), 'admin',GETDATE(), 1, 
    1, 'FormLoad Cache', 
    'FormLoad', 'configtypeFormLoad Cache', 'Tstruct', 'F', 'F', 'T', 'F', 'T')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1104220000001, 1104220000000, 1, '30 min')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1104220000002, 1104220000000, 2, '1 hour')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1104220000003, 1104220000000, 3, '2 hour')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1104220000004, 1104220000000, 4, '5 hour')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1104220000005, 1104220000000, 5, '10 hour')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1104220000006, 1104220000000, 6, 'None')
>>

 <<
Insert into AXPSTRUCTCONFIGPROPS
   (AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, PROPCODE, DUPCHK, PTYPE, 
   CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS, ALLUSERROLES)
 Values
   (1000440000000, 'F', 0, 'admin', 
    GETDATE(), 'admin',GETDATE(), 1, 
    1, 'Autocomplete Search Pattern', 
    'Autocomplete Search Pattern', 'configtypeAutocomplete Search Pattern', 'Tstruct', 'F', 'F', 'T', 'F', 'T')
>>

<<
   Insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1000440000001, 1000440000000, 1, 'starts with')
   >>   
   <<
Insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1000440000002, 1000440000000, 2, 'contains')
   >> 

<<
insert into axctx1(axcontext,atype) values ('Multi Select','Property')
>>
<<
Insert into AXPSTRUCTCONFIGPROPS
   (AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, PROPCODE, DUPCHK, PTYPE, 
   CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS, ALLUSERROLES)
 Values
   (1008440000004, 'F', 0, 'admin', 
    GETDATE(), 'admin',GETDATE(), 1, 
    1, 'Multi Select Field', 
    'Multi Select', 'configtypeMulti Select Field', 'Tstruct', 'F', 'F', 'T', 'F', 'T')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES 
(1008440000005,1008440000004,1,'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES 
(1008440000006,1008440000004,2,'false')
>>

<<
update axpstructconfig set purpose='Enable/Disable to trim spaces in iview data' where asprops ='Trim IView Data'
>>
<<
update axpstructconfig set purpose='Page Size number of Iview data to be loaded' where asprops ='FetchSize'
>>
<<
update axpstructconfig set purpose='.html templete to customize AxpertWeb Application UI' where asprops ='ApplicationTemplate'
>>
<<
update axpstructconfig set purpose='Google Maps registered API key created by particular project' where asprops ='Google Maps Api Key'
>>
<<
update axpstructconfig set purpose='Enable split on tstruct and load along with listview' where asprops ='Load forms along with list'
>>
<<
update axpstructconfig set purpose='Load template to customize home page widgets' where asprops ='HomePageTemplate'
>>
<<
update axpstructconfig set purpose='Enable/Disable to inline grid or popup grid' where asprops ='Tstruct Grid edit option'
>>
<<
update axpstructconfig set purpose='Enable/Disable change password option for cloud application' where asprops ='Change Password'
>>
<<
update axpstructconfig set purpose='To avoid tstruct formload service call' where asprops ='FormLoad Cache'
>>
<<
update axpstructconfig set purpose='Cloud application can customize tstruct/iview to load the first time and can set the parameters' where asprops ='Main Page Reload'
>>
<<
update axpstructconfig set purpose='Enable split on iview and open/load the tstruct on the first hyperlink' where asprops ='Load reports/lists along with form'
>>
<<
update axpstructconfig set purpose='To disable split to the application or page wise' where asprops ='Disablesplit'
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Resolve Attachment Path')
>>
<<
Insert into AXPSTRUCTCONFIGPROPS
   (AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, PROPCODE, DUPCHK, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS, ALLUSERROLES, CFIELDS)
 Values
   (1072550000003, 'F', 0, 'admin', 
   GETDATE(), 'admin', GETDATE(), 1, 
    1, 'Resolve Attachment Path', 
    'Resolve Attachment Path', 'configtypeResolve Attachment Path', 'Iview', 'F', 'F', 'F', 'T', 'F', 'F')
>>
<<
Insert into AXPSTRUCTCONFIGPROPS
   (AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, PROPCODE, DUPCHK, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS, ALLUSERROLES, CFIELDS)
 Values
   (1072550000000, 'F', 0, 'admin', 
    GETDATE(), 'admin', GETDATE(), 1, 
    1, 'Global Parameter Form', 
    'General', 'configtypeGlobal Parameter Form', 'Tstruct', 'F', 'F', 'T', 'F', 'T', 'F')
>>
<<
Insert into AXPSTRUCTCONFIGPROPS
   (AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, PROPCODE, DUPCHK, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS, ALLUSERROLES, CFIELDS)
 Values
   (1072550000006, 'F', 0, 'admin', 
    GETDATE(), 'admin', GETDATE(), 1, 
    1, 'Google Maps Api Key', 
    'General', 'configtypeGoogle Maps Api Key', 'Tstruct', 'F', 'F', 'T', 'T', 'F', 'F')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1072550000001, 1072550000000, 1, 'hide')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1072550000002, 1072550000000, 2, 'show')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1072550000004, 1072550000003, 1, 'false')
>>
<<
Insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1072550000005, 1072550000003, 2, 'true')
>>
<<
ALTER TABLE AXUSERS ADD singleloginkey VARCHAR(50)
>>
<<
ALTER TABLE AX_PAGE_SAVED ADD WIDGET_GROUPS Varchar(1)
>>
<<
ALTER TABLE AX_PAGES ADD WIDGET_GROUPS Varchar(1)
>>
<<
update axpstructconfigprops set description= configprops where description is null or description=''
>>
<<
 insert into axctx1 (axcontext,atype) values ('Custom JavaScript','Property')
>>
<<
 insert into axctx1 (axcontext,atype) values ('Custom CSS','Property')
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid,cancel,sourceid,mapname,username,modifiedon,createdby,createdon,wkid,app_level,app_desc,app_slevel,cancelremarks,wfroles,configprops,propcode,dupchk,context,ptype,caction,chyperlink,alltstructs,alliviews,alluserroles,cfields,description) VALUES (1235440000043,'F',0,NULL,'superadmin',getdate(),'admin',getdate(),NULL,1,1,NULL,NULL,NULL,'Custom JavaScript','Custom JavaScript','configtypeCustom JavaScript','','All','F','F','T','T','F','F','Reports:
Use this property to attach custom javascript to Reports/forms. Set this property value to "true" for a selected report. If this property is set to true, the custom javascript file for Reposts should be saved into the web root\<ProjectName>\report\js folder. The file name should <reportName>.js. In case this property is set to true for all reports instead of a selected report, the file name should be custom.js

Tstructs:
Use this property to attach custom javascript to TStructs. Set this property value to "True" for a selected form. If this property is set to true, the custom javascript file should be saved into the web root\<ProjectName>\tstructs\js folder. The file name should <tstructname>.js. In case this property is set to true for all forms instead of a selected form, the file name should be custom.js.')
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid,cancel,sourceid,mapname,username,modifiedon,createdby,createdon,wkid,app_level,app_desc,app_slevel,cancelremarks,wfroles,configprops,propcode,dupchk,context,ptype,caction,chyperlink,alltstructs,alliviews,alluserroles,cfields,description) VALUES (1235660000010,'F',0,NULL,'superadmin',getdate(),'admin',getdate(),NULL,1,1,NULL,NULL,NULL,'Custom CSS','Custom CSS','configtypeCustom CSS','','All','F','F','T','T','F','F','Reports:
Use this property to attach custom CSS to Reports. Set this property value to "True" for a selected report. If for report this property is set to true, the custom CSS file should be saved into the web root\<ProjectName>\report\js folder. The file name should <reportName>.CSS. In case this property is set to true for all reports instead of a selected report, the file name should be custom.CSS.

Tstructs:
Use this property to attach custom CSS to TStructs. Set this property value to "True" for a selected form. If this property is set to true, the custom CSS file should be saved into the web root\<ProjectName>\tstructs\js folder. The file name should <tstructname>.CSS. In case this property is set to true for all forms instead of a selected form, the file name should be custom.CSS.
')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1235440000044,1235440000043,1,'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1235440000045,1235440000043,2,'false')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1235660000011,1235660000010,1,'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1235660000012,1235660000010,2,'false')
>>
<<
insert into axctx1 (axcontext,atype) values('Auto Save Draft','Property')
>>
<<
insert into axctx1 (axcontext,atype) values('Grid Scrollbar','Property')
>>
<<
insert into axctx1 (axcontext,atype) values('Show keyboard in Hybrid App','Property')
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid,cancel,sourceid,mapname,username,modifiedon,createdby,createdon,wkid,app_level,app_desc,app_slevel,cancelremarks,wfroles,configprops,propcode,dupchk,context,ptype,caction,chyperlink,alltstructs,alliviews,alluserroles,cfields,description) VALUES (1355440000009,'F',0,NULL,'admin',GETDATE(),'admin',GETDATE(),NULL,1,1,NULL,NULL,NULL,'Grid Scrollbar','Grid Scrollbar','configtypeGrid Scrollbar',NULL,'Tstruct','F','F','T','F','F','F','If key is set to true,then if grid dc is there for the tstruct,then horizontal scroll bar will be fixed at the bottom of the page.')
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid,cancel,sourceid,mapname,username,modifiedon,createdby,createdon,wkid,app_level,app_desc,app_slevel,cancelremarks,wfroles,configprops,propcode,dupchk,context,ptype,caction,chyperlink,alltstructs,alliviews,alluserroles,cfields,description) VALUES (1355440000006,'F',0,NULL,'admin',GETDATE(),'admin',GETDATE(),NULL,1,1,NULL,NULL,NULL,'Auto Save Draft','Auto Save Draft','configtypeAuto Save Draft',NULL,'Tstruct','F','F','T','F','F','F','If key is set to true and time in millisecs(for ex for 60 secs give 60000 . Note: default time will be 120 seconds/2 minutes if no time is set) then on loading tstruct,it will check if unsaved data is there, if unsaved data  exists it will throw a popup with yes /no buttons.If yes, it will load the unsaved data else it will load a new tstruct.If new tstruct is opened for which key exists,then only if any field is changed,it will push data in redis after the mentioned time  in developer options at regular intervals.')
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid,cancel,sourceid,mapname,username,modifiedon,createdby,createdon,wkid,app_level,app_desc,app_slevel,cancelremarks,wfroles,configprops,propcode,dupchk,context,ptype,caction,chyperlink,alltstructs,alliviews,alluserroles,cfields,description) VALUES (1355440000003,'F',0,NULL,'admin',GETDATE(),'admin',GETDATE(),NULL,1,1,NULL,NULL,NULL,'Show keyboard in Hybrid App','Show keyboard in Hybrid App','configtypeShow keyboard in Hybrid App',NULL,'Tstruct','F','F','T','F','F','F','An enhancement to make an intuitive UI in Axpert Hybrid App i.e., 
-- based on the "Show keyboard in Hybrid App" key value, user can enable or disable the keyboard for autocomplete fields in tstruct level.
-- By default, value is set as true which makes no difference in the existing feature/functionality.
-- If set false,  keyboard is hidden/disabled along with the drop-down and clear icons. On single click of the field, drop down appears to choose the desired value.
')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1355440000004,1355440000003,1,'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1355440000005,1355440000003,2,'false')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1355440000007,1355440000006,1,'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1355440000008,1355440000006,2,'false')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1355440000010,1355440000009,1,'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1355440000011,1355440000009,2,'false')
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid,cancel,sourceid,mapname,username,modifiedon,createdby,createdon,wkid,app_level,app_desc,app_slevel,cancelremarks,wfroles,configprops,propcode,dupchk,context,ptype,caction,chyperlink,alltstructs,alliviews,alluserroles,cfields,description) VALUES 
(1635440000037,'F',0,NULL,'admin',GETDATE(),'admin',GETDATE(),NULL,1,1,NULL,NULL,NULL,'Enforced Strong Password Policy','General','configtypeEnforced Strong Password Policy',NULL,'Common','F','F','F','F','F','F','If key is set to true,Strong Password Policy will work.Details for Enforced Strong Password Policy: Password should be alphanumeric, contains one UpperCharacter, one LowerCharacter with atleast one special character.It will check the following condition if key set to true and if password entered is not matching the condition,then it will throw error.')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES 
(1635440000038,1635440000037,1,'true')
>>

<< 
INSERT INTO axctx1 (axcontext,atype) values ('Mobile Reports as Table','Property') 
>>
<< 
INSERT INTO axpstructconfigprops (axpstructconfigpropsid,cancel,sourceid,mapname,username,modifiedon,createdby,createdon,wkid,app_level,app_desc,app_slevel,cancelremarks,wfroles,configprops,propcode,dupchk,context,ptype,caction,chyperlink,alltstructs,alliviews,alluserroles,cfields,description) VALUES (1984880000036,'F',0,NULL,'superadmin',GETDATE(),'superadmin',GETDATE(),NULL,1,1,NULL,NULL,NULL,'Notification Time Interval','General','configtypeNotification Time Interval',NULL,'All','F','F','T','T','F','F','Notification feature can be enabled at Application level by adding Developer Option "Notification Time Interval" , with values in minutes for time intervals as 1, 2, 3 , 4 etc. Once this key is added, long running web services/backend scheduled jobs completion can be notified to the user with given time intervals, so that user would be able to do other operations during long running web services/backend jobs.') 
>>
<< 
INSERT INTO axpstructconfigprops (axpstructconfigpropsid,cancel,sourceid,mapname,username,modifiedon,createdby,createdon,wkid,app_level,app_desc,app_slevel,cancelremarks,wfroles,configprops,propcode,dupchk,context,ptype,caction,chyperlink,alltstructs,alliviews,alluserroles,cfields,description) VALUES (1984440000004,'F',0,NULL,'superadmin',GETDATE(),'superadmin',GETDATE(),NULL,1,1,NULL,NULL,NULL,'User Manual','General','configtypeUser Manual',NULL,'All','F','F','T','T','F','F','User can able to access the files through web application which is saved in local folder through User Manual option (located in right sidebar menu)') 
>>
<<
 INSERT INTO axpstructconfigprops (axpstructconfigpropsid,cancel,sourceid,mapname,username,modifiedon,createdby,createdon,wkid,app_level,app_desc,app_slevel,cancelremarks,wfroles,configprops,propcode,dupchk,context,ptype,caction,chyperlink,alltstructs,alliviews,alluserroles,cfields,description) VALUES (1984220000001,'F',0,NULL,'superadmin',GETDATE(),'superadmin',GETDATE(),NULL,1,1,NULL,NULL,NULL,'Mobile Reports as Table','Mobile Reports as Table','configtypeMobile Reports as Table',NULL,'All','F','F','T','T','F','F','Administrator can enable tabular view in mobile instead of cards view') 
>>


<< 
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1984220000002,1984220000001,1,'true') 
>>
<< 
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1984220000003,1984220000001,2,'false') 
>>
<< 
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1984440000005,1984440000004,1,'true') 
>>
<< 
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1984440000006,1984440000004,2,'false') 
>>
<< 
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1984880000037,1984880000036,1,'1') 
>>
<< 
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1984880000038,1984880000036,2,'3') 
>>
<< 
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1984880000039,1984880000036,3,'5') 
>>
<< 
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1984880000040,1984880000036,4,'10') 
>>
<< 
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1984880000041,1984880000036,5,'30') 
>>
<<
create table Axp_TransCheck(sessionid char(50))
>>

<<
INSERT INTO axctx1 (axcontext,atype) values ('WebService Timeout','Property') 
>>
<<
Insert into AXPSTRUCTCONFIGPROPS
   (AXPSTRUCTCONFIGPROPSID, CANCEL, SOURCEID, USERNAME, MODIFIEDON, CREATEDBY, CREATEDON, APP_LEVEL, APP_DESC, CONFIGPROPS, PROPCODE, DUPCHK, PTYPE, CACTION, CHYPERLINK, ALLTSTRUCTS, ALLIVIEWS, ALLUSERROLES, CFIELDS, DESCRIPTION)
 Values
   (1000330000005, 'F', 0, 'admin', 
    GETDATE(), 'admin', GETDATE(), 1, 
    1, 'WebService Timeout', 
    'WebService Timeout', 'configtypeWebService Timeout', 'All', 'F', 'F', 'T', 'T', 'F', 'F', 'WebService Timeout')
>>    
<<  
    Insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1000330000006, 1000330000005, 1, '100000')
>>
<<   
Insert into AXPSTRUCTCONFIGPROVAL
   (AXPSTRUCTCONFIGPROVALID, AXPSTRUCTCONFIGPROPSID, AXPSTRUCTCONFIGPROVALROW, CONFIGVALUES)
 Values
   (1525110003964, 1000330000005, 2, '1000000')
>>
<<
INSERT INTO axctx1 (axcontext,atype) values ('Iview Button Style','Property') 
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid,cancel,sourceid,mapname,username,modifiedon,createdby,createdon,wkid,app_level,app_desc,app_slevel,cancelremarks,wfroles,configprops,propcode,dupchk,context,ptype,caction,chyperlink,alltstructs,alliviews,alluserroles,cfields,description) VALUES 
(1226220000004,'F',0,NULL,'superadmin','2020-08-26','superadmin','2020-08-26',NULL,1,1,NULL,NULL,NULL,'Iview Button Style','Iview Button Style','configtypeIview Button Style','','Iview','F','F','F','T','F','F','New Iview buttons UI can be switched as Modern(Google like UI) / Classic(Classic Bootstrap like UI) . Product default Iview Button UI is  "Modern" Style.')
>>
<<
INSERT INTO AXPSTRUCTCONFIGPROVAL (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) 
VALUES (1226220000005,1226220000004,1,'Modern')
>>
<<
INSERT INTO AXPSTRUCTCONFIGPROVAL (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) 
VALUES (1226220000006,1226220000004,2,'Classic')
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid,cancel,sourceid,mapname,username,modifiedon,createdby,createdon,wkid,app_level,app_desc,app_slevel,cancelremarks,wfroles,configprops,propcode,dupchk,context,ptype,caction,chyperlink,alltstructs,alliviews,alluserroles,cfields,description) 
VALUES (1251990000026,'F',0,NULL,'superadmin',GETDATE(),'superadmin',GETDATE(),NULL,1,1,NULL,NULL,NULL,'Show Image Widget Action Button','General','configtypeShow Image Widget Action Button',NULL,'Common','F','F','T','T','T','F','The SmartView''s columns template can be changed to achieve desired UI and Actions')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1251990000027,1251990000026,1,'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1251990000028,1251990000026,2,'false')
>> 
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid,cancel,sourceid,mapname,username,modifiedon,createdby,createdon,wkid,app_level,app_desc,app_slevel,cancelremarks,wfroles,configprops,propcode,dupchk,context,ptype,caction,chyperlink,alltstructs,alliviews,alluserroles,cfields,description) VALUES (1420440000004,'F',0,NULL,'superadmin',getdate(),'superadmin',getdate(),NULL,1,1,NULL,NULL,NULL,'Show Application Menu on Login','General','configtypeShow Application Menu on Login',NULL,'All','F','F','T','T','F','F','Application menu can be shown/hidden by setting this Developer Option.')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1420440000005,1420440000004,1,'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid,axpstructconfigpropsid,axpstructconfigprovalrow,configvalues) VALUES (1420440000006,1420440000004,2,'false')
>>
<<
update axpstructconfigprops set ptype='All',alltstructs='T',alliviews='T' WHERE PTYPE='Iview' and configprops<>'Load reports/lists along with form'
>>
<<
CREATE VIEW vw_cards_calendar_data
AS 
SELECT DISTINCT a.uname,
    a.axcalendarid,
    a.eventname,
    a.sendername,
    a.messagetext,
    a.eventtype,
    a.startdate,
    isnull(a.axptm_starttime, '00:00') AS axptm_starttime,
    a.enddate,
        CASE
            WHEN isnull(a.axptm_endtime, '00:00') = '00:00' THEN '23:59'
            ELSE a.axptm_endtime
        END AS axptm_endtime,
    a.location,
    a.status
   FROM axcalendar a
  WHERE a.cancel = 'F' AND a.parenteventid > 0
UNION ALL
 SELECT DISTINCT a.sendername AS uname,
    a.axcalendarid,
    a.eventname,
    a.sendername,
    a.messagetext,
    a.eventtype,
    a.startdate,
isnull(a.axptm_starttime, '00:00') AS axptm_starttime,
        CASE
            WHEN a.recurring IS NULL THEN a.enddate
            ELSE a.startdate
        END AS enddate,
        CASE
            WHEN isnull(a.axptm_endtime, '00:00') = '00:00'THEN '23:59'
            ELSE a.axptm_endtime
        END AS axptm_endtime,
    a.location,
    a.status
   FROM axcalendar a
  WHERE a.cancel= 'F' AND a.parenteventid = 0;
>>
<<
INSERT INTO AXPDEF_AXPERTPROPS (axpdef_axpertpropsid, Cancel, Sourceid, MapName, UserName, Modifiedon, CreatedBy, CreatedOn, Wkid, App_level, App_desc, App_slevel, CancelRemarks, WFRoles, smtphost, smtpport, smtpuser, smtppwd, axpsiteno, amtinmillions, currseperator, lastlogin, autogen, customfrom, customto, loginattempt, pwdexp, pwdchange, pwdminchar, pwdreuse, pwdalphanum, pwdencrypt, pwdmaxchar, pwdcapchar, pwdsmallchar, pwdnumchar, pwdsplchar, otpauth, otpchars, otpexpiry, emailsubject, emailbody, smscontent, onlysso, sso_windows, sso_saml, sso_office365, sso_okta, sso_google, sso_facebook, sso_openid, tbl_windows, tbl_saml, tbl_okta, tbl_office365, tbl_google, tbl_facebook, tbl_openid, mob_citizenuser, mob_geofencing, mob_geotag, mob_fingerauth, mob_faceauth, mob_forcelogin, mob_forceloginusers) 
VALUES(1, N'F', 0, NULL, N'admin', '2026-01-27 06:25:14.000', N'admin', '2026-01-27 06:04:07.413', NULL, 1, 1, NULL, NULL, NULL, NULL, 0, NULL, NULL, 0, N'F', N'F', N'F', N'F', NULL, NULL, 0, 0, 0, 2, 0, N'F', N'F', 30, 0, 0, 0, 0, N'F', NULL, NULL, NULL, NULL, NULL, NULL, N'F', NULL, N'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, N'F', N'F', N'F', N'F', N'F', N'F', N'F')
>>
<<
CREATE TABLE AXPDEF_LANGUAGE (
	axpdef_languageid numeric(16,0) NOT NULL,
	Cancel char(1) NULL,
	Sourceid numeric(16,0) NULL,
	MapName varchar(20) NULL,
	UserName varchar(50) NULL,
	Modifiedon datetime NULL,
	CreatedBy varchar(50) NULL,
	CreatedOn datetime NULL,
	Wkid varchar(15) NULL,
	App_level numeric(3,0) NULL,
	App_desc numeric(1,0) NULL,
	App_slevel numeric(3,0) NULL,
	CancelRemarks varchar(150) NULL,
	WFRoles varchar(250) NULL,
	fontcharset varchar(25) NULL,
	fontname varchar(200) NULL,
	fontsize varchar(10) NULL,
	[language] varchar(100) NULL,
	exportto varchar(1000) NULL,
	tstructcap varchar(4000) NULL,
	tstructnames varchar(4000) NULL,
	iviewcap varchar(4000) NULL,
	iviewnames varchar(4000) NULL,
	uploadfiletype varchar(20) NULL,
	exportfiles varchar(1000) NULL,
	expalltstruct varchar(10) NULL,
	expalliview varchar(10) NULL,
	CONSTRAINT AGLaxpdef_languageid PRIMARY KEY (axpdef_languageid)
)
>>
<<
CREATE TABLE axpformlbls (
  transid varchar(5) NULL,
  lblname varchar(50) NULL,
  lblcaption varchar(4000) NULL
)
>>
<<
alter table axfastlink add istemplate varchar(1)
>>
<<
update axfastlink set istemplate='T' where caption='defaulttemplate'
>>
<<
ALTER TABLE axusers ADD pwdauth varchar(1)
>>
<<
ALTER TABLE axusers ADD otpauth varchar(1)
>>
<<
update axusers set pwdauth='T',otpauth='F'
>>
<<
INSERT INTO axpdef_axcalendar_event (axpdef_axcalendar_eventid,Cancel,Sourceid,MapName,UserName,Modifiedon,CreatedBy,CreatedOn,Wkid,App_level,App_desc,App_slevel,CancelRemarks,WFRoles,eventname,eventcolor) VALUES
(1010550000000,N'F',0,NULL,N'admin','2022-12-16 09:40:30.000',N'admin','2022-12-16 09:40:30.000',NULL,1,1,0,NULL,NULL,N'Meeting',N'cerise')
>>
<<
INSERT INTO axpdef_axcalendar_event (axpdef_axcalendar_eventid,Cancel,Sourceid,MapName,UserName,Modifiedon,CreatedBy,CreatedOn,Wkid,App_level,App_desc,App_slevel,CancelRemarks,WFRoles,eventname,eventcolor) VALUES
(1010550000001,N'F',0,NULL,N'admin','2022-12-16 09:40:37.000',N'admin','2022-12-16 09:40:37.000',NULL,1,1,0,NULL,NULL,N'Personal',N'blue')
>>
<<
INSERT INTO axpdef_axcalendar_event (axpdef_axcalendar_eventid,Cancel,Sourceid,MapName,UserName,Modifiedon,CreatedBy,CreatedOn,Wkid,App_level,App_desc,App_slevel,CancelRemarks,WFRoles,eventname,eventcolor) VALUES
(1010550000002,N'F',0,NULL,N'admin','2022-12-16 09:40:43.000',N'admin','2022-12-16 09:40:43.000',NULL,1,1,0,NULL,NULL,N'Online meet',N'Fuchsia Blue')
>>
<<
INSERT INTO axpdef_axcalendar_event (axpdef_axcalendar_eventid,Cancel,Sourceid,MapName,UserName,Modifiedon,CreatedBy,CreatedOn,Wkid,App_level,App_desc,App_slevel,CancelRemarks,WFRoles,eventname,eventcolor) VALUES	 
(1010550000003,N'F',0,NULL,N'admin','2022-12-16 09:40:49.000',N'admin','2022-12-16 09:40:49.000',NULL,1,1,0,NULL,NULL,N'Leave',N'Red')
>>
<<
ALTER TABLE axuseraccess ALTER COLUMN rname varchar(50) NOT NULL
>>
<<
alter table axpertlog add calldetails varchar(2000) 
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Disablesplit')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Navigation')
>>
<<
insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property','FetchSize')
>>
<<
insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property','General')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'SaveImage')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'ApplicationTemplate')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'mainPageTemplate')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'WebService Timeout')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Trim IView Data')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Excel Export')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'ExportVerticalAlign')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Autocomplete Search Pattern')
>>
<<
Insert into AXCTX1(AXCONTEXT, ATYPE) Values ('File Upload Limit', 'Property')
>>
<<
Insert into AXCTX1(AXCONTEXT, ATYPE) Values   ('camera option', 'Property')
>>
<<
 Insert into AXCTX1(AXCONTEXT, ATYPE) Values ('Date format','Property')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Text')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Lds')
>>
<<
Insert into AXCTX1(AXCONTEXT, ATYPE) Values('GridEdit', 'Property')
>>
<<
Insert into AXCTX1   (AXCONTEXT, ATYPE) Values ('FormLoad', 'Property')
>>
<<
insert into axctx1(axcontext,atype) values ('Multi Select','Property')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Resolve Attachment Path')
>>
<<
insert into axctx1 (axcontext,atype) values ('Custom JavaScript','Property')
>>
<<
insert into axctx1 (axcontext,atype) values ('Custom CSS','Property')
>>
<<
insert into axctx1 (axcontext,atype) values('Auto Save Draft','Property')
>>
<<
insert into axctx1 (axcontext,atype) values('Show keyboard in Hybrid App','Property')
>>
<< 
INSERT INTO axctx1 (axcontext,atype) values ('Mobile Reports as Table','Property') 
>>
<<
INSERT INTO axctx1 (axcontext,atype) values ('Iview Button Style','Property') 
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'icon path')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Tstruct Button Style')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Apply Mobile UI')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Split Ratio')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Iview Retain Parameters On Next Load')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Fixed Header for Grid')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Iview Responsive Column Width')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Not Fill Dependent Fields')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Fill Dependent Fields')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Striped Reports UI')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'HomePageTemplate')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'CompressedMode')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Upload file types')
>>
<<
Insert into AXCTX1(ATYPE, AXCONTEXT)Values('Property', 'Autosplit')
>>
<<
insert into axctx1(atype,axcontext) values('Property','Google Maps Zoom')
>>
<<
insert into axctx1(atype,axcontext) values('Property','Iview Session Caching');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1000220000000, 'F', 0, NULL, 'admin', '2022-12-26 14:22:37.000', 'admin', '2019-11-15 15:17:24.000', NULL, 1, 1, NULL, NULL, NULL, 'ExportVerticalAlign', 'ExportVerticalAlign', 'allows you to set excel row data vertical aligned', 'configtypeExportVerticalAlign', '', 'Iview', 'F', 'F', 'T', 'F', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1000220000004, 'F', 0, NULL, 'admin', '2022-12-26 14:24:57.000', 'admin', '2019-11-15 15:17:43.000', NULL, 1, 1, NULL, NULL, NULL, 'Excel Export', 'Excel Export', 'enable Excel button in reports to download the report data into excel format', 'configtypeExcel Export', '', 'Iview', 'F', 'F', 'T', 'F', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1000220000007, 'F', 0, NULL, 'admin', '2022-12-26 14:26:51.000', 'admin', '2019-11-15 15:17:58.000', NULL, 1, 1, NULL, NULL, NULL, 'Trim IView Data', 'Trim IView Data', 'Enable/Disable to trim spaces in iview data', 'configtypeTrim IView Data', '', 'Iview', 'F', 'F', 'T', 'F', 'T', '');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1000220000012, 'F', 0, NULL, 'admin', '2022-12-26 14:28:28.000', 'admin', '2019-11-15 15:18:35.000', NULL, 1, 1, NULL, NULL, NULL, 'ApplicationCompressedMode', 'General', 'This property will allow you to fit the page on screen, it will disable the card layout of the application.', 'configtypeApplicationCompressedMode', '', 'Common', 'F', 'F', 'F', 'F', 'F', '');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1000220000015, 'F', 0, NULL, 'admin', '2022-12-26 14:31:10.000', 'admin', '2019-11-15 15:18:53.000', NULL, 1, 1, NULL, NULL, NULL, 'ApplicationTemplate', 'General', 'Using this property you can change the application layout template.', 'configtypeApplicationTemplate', '', 'All', 'F', 'F', 'F', 'F', 'F', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1000550000003, 'F', 0, NULL, 'admin', '2018-12-27 00:00:00.000', 'admin', '2018-12-27 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Load forms along with list', 'Autosplit', 'Enable split on tstruct and load along with listview', 'configtypeLoad forms along with list', NULL, 'Tstruct', 'F', 'F', NULL, 'T', 'F', NULL);
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1000550000006, 'F', 0, NULL, 'admin', '2018-12-27 00:00:00.000', 'admin', '2018-12-27 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Load reports/lists along with form', 'Autosplit', 'Enable split on iview and open/load the tstruct on the first hyperlink', 'configtypeLoad reports/lists along with form', NULL, 'Iview', 'F', 'F', NULL, 'F', 'T', NULL);
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1000550000009, 'F', 0, NULL, 'admin', '2018-12-27 00:00:00.000', 'admin', '2018-12-27 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Disablesplit', 'Disablesplit', 'To disable split to the application or page wise', 'configtypeDisablesplit', NULL, 'All', 'F', 'F', NULL, 'T', 'T', NULL);
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1000550000012, 'F', 0, NULL, 'admin', '2018-12-27 00:00:00.000', 'admin', '2018-12-27 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Open Window mode', 'Navigation', 'Open Window mode', 'configtypeOpen Window mode', NULL, 'All', 'T', 'T', NULL, 'F', 'F', NULL);
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1040440000000, 'F', 0, NULL, 'admin', '2019-04-10 00:00:00.000', 'admin', '2019-04-10 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Tstruct Grid edit option', 'GridEdit', 'Enable/Disable to inline grid or popup grid', 'configtypeTstruct Grid edit option', NULL, 'Tstruct', 'F', 'F', NULL, 'T', 'F', NULL);
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1903990000000, 'F', 0, NULL, 'admin', '2019-01-23 00:00:00.000', 'admin', '2019-01-23 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Align Text', 'Text', 'Align Text', 'configtypeAlign Text', NULL, 'Tstruct', 'F', 'F', NULL, 'T', 'T', NULL);
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1751880000000, 'F', 0, NULL, 'admin', '2019-04-05 00:00:00.000', 'admin', '2019-04-05 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Main Page Reload', 'General', 'Main Page Reload', 'configtypeMain Page Reload', NULL, 'Tstruct', 'F', 'F', NULL, 'T', 'T', NULL);
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1742550000002, 'F', 0, NULL, 'admin', '2019-04-03 00:00:00.000', 'admin', '2019-04-03 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Change Password', 'General', 'Enable/Disable change password option for cloud application', 'configtypeChange Password', NULL, 'All', 'F', 'F', NULL, 'T', 'T', NULL);
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1000440000000, 'F', 0, NULL, 'admin', '2018-12-27 00:00:00.000', 'admin', '2018-12-27 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Autocomplete Search Pattern', 'Autocomplete Search Pattern', 'Autocomplete Search Pattern', 'configtypeAutocomplete Search Pattern', NULL, 'Tstruct', 'F', 'F', NULL, 'T', 'F', NULL);
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1742550000008, 'F', 0, NULL, 'admin', '2019-04-03 00:00:00.000', 'admin', '2019-04-03 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'FetchSize', 'FetchSize', 'Page Size number of Iview data to be loaded', 'configtypeFetchSize', NULL, 'All', 'F', 'F', NULL, 'T', 'T', NULL);
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1790770000000, 'F', 0, NULL, 'pandi', '2019-04-12 00:00:00.000', 'pandi', '2019-04-12 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Local Dataset', 'Lds', 'Local Dataset', 'configtypeLocal Dataset', NULL, 'Tstruct', 'F', 'F', NULL, 'T', 'T', NULL);
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1104220000000, 'F', 0, NULL, 'admin', '2019-02-25 00:00:00.000', 'admin', '2019-02-25 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'FormLoad Cache', 'FormLoad', 'To avoid tstruct formload service call', 'configtypeFormLoad Cache', NULL, 'Tstruct', 'F', 'F', NULL, 'T', 'F', 'T');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1657440000021, 'F', 0, NULL, 'admin', '2019-06-03 00:00:00.000', 'admin', '2019-06-03 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Save Image in DB', 'SaveImage', 'Save Image in DB', 'configtypeSave Image in DB', NULL, 'Tstruct', 'F', 'F', 'T', 'T', 'F', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(2680010000000, 'F', 0, NULL, 'admin', '2019-06-13 00:00:00.000', 'admin', '2019-06-13 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Date Format', 'General', 'Date Format', 'configtypeDate Format', NULL, 'All', 'F', 'F', 'F', 'T', 'T', 'T');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(2175770000001, 'F', 0, NULL, 'admin', '2019-07-04 00:00:00.000', 'admin', '2019-06-29 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Hide Camera Option', 'camera option', 'Hide Camera Option', 'configtypeHide Camera Option', NULL, 'Tstruct', 'F', 'F', 'F', 'T', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(2037880000001, 'F', 0, NULL, 'admin', '2019-07-05 00:00:00.000', 'admin', '2019-07-05 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'File upload limit', 'File Upload Limit', 'File upload limit', 'configtypeFile upload limit', NULL, 'Tstruct', 'F', 'F', 'F', 'T', 'F', 'T');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1008440000004, 'F', 0, NULL, 'admin', '2019-12-27 17:34:22.000', 'admin', '2019-12-27 17:34:22.000', NULL, 1, 1, NULL, NULL, NULL, 'Multi Select Field', 'Multi Select', 'Multi Select Field', 'configtypeMulti Select Field', NULL, 'Tstruct', 'F', 'F', 'T', 'T', 'F', 'T');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1072550000000, 'F', 0, NULL, 'superadmin', '2020-01-31 00:00:00.000', 'superadmin', '2020-01-31 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Global Parameter Form', 'General', 'Global Parameter Form', 'configtypeGlobal Parameter Form', NULL, 'Tstruct', 'F', 'F', 'F', 'T', 'F', 'T');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1072550000006, 'F', 0, NULL, 'superadmin', '2020-01-31 00:00:00.000', 'superadmin', '2020-01-31 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Google Maps Api Key', 'General', 'Google Maps Api Key', 'configtypeGoogle Maps Api Key', NULL, 'Tstruct', 'F', 'F', 'F', 'T', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1235440000043, 'F', 0, NULL, 'superadmin', '2022-12-25 22:29:56.484', 'admin', '2022-12-25 22:29:56.484', NULL, 1, 1, NULL, NULL, NULL, 'Custom JavaScript', 'Custom JavaScript', 'Reports:
Use this property to attach custom javascript to Reports/forms. Set this property value to "true" for a selected report. If this property is set to true, the custom javascript file for Reposts should be saved into the web root\<ProjectName>\report\js folder. The file name should <reportName>.js. In case this property is set to true for all reports instead of a selected report, the file name should be custom.js

Tstructs:
Use this property to attach custom javascript to TStructs. Set this property value to "True" for a selected form. If this property is set to true, the custom javascript file should be saved into the web root\<ProjectName>\tstructs\js folder. The file name should <tstructname>.js. In case this property is set to true for all forms instead of a selected form, the file name should be custom.js.', 'configtypeCustom JavaScript', '', 'All', 'F', 'F', 'F', 'T', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1235660000010, 'F', 0, NULL, 'superadmin', '2022-12-25 22:29:56.485', 'admin', '2022-12-25 22:29:56.485', NULL, 1, 1, NULL, NULL, NULL, 'Custom CSS', 'Custom CSS', 'Reports:
Use this property to attach custom CSS to Reports. Set this property value to "True" for a selected report. If for report this property is set to true, the custom CSS file should be saved into the web root\<ProjectName>\report\js folder. The file name should <reportName>.CSS. In case this property is set to true for all reports instead of a selected report, the file name should be custom.CSS.

Tstructs:
Use this property to attach custom CSS to TStructs. Set this property value to "True" for a selected form. If this property is set to true, the custom CSS file should be saved into the web root\<ProjectName>\tstructs\js folder. The file name should <tstructname>.CSS. In case this property is set to true for all forms instead of a selected form, the file name should be custom.CSS.
', 'configtypeCustom CSS', '', 'All', 'F', 'F', 'F', 'T', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1355440000006, 'F', 0, NULL, 'admin', '2022-12-25 22:29:56.490', 'admin', '2022-12-25 22:29:56.490', NULL, 1, 1, NULL, NULL, NULL, 'Auto Save Draft', 'Auto Save Draft', 'If key is set to true and time in millisecs(for ex for 60 secs give 60000 . Note: default time will be 120 seconds/2 minutes if no time is set) then on loading tstruct,it will check if unsaved data is there, if unsaved data  exists it will throw a popup with yes /no buttons.If yes, it will load the unsaved data else it will load a new tstruct.If new tstruct is opened for which key exists,then only if any field is changed,it will push data in redis after the mentioned time  in developer options at regular intervals.', 'configtypeAuto Save Draft', NULL, 'Tstruct', 'F', 'F', 'F', 'T', 'F', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1355440000003, 'F', 0, NULL, 'admin', '2022-12-25 22:29:56.491', 'admin', '2022-12-25 22:29:56.491', NULL, 1, 1, NULL, NULL, NULL, 'Show keyboard in Hybrid App', 'Show keyboard in Hybrid App', 'An enhancement to make an intuitive UI in Axpert Hybrid App i.e., 
-- based on the "Show keyboard in Hybrid App" key value, user can enable or disable the keyboard for autocomplete fields in tstruct level.
-- By default, value is set as true which makes no difference in the existing feature/functionality.
-- If set false,  keyboard is hidden/disabled along with the drop-down and clear icons. On single click of the field, drop down appears to choose the desired value.
', 'configtypeShow keyboard in Hybrid App', NULL, 'Tstruct', 'F', 'F', 'F', 'T', 'F', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1635440000037, 'F', 0, NULL, 'admin', '2022-12-25 22:29:56.517', 'admin', '2022-12-25 22:29:56.517', NULL, 1, 1, NULL, NULL, NULL, 'Enforced Strong Password Policy', 'General', 'If key is set to true,Strong Password Policy will work.Details for Enforced Strong Password Policy: Password should be alphanumeric, contains one UpperCharacter, one LowerCharacter with atleast one special character.It will check the following condition if key set to true and if password entered is not matching the condition,then it will throw error.', 'configtypeEnforced Strong Password Policy', NULL, 'Common', 'F', 'F', 'F', 'F', 'F', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1984880000036, 'F', 0, NULL, 'superadmin', '2022-12-25 22:29:56.519', 'superadmin', '2022-12-25 22:29:56.519', NULL, 1, 1, NULL, NULL, NULL, 'Notification Time Interval', 'General', 'Notification feature can be enabled at Application level by adding Developer Option "Notification Time Interval" , with values in minutes for time intervals as 1, 2, 3 , 4 etc. Once this key is added, long running web services/backend scheduled jobs completion can be notified to the user with given time intervals, so that user would be able to do other operations during long running web services/backend jobs.', 'configtypeNotification Time Interval', NULL, 'All', 'F', 'F', 'F', 'T', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1984440000004, 'F', 0, NULL, 'superadmin', '2022-12-25 22:29:56.520', 'superadmin', '2022-12-25 22:29:56.520', NULL, 1, 1, NULL, NULL, NULL, 'User Manual', 'General', 'User can able to access the files through web application which is saved in local folder through User Manual option (located in right sidebar menu)', 'configtypeUser Manual', NULL, 'All', 'F', 'F', 'F', 'T', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1984220000001, 'F', 0, NULL, 'superadmin', '2022-12-25 22:29:56.521', 'superadmin', '2022-12-25 22:29:56.521', NULL, 1, 1, NULL, NULL, NULL, 'Mobile Reports as Table', 'Mobile Reports as Table', 'Administrator can enable tabular view in mobile instead of cards view', 'configtypeMobile Reports as Table', NULL, 'All', 'F', 'F', 'F', 'T', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1000330000005, 'F', 0, NULL, 'admin', '2022-12-25 22:29:56.532', 'admin', '2022-12-25 22:29:56.532', NULL, 1, 1, NULL, NULL, NULL, 'WebService Timeout', 'WebService Timeout', 'WebService Timeout', 'configtypeWebService Timeout', NULL, 'All', 'F', 'F', 'F', 'T', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1251990000026, 'F', 0, NULL, 'superadmin', '2022-12-25 22:29:56.536', 'superadmin', '2022-12-25 22:29:56.536', NULL, 1, 1, NULL, NULL, NULL, 'Show Image Widget Action Button', 'General', 'The SmartView''s columns template can be changed to achieve desired UI and Actions', 'configtypeShow Image Widget Action Button', NULL, 'Common', 'F', 'F', 'F', 'T', 'T', 'T');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1420440000004, 'F', 0, NULL, 'superadmin', '2022-12-25 22:29:56.538', 'superadmin', '2022-12-25 22:29:56.538', NULL, 1, 1, NULL, NULL, NULL, 'Show Application Menu on Login', 'General', 'Application menu can be shown/hidden by setting this Developer Option.', 'configtypeShow Application Menu on Login', NULL, 'All', 'F', 'F', 'F', 'T', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1072550000003, 'F', 0, NULL, 'superadmin', '2020-01-31 00:00:00.000', 'superadmin', '2020-01-31 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, 'Resolve Attachment Path', 'Resolve Attachment Path', 'Resolve Attachment Path', 'configtypeResolve Attachment Path', NULL, 'All', 'F', 'F', 'F', 'T', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1226220000004, 'F', 0, NULL, 'superadmin', '2022-12-25 22:29:56.534', 'superadmin', '2022-12-25 22:29:56.534', NULL, 1, 1, NULL, NULL, NULL, 'Iview Button Style', 'Iview Button Style', 'New Iview buttons UI can be switched as Modern(Google like UI) / Classic(Classic Bootstrap like UI) . Product default Iview Button UI is  "Modern" Style.', 'configtypeIview Button Style', '', 'All', 'F', 'F', 'F', 'T', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1314010000000, 'F', 0, NULL, 'admin', '2021-04-14 12:01:12.000', 'admin', '2021-03-31 11:50:59.000', NULL, 1, 1, NULL, NULL, NULL, 'Tstruct Button Style', 'Tstruct Button Style', 'Tstruct Button Style', 'configtypeTstruct Button Style', '', 'Tstruct', 'F', 'F', 'F', 'T', 'F', 'T');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1294220000002, 'F', 0, NULL, 'admin', '2021-04-27 18:22:36.000', 'admin', '2021-04-27 18:22:36.000', NULL, 1, 1, NULL, NULL, NULL, 'Apply Mobile UI', 'Apply Mobile UI', 'Apply Mobile UI', 'configtypeApply Mobile UI', NULL, 'Tstruct', 'T', 'F', 'T', 'T', 'F', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(9436330000000, 'F', 0, NULL, 'admin', '2021-07-21 18:40:15.000', 'admin', '2021-07-21 18:25:02.000', NULL, 1, 1, NULL, NULL, NULL, 'Split Ratio', 'Split Ratio', ' Description : Split Ratio format - windowSIze1:windowsize2:splitRatioType(Optional: auto(default)/fixed)
            § Developer Option Key : Split Ratio
        ○ Note: Split Ratio value is in following format 
            § windowSIze1:windowsize2:splitRatioType(Optional: auto(default)/fixed)
            §  Example:
                □ 1:1
                □ 1:2:auto
                □ 2:1
                □ 25:75
                □ 40:60
                □ 1:3:fixed
            § Split Ratio Type
                □ auto(default)
                    ®  If window is not resized manually then given split ratio configuration will be used
                    ® If window is resized manually then configuration is ignored
                □ fixed
                    ® If configuration is applied with fixed then resized window size will be ignored and split ratio configuration will always be applied', 'configtypeSplit Ratio', '', 'All', 'F', 'T', 'T', 'T', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1913880000000, 'F', 0, NULL, 'admin', '2021-11-03 20:05:58.000', 'swetha', '2021-10-29 18:23:59.000', NULL, 1, 1, NULL, NULL, NULL, 'Fixed Header for Grid', 'Fixed Header for Grid', 'Fixed Header for Grid', 'configtypeFixed Header for Grid', '', 'Tstruct', 'F', 'F', 'F', 'T', 'F', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1005770000000, 'F', 0, NULL, 'admin', '2021-12-07 13:32:15.000', 'admin', '2021-12-07 13:32:15.000', NULL, 1, 1, NULL, NULL, NULL, 'Not Fill Dependent Fields', 'Not Fill Dependent Fields', 'Not Fill Dependent Fields', 'configtypeNot Fill Dependent Fields', NULL, 'Tstruct', 'F', 'F', 'T', 'T', 'F', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1005880000000, 'F', 0, NULL, 'admin', '2021-12-07 13:33:12.000', 'admin', '2021-12-07 13:33:12.000', NULL, 1, 1, NULL, NULL, NULL, 'Fill Dependent Fields', 'Fill Dependent Fields', 'Fill Dependent Fields', 'configtypeFill Dependent Fields', NULL, 'Tstruct', 'F', 'F', 'T', 'T', 'F', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(6210110000000, 'F', 0, NULL, 'admin', '2022-08-12 10:55:30.000', 'admin', '2022-08-12 10:55:30.000', NULL, 1, 1, NULL, NULL, NULL, 'Listview as default from search', 'General', 'Listview as default from search', 'configtypeListview as default from search', NULL, 'Tstruct', 'F', 'F', 'F', 'T', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1373110000000, 'F', 0, NULL, 'admin', '2022-12-02 16:06:01.000', 'admin', '2022-12-02 16:06:01.000', NULL, 1, 1, 0, NULL, NULL, 'Upload file types', 'Upload file types', 'Upload file types', 'configtypeUpload file types', NULL, 'Tstruct', 'F', 'F', 'F', 'T', 'F', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1913770000000, 'F', 0, NULL, 'admin', '2021-11-03 20:04:40.000', 'swetha', '2021-10-29 18:21:27.000', NULL, 1, 1, NULL, NULL, NULL, 'Iview Retain Parameters On Next Load', 'Iview Retain Parameters On Next Load', 'Iview Retain Parameters On Next Load', 'configtypeIview Retain Parameters On Next Load', '', 'All', 'F', 'F', 'F', 'T', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1883880000000, 'F', 0, NULL, 'admin', '2021-11-19 19:27:08.000', 'admin', '2021-11-19 19:23:23.000', NULL, 1, 1, NULL, NULL, NULL, 'Iview Responsive Column Width', 'Iview Responsive Column Width', NULL, 'configtypeIview Responsive Column Width', NULL, 'All', 'F', 'F', NULL, 'T', 'T', NULL);
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1121550000000, 'F', 0, NULL, 'admin', '2022-12-29 08:30:30.000', 'admin', '2022-12-29 08:30:30.000', NULL, 1, 1, NULL, NULL, NULL, 'Google Maps Zoom', 'Google Maps Zoom', 'Google Maps Zoom', 'configtypeGoogle Maps Zoom', NULL, 'Tstruct', 'F', 'F', 'F', 'T', 'T', 'F');
>>
<<
INSERT INTO axpstructconfigprops
(axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, dupchk, context, ptype, caction, chyperlink, alltstructs, alliviews, alluserroles, cfields, description)
VALUES(1518330000000, 'F', 0, NULL, 'admin', '2022-12-29 11:41:12.000', 'admin', '2022-12-29 11:41:12.000', NULL, 1, 1, 0, NULL, NULL, 'Iview Session Caching', 'Iview Session Caching', 'configtypeIview Session Caching', NULL, 'Iview', 'F', 'F', 'F', 'T', 'F', 'F', 'Iview Session Caching');
>>
<<
update axpstructconfigprops set description= configprops where description is null or description=''
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000550000004, 1000550000003, 1, 'True');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000550000005, 1000550000003, 2, 'False');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000550000007, 1000550000006, 1, 'True');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000550000008, 1000550000006, 2, 'False');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000550000010, 1000550000009, 1, 'True');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000550000011, 1000550000009, 2, 'False');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000550000013, 1000550000012, 1, 'Default');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000550000014, 1000550000012, 2, 'Popup');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000550000015, 1000550000012, 3, 'Newpage');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000550000016, 1000550000012, 4, 'Split');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000220000001, 1000220000000, 1, 'middle');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000220000002, 1000220000000, 2, 'top');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000220000003, 1000220000000, 3, 'bottom');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000220000005, 1000220000004, 1, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000220000006, 1000220000004, 2, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000220000008, 1000220000007, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000220000009, 1000220000007, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000220000013, 1000220000012, 1, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000220000014, 1000220000012, 2, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000220000016, 1000220000015, 1, 'mainPageTemplate.html');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000440000001, 1000440000000, 1, 'starts with');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000440000002, 1000440000000, 2, 'contains');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1840440000000, 1314010000000, 1, 'old');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1840440000001, 1314010000000, 2, 'modern');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1840440000002, 1314010000000, 3, 'classic');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1294220000003, 1294220000002, 1, 'all');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1294220000004, 1294220000002, 2, 'mobile');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1294220000005, 1294220000002, 3, 'none');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(9436330000001, 9436330000000, 1, '1:1');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(9436330000002, 9436330000000, 2, '1:2:auto');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(9436330000003, 9436330000000, 3, '2:1 ');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(9436330000004, 9436330000000, 4, '25:75:fixed');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000003, 1742550000002, 1, 'Disable');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000004, 1742550000002, 2, 'Enable');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000007, 1742550000005, 2, 'iview');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000006, 1742550000005, 1, 'tstruct');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000010, 1742550000008, 2, '30');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000028, 1742550000008, 20, '5000');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000027, 1742550000008, 19, '2000');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000026, 1742550000008, 18, '1000');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000009, 1742550000008, 1, '25');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000029, 1742550000008, 21, 'ALL');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000011, 1742550000008, 3, '35');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000012, 1742550000008, 4, '40');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000013, 1742550000008, 5, '45');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000014, 1742550000008, 6, '50');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000015, 1742550000008, 7, '55');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000016, 1742550000008, 8, '60');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000017, 1742550000008, 9, '65');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000018, 1742550000008, 10, '70');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000019, 1742550000008, 11, '75');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000020, 1742550000008, 12, '80');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000021, 1742550000008, 13, '85');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000022, 1742550000008, 14, '90');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000023, 1742550000008, 15, '95');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000024, 1742550000008, 16, '100');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1742550000025, 1742550000008, 17, '500');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1751880000001, 1751880000000, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1751880000002, 1751880000000, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1903990000001, 1903990000000, 1, 'Right');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1903990000002, 1903990000000, 2, 'Left');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1790770000002, 1790770000000, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1040440000001, 1040440000000, 1, 'Inline');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1040440000002, 1040440000000, 2, 'Popup');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1104220000001, 1104220000000, 1, '30 min');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1104220000002, 1104220000000, 2, '1 hour');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1104220000003, 1104220000000, 3, '2 hour');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1104220000004, 1104220000000, 4, '5 hour');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1104220000005, 1104220000000, 5, '10 hour');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1104220000006, 1104220000000, 6, 'None');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1657440000022, 1657440000021, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(9436330000005, 9436330000000, 5, '40:60');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1913770000001, 1913770000000, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1913770000002, 1913770000000, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1913880000001, 1913880000000, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1913880000002, 1913880000000, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1883880000001, 1883880000000, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1883880000002, 1883880000000, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1005770000001, 1005770000000, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1005770000002, 1005770000000, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1005880000001, 1005880000000, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1005880000002, 1005880000000, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1210110000001, 1210110000000, 1, 'True');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1210110000002, 1210110000000, 2, 'False');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1373110000001, 1373110000000, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1373110000002, 1373110000000, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1237550000000, 1742550000005, 3, 'general');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1787880000005, 1742550000008, 22, '10');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(2680010000001, 2680010000000, 1, 'en-US');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(2175770000002, 2175770000001, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(2037880000002, 2037880000001, 1, '1');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1008440000005, 1008440000004, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1008440000006, 1008440000004, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1072550000001, 1072550000000, 1, 'hide');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1072550000002, 1072550000000, 2, 'show');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1072550000004, 1072550000003, 1, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1072550000005, 1072550000003, 2, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1235440000044, 1235440000043, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1235440000045, 1235440000043, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1235660000011, 1235660000010, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1235660000012, 1235660000010, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1355440000004, 1355440000003, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1355440000005, 1355440000003, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1355440000007, 1355440000006, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1355440000008, 1355440000006, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1355440000010, 1355440000009, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1355440000011, 1355440000009, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1635440000038, 1635440000037, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1984220000002, 1984220000001, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1984220000003, 1984220000001, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1984440000005, 1984440000004, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1984440000006, 1984440000004, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1984880000037, 1984880000036, 1, '1');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1984880000038, 1984880000036, 2, '3');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1984880000039, 1984880000036, 3, '5');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1984880000040, 1984880000036, 4, '10');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1984880000041, 1984880000036, 5, '30');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1000330000006, 1000330000005, 1, '100000');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1525110003964, 1000330000005, 2, '1000000');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1226220000005, 1226220000004, 1, 'Modern');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1226220000006, 1226220000004, 2, 'Classic');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1251990000027, 1251990000026, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1251990000028, 1251990000026, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1420440000005, 1420440000004, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1420440000006, 1420440000004, 2, 'false');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1121550000001, 1121550000000, 1, '1');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1121550000002, 1121550000000, 2, '5');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1121550000003, 1121550000000, 3, '10');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1121550000004, 1121550000000, 4, '11');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1121550000005, 1121550000000, 5, '15');
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1121550000006, 1121550000000, 6, '20');
>>
<<
INSERT INTO axpstructconfigproval(axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues)VALUES(1518330000001, 1518330000000, 1, 'true');
>>
<<
INSERT INTO axpstructconfigproval(axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues)VALUES(1518330000002, 1518330000000, 2, 'false');
>>
<<
INSERT INTO axctx1 (atype, axcontext) VALUES('Property', 'column separator for reports')
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) 
VALUES(1601770000002, 'F', 0, NULL, 'admin', '2022-12-29 11:41:12.000', 'admin','2022-12-29 11:41:12.000', NULL, 1, 1, 0, NULL, NULL, 'column separator for reports', 'column separator for reports', 'column separator for reports', 'configtypecolumn separator for reports', NULL, 'Common', 'F', 'F', 'F', 'T', 'T', 'F')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1601770000003, 1601770000002, 1, 'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1601770000004, 1601770000002, 2, 'false')
>>
<<
INSERT INTO axctx1 (atype, axcontext) VALUES('Property', 'Popup fillgrid data based on query order')
>>
<<
INSERT INTO axctx1 (atype, axcontext) VALUES('Property', 'Popup fillgrid data show all')
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) 
VALUES(1368990000000, 'F', 0, NULL, 'admin', '2022-12-29 11:41:12.000', 'admin', '2022-12-29 11:41:12.000', NULL, 1, 1, NULL, NULL, NULL, 'Popup fillgrid data based on query order', 'Popup fillgrid data based on query order', 'Popup fillgrid data based on query order', 'configtypePopup fillgrid data based on query order', NULL, 'Tstruct', 'F', 'F', 'F', 'T', 'T', 'F')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1368990000001, 1368990000000, 1, 'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1368990000002, 1368990000000, 2, 'false')
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) 
VALUES(1368990000003, 'F', 0, NULL, 'admin', '2022-12-29 11:41:12.000', 'admin', '2022-12-29 11:41:12.000', NULL, 1, 1, NULL, NULL, NULL, 'Popup fillgrid data show all', 'Popup fillgrid data show all', 'Popup fillgrid data show all', 'configtypePopup fillgrid data show all', NULL, 'Tstruct', 'F', 'F', 'F', 'T', 'T', 'F')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1368990000004, 1368990000003, 1, 'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1368990000005, 1368990000003, 2, 'false')
>>
<<
CREATE TABLE IF NOT EXISTS axp_struct_release_log (createdon timestamp NULL DEFAULT now(),axpversion varchar(100) NULL)
>>
<<
ALTER TABLE executeapidef ADD execapiauthstring nvarchar(100) null
>>
<<
ALTER TABLE axprocessdefv2 ADD action_buttons varchar(50) null
>>
<<
ALTER TABLE axprocessdefv2 ADD assigntouser varchar(100) null
>>
<<
ALTER TABLE axprocessdefv2 ADD assigntouserflag varchar(5) null
>>
<<
ALTER TABLE axprocessdefv2 ADD displaybuttons varchar(100) null
>>
<<
ALTER TABLE axprocessdefv2 ADD displaysubtitle varchar(100) null
>>
<<
ALTER TABLE axprocessdefv2 ADD editablefieldscaption varchar(4000) null
>>
<<
ALTER TABLE axprocessdefv2 ADD exp_editor_applicability text null
>>
<<
ALTER TABLE axprocessdefv2 ADD exp_editor_nexttask text null
>>
<<
ALTER TABLE axprocessdefv2 ADD mapfield varchar(100) null
>>
<<
ALTER TABLE axprocessdefv2 ADD mapfield_group varchar(250) null
>>
<<
ALTER TABLE axprocessdefv2 ADD mapfieldcaption varchar(250) null
>>
<<
ALTER TABLE axprocessdefv2 ADD mobilenotify varchar(1) null
>>
<<
ALTER TABLE axprocessdefv2 ADD nexttask varchar(4000) null
>>
<<
ALTER TABLE axprocessdefv2 ADD nexttask_falsecnd varchar(250) null
>>
<<
ALTER TABLE axprocessdefv2 ADD nexttask_tbl varchar(4000) null
>>
<<
ALTER TABLE axprocessdefv2 ADD nexttask_truecnd varchar(250) null
>>
<<
ALTER TABLE axprocessdefv2 ADD parenttask varchar(200) null
>>
<<
ALTER TABLE axprocessdefv2 ADD prenotify varchar(250) null
>>
<<
ALTER TABLE axprocessdefv2 ADD subindexno numeric(2) null
>>
<<
CREATE TABLE axactivetasks (
	eventdatetime varchar(30)  NULL,
	taskid varchar(15)  NULL,
	processname varchar(500)  NULL,
	tasktype varchar(30)  NULL,
	taskname varchar(500)  NULL,
	taskdescription varchar(MAX)  NULL,
	assigntorole varchar(50)  NULL,
	transid varchar(8)  NULL,
	keyfield varchar(30)  NULL,
	execonapprove varchar(5)  NULL,
	keyvalue varchar(500)  NULL,
	transdata varchar(MAX)  NULL,
	fromrole varchar(30)  NULL,
	fromuser varchar(30)  NULL,
	touser varchar(500)  NULL,
	priorindex int NULL,
	priortaskname varchar(200)  NULL,
	corpdimension varchar(10)  NULL,
	orgdimension varchar(10)  NULL,
	department varchar(30)  NULL,
	grade varchar(10)  NULL,
	datavalue varchar(MAX)  NULL,
	displayicon varchar(200)  NULL,
	displaytitle varchar(500)  NULL,
	displaysubtitle varchar(250)  NULL,
	displaycontent varchar(MAX)  NULL,
	displaybuttons varchar(250)  NULL,
	groupfield varchar(MAX)  NULL,
	groupvalue varchar(MAX)  NULL,
	priorusername varchar(100)  NULL,
	initiator varchar(100)  NULL,
	mapfieldvalue varchar(MAX)  NULL,
	useridentificationfilter varchar(1000)  NULL,
	useridentificationfilter_of varchar(1000)  NULL,
	mapfield_group varchar(1000)  NULL,
	mapfield varchar(1000)  NULL,
	grouped char(1)  NULL,
	indexno int NULL,
	subindexno int NULL,
	processowner varchar(100)  NULL,
	assigntoflg char(1)  NULL,
	assigntoactor varchar(1000)  NULL,
	actorfilter varchar(MAX)  NULL,
	recordid bigint NULL,
	processownerflg int NULL,
	pownerfilter varchar(MAX)  NULL,
	approvereasons varchar(MAX)  NULL,
	defapptext varchar(MAX)  NULL,
	returnreasons varchar(MAX)  NULL,
	defrettext varchar(MAX)  NULL,
	rejectreasons varchar(MAX)  NULL,
	defregtext varchar(MAX)  NULL,
	approvalcomments char(1)  NULL,
	rejectcomments char(1)  NULL,
	returncomments char(1)  NULL,
	escalation char(1)  NULL,
	reminder char(1)  NULL,
	displaymcontent varchar(MAX)  NULL,
	groupwithpriorindex int NULL,
	delegation char(1)  DEFAULT 'F' NULL,
	returnable char(1)  NULL,
	sendtoactor varchar(MAX)  NULL,
	allowsend varchar(30)  NULL,
	allowsendflg char(1)  NULL,
	sendtocomments varchar(MAX)  NULL,
	usebusinessdatelogic char(1)  NULL,
	initiator_approval char(1)  NULL,
	initonbehalf varchar(100)  NULL,
	removeflg char(1)  DEFAULT 'F' NULL,
	pownerflg char(1)  DEFAULT 'F' NULL,
	changedusr char(1)  DEFAULT 'F' NULL,
	actor_user_groups varchar(MAX)  NULL,
	actor_default_users char(1)  NULL,
	actor_data_grp varchar(200)  NULL,
	cancel char(1)  DEFAULT 'F' NULL,
	cancelledby varchar(100)  NULL,
	cancelledon datetime NULL,
	cancelremarks varchar(MAX)  NULL,
	action_buttons varchar(100)  NULL,
	autoapprove char(1)  NULL,
	isoptional char(1)  NULL,
	reminderstartdate date NULL,
	escalationstartdate date NULL,
	reminderjsondata varchar(MAX)  NULL,
	escalationjsondata varchar(MAX)  NULL
)
>>
<<
CREATE NONCLUSTERED INDEX ui_axactivetasks_keyvalue ON axactivetasks (  keyvalue  )
>>
<<
CREATE NONCLUSTERED INDEX ui_axactivetasks_transid ON axactivetasks (  transid )
>>
<<
CREATE TABLE axactivetaskdata (
	eventdatetime nvarchar(30)  NULL,
	taskid nvarchar(15)  NULL,
	transid nvarchar(8)  NULL,
	keyfield nvarchar(30)  NULL,
	keyvalue nvarchar(500)  NULL,
	datavalues nvarchar(4000)  NULL
)
>>
<<
CREATE TABLE axactivetaskstatus (
	eventdatetime nvarchar(30)  NULL,
	taskid nvarchar(15)  NULL,
	transid nvarchar(8)  NULL,
	keyfield nvarchar(30)  NULL,
	keyvalue nvarchar(500)  NULL,
	taskstatus nvarchar(15)  NULL,
	username nvarchar(30)  NULL,
	tasktype nvarchar(500)  NULL,
	taskname nvarchar(500)  NULL,
	processname nvarchar(500)  NULL,
	priorindex int NULL,
	indexno int NULL,
	subindexno int NULL,
	recordid bigint NULL,
	statusreason nvarchar(4000)  NULL,
	statustext nvarchar(4000)  NULL,
	cancelremarks nvarchar(MAX)  NULL,
	cancelledby nvarchar(100)  NULL,
	cancelledon datetime NULL,
	cancel nvarchar(1)  NULL,
	sendtocomments nvarchar(4000)  NULL
)
>>
<<
CREATE TABLE axpdef_peg_usergroups (
	username varchar(100)  NULL,
	usergroupname varchar(500)  NULL,
	usergroupcode varchar(20)  NULL,
	active varchar(1)  NULL,
	effectivefrom datetime NULL,
	fromuser varchar(1)  DEFAULT 'F' NULL
)
>>
<<
CREATE NONCLUSTERED INDEX username_idx ON axpdef_peg_usergroups (  username )
>>
<<
CREATE TABLE axprocessdef (
	active nvarchar(1)  NULL,
	allowforwardto nvarchar(4000)  NULL,
	app_desc numeric(18,0) NULL,
	app_level numeric(18,0) NULL,
	app_slevel numeric(18,0) NULL,
	applicability nvarchar(4000)  NULL,
	applicability_tbl nvarchar(4000)  NULL,
	approvecmt nvarchar(1)  NULL,
	approvereasons nvarchar(4000)  NULL,
	assignto nvarchar(50)  NULL,
	assigntoactor nvarchar(100)  NULL,
	assigntoflg nvarchar(10)  NULL,
	assigntorole nvarchar(4000)  NULL,
	assigntouser nvarchar(100)  NULL,
	assigntouserflag nvarchar(5)  NULL,
	axpdef_peg_processmasterid numeric(18,0) NULL,
	axprocessdefid numeric(18,0) NOT NULL,
	cancel nvarchar(1)  NULL,
	cancelremarks nvarchar(150)  NULL,
	createdby nvarchar(50)  NULL,
	createdon datetime NULL,
	datafields nvarchar(4000)  NULL,
	defapptext nvarchar(4000)  NULL,
	defregtext nvarchar(4000)  NULL,
	defrettext nvarchar(4000)  NULL,
	displaybuttons nvarchar(250)  NULL,
	displaycontent nvarchar(MAX)  NULL,
	displayicon nvarchar(200)  NULL,
	displaysubtitle nvarchar(250)  NULL,
	displaytemplate nvarchar(MAX)  NULL,
	displaytitle nvarchar(500)  NULL,
	editablefieldscaption nvarchar(4000)  NULL,
	escalation numeric(18,0) NULL,
	escalation_actor nvarchar(250)  NULL,
	excalation_role nvarchar(4000)  NULL,
	execmaps nvarchar(2000)  NULL,
	execonapprove nvarchar(250)  NULL,
	exp_editor_applicability nvarchar(MAX)  NULL,
	exp_editor_nexttask nvarchar(MAX)  NULL,
	formcaption nvarchar(500)  NULL,
	formdatacache nvarchar(10)  NULL,
	formfieldname nvarchar(100)  NULL,
	formfieldscaption nvarchar(250)  NULL,
	formula_andor nvarchar(20)  NULL,
	formula_opr nvarchar(50)  NULL,
	indexdupchk nvarchar(1000)  NULL,
	indexno numeric(18,0) NULL,
	keyfield nvarchar(250)  NULL,
	keyfieldcaption nvarchar(500)  NULL,
	mapfield nvarchar(100)  NULL,
	mapfield_group nvarchar(250)  NULL,
	mapfieldcaption nvarchar(250)  NULL,
	mapname nvarchar(20)  NULL,
	maxtime nvarchar(20)  NULL,
	maxtimedays numeric(18,0) NULL,
	maxtimehr numeric(18,0) NULL,
	maxtimemm numeric(18,0) NULL,
	mobilenotify nvarchar(1)  NULL,
	modifiedon datetime NULL,
	nexttask nvarchar(4000)  NULL,
	nexttask_falsecnd nvarchar(250)  NULL,
	nexttask_tbl nvarchar(4000)  NULL,
	nexttask_truecnd nvarchar(250)  NULL,
	postnotify nvarchar(250)  NULL,
	prenotify nvarchar(250)  NULL,
	processname nvarchar(500)  NULL,
	processowner nvarchar(300)  NULL,
	processownerflg numeric(18,0) NULL,
	processownerui nvarchar(300)  NULL,
	rejectcmt nvarchar(1)  NULL,
	rejectreasons nvarchar(4000)  NULL,
	reminder numeric(18,0) NULL,
	returncmt nvarchar(1)  NULL,
	returnreasons nvarchar(4000)  NULL,
	sourceid numeric(18,0) NULL,
	subindexno numeric(18,0) NULL,
	taskdesc nvarchar(MAX)  NULL,
	taskdescription nvarchar(MAX)  NULL,
	taskgroupname nvarchar(250)  NULL,
	taskname nvarchar(500)  NULL,
	tasktype nvarchar(10)  NULL,
	transid nvarchar(10)  NULL,
	useridentificationfilter nvarchar(4000)  NULL,
	useridentificationfilter_of nvarchar(20)  NULL,
	username nvarchar(50)  NULL,
	wfroles nvarchar(250)  NULL,
	wkid nvarchar(15)  NULL
)
>>
<<
CREATE TABLE axactivemessages (
	eventdatetime nvarchar(30)  NULL,
	msgtype nvarchar(30)  NULL,
	fromuser nvarchar(30)  NULL,
	touser nvarchar(500)  NULL,
	taskid nvarchar(15)  NULL,
	tasktype nvarchar(30)  NULL,
	processname nvarchar(500)  NULL,
	taskname nvarchar(500)  NULL,
	indexno int NULL,
	keyfield nvarchar(30)  NULL,
	keyvalue nvarchar(30)  NULL,
	transid nvarchar(8)  NULL,
	displaytitle nvarchar(500)  NULL,
	displaycontent nvarchar(MAX)  NULL,
	effectivefrom datetime NULL,
	effectiveto datetime NULL,
	html nvarchar(MAX)  NULL,
	scripts nvarchar(MAX)  NULL,
	hide nvarchar(1)  NULL,
	displayicon nvarchar(200)  NULL,
	hlink nvarchar(500)  NULL,
	hlink_transid nvarchar(50)  NULL,
	hlink_params nvarchar(2000)  NULL,
	requestpayload nvarchar(MAX)  NULL
)
>>
<<
CREATE TABLE axactivetaskparams (

	eventdatetime varchar(30)  NULL,
	indexno numeric(18,0) NULL,
	keyfield varchar(30)  NULL,
	keyvalue varchar(500)  NULL,
	priorindex numeric(18,0) NULL,
	processname varchar(500)  NULL,
	recordid numeric(18,0) NULL,
	subindexno numeric(18,0) NULL,
	taskid varchar(30)  NULL,
	taskname varchar(500)  NULL,
	taskparams varchar(4000)  NULL,
	taskstatus varchar(15)  NULL,
	tasktype varchar(500)  NULL,
	transid varchar(8)  NULL,
	username varchar(30)  NULL
)
>>
<<
INSERT INTO axctx1 (atype, axcontext) VALUES('Property', 'Unicode support for PDF export')
>>
<<
INSERT INTO axctx1 (atype, axcontext) VALUES('Property', 'Auto column width for report based on data')
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) 
VALUES(3819110000000, 'F', 0, NULL, 'admin', '2023-04-10 10:57:39.000', 'admin', '2023-04-10 10:57:39.000', NULL, 1, 1, NULL, NULL, NULL, 'Unicode support for PDF export', 'Unicode support for PDF export', 'Unicode support for PDF export', 'configtypeUnicode support for PDF export', NULL, 'All', 'F', 'F', 'F', 'T', 'T', 'F')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1819110000001, 3819110000000, 1, 'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1819110000002, 3819110000000, 2, 'false')
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) 
VALUES(3819010000000, 'F', 0, NULL, 'admin', '2023-04-10 10:57:10.000', 'admin', '2023-04-10 10:57:10.000', NULL, 1, 1, NULL, NULL, NULL, 'Auto column width for report based on data', 'Auto column width for report based on data', 'Auto column width for report based on data', 'configtypeAuto column width for report based on data', NULL, 'All', 'F', 'F', 'F', 'F', 'T', 'F')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1819010000001, 3819010000000, 1, 'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1819010000002, 3819010000000, 2, 'false')
>>
<<
alter table axactivetasks add column returnable varchar(1)
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(5095990000000, 'F', 0, NULL, 'admin', '2023-06-09 19:06:34.000', 'admin', '2023-06-09 19:04:03.000', NULL, 1, 1, 0, NULL, NULL, 'Force Field Validation', 'General', 'Force Field Validation', 'configtypeForce Field Validation', NULL, 'Tstruct', 'F', 'F', 'T', 'T', 'T', 'F')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1095990000001, 5095990000000, 1, 'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1095990000002, 5095990000000, 2, 'false')
>>
<<
update axusers set pwdauth='T',otpauth='F'
>>
<<
ALTER TABLE axcalendar ADD axpdef_axcalendar_eventid numeric(15) NULL
>>
<<
ALTER TABLE axcalendar ADD axpdef_axcalendar_eventstatusid numeric(15) NULL
>>
<<
ALTER TABLE axcalendar ADD calendarevent numeric(10) NULL
>>
<<
ALTER TABLE axcalendar ADD aftsaveflg varchar(1) NULL
>>
<<
INSERT INTO AXDIRECTSQL (axdirectsqlid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, sqlname, ddldatatype, sqltext, paramcal, sqlparams, accessstring, groupname, sqlsrc, sqlsrccnd, sqlquerycols, encryptedflds, cachedata, cacheinterval) VALUES(1076110000000, N'F', 0, NULL, N'admin', '2024-10-16 17:29:40.000', N'admin', '2024-10-16 17:29:40.000', NULL, 1, 1, 0, NULL, NULL, N'Text_Field_Intelligence', NULL, N'select id,caption,source from(
select fname id,caption,''Form'' source,2 ord from axpflds where asgrid=''F'' and tstruct = :txttransid 
union all
select db_varname,db_varcaption,''Axvars'' ,3 ord from axpdef_axvars_dbvar a,axpdef_axvars b
where b.axpdef_axvarsid=a.axpdef_axvarsid 
union all
select value,value,''App vars'' ,4 ord 
from regexp_split_to_table(''username,usergroup'','','')
union all
select fname,caption,''Glovar'',5 ord from axpflds where tstruct=''axglo'')a
order by 3,1', N'txttransid', N'txttransid', N'ALL', NULL, N'Data intellisense', 3, N'id,caption,source', NULL, NULL, NULL)
>>
<<
INSERT INTO AXDIRECTSQL (axdirectsqlid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, sqlname, ddldatatype, sqltext, paramcal, sqlparams, accessstring, groupname, sqlsrc, sqlsrccnd, sqlquerycols, encryptedflds, cachedata, cacheinterval) VALUES(1104660000000, N'F', 0, NULL, N'admin', '2026-01-28 15:47:51.000', N'admin', '2026-01-28 15:47:51.000', NULL, 1, 1, 0, NULL, NULL, N'axcalendarsource', NULL, N'select * from vw_cards_calendar_data where mapname is null and uname = :username order by startdate', N'username', N'username~Character~', NULL, NULL, N'Home configuration', 2, NULL, NULL, N'T', N'6 Hr')
>>
<<
INSERT INTO AXDIRECTSQL (axdirectsqlid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, sqlname, ddldatatype, sqltext, paramcal, sqlparams, accessstring, groupname, sqlsrc, sqlsrccnd, sqlquerycols, encryptedflds, cachedata, cacheinterval) VALUES(1108110000000, N'F', 0, NULL, N'admin', '2025-02-05 11:40:58.000', N'admin', '2025-01-31 11:49:33.000', NULL, 1, 1, 0, NULL, NULL, N'ds_homepage_quicklinks', NULL, N'SELECT DISTINCT 
    CASE 
        WHEN LOWER(servicename collate Arabic_CI_AS) = ''get structure'' THEN t.caption collate Arabic_CI_AS
        WHEN LOWER(servicename collate Arabic_CI_AS) IN (''get iview new'', ''get iview'') THEN i.caption collate Arabic_CI_AS 
    END AS caption,
    CASE 
        WHEN LOWER(servicename collate Arabic_CI_AS) = ''get structure'' THEN ''t'' + structname + ''()''
        WHEN LOWER(servicename collate Arabic_CI_AS) IN (''get iview new'', ''get iview'') THEN ''i'' + structname + ''()'' 
    END AS link
FROM axpertlog a 
LEFT JOIN tstructs t ON a.structname = t.name 
LEFT JOIN iviews i ON a.structname = i.name
WHERE CAST(calledon AS DATE) > GETDATE()  - 1  
AND LOWER(servicename) IN (''get structure'', ''get iview new'', ''get iview'')
AND structname IS NOT NULL
AND a.username = :username
', N'username', N'username', N'ALL', NULL, N'Home configuration', 2, NULL, NULL, NULL, NULL)
>>
<<
INSERT INTO AXDIRECTSQL (axdirectsqlid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, sqlname, ddldatatype, sqltext, paramcal, sqlparams, accessstring, groupname, sqlsrc, sqlsrccnd, sqlquerycols, encryptedflds, cachedata, cacheinterval) VALUES(1108330000000, N'F', 0, NULL, N'admin', '2025-02-05 11:43:37.000', N'admin', '2025-01-31 11:50:05.000', NULL, 1, 1, 0, NULL, NULL, N'ds_homepage_recentactivities', NULL, N'SELECT * FROM 
(
    SELECT 
        CASE LOWER(servicename collate Arabic_CI_AS) 
            WHEN ''saving data'' THEN ''new data created in '' + t.caption  collate Arabic_CI_AS
            WHEN ''quick form load'' THEN t.caption  collate Arabic_CI_AS+ '' opened''
            WHEN ''form load'' THEN t.caption  collate Arabic_CI_AS+ '' opened''
            WHEN ''importdata''  THEN ''Data import''
            WHEN ''exportdata'' THEN ''Data export''
            WHEN ''deleting data'' THEN ''Data deleted in '' + t.caption  collate Arabic_CI_AS
            WHEN ''get iview new'' THEN i.caption  collate Arabic_CI_AS + '' report opened''
            WHEN ''get iview'' THEN i.caption  collate Arabic_CI_AS + '' report opened''
            WHEN ''logout'' THEN ''Logout''
            WHEN ''login'' THEN ''Login''
            WHEN ''get structure'' THEN t.caption  collate Arabic_CI_AS + '' opened''
            WHEN ''load data''  THEN ''Load data in '' + t.caption  collate Arabic_CI_AS
            WHEN ''quick load data'' THEN ''Load data in '' + t.caption  collate Arabic_CI_AS
        END AS title,
        username,
        calledon,
        CASE 
            WHEN LOWER(servicename) IN (''get iview new'', ''get iview'') THEN ''i'' + structname + ''()'' 
            WHEN LOWER(servicename) IN (''quick load data'', ''load data'') THEN ''t'' + structname + ''(recordid='' + CAST(recordid AS VARCHAR) + '')''
            WHEN LOWER(servicename) IN (''get structure'', ''quick form load'', ''form load'', ''deleting data'') THEN ''t'' + structname + ''()'' 
        END AS link 
    FROM axpertlog a 
    LEFT JOIN tstructs t ON a.structname = t.[name] 
    LEFT JOIN iviews i ON a.structname = i.[name] 
    WHERE LOWER(servicename) IN (''load data'', ''quick load data'', ''form load'', ''get structure'', ''saving data'', 
                                 ''quick form load'', ''importdata'', ''exportdata'', ''deleting data'', ''get iview new'', 
                                 ''get iview'', ''logout'', ''login'')
    AND calledon > DATEADD(DAY, -2, CAST(GETDATE() AS DATE))
    AND username = :username
) a
WHERE a.title IS NOT NULL
ORDER BY calledon DESC', N'username', N'username', N'ALL', NULL, N'Home configuration', 2, NULL, NULL, NULL, NULL)
>>
<<
INSERT INTO AXDIRECTSQL (axdirectsqlid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, sqlname, ddldatatype, sqltext, paramcal, sqlparams, accessstring, groupname, sqlsrc, sqlsrccnd, sqlquerycols, encryptedflds, cachedata, cacheinterval) VALUES(1108440000000, N'F', 0, NULL, N'admin', '2025-01-31 11:50:25.000', N'admin', '2025-01-31 11:50:25.000', NULL, 1, 1, 0, NULL, NULL, N'ds_homepage_events', NULL, N'SELECT 
    eventname AS title,
    eventtype AS subtitle,
    CONCAT(startdate, '' '', axptm_starttime) AS start_datetime,
    ''taxclr(recordid='' + CAST(recordid AS VARCHAR) + '')'' AS link
FROM vw_cards_calendar_data
WHERE mapname IS NULL AND uname = :username
ORDER BY startdate', N'username', N'username', N'ALL', NULL, N'Home configuration', 2, NULL, NULL, NULL, NULL)
>>
<<
INSERT INTO AXDIRECTSQL (axdirectsqlid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, sqlname, ddldatatype, sqltext, paramcal, sqlparams, accessstring, groupname, sqlsrc, sqlsrccnd, sqlquerycols, encryptedflds, cachedata, cacheinterval) VALUES(1108550000000, N'F', 0, NULL, N'admin', '2025-01-31 11:50:41.000', N'admin', '2025-01-31 11:50:41.000', NULL, 1, 1, 0, NULL, NULL, N'ds_homepage_activelist', NULL, N'select null touser, null fromuser, null taskname, null eventdatetime, null displaytitle, null displaycontent , null tasktype , null rectype, 
null msgtype , null taskstatus, null cstatus 
from dual 
', NULL, NULL, N'ALL', NULL, N'Home configuration', 2, N'touser,fromuser,taskname,eventdatetime,displaytitle,displaycontent,tasktype,rectype,msgtype,taskstatus,cstatus', NULL, NULL, NULL)
>>
<<
INSERT INTO AXDIRECTSQL (axdirectsqlid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, sqlname, ddldatatype, sqltext, paramcal, sqlparams, accessstring, groupname, sqlsrc, sqlsrccnd, sqlquerycols, encryptedflds, cachedata, cacheinterval) VALUES(1108660000000, N'F', 0, NULL, N'admin', '2025-01-31 11:51:02.000', N'admin', '2025-01-31 11:51:02.000', NULL, 1, 1, 0, NULL, NULL, N'ds_homepage_kpicards', NULL, N'SELECT ''Users'' AS name, COUNT(*) AS value, ''taxusr()'' AS link 
FROM axusers
UNION ALL 
SELECT ''Records created today'', COUNT(*), NULL 
FROM axpertlog a 
WHERE LOWER(servicename) = ''saving data'' 
AND CAST(calledon AS DATE) = CAST(GETDATE() AS DATE) 
AND username = :username
UNION ALL 
SELECT ''Active sessions'', COUNT(*), NULL 
FROM axaudit a 
WHERE CAST(logintime AS DATE) = CAST(GETDATE() AS DATE) 
AND nologout = ''T''
UNION ALL 
SELECT ''Sample with params'', 0, ''taxusr(pusername=admin~build=T)'' 
WHERE 1 = 2', N'username', N'username', N'ALL', NULL, N'Home configuration', 2, NULL, NULL, NULL, NULL)
>>
<<
INSERT INTO AXDIRECTSQL (axdirectsqlid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, sqlname, ddldatatype, sqltext, paramcal, sqlparams, accessstring, groupname, sqlsrc, sqlsrccnd, sqlquerycols, encryptedflds, cachedata, cacheinterval) VALUES(1110010000000, N'F', 0, NULL, N'admin', '2025-02-06 10:04:21.000', N'admin', '2025-02-06 10:04:21.000', NULL, 1, 1, 0, NULL, NULL, N'ds_homepage_banner', NULL, N'SELECT ''Developer faster'' as title, ''Developer faster using Axpert low code platform.'' as subtitle, ''Jan 01, 2025'' as time, ''https://dev.agilecloud.biz/axpert11.3web/CustomPages/images/slider1.png'' as image, '''' as link from dual
union
SELECT ''UI Plugins'' as title, ''Use UI Plugins to enhance the user experience'' as subtitle, ''Jan 01, 2025'' as time, ''https://dev.agilecloud.biz/axpert11.3web/CustomPages/images/slider1.png'' as image, '''' as link from dual
union
SELECT ''Configure yourself'' as title, ''Configure functionalities as per customer needs'' as subtitle, ''Jan 01, 2025'' as time, ''https://dev.agilecloud.biz/axpert11.3web/CustomPages/images/slider1.png'' as image, '''' as link from dual
', NULL, NULL, N'ALL', NULL, N'Home configuration', 2, NULL, NULL, NULL, NULL)
>>
<<

INSERT INTO EXECUTEAPIDEF (executeapidefid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, execapidefname, execapiurl, execapiparameterstring, execapiheaderstring, execapirequeststring, execapimethod, execapibasedon, stype, execapiform, execapitransid, execapifilterstring, execapilprintformnames, execapiformattachments, execapiiview, execapiiviewname, execapiiparams, sql_editor_execapisqltext, apicategory, apiresponsetype, apiresponseformat, execapibodyparamstring, execapiauthstring, apitype, apitypecnd, isdropdown) VALUES(1076770000000, N'F', 0, NULL, N'admin', '2024-10-16 18:12:46.000', N'admin', '2024-10-16 18:10:07.000', NULL, 1, 1, 0, NULL, NULL, N'Text_Field_Intelligence', NULL, NULL, NULL, N'{"_parameters":[{"getsqldata":{"axpapp":"defmssql112","sqlname":"Text_Field_Intelligence","isdropdown":"F","trace":"false"},"defmssql112":{
  "type": "db",
  "structurl": "",
  "db": "MS SQL",
  "driver": "ado",
  "version": "Above 2012",
  "dbcon": "mssql2022",
  "dbuser": "defmssql112",
  "pwd": "",
  "dataurl": ""
},"sqlparams":{"txttransid":""}}]}', N'Post', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, N'SQL', N'Axpert', N'JSON', NULL, NULL, NULL, NULL, NULL)
>>
<<
CREATE TABLE axinqueuesdata (
	createdon datetime2 DEFAULT sysdatetime() NULL,
	axqueuename varchar(100)  NULL,
	transid varchar(10)  NULL,
	recordid numeric(18,0) NULL,
	queuedata nvarchar(MAX)  NULL
)
>>
<<
CREATE TABLE axoutqueuesdata (
	createdon datetime2 DEFAULT sysdatetime() NULL,
	axqueuename varchar(100)  NULL,
	transid varchar(10)  NULL,
	recordid numeric(18,0) NULL,
	queuedata nvarchar(MAX)  NULL
)
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1320010000002, 'F', 0, NULL, 'admin', '2023-10-31 17:22:16.000', 'admin', '2023-10-31 16:30:04.000', NULL, 1, 1, 0, NULL, NULL, 'Hide Select ALL option in Multiselect Component', 'Hide Select ALL option in Multiselect Component', 'Hide Select ALL option in Multiselect Component', 'configtypeHide Select ALL option in Multiselect Component', NULL, 'Iview', 'F', 'F', 'F', 'T', 'T', 'F')
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1393550000002, 'F', 0, NULL, 'admin', '2023-08-04 14:44:31.000', 'admin', '2023-08-04 14:44:15.000', NULL, 1, 1, 0, NULL, NULL, 'Fill AutoSelect fields for dropdown fields', 'Fill AutoSelect fields for dropdown fields', 'Fill AutoSelect fields for dropdown fields', 'configtypeFill AutoSelect fields for dropdown fields', NULL, 'Tstruct', 'F', 'F', 'F', 'T', 'T', 'T')
>>
<<
INSERT INTO axpstructconfigprops (axpstructconfigpropsid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, configprops, propcode, description, dupchk, context, ptype, caction, chyperlink, cfields, alltstructs, alliviews, alluserroles) VALUES(1369990000002, 'F', 0, NULL, 'admin', '2023-08-02 10:13:46.000', 'admin', '2023-08-02 10:13:46.000', NULL, 1, 1, 0, NULL, NULL, 'Show Sql Columns In Advance Search In Field Level', 'Show Sql Columns In Advance Search In Field Level', 'Show Sql Columns In Advance Search In Field Level', 'configtypeShow Sql Columns In Advance Search In Field Level', NULL, 'Tstruct', 'F', 'F', 'F', 'T', 'T', 'F')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1369990000003, 1369990000002, 1, 'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1369990000004, 1369990000002, 2, 'false')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1393550000003, 1393550000002, 1, 'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1393550000004, 1393550000002, 2, 'false')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1320010000003, 1320010000002, 1, 'true')
>>
<<
INSERT INTO axpstructconfigproval (axpstructconfigprovalid, axpstructconfigpropsid, axpstructconfigprovalrow, configvalues) VALUES(1320010000004, 1320010000002, 2, 'false')
>>
<<
CREATE TABLE AXPDEF_AXVARS_DBVAR (
	axpdef_axvars_dbvarid numeric(16,0) NOT NULL,
	axpdef_axvarsid numeric(16,0) NULL,
	axpdef_axvars_dbvarrow numeric(32,0) NULL,
	db_varname nvarchar(200)  NULL,
	db_varval nvarchar(500)  NULL,
	db_vartype nvarchar(100)  NULL,
	db_varcaption nvarchar(500)  NULL,
	CONSTRAINT aglaxpdef_axvars_dbvarid PRIMARY KEY (axpdef_axvars_dbvarid)
)
>>
<<
CREATE TABLE AXPDEF_AXVARS (
	axpdef_axvarsid numeric(16,0) NOT NULL,
	cancel nvarchar(1)  NULL,
	sourceid numeric(16,0) NULL,
	mapname nvarchar(20)  NULL,
	username nvarchar(50)  NULL,
	modifiedon datetime NULL,
	createdby nvarchar(50)  NULL,
	createdon datetime NULL,
	wkid nvarchar(15)  NULL,
	app_level numeric(3,0) NULL,
	app_desc numeric(1,0) NULL,
	app_slevel numeric(3,0) NULL,
	cancelremarks nvarchar(150)  NULL,
	wfroles nvarchar(250)  NULL,
	transid nvarchar(5)  NULL,
	db_function nvarchar(500)  NULL,
	db_function_params nvarchar(4000)  NULL,
	event_onlogin nvarchar(1)  NULL,
	event_onformload nvarchar(1)  NULL,
	forms nvarchar(4000)  NULL,
	forms_transid nvarchar(4000)  NULL,
	event_onreportload nvarchar(1)  NULL,
	reports nvarchar(4000)  NULL,
	reports_transid nvarchar(4000)  NULL,
	isdbobj nvarchar(1)  NULL,
	remarks nvarchar(MAX)  NULL,
	CONSTRAINT aglaxpdef_axvarsid PRIMARY KEY (axpdef_axvarsid)
)
>>
<<
CREATE TABLE axamend (
	transid nvarchar(5)  NULL,
	usersession nvarchar(50)  NULL,
	primaryrecordid numeric(20,0) NULL,
	amendno nvarchar(25)  NULL,
	amendedby nvarchar(100)  NULL,
	amendedon datetime2 NULL,
	fieldlist varchar(MAX)  NULL,
	parselist varchar(MAX)  NULL,
	recidlist varchar(MAX)  NULL
)
>>
<<
alter table axapijobdetails add authstr varchar(100)
>>
<<CREATE TABLE axrequest (

	requestid varchar(100)  NOT NULL,
	requestreceivedtime datetimeoffset NULL,
	sourcefrom varchar(255)  NULL,
	requeststring text  NULL,
	headers text  NULL,
	params text  NULL,
	authz varchar(255)  NULL,
	contenttype varchar(150)  NULL,
	contentlength varchar(10)  NULL,
	host varchar(255)  NULL,
	url text  NULL,
	endpoint varchar(255)  NULL,
	requestmethod varchar(10)  NULL,
	apiname varchar(255)  NULL,
	username varchar(255)  NULL,
	additionaldetails text  NULL,
	sourcemachineip varchar(255)  NULL,
	CONSTRAINT axrequest_pkey PRIMARY KEY (requestid)
)
>>
<<
CREATE TABLE axresponse (
	responseid varchar(100)  NOT NULL,
	responsesenttime datetimeoffset NULL,
	statuscode int NULL,
	responsestring text  NULL,
	headers text  NULL,
	contenttype varchar(150)  NULL,
	contentlength varchar(10)  NULL,
	errordetails text  NULL,
	endpoint varchar(255)  NULL,
	requestmethod varchar(10)  NULL,
	username varchar(255)  NULL,
	additionaldetails text  NULL,
	requestid varchar(100)  NULL,
	executiontime varchar(20)  NULL,
	CONSTRAINT axresponse_pkey PRIMARY KEY (responseid),
	CONSTRAINT axresponse_requestid_fkey FOREIGN KEY (requestid) REFERENCES axrequest(requestid)
)
>>
<<
CREATE TABLE importdatadetails (
	Sessionid varchar(30)  NULL,
	Username varchar(50)  NULL,
	Calledon datetime NULL,
	Structname varchar(6)  NULL,
	Recordid numeric(15,0) NULL,
	Recordcount numeric(5,0) NULL,
	Paramdetails varchar(250)  NULL,
	Filename varchar(200)  NULL,
	Success numeric(5,0) NULL,
	ID numeric(30,0) NULL,
	Mapfields varchar(250)  NULL,
	Infile numeric(1,0) NULL
)
>>
<<
alter table importdatadetails add rapidimpid varchar(100)
>>
<<
CREATE TABLE importdataexceptions (
	Sessionid varchar(30)  NULL,
	Username varchar(50)  NULL,
	Calledon date NULL,
	Recordno numeric(5,0) NULL,
	Errormsg varchar(250)  NULL,
	ID varchar(30)  NULL
)
>>
<<
alter table importdataexceptions add rapidimpid varchar(100)
>>
<<
CREATE TABLE importdatacompletion
(
    id           NUMERIC(30, 0) NULL,
    rapidimpid   VARCHAR(100)   NULL,
    sessionid    VARCHAR(30)    NULL,
    username     VARCHAR(50)    NULL,
    calledon     DATETIME2      NULL,
    structname   VARCHAR(6)     NULL,
    filename     VARCHAR(200)   NULL,
    recordcount  NUMERIC(5, 0)  NULL,
    success      NUMERIC(5, 0)  NULL,
    resultmsg    VARCHAR(4000)  NULL,
    errlist      VARCHAR(MAX)  NULL,
    blobno       NUMERIC(18, 0) NULL
)
>>
<<
ALTER TABLE axprocessdefv2 ADD approve_forwardto varchar(1) NULL
>>
<<
ALTER TABLE axprocessdefv2 ADD return_to_priorindex varchar(1) NULL
>>
<<
ALTER TABLE axp_vp ALTER COLUMN vpvalue varchar(300)
>>
<<
alter table aximpdef add aximpprimaryfield_details varchar(300)
>>
<<
INSERT INTO AXIMPDEF (aximpdefid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, aximpdefname, aximpform, aximptransid, aximptextqualifier, aximpmapinfile, aximpheaderrows, aximpprimayfield, aximpgroupfield, aximpfieldseperator, aximpmapfields, aximpthreadcount, aximpprocname, aximpbindtotstruct, aximpstdcolumnwidth, aximpignorefldexception, aximponlyappend, aximpprocessmode, aximpfilefromtable, aximpfieldseperatorui, aximpprimaryfield_details) VALUES(1783010000000, N'F', 0, NULL, N'admin', '2023-03-28 00:00:00.000', N'admin', '2023-03-24 00:00:00.000', NULL, 1, 1, NULL, NULL, NULL, N'Axlanguage', N'Axlanguage Data', N'ad_li', N'F', N'F', 1, N'', N'compname', N',', N'dispname,sname,compname,compengcap,compcaption', 1, N'', N'F', 0, N'F', N'F', N'Process with error (ALL)', N'F', N'(comma)', NULL)
>>
<<
ALTER TABLE AXUSERGROUPS ADD mapname varchar(20)
>>
<<
CREATE TABLE ax_userconfigdata (
	page varchar(100)  NULL,
	struct varchar(100)  NULL,
	keyname varchar(100)  NULL,
	username varchar(100)  NULL,
	value nvarchar(MAX)  NULL
)
>>
<<
INSERT INTO axcardtypemaster (axcardtypemasterid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, cardtype, cardcaption, cardicon, axpfile_cardimg, axpfilepath_cardimg) VALUES(1362010000000, 'F', 0, NULL, 'abinash', '2021-04-28 19:18:59.000', 'abinash', '2021-04-28 19:18:42.000', NULL, 1, 1, NULL, NULL, NULL, 'chart', 'Chart', '', '', '')
>>
<<
INSERT INTO axcardtypemaster (axcardtypemasterid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, cardtype, cardcaption, cardicon, axpfile_cardimg, axpfilepath_cardimg) VALUES(1362220000000, 'F', 0, NULL, 'abinash', '2021-04-28 19:22:00.000', 'abinash', '2021-04-28 19:22:00.000', NULL, 1, 1, NULL, NULL, NULL, 'kpi', 'KPI', NULL, NULL, NULL)
>>
<<
INSERT INTO axcardtypemaster (axcardtypemasterid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, cardtype, cardcaption, cardicon, axpfile_cardimg, axpfilepath_cardimg) VALUES(1362440000000, 'F', 0, NULL, 'abinash', '2021-04-28 19:22:50.000', 'abinash', '2021-04-28 19:22:50.000', NULL, 1, 1, NULL, NULL, NULL, 'list', 'List', NULL, NULL, NULL)
>>
<<
INSERT INTO axcardtypemaster (axcardtypemasterid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, cardtype, cardcaption, cardicon, axpfile_cardimg, axpfilepath_cardimg) VALUES(1362550000000, 'F', 0, NULL, 'abinash', '2021-04-28 19:23:04.000', 'abinash', '2021-04-28 19:23:04.000', NULL, 1, 1, NULL, NULL, NULL, 'menu', 'Menu card', NULL, NULL, NULL)
>>
<<
INSERT INTO axcardtypemaster (axcardtypemasterid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, cardtype, cardcaption, cardicon, axpfile_cardimg, axpfilepath_cardimg) VALUES(1362660000000, 'F', 0, NULL, 'abinash', '2021-04-28 19:23:23.000', 'abinash', '2021-04-28 19:23:23.000', NULL, 1, 1, NULL, NULL, NULL, 'modern menu', 'Modern menu', NULL, NULL, NULL)
>>
<<
INSERT INTO axcardtypemaster (axcardtypemasterid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, cardtype, cardcaption, cardicon, axpfile_cardimg, axpfilepath_cardimg) VALUES(1659550000037, 'F', 0, NULL, 'abinash', '2021-05-07 09:33:54.000', 'abinash', '2021-05-07 09:33:54.000', NULL, 1, 1, NULL, NULL, NULL, 'image card', 'Image card', NULL, NULL, NULL)
>>
<<
INSERT INTO axcardtypemaster (axcardtypemasterid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, cardtype, cardcaption, cardicon, axpfile_cardimg, axpfilepath_cardimg) VALUES(1962990000000, 'F', 0, NULL, 'abinash', '2021-06-09 16:04:56.000', 'abinash', '2021-06-09 16:04:56.000', NULL, 1, 1, NULL, NULL, NULL, 'calendar', 'Calendar', NULL, NULL, NULL)
>>
<<
INSERT INTO axcardtypemaster (axcardtypemasterid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, cardtype, cardcaption, cardicon, axpfile_cardimg, axpfilepath_cardimg) VALUES(1042770000000, 'F', 0, NULL, 'admin', '2022-01-24 19:52:53.000', 'admin', '2022-01-24 19:52:53.000', NULL, 1, 1, NULL, NULL, NULL, 'html', 'HTML Card', NULL, NULL, NULL)
>>
<<
INSERT INTO axcardtypemaster (axcardtypemasterid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, cardtype, cardcaption, cardicon, axpfile_cardimg, axpfilepath_cardimg) VALUES(8139880000000, 'F', 0, NULL, 'admin', '2023-04-26 18:15:25.000', 'admin', '2023-04-26 18:15:25.000', NULL, 1, 1, NULL, NULL, NULL, 'options card', 'options card', NULL, NULL, NULL)
>>
<<
CREATE TABLE ax_htmlplugins (
	name nvarchar(200)  NOT NULL,
	htmltext nvarchar(MAX)  NULL,
	context nvarchar(20)  NULL,
	CONSTRAINT ax_htmlplugins_pk PRIMARY KEY (name)
)
>>
<<
CREATE TABLE AXTOOLBAR (
	name nvarchar(50)  NULL,
	stype nvarchar(20)  NULL,
	title nvarchar(50)  NULL,
	[key] nvarchar(50)  NULL,
	folder nvarchar(10)  NULL,
	[action] nvarchar(100)  NULL,
	task nvarchar(100)  NULL,
	script nvarchar(1000)  NULL,
	icon nvarchar(100)  NULL,
	parent nvarchar(50)  NULL,
	haschildren nvarchar(5)  NULL,
	ordno numeric(3,0) NULL,
	footer nvarchar(6)  NULL,
	visible nvarchar(7)  NULL,
	parentdc nvarchar(10)  NULL,
	[position] nvarchar(30)  NULL,
	api nvarchar(200)  NULL,
	scripts nvarchar(100)  NULL
)
>>
<<
CREATE TABLE axmmetadatamaster (
	structtype nvarchar(10)  NULL,
	structname nvarchar(15)  NULL,
	structcaption nvarchar(50)  NULL,
	structstatus nvarchar(50)  NULL,
	ordno numeric(18,0) NULL,
	createdon datetime DEFAULT getdate() NULL,
	updatedon datetime NULL,
	createdby nvarchar(50)  NULL,
	updatedby nvarchar(50)  NULL,
	CONSTRAINT unique_structtype_structname UNIQUE (structtype,structname)
)
>>
<<
INSERT INTO axmmetadatamaster
(
    structtype,
    structname,
    structcaption,
    structstatus,
    createdon,
    updatedby,
    createdby,
    updatedon
)
SELECT DISTINCT
    'tstruct' AS structtype,
    t.name    AS structname,
    t.caption AS structcaption,
    'prepare' AS structstatus,
    null AS createdon,
    COALESCE(t.updatedby, 'admin') AS updatedby,
    COALESCE(t.createdby, 'admin') AS createdby,
    null AS updatedon
FROM tstructs t
JOIN (
        SELECT SUBSTRING(pagetype, 2, LEN(pagetype)) AS stname
        FROM axpages
        WHERE LEN(pagetype) > 1
     ) c
    ON t.name = c.stname
WHERE NOT EXISTS
(
    SELECT 1
    FROM axmmetadatamaster m
    WHERE m.structname = t.name
      AND m.structtype = 'tstruct'
)
AND t.blobno = 1
UNION ALL
SELECT DISTINCT
    'iview' AS structtype,
    i.name  AS structname,
    i.caption AS structcaption,
    'prepare' AS structstatus,
    null AS createdon,
    COALESCE(i.updatedby, 'admin') AS updatedby,
    COALESCE(i.createdby, 'admin') AS createdby,
    null AS updatedon
FROM iviews i
JOIN (
        SELECT SUBSTRING(pagetype, 2, LEN(pagetype)) AS stname
        FROM axpages
        WHERE LEN(pagetype) > 1
     ) c
    ON i.name = c.stname
WHERE NOT EXISTS
(
    SELECT 1
    FROM axmmetadatamaster m
    WHERE m.structname = i.name
      AND m.structtype = 'iview'
)
AND i.blobno = 1
>>
<<
alter table axpertlog add calldetails varchar(2000)
>>
<<
CREATE TABLE AXPUBLISHREPORT (
	transid nvarchar(30)  NULL,
	publishedon nvarchar(25)  NULL,
	publishedby nvarchar(30)  NULL,
	status nvarchar(4000)  NULL,
	remarks nvarchar(1000)  NULL,
	createdon datetime DEFAULT getdate() NULL,
	publishedto nvarchar(100)  NULL,
	transtype nvarchar(10)  NULL
)
>>
<<
CREATE TABLE tstructscripts (
	username nvarchar(50)  NOT NULL,
	createdon datetime DEFAULT getdate() NULL,
	createdby nvarchar(50)  NULL,
	modifiedon datetime NULL,
	modifiedby nvarchar(50)  NULL,
	stransid nvarchar(5)  NULL,
	control_type char(1)  NULL,
	event nvarchar(50)  NULL,
	[type] nvarchar(20)  NULL,
	name nvarchar(10)  NULL,
	caption nvarchar(20)  NULL,
	script text  NULL
)
>>
<<
CREATE TABLE iviewscripts (
	username varchar(50)  NULL,
	modifiedon datetime2 NULL,
	modifiedby varchar(50)  NULL,
	createdby varchar(50)  NULL,
	createdon datetime2 NULL,
	iname varchar(8)  NULL,
	event varchar(50)  NULL,
	stype varchar(10)  NULL,
	name varchar(10)  NULL,
	caption varchar(20)  NULL,
	exp_editor_script nvarchar(MAX)  NULL
)
>>
<<
DROP TABLE customtypes;
>>
<<
CREATE TABLE customtypes (
	customtypesid numeric(16,0) NOT NULL,
	cancel nvarchar(1)  NULL,
	sourceid numeric(16,0) NULL,
	mapname nvarchar(20)  NULL,
	username nvarchar(50)  NULL,
	modifiedon datetime NULL,
	createdby nvarchar(50)  NULL,
	createdon datetime NULL,
	wkid nvarchar(15)  NULL,
	app_level numeric(3,0) NULL,
	app_desc numeric(1,0) NULL,
	app_slevel numeric(3,0) NULL,
	cancelremarks nvarchar(150)  NULL,
	wfroles nvarchar(250)  NULL,
	typename nvarchar(20)  NULL,
	datatype nvarchar(10)  NULL,
	width numeric(4,0) NULL,
	deci numeric(5,3) NULL,
	namecheck nvarchar(30)  NULL,
	replacechar nvarchar(30)  NULL,
	fcharcheck nvarchar(30)  NULL,
	validchk nvarchar(30)  NULL,
	modeofentry nvarchar(20)  NULL,
	cvalues nvarchar(100)  NULL,
	defaultvalue nvarchar(100)  NULL,
	sql_editor_details nvarchar(500)  NULL,
	exp_editor_expression nvarchar(200)  NULL,
	exp_editor_validateexpression nvarchar(200)  NULL,
	readonly nvarchar(10)  NULL,
	chide nvarchar(1)  NULL,
	cpattern nvarchar(20)  NULL,
	cmask nvarchar(50)  NULL,
	cregularexpress nvarchar(500)  NULL,
	CONSTRAINT aglcustomtypesid PRIMARY KEY (customtypesid)
)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1065440000000, 'F', 0, NULL, 'admin', '2020-10-30 11:50:42.000', 'admin', '2020-09-15 17:31:04.000', NULL, 1, 1, NULL, NULL, NULL, 'Random Number', 'Numeric', 10, 0.000, 'ADD', 'Random Number', 'T', 'T', 'Accept', '', '', '', '', '', 'F', 'F', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1055660000007, 'F', 0, NULL, 'admin', '2020-09-12 13:37:11.000', 'admin', '2020-09-12 09:39:26.000', NULL, 1, 1, NULL, NULL, NULL, 'Date', 'Date/Time', 10, 0.000, 'ADD', 'Date', 'T', 'T', 'Accept', '', '', '', 'Date()', '', '', '', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1056880000000, 'F', 0, NULL, 'admin', '2020-09-14 14:57:46.000', 'admin', '2020-09-14 14:57:46.000', NULL, 1, 1, NULL, NULL, NULL, 'Short Text', 'Character', 10, 0.000, 'ADD', 'Short Text', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1055660000009, 'F', 0, NULL, 'admin', '2020-09-15 11:27:42.000', 'admin', '2020-09-12 09:42:14.000', NULL, 1, 1, NULL, NULL, NULL, 'Auto Generate', 'Character', 20, 0.000, 'ADD', 'Auto Generate', 'T', 'T', 'AutoGenerate', '', '', '', '', '', 'T', '', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1055660000003, 'F', 0, NULL, 'admin', '2020-09-15 14:23:29.000', 'admin', '2020-09-12 09:37:34.000', NULL, 1, 1, NULL, NULL, NULL, 'HTML Text', 'Text', 4000, 0.000, 'ADD', 'HTML Text', 'T', 'T', 'Accept', '', '', '', '', '', '', '', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1055660000002, 'F', 0, NULL, 'admin', '2020-09-15 14:23:55.000', 'admin', '2020-09-12 09:37:09.000', NULL, 1, 1, NULL, NULL, NULL, 'Rich Text', 'Text', 4000, 0.000, 'ADD', 'Rich Text', 'T', 'T', 'Accept', '', '', '', '', '', '', '', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1055660000004, 'F', 0, NULL, 'admin', '2020-09-15 14:24:09.000', 'admin', '2020-09-12 09:38:05.000', NULL, 1, 1, NULL, NULL, NULL, 'Whole Number', 'Numeric', 10, 0.000, 'ADD', 'Whole Number', 'T', 'T', 'Accept', '', '', '', '', '', '', '', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1055660000000, 'F', 0, NULL, 'admin', '2020-09-15 14:24:39.000', 'admin', '2020-09-12 09:36:21.000', NULL, 1, 1, NULL, NULL, NULL, 'Simple Text', 'Character', 50, 0.000, 'ADD', 'Simple Text', 'T', 'T', 'Accept', '', '', '', '', '', '', '', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1055660000008, 'F', 0, NULL, 'admin', '2020-09-15 14:24:53.000', 'admin', '2020-09-12 09:39:45.000', NULL, 1, 1, NULL, NULL, NULL, 'Time', 'Character', 10, 0.000, 'ADD', 'Time', 'T', 'T', 'Accept', '', '', '', '', '', '', '', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1055660000006, 'F', 0, NULL, 'admin', '2020-09-15 14:25:08.000', 'admin', '2020-09-12 09:38:56.000', NULL, 1, 1, NULL, NULL, NULL, 'Currency', 'Numeric', 10, 2.000, 'ADD', 'Currency', 'T', 'T', 'Accept', '', '', '', '', '', '', '', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1055660000005, 'F', 0, NULL, 'admin', '2020-09-15 15:17:38.000', 'admin', '2020-09-12 09:38:31.000', NULL, 1, 1, NULL, NULL, NULL, 'Decimal Number', 'Numeric', 10, 2.000, 'ADD', 'Decimal Number', 'T', 'T', 'Accept', '', '', '', '', '', '', '', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1065550000000, 'F', 0, NULL, 'admin', '2020-09-15 17:31:30.000', 'admin', '2020-09-15 17:31:30.000', NULL, 1, 1, NULL, NULL, NULL, 'Email', 'Character', 50, 0.000, 'ADD', 'Email', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1065660000000, 'F', 0, NULL, 'admin', '2020-09-15 17:32:07.000', 'admin', '2020-09-15 17:32:07.000', NULL, 1, 1, NULL, NULL, NULL, 'URL', 'Character', 100, 0.000, 'ADD', 'URL', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1065880000000, 'F', 0, NULL, 'admin', '2020-09-15 17:32:55.000', 'admin', '2020-09-15 17:32:55.000', NULL, 1, 1, NULL, NULL, NULL, 'Password', 'Character', 15, 0.000, 'ADD', 'Password', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1065990000000, 'F', 0, NULL, 'admin', '2020-09-15 17:33:55.000', 'admin', '2020-09-15 17:33:55.000', NULL, 1, 1, NULL, NULL, NULL, 'Mobile Number', 'Numeric', 10, 0.000, 'ADD', 'Mobile Number', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1066010000000, 'F', 0, NULL, 'admin', '2020-09-15 17:34:16.000', 'admin', '2020-09-15 17:34:16.000', NULL, 1, 1, NULL, NULL, NULL, 'Phone Number', 'Numeric', 10, 0.000, 'ADD', 'Phone Number', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1066110000000, 'F', 0, NULL, 'admin', '2020-09-15 17:34:36.000', 'admin', '2020-09-15 17:34:36.000', NULL, 1, 1, NULL, NULL, NULL, 'Pin Code', 'Numeric', 6, 0.000, 'ADD', 'Pin Code', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1066220000000, 'F', 0, NULL, 'admin', '2020-09-15 17:34:58.000', 'admin', '2020-09-15 17:34:58.000', NULL, 1, 1, NULL, NULL, NULL, 'Zip Code', 'Numeric', 6, 0.000, 'ADD', 'Zip Code', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1065770000000, 'F', 0, NULL, 'admin', '2020-09-16 10:11:07.000', 'admin', '2020-09-15 17:32:28.000', NULL, 1, 1, NULL, NULL, NULL, 'IP Address', 'Character', 100, 0.000, 'ADD', 'IP Address', 'T', 'T', 'Accept', '', '', '', '', '', 'F', 'F', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1100220000000, 'F', 0, NULL, 'admin', '2020-09-30 10:44:32.000', 'admin', '2020-09-30 10:44:32.000', NULL, 1, 1, NULL, NULL, NULL, 'Table', 'Character', 2000, 0.000, 'ADD', 'Table', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1078330000000, 'F', 0, NULL, 'admin', '2020-09-30 14:34:24.000', 'admin', '2020-09-25 10:50:28.000', NULL, 1, 1, NULL, NULL, NULL, 'DropDown', 'Character', 20, 0.000, 'ADD', 'DropDown', 'T', 'T', 'Select From Form', '', '', '', '', '', 'F', 'F', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1139550000000, 'F', 0, NULL, 'admin', '2020-10-21 17:12:41.000', 'admin', '2020-10-21 17:12:41.000', NULL, 1, 1, NULL, NULL, NULL, 'Expression Editor', 'Character', 300, 0.000, 'ADD', 'Expression Editor', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1139440000000, 'F', 0, NULL, 'admin', '2020-10-21 17:13:09.000', 'admin', '2020-10-21 17:08:31.000', NULL, 1, 1, NULL, NULL, NULL, 'SQL Editor', 'Character', 2000, 0.000, 'ADD', 'SQL Editor', 'T', 'T', 'Accept', '', '', '', '', '', 'F', 'F', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1200660000000, 'F', 0, NULL, 'admin', '2020-11-24 15:18:20.000', 'admin', '2020-11-24 15:18:20.000', NULL, 1, 1, NULL, NULL, NULL, 'Image', 'Image', 50, 0.000, 'ADD', 'Image', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1215880000000, 'F', 0, NULL, 'admin', '2020-12-02 12:15:06.000', 'admin', '2020-12-01 13:09:13.000', NULL, 1, 1, NULL, NULL, NULL, 'RadioGroup', 'Character', 50, 0.000, 'ADD', 'RadioGroup', 'T', 'T', 'Select From Form', '', '', '', '', '', 'F', 'F', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1215770000000, 'F', 0, NULL, 'admin', '2020-12-01 13:35:40.000', 'admin', '2020-12-01 13:08:45.000', NULL, 1, 1, NULL, NULL, NULL, 'Check box', 'Character', 20, 0.000, 'ADD', 'Check box', 'T', 'T', 'Accept', '', '', '', '', '', 'F', 'F', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1215660000000, 'F', 0, NULL, 'admin', '2020-12-02 12:14:54.000', 'admin', '2020-12-01 13:08:19.000', NULL, 1, 1, NULL, NULL, NULL, 'CheckList', 'Character', 50, 0.000, 'ADD', 'CheckList', 'T', 'T', 'Select From Form', '', '', '', '', '', 'F', 'F', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1245880000000, 'F', 0, NULL, 'admin', '2020-12-09 15:29:42.000', 'admin', '2020-12-09 15:29:42.000', NULL, 1, 1, NULL, NULL, NULL, 'Multi Select', 'Character', 200, 0.000, 'ADD', 'Multi Select', 'T', 'T', 'Select From Form', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1055660000001, 'F', 0, NULL, 'admin', '2020-09-15 10:58:45.000', 'admin', '2020-09-12 09:36:46.000', NULL, 1, 1, NULL, NULL, NULL, 'Large Text', 'Text', 4000, 0.000, 'ADD', 'Large Text', 'T', 'T', 'Accept', '', '', '', '', '', '', '', '', '', '')
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1058990000006, 'F', 0, NULL, 'admin', '2022-07-04 12:59:55.000', 'admin', '2022-07-04 12:59:55.000', NULL, 1, 1, NULL, NULL, NULL, 'Address', 'Character', 1000, 0.000, 'ADD', 'Address', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1058990000005, 'F', 0, NULL, 'admin', '2022-07-04 12:59:38.000', 'admin', '2022-07-04 12:59:38.000', NULL, 1, 1, NULL, NULL, NULL, 'Boolean', 'Character', 10, 0.000, 'ADD', 'Boolean', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1058990000004, 'F', 0, NULL, 'admin', '2022-07-04 12:59:13.000', 'admin', '2022-07-04 12:59:13.000', NULL, 1, 1, NULL, NULL, NULL, 'Date Range', 'Character', 500, 0.000, 'ADD', 'Date Range', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1058990000003, 'F', 0, NULL, 'admin', '2022-07-04 12:59:03.000', 'admin', '2022-07-04 12:59:03.000', NULL, 1, 1, NULL, NULL, NULL, 'File upload field', 'Character', 250, 0.000, 'ADD', 'File upload field', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1058990000002, 'F', 0, NULL, 'admin', '2022-07-04 12:58:51.000', 'admin', '2022-07-04 12:58:51.000', NULL, 1, 1, NULL, NULL, NULL, 'Number range', 'Character', 500, 0.000, 'ADD', 'Number range', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1058990000001, 'F', 0, NULL, 'admin', '2022-07-04 12:58:39.000', 'admin', '2022-07-04 12:58:39.000', NULL, 1, 1, NULL, NULL, NULL, 'Time Range', 'Character', 500, 0.000, 'ADD', 'Time Range', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
INSERT INTO customtypes (customtypesid, cancel, sourceid, mapname, username, modifiedon, createdby, createdon, wkid, app_level, app_desc, app_slevel, cancelremarks, wfroles, typename, "datatype", width, deci, namecheck, replacechar, fcharcheck, validchk, modeofentry, cvalues, defaultvalue, sql_editor_details, exp_editor_expression, exp_editor_validateexpression, readonly, chide, cpattern, cmask, cregularexpress) VALUES(1058990000000, 'F', 0, NULL, 'admin', '2022-07-04 12:58:25.000', 'admin', '2022-07-04 12:58:25.000', NULL, 1, 1, NULL, NULL, NULL, 'Website', 'Character', 250, 0.000, 'ADD', 'Website', 'T', 'T', 'Accept', NULL, NULL, NULL, NULL, NULL, 'F', 'F', NULL, NULL, NULL)
>>
<<
UPDATE axdirectsql SET sqltext='select	title,subdetails subtitle,modifiedon ,''ta__na(recordid=''||axpdef_news_eventsid||'')'' link
from axpdef_news_events
where active=''T'' 
and  (current_date >= effectfrom and (effecto >= current_date or effecto is null))
order by effectfrom' where sqlname='ds_homepage_events'
>>
<<
ALTER TABLE axp_appsearch_data_period Disable TRIGGER axp_tr_search_appsearch1
>>
<<
CREATE TABLE AXPDEF_USERGROUPS (
	axpdef_usergroupsid numeric(16,0) NOT NULL,
	Cancel char(1)  NULL,
	Sourceid numeric(16,0) NULL,
	MapName varchar(20)  NULL,
	UserName varchar(50)  NULL,
	Modifiedon datetime NULL,
	CreatedBy varchar(50)  NULL,
	CreatedOn datetime NULL,
	Wkid varchar(15)  NULL,
	App_level numeric(3,0) NULL,
	App_desc numeric(1,0) NULL,
	App_slevel numeric(3,0) NULL,
	CancelRemarks nvarchar(500)  NULL,
	WFRoles varchar(250)  NULL,
	usernames nvarchar(4000)  NULL,
	users_group_name nvarchar(254)  NULL,
	users_group_description nvarchar(254)  NULL,
	isactive nvarchar(1)  NULL,
	CONSTRAINT AGLaxpdef_usergroupsid PRIMARY KEY (axpdef_usergroupsid)
)
>>
<<

CREATE TABLE ax_mobilenotify (
	username varchar(50)  NULL,
	projectname varchar(50)  NULL,
	guid varchar(200)  NULL,
	firebase_id varchar(500)  NULL,
	imei_no varchar(50)  NULL,
	status varchar(2)  NULL
)
>>
<<
CREATE OR ALTER FUNCTION dbo.fn_dbo_notify_periodic_json(@projname varchar(100),@name varchar(300),@fromuser varchar(200),@startdate date,@frequency varchar(100),@Sendday varchar(100),@sendon varchar(100),@sendtime varchar(20))
RETURNS nvarchar(max)
AS
begin
declare 
@v_json nvarchar(max)



select @v_json =
	json_object('queuename':'ARMPeriodicNotificationQueue',
	'queuedata':'ARMPeriodicNotificationQueueData',
	'queuejson':(select
		@projname project,
		@name notification,
		@fromuser username,
		cast( @startdate as date) start_date,
		@frequency period ,
		case
			when @frequency = 'Weekly' then @Sendday
			else @sendon
		end sendon,
		@sendtime sendtime for json path,WITHOUT_ARRAY_WRAPPER ))


	return @v_json;	
end;
>>
<<
create OR ALTER  FUNCTION dbo.fn_ruledef_formula_v1(@formula varchar(max), @applicability varchar(max), @nexttask varchar(max), @nexttask_true varchar(max), @nexttask_false varchar(max), @pegversion varchar(10) ='v1')
RETURNS nvarchar(max)
AS
begin
   declare
   @v_script nvarchar(max);
   
  WITH a AS (
    SELECT value AS cols
    FROM dbo.regexp_split_to_table(@formula, '~')
),
b AS (
    SELECT 
        cols,
        dbo.split_part(cols, '|', 1) AS sp1,
        dbo.split_part(cols, '|', 2) AS sp2,
        dbo.split_part(cols, '|', 3) AS sp3,
        dbo.split_part(cols, '|', 4) AS sp4
    FROM a
),
c AS (
    SELECT STRING_AGG(
        CASE 
            WHEN b.sp2 NOT IN ('In','Not in') 
            THEN SUBSTRING(
                     SUBSTRING(b.sp1, CHARINDEX('-(', b.sp1) + 2,
                     ABS((CHARINDEX('-(', b.sp1) + 2) - LEN(b.sp1))), 
                     2, LEN(b.sp1))
            ELSE '' 
        END + ' ' +
        CASE 
            WHEN b.sp2 = 'Equal to' THEN '='
            WHEN b.sp2 = 'Not equal to' THEN '#'
            WHEN b.sp2 = 'Greater than' THEN '>'
            WHEN b.sp2 = 'Lesser than' THEN '<'
            WHEN b.sp2 IN ('In','Not in') THEN 
                'StringPOS(' +
                SUBSTRING(
                    SUBSTRING(b.sp1, CHARINDEX('-(', b.sp1) + 2,
                    ABS((CHARINDEX('-(', b.sp1) + 2) - LEN(b.sp1))),
                    2, LEN(b.sp1)
                ) + ','
        END + ' ' +
        CASE 
            WHEN SUBSTRING(
                    SUBSTRING(b.sp1, CHARINDEX('-(', b.sp1) + 2,
                    ABS((CHARINDEX('-(', b.sp1) + 2) - LEN(b.sp1))),
                    1, 1
                 ) IN ('c','t')
            THEN CASE 
                    WHEN SUBSTRING(LTRIM(RTRIM(b.sp3)),1,1) <> ':' 
                        THEN '{' + b.sp3 + '}'
                    ELSE REPLACE(b.sp3, ':', ' ')
                 END
            ELSE CASE 
                    WHEN SUBSTRING(LTRIM(RTRIM(b.sp3)),1,1) <> ':' 
                        THEN b.sp3
                    ELSE REPLACE(b.sp3, ':', ' ')
                 END
        END +
        CASE 
            WHEN b.sp2 = 'In' THEN ') # -1'
            WHEN b.sp2 = 'Not in' THEN ') = -1'
            ELSE ''
        END + ' ' +
        CASE 
            WHEN b.sp4 = 'And' THEN '&'
            WHEN b.sp4 = 'Or' THEN '|'
            WHEN b.sp4 = 'And(' THEN '&('
            WHEN b.sp4 = 'Or(' THEN '|('
            ELSE b.sp4
        END, ' '
    ) AS cndtxt
    FROM b
)
select @v_script= case when @applicability ='T' then 'iif('+c.cndtxt+',{T},{F})' 
when @nexttask='T' then 'iif('+c.cndtxt+',{'+@nexttask_true+'},'+'{'+@nexttask_false+'})'
else c.cndtxt end    from c;

return  @v_script;
end;
>>
<<
CREATE  OR ALTER FUNCTION dbo.fn_ruledef_table_genaxscript(@pcmd varchar(50), @ptbldtls nvarchar(max), @pcnd numeric)
 RETURNS nvarchar(max)
 AS
 BEGIN
declare
    @v_formula nvarchar(max);

if @pcnd =2 
	select @v_formula=
	case
		when @pcmd = 'Show' then concat('Axunhidecontrols({', fnames , '})')
		when @pcmd = 'Hide' then concat('Axhidecontrols({', fnames , '})')
		when @pcmd = 'Enable' then concat('Axenablecontrols({', fnames , '})')
		when @pcmd = 'Disable' then concat('Axdisablecontrols({', fnames , '})')
		when @pcmd = 'Mandatory' then concat('AxAllowEmpty({', fnames , '},{F})')
		when @pcmd = 'Non mandatory' then concat('AxAllowEmpty({', fnames , '},{T})')
	end 
	from(
	select string_agg(substring(value, CHARINDEX('-(',value)+ 2, abs((CHARINDEX('-(',value )+ 2) - len(substring(value, 1, len(value))))),',') fnames 
	from dbo.regexp_split_to_table(@ptbldtls, '~'))n; 
	
RETURN @v_formula;
END;
>>
<<
CREATE  OR ALTER  FUNCTION dbo.fn_ruledef_tablefield
(
    @pcnd INT
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @v_json VARCHAR(MAX);

    /*
    1  If, Else if
    2  Enable, Show, Hide, Disable, Mandatory, Non mandatory
    3  Mask all characters, Mask few characters
    4  Set value to field
    5  Show message, Show error
    6  Else
    */

    IF @pcnd = 1   -- If , Else if
    BEGIN
        SET @v_json =
'{"props":{"type":"table","colcount":"4","rowcount":"1","addrow":"t","deleterow":"t","valueseparator":"|","rowseparator":"~"},
  "columns":{
    "1":{"caption":"Condition field","name":"cfld","value":"","source":"cndfldcaption","exp":"","vexp":""},
    "2":{"caption":"Operator","name":"opr","value":"","source":"formula_opr","exp":"","vexp":""},
    "3":{"caption":"Value","name":"fldvalue","value":"","source":"","exp":"","vexp":""},
    "4":{"caption":"Condition","name":"ccnd","value":"","source":"formula_andor","exp":"","vexp":""}
  }}';
    END
    ELSE IF @pcnd = 2   -- Enable, Disable, Show, Hide, Mandatory, Non mandatory
    BEGIN
        SET @v_json =
'{"props":{"type":"table","colcount":"1","rowcount":"1","addrow":"t","deleterow":"t","valueseparator":"|","rowseparator":"~"},
  "columns":{
    "1":{"caption":"Apply rule on","name":"cndfld","value":"","source":"fctlfldcaption","exp":"","vexp":""}
  }}';
    END
    ELSE IF @pcnd = 4   -- Set value to field
    BEGIN
        SET @v_json =
'{"props":{"type":"table","colcount":"2","rowcount":"1","addrow":"t","deleterow":"t","valueseparator":"|","rowseparator":"~"},
  "columns":{
    "1":{"caption":"Set value to field","name":"cndfld","value":"","source":"setvalueflds","exp":"","vexp":""},
    "2":{"caption":"Value","name":"sval","value":"","source":"","exp":"","vexp":""}
  }}';
    END
    ELSE IF @pcnd = 5   -- Show message, Show error
    BEGIN
        SET @v_json =
'{"props":{"type":"table","colcount":"1","rowcount":"1","addrow":"f","deleterow":"f","valueseparator":"|","rowseparator":"~"},
  "columns":{
    "1":{"caption":"Message","name":"cndfld","value":"","source":"","exp":"","vexp":""}
  }}';
    END

    RETURN @v_json;
END;
>>
<<
CREATE  OR ALTER  FUNCTION dbo.fn_ruledefv3_masking
(
    @pmaskstring VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE 
        @v_maskstring      VARCHAR(MAX),
        @v_maskfldcap      VARCHAR(MAX),
        @v_maskfldname     VARCHAR(MAX),
        @v_masktype        VARCHAR(MAX),
        @v_maskchar        VARCHAR(MAX),
        @v_maskfirstnchar  VARCHAR(MAX),
        @v_masklastnchar   VARCHAR(MAX),
        @result            VARCHAR(MAX) = '';

    DECLARE @t TABLE
    (
        id INT IDENTITY(1,1),
        maskstr VARCHAR(MAX)
    );

 
    INSERT INTO @t(maskstr)
    SELECT value
    FROM STRING_SPLIT(@pmaskstring, '~');

    DECLARE @i INT = 1;
    DECLARE @cnt INT = (SELECT COUNT(*) FROM @t);

    WHILE @i <= @cnt
    BEGIN
        SELECT @v_maskfldcap = maskstr
        FROM @t
        WHERE id = @i;

        SET @v_maskfldname =
            SUBSTRING(
                @v_maskfldcap,
                CHARINDEX('-(', @v_maskfldcap) + 2,
                ABS(
                    (CHARINDEX('-(', @v_maskfldcap) + 2)
                    - LEN(@v_maskfldcap)
                )
            );

        SET @v_masktype        = dbo.split_part(@v_maskfldcap, '|', 2);
        SET @v_maskchar        = dbo.split_part(@v_maskfldcap, '|', 3);
        SET @v_maskfirstnchar  = dbo.split_part(@v_maskfldcap, '|', 4);
        SET @v_masklastnchar   = dbo.split_part(@v_maskfldcap, '|', 5);

        SET @v_maskstring =
            CASE 
                WHEN @v_masktype = 'Mask few characters'
                THEN CONCAT(
                        'AxMask({', @v_maskfldname, '},{',
                        @v_maskchar, '},{',
                        @v_maskfirstnchar, '~', @v_masklastnchar,
                        '})'
                     )
                ELSE CONCAT(
                        'AxMask({', @v_maskfldname, '},{',
                        @v_maskchar, '},{all})'
                     )
            END;

        SET @result =
            CASE 
                WHEN @result = '' THEN @v_maskstring
                ELSE @result + CHAR(10) + @v_maskstring
            END;

        SET @i += 1;
    END;

    RETURN @result;
   
END;
>>
<<
CREATE  OR ALTER FUNCTION dbo.fn_ruledefv3_scriptgen (@pcmd VARCHAR(MAX), @pfldstring VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @v_fldnames VARCHAR(MAX);

    SELECT @v_fldnames = STRING_AGG(fname, ',')
    FROM (
        SELECT 
            SUBSTRING(value, CHARINDEX('-(', value) + 2, 
                      ABS((CHARINDEX('-(', value) + 2) - LEN(value))) 
        AS fname
        FROM STRING_SPLIT(@pfldstring, ',')
        WHERE @pfldstring IS NOT NULL
    ) a;

    RETURN CASE
        WHEN @pcmd = 'Mandatory' THEN CONCAT('AxAllowEmpty({', @v_fldnames, '},{F})')
        WHEN @pcmd = 'NonMandatory' THEN CONCAT('AxAllowEmpty({', @v_fldnames, '},{T})')
        ELSE CONCAT(@pcmd, '({', @v_fldnames, '})')
    END;
END;
>>
<<
CREATE  OR ALTER FUNCTION dbo.regexp_split_to_table(@pstring varchar(max),@pdelimiter varchar(10))
RETURNS TABLE
AS
RETURN
(
    SELECT value FROM STRING_SPLIT(@pstring, @pdelimiter)
);

CREATE FUNCTION dbo.Split_Part (
    @String NVARCHAR(MAX),
    @Delimiter NVARCHAR(1),
    @Part INT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Result NVARCHAR(MAX);

    WITH CTE AS (
        SELECT 
            value,
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS PartIndex
        FROM STRING_SPLIT(@String, @Delimiter)
    )
    SELECT @Result = value
    FROM CTE
    WHERE PartIndex = @Part;

    RETURN @Result;
END;
>>
<<
CREATE OR ALTER VIEW axp_vw_menulist
AS
SELECT
    REPLACE(
        REPLACE(
            ISNULL('\' + h.caption, '') + ISNULL('\' + g.caption, ''),
            '\\\', '\'
        ),
        '\\', '\'
    ) AS menupath,
    g.name,
    g.ordno,
    g.levelno,
    g.parent,
    g.type,
    g.pagetype
FROM axpages g
LEFT JOIN (
    SELECT
        ISNULL('\' + f.caption, '') + ISNULL('\' + e.caption, '') AS caption,
        e.parent,
        e.name
    FROM axpages e
    LEFT JOIN (
        SELECT
            (ISNULL('\' + d.caption, '') + '\') + ISNULL(c.caption, '') AS caption,
            c.name
        FROM axpages c
        LEFT JOIN (
            SELECT
                a.name,
                a.parent,
                a.caption,
                a.levelno,
                a.ordno,
                1 AS levlno
            FROM axpages a
            WHERE a.levelno = 0
        ) d
            ON c.parent = d.name
        WHERE c.levelno IN (0, 1)
    ) f
        ON e.parent = f.name
    WHERE e.levelno IN (0, 1, 2)
) h
    ON g.parent = h.name
WHERE ISNULL(g.levelno, 0) <= 3;
>>
<<
CREATE OR ALTER  VIEW axp_vw_menu AS
SELECT 
    REPLACE(REPLACE(COALESCE(h.caption, '') + COALESCE('\', '') + g.caption, '\\', '\'), '\\', '\') AS menupath,
    g.caption,
    g.name,
    g.ordno,
    g.levelno,
    g.parent,
    g.type,
    g.pagetype,
    REPLACE(REPLACE((COALESCE('\', '') + COALESCE(g.visible, 'F') + COALESCE('\', '') + h.visible), '\\', '\'), '\\', '\') AS visible
FROM axpages g
LEFT JOIN (
    SELECT 
        COALESCE(f.caption, '') + COALESCE('\', '') + e.caption AS caption,
        e.parent,
        e.name,
        (COALESCE('\', '') + COALESCE(f.visible, '') + COALESCE('\', '') + e.visible) AS visible
    FROM axpages e
    LEFT JOIN (
        SELECT 
            (COALESCE(d.caption, '') + '\' + COALESCE(c.caption, '')) AS caption,
            c.name,
            (COALESCE('\', '') + COALESCE(d.visible, '') + COALESCE('\', '') + c.visible) AS visible
        FROM axpages c
        LEFT JOIN (
            SELECT 
                a.name,
                a.parent,
                a.caption,
                a.levelno,
                a.ordno,
                1 AS levlno,
                ('\' + a.visible) AS visible
            FROM axpages a
            WHERE a.levelno = 0
             ) d ON c.parent = d.name
        WHERE c.levelno IN (0, 1)
    ) f ON e.parent = f.name
    WHERE e.levelno IN (0, 1, 2)
) h ON g.parent = h.name
WHERE g.levelno <= 3
;
>>
<<
CREATE   VIEW axp_appsearch_data_new
AS 
SELECT 
    2 AS slno,
    axp_appsearch_data_v2.hltype ,
    axp_appsearch_data_v2.structname ,
    LTRIM(RTRIM(REPLACE(CAST(axp_appsearch_data_v2.searchtext AS NVARCHAR), 'View', ' ')))  AS searchtext,
    axp_appsearch_data_v2.params  AS params,
    cast(a.oldappurl as NVARCHAR)  as oldappurl
FROM axp_appsearch_data_v2
JOIN axpages a ON 
    CASE axp_appsearch_data_v2.hltype
        WHEN 'iview' THEN ('i' + CAST(axp_appsearch_data_v2.structname AS NVARCHAR)) 
        WHEN 'tstruct' THEN ('t' + CAST(axp_appsearch_data_v2.structname AS NVARCHAR)) 
        ELSE axp_appsearch_data_v2.structname 
    END =
    CASE
        WHEN axp_appsearch_data_v2.hltype = 'Page' THEN a.name 
        ELSE a.pagetype 
    END
WHERE LOWER(CAST(axp_appsearch_data_v2.params AS NVARCHAR)) NOT LIKE '%current_date%'
UNION ALL
 SELECT 1.9 AS slno, cast(a.hltype as NVARCHAR) as hltype, 
 cast(a.structname as NVARCHAR)  as structname,
    LTRIM(RTRIM(REPLACE(CAST(a.searchtext AS NVARCHAR), 'View', ' ')))  AS searchtext,
    cast(a.params as NVARCHAR) as params, cast(p.oldappurl as NVARCHAR) as oldappurl
FROM axp_appsearch_data a
JOIN axpages p ON
    CASE a.hltype 
        WHEN 'iview' THEN ('i' + CAST(a.structname AS NVARCHAR)) 
        WHEN 'tstruct' THEN ('t' + CAST(a.structname AS NVARCHAR)) 
        ELSE a.structname 
    END  = 
    CASE
        WHEN a.hltype = 'Page'  THEN p.name 
        ELSE p.pagetype  
    END 
WHERE NOT EXISTS (
    SELECT 'x'
    FROM axp_appsearch_data_v2 b
    WHERE a.structname  = b.structname 
    AND a.params  = b.params 
)
UNION ALL
SELECT 2 AS slno,
       axp_appsearch_data_v2.hltype as hltype,
       axp_appsearch_data_v2.structname as structname,
       LTRIM(RTRIM(REPLACE(CAST(axp_appsearch_data_v2.searchtext AS NVARCHAR), 'View', '')))  AS searchtext,
       REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CAST(axp_appsearch_data_v2.params AS NVARCHAR),
            'date_trunc(''month'', current_date)', LTRIM(RTRIM(CONVERT(NVARCHAR, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0), 103)))),
            'date_trunc(''month'', (add_months(current_date, 0 - 1)))', LTRIM(RTRIM(CONVERT(NVARCHAR, DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(MONTH, -1, GETDATE())), 0), 103)))),
            'date_trunc(''month'', current_date) + interval ''0 month'' - interval ''1 day''', LTRIM(RTRIM(CONVERT(NVARCHAR, DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)), 103)))),
            'date_trunc(''week'', current_date)', LTRIM(RTRIM(CONVERT(NVARCHAR, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0), 103)))),
            'date_trunc(''week'', current_date - 7) + interval ''6 day''', LTRIM(RTRIM(CONVERT(NVARCHAR, DATEADD(DAY, 6, DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(DAY, -7, GETDATE())), 0)), 103)))),
            'date_trunc(''week'', current_date - 7)', LTRIM(RTRIM(CONVERT(NVARCHAR, DATEADD(DAY, -7, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0)), 103)))),
            'date_trunc(''month'', current_date)', LTRIM(RTRIM(CONVERT(NVARCHAR, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0), 103)))),
            'current_date - 1', LTRIM(RTRIM(CONVERT(NVARCHAR, DATEADD(DAY, -1, GETDATE()), 103)))),
            'current_date', LTRIM(RTRIM(CONVERT(NVARCHAR, GETDATE(), 103)))),
            ' &', '&') AS params,
       cast(a.oldappurl as nvarchar) as oldappurl
FROM axp_appsearch_data_v2
JOIN axpages a ON
    CASE axp_appsearch_data_v2.hltype
        WHEN 'iview' THEN 'i' + CAST(axp_appsearch_data_v2.structname AS NVARCHAR) 
        WHEN 'tstruct' THEN 't' + CAST(axp_appsearch_data_v2.structname AS NVARCHAR) 
        ELSE axp_appsearch_data_v2.structname 
    END = 
    CASE
        WHEN axp_appsearch_data_v2.hltype = 'Page' THEN a.name 
        ELSE a.pagetype
    END
WHERE LOWER(CAST(axp_appsearch_data_v2.params AS NVARCHAR)) LIKE '%current_date%'
UNION ALL
 SELECT 1 AS slno,
       'tstruct' AS hltype,
       t.name  AS structname,
       t.caption  AS searchtext,
       NULL AS params,
       cast(p.oldappurl as nvarchar) as oldappurl
FROM tstructs t
JOIN axpages p 
    ON ('t' + CAST(t.name AS NVARCHAR))  = CAST(p.pagetype AS NVARCHAR) 
WHERE t.blobno = 1
  AND EXISTS ( 
        SELECT 'x' AS text
        FROM axp_vw_menu x
        WHERE x.pagetype LIKE 't%' 
          AND LTRIM(RTRIM(SUBSTRING(x.pagetype, 2, 20)))  = t.name 
          AND x.visible  NOT LIKE '%F%' 
  )
UNION ALL
 SELECT 0 AS slno,
       'iview' AS hltype,
       i.name  AS structname,
       i.caption  AS searchtext,
       NULL AS params,
       cast(p.oldappurl as nvarchar) as oldappurl
FROM iviews i
JOIN axpages p 
    ON ('i' + CAST(i.name AS NVARCHAR))  = CAST(p.pagetype AS NVARCHAR) 
WHERE i.blobno = 1
  AND EXISTS (
        SELECT 'x' AS text
        FROM axp_vw_menu x
        WHERE x.pagetype LIKE 'i%' 
          AND LTRIM(RTRIM(SUBSTRING(x.pagetype , 2, 20))) = i.name 
          AND x.visible NOT LIKE '%F%' 
  )
UNION ALL
SELECT 3 AS slno,
       'Page' AS hltype,
       axp_vw_menu.name AS structname,
       axp_vw_menu.caption  AS searchtext,
       NULL AS params,
       cast(p.oldappurl as nvarchar) as oldappurl
FROM axp_vw_menu
JOIN axpages p 
    ON CAST(axp_vw_menu.name AS NVARCHAR) = CAST(p.name AS NVARCHAR) 
WHERE axp_vw_menu.pagetype = 'web';
>>
<<
CREATE  OR ALTER VIEW axp_appsearch
AS SELECT DISTINCT 
    a.searchtext  as searchtext,
    a.params   + 
        CASE 
            WHEN a.params IS NOT NULL AND LOWER(a.params) NOT LIKE '%~act%' THEN '~act=load'
            ELSE NULL
        END  AS params,
    a.hltype,
    a.structname ,
    a.username  as username,
    a.oldappurl 
FROM (
    SELECT s.slno,
           s.searchtext  as searchtext,
           s.params  as params,
           s.hltype ,
           s.structname ,
           cast(lg.username as nvarchar)  as username,
           s.oldappurl 
    FROM axp_appsearch_data_new s
    JOIN axuseraccess a_1 ON a_1.sname  = s.structname 
    JOIN axusergroups g ON a_1.rname  = g.userroles 
    JOIN axuserlevelgroups lg ON g.groupname  = lg.usergroup 
    WHERE a_1.stype IN ('t', 'i')
    GROUP BY s.searchtext, s.params, s.hltype, s.structname, lg.username, s.slno, s.oldappurl
UNION
SELECT b.slno,
           b.searchtext  as searchtext,
           b.params  as params,
           b.hltype ,
           b.structname ,
           cast(lg.username as nvarchar)  as username,
           b.oldappurl 
    FROM axuserlevelgroups lg
    JOIN (
        SELECT DISTINCT s.searchtext  as searchtext,
               s.params  as params,
               s.hltype ,
               s.structname ,
               0 AS slno,
               s.oldappurl 
        FROM axp_appsearch_data_new s
        LEFT JOIN axuseraccess a_1 ON s.structname  = a_1.sname 
        AND a_1.stype  IN ('t', 'i')
    ) b ON lg.usergroup  = 'default' 
) a;
>>
<<
CREATE OR ALTER   VIEW vw_axlanguage_export AS
SELECT 
    'tstruct' AS comptype,
    0 AS ord,
    't' + CAST(t.name AS VARCHAR) AS ntransid,
    'x__headtext' AS compname,
    t.caption,
    0 AS ord2,
    0 AS ord3,
    'NA' AS hidden
FROM tstructs t
UNION ALL
SELECT 
    'tstruct' AS comptype,
    1 AS ord,
    't' + CAST(p.tstruct AS VARCHAR) AS ntransid,
    p.dname AS compname,
    p.caption,
    CAST(SUBSTRING(p.dname, 3, LEN(p.dname)) AS INT) AS ord2,
    CAST(SUBSTRING(p.dname, 3, LEN(p.dname)) AS INT) AS ord3,
    'NA' AS hidden
FROM axpdc p
UNION ALL
SELECT 
    'tstruct' AS comptype,
    2 AS ord,
    't' + CAST(f.tstruct AS VARCHAR) AS ntransid,
    f.fname AS compname,
    f.caption,
    CAST(SUBSTRING(f.dcname, 3, LEN(f.dcname)) AS INT) AS ord2,
    f.ordno AS ord3,
    CASE WHEN CAST(f.hidden AS VARCHAR) = 'TRUE' THEN 'Yes' ELSE 'No' END AS hidden
FROM axpflds f
UNION ALL
SELECT 
    'tstruct' AS comptype,
    4 AS ord,
    't' + CAST(tb.name AS VARCHAR) AS ntransid,
    tb.[key] AS compname,
    tb.title COLLATE Arabic_CI_AS AS caption,
    100 AS ord2,
    tb.ordno AS ord3,
    'NA' AS hidden
FROM axtoolbar tb
WHERE tb.stype = 'tstruct'
UNION ALL
SELECT 
    'tstruct' AS comptype,
    5 AS ord,
    't' + CAST(b.name AS VARCHAR) AS ntransid,
    a.ctype AS compname,
    a.ccaption AS caption,
    a.ord AS ord2,
    0 AS ord3,
    'NA' AS hidden
FROM (
    SELECT 'pop1' AS ctype, 'Remove' AS ccaption, 10001 AS ord UNION ALL
    SELECT 'pop2', 'Print', 10002 UNION ALL
    SELECT 'pop3', 'Preview', 10003 UNION ALL
    SELECT 'pop4', 'Regenerate Packets', 10004 UNION ALL
    SELECT 'pop5', 'View History', 10005 UNION ALL
    SELECT 'lpop1', 'Remove', 10006 UNION ALL
    SELECT 'lpop2', 'Print', 10007 UNION ALL
    SELECT 'lpop3', 'Preview', 10008 UNION ALL
    SELECT 'lpop4', 'Params', 10009 UNION ALL
    SELECT 'lpop5', 'Preview Form', 10010 UNION ALL
    SELECT 'lpop6', 'Print Form', 10011 UNION ALL
    SELECT 'lpop7', 'PDF', 10012 UNION ALL
    SELECT 'lpop8', 'Regenerate Packets', 10013 UNION ALL
    SELECT 'lpop9', 'Save As', 10014 UNION ALL
    SELECT 'lpop10', 'To XL', 10015 UNION ALL
    SELECT 'lpop11', 'Rapid XL Export', 10016 UNION ALL
    SELECT 'lpop12', 'View Attachment', 10017 UNION ALL
    SELECT 'lblSearh', 'Search For', 10018 UNION ALL
    SELECT 'lblWith', 'With', 10019
) a
CROSS JOIN tstructs b
UNION ALL
SELECT 
    'AxPages' AS comptype,
    p.levelno AS ord,
    NULL AS ntransid,
    p.name AS compname,
    p.caption,
    p.ordno AS ord2,
    0 AS ord3,
    'NA' AS hidden
FROM axpages p
UNION ALL
SELECT 
    'iview' AS comptype,
    0 AS ord,
    'i' + CAST(i.name AS VARCHAR) AS ntransid,
    'x__head' AS compname,
    i.caption,
    1 AS ord2,
    0 AS ord3,
    'NA' AS hidden
FROM iviews i
UNION ALL
SELECT 
    'iview' AS comptype,
    1 AS ord,
    'i' + CAST(vm.iname AS VARCHAR) AS ntransid,
    'RH1' AS compname,
    vm.header1 AS caption,
    2 AS ord2,
    0 AS ord3,
    'NA' AS hidden
FROM iviewmain vm
UNION ALL
SELECT 
    'iview' AS comptype,
    2 AS ord,
    'i' + CAST(p.iname AS VARCHAR) AS ntransid,
    p.pname AS compname,
    p.pcaption AS caption,
    p.ordno AS ord2,
    0 AS ord3,
    'NA' AS hidden
FROM iviewparams p
UNION ALL
SELECT 
    'iview' AS comptype,
    3 AS ord,
    'i' + CAST(c.iname AS VARCHAR) AS ntransid,
    c.f_name AS compname,
    c.f_caption AS caption,
    c.ordno AS ord2,
    0 AS ord3,
    'NA' AS hidden
FROM iviewcols c
UNION ALl
SELECT 
    'iview' AS comptype,
    4 AS ord,
    'i' + CAST(tb.name AS VARCHAR) AS ntransid,
    tb.[key] AS compname,
    tb.title AS caption,
    tb.ordno AS ord2,
    0 AS ord3,
    'NA' AS hidden
FROM axtoolbar tb
WHERE tb.stype = 'iview'
UNION ALL
SELECT 
    'iview' AS comptype,
    5 AS ord,
    'i' + CAST(b.name AS VARCHAR) AS ntransid,
    a.ctype AS compname,
    a.ccaption AS caption,
    a.ord AS ord2,
    0 AS ord3,
    'NA' AS hidden
FROM iviews b
CROSS JOIN (
    SELECT 'anac1' AS ctype, 'Column Heading' AS ccaption, 1 AS ord UNION ALL
    SELECT 'anac2', 'Operator', 2 UNION ALL
    SELECT 'anac3', 'Value (s)', 3 UNION ALL
    SELECT 'anac4', 'Relations', 4 UNION ALL
    SELECT 'pop1', 'Delete', 5 UNION ALL
    SELECT 'pop2', 'New', 6 UNION ALL
    SELECT 'pop3', 'Params', 7 UNION ALL
    SELECT 'pop4', 'Preview Form', 8 UNION ALL
    SELECT 'pop5', 'Print Form', 9 UNION ALL
    SELECT 'pop6', 'PDF', 10 UNION ALL
    SELECT 'pop7', 'Regenerate Packets', 11 UNION ALL
    SELECT 'pop8', 'Save As', 12 UNION ALL
    SELECT 'pop9', 'To XL', 13 UNION ALL
    SELECT 'pop10', 'Rapid XL Export', 14 UNION ALL
    SELECT 'pop11', 'View Attachment', 15
) a;
>>
<<
CREATE OR ALTER  VIEW vw_cards_calendar_data
AS
SELECT DISTINCT
    a.uname,
    a.axcalendarid,
    a.eventname,
    a.sendername,
    a.messagetext,
    a.eventtype,
    a.startdate,
    COALESCE(a.axptm_starttime, '00:00') AS axptm_starttime,
    a.enddate,
    CASE
        WHEN COALESCE(a.axptm_endtime, '00:00') = '00:00'
            THEN '23:59'
        ELSE a.axptm_endtime
    END AS axptm_endtime,
    a.location,
    a.status,
    b.eventcolor,
    CASE
        WHEN a.sourceid = 0 THEN a.axcalendarid
        ELSE a.sourceid
    END AS recordid,
    a.eventstatus,
    c.eventstatcolor,
    SUBSTRING(a.mapname, 1, 5) AS mapname
FROM axcalendar a
JOIN axpdef_axcalendar_event b
    ON a.axpdef_axcalendar_eventid = b.axpdef_axcalendar_eventid
LEFT JOIN axpdef_axcalendar_eventstatus c
    ON a.axpdef_axcalendar_eventid = c.axpdef_axcalendar_eventid
   AND a.eventstatus = c.eventstatus
WHERE a.cancel = 'F'
  AND a.parenteventid > 0
UNION ALL
SELECT DISTINCT
    a.sendername AS uname,
    a.axcalendarid,
    a.eventname,
    a.sendername,
    a.messagetext,
    a.eventtype,
    a.startdate,
    COALESCE(a.axptm_starttime, '00:00') AS axptm_starttime,
    CASE
        WHEN a.recurring IS NULL THEN a.enddate
        ELSE a.startdate
    END AS enddate,
    CASE
        WHEN COALESCE(a.axptm_endtime, '00:00') = '00:00'
            THEN '23:59'
        ELSE a.axptm_endtime
    END AS axptm_endtime,
    a.location,
    a.status,
    b.eventcolor,
    CASE
        WHEN a.sourceid = 0 THEN a.axcalendarid
        ELSE a.sourceid
    END AS recordid,
    a.eventstatus,
    c.eventstatcolor,
    SUBSTRING(a.mapname, 1, 5) AS mapname
FROM axcalendar a
JOIN axpdef_axcalendar_event b
    ON a.axpdef_axcalendar_eventid = b.axpdef_axcalendar_eventid
LEFT JOIN axpdef_axcalendar_eventstatus c
    ON a.axpdef_axcalendar_eventid = c.axpdef_axcalendar_eventid
   AND a.eventstatus = c.eventstatus
WHERE a.cancel = 'F'
  AND a.parenteventid = 0;
>>
<<
CREATE  OR ALTER   VIEW vw_cards_dashboard
AS 
SELECT 
    a.cardtype,
    a.cardname,
    a.cardicon,
    a.charttype,
    a.pluginname,
    CASE 
        WHEN a.pluginname IS NULL THEN a.html_editor_card
        ELSE h.htmltext 
    END AS htmltext,
    a.card_datasource,
    s.sqltext,
    a.width,
    a.height,
    a.autorefresh,
    value AS uroles,  -- Unnest equivalent
    a.axp_cardsid,
    h.context,
    a.orderno,
    a.chartjson
FROM axp_cards a
LEFT JOIN ax_htmlplugins h ON a.pluginname = h.name
LEFT JOIN axdirectsql s ON a.card_datasource = s.sqlname
CROSS APPLY STRING_SPLIT(a.accessstringui, ',')  
WHERE a.indashboard = 'T';
>>
<<
CREATE  OR ALTER   VIEW vw_cards_homepages
AS 
SELECT 
    a.cardtype,
    a.cardname,
    a.cardicon,
    a.charttype,
    a.pluginname,
    CASE 
        WHEN a.pluginname IS NULL THEN a.html_editor_card
        ELSE h.htmltext 
    END AS htmltext,
    a.card_datasource,
    s.sqltext,
    a.width,
    a.height,
    a.autorefresh,
    value AS uroles,  -- Unnest equivalent
    a.axp_cardsid,
    h.context,
    a.orderno,
    a.chartjson
FROM axp_cards a
LEFT JOIN ax_htmlplugins h ON a.pluginname = h.name
LEFT JOIN axdirectsql s ON a.card_datasource = s.sqlname
CROSS APPLY STRING_SPLIT(a.accessstringui, ',')  
WHERE a.inhomepage = 'T';
>>
<<
CREATE  OR ALTER VIEW vw_entityrelations AS
SELECT DISTINCT     
    'F' AS cancel,
    'admin' AS username,
    SYSDATETIME() AS modifiedon,
    'admin' AS createdby,
    SYSDATETIME() AS createdon,
    1 AS app_level,
    1 AS app_desc,
    a.rtype,
    a.mstruct,
    a.mfield,
    m.tablename AS mtable,
    dc.tablename AS primarytable,
    a.dstruct,
    a.dfield,
    d.tablename AS dtable,
    'Dropdown' AS rtypeui,
    CONCAT(mt.caption, '-(', mt.name, ')') AS mstructui,
    CONCAT(m.caption, '-(', m.fname, ')') AS mfieldui,
    CONCAT(dt.caption, '-(', dt.name, ')') AS dstructui,
    CONCAT(d.caption, '-(', d.fname, ')') AS dfieldui,
    ddc.tablename AS dprimarytable
FROM 
    (SELECT DISTINCT axrelations.mstruct,
            axrelations.dstruct,
            axrelations.mfield,
            axrelations.dfield,
            axrelations.rtype
    FROM axrelations) a
JOIN tstructs mt ON a.mstruct = mt.name
JOIN tstructs dt ON a.dstruct = dt.name
LEFT JOIN axpflds m ON a.mstruct = m.tstruct AND a.mfield = m.fname
LEFT JOIN axpflds d ON a.dstruct = d.tstruct AND a.dfield = d.fname
LEFT JOIN axpdc dc ON a.mstruct = dc.tstruct AND dc.dname = 'dc1'
LEFT JOIN axpdc ddc ON a.dstruct = ddc.tstruct AND ddc.dname = 'dc1'
WHERE a.rtype = 'md'
UNION ALL
SELECT DISTINCT     
    'F' AS cancel,
    'admin' AS username,
    SYSDATETIME() AS modifiedon,
    'admin' AS createdby,
    SYSDATETIME() AS createdon,
    1 AS app_level,
    1 AS app_desc,
    'gm' AS rtype,
    a.tstruct AS mstruct,
    CONCAT(sd.tablename, 'id') AS mfield,
    sd.tablename AS mtable,
    pd.tablename AS primarytable,
    a.targettstr AS dstruct,
    'sourceid' AS dfield,
    td.tablename AS dtable,
    'Genmap' AS rtypeui,
    CONCAT(mt.caption, '-(', mt.name, ')') AS mstructui,
    NULL AS mfieldui,
    CONCAT(dt.caption, '-(', dt.name, ')') AS dstructui,
    NULL AS dfieldui,
    td.tablename AS dprimarytable
FROM axpgenmaps a
JOIN tstructs mt ON a.tstruct = mt.name
JOIN tstructs dt ON a.targettstr = dt.name
LEFT JOIN axpdc sd ON a.tstruct = sd.tstruct AND sd.dname = a.basedondc
LEFT JOIN axpdc td ON a.targettstr = td.tstruct AND td.dname = 'dc1'
LEFT JOIN axpdc pd ON a.tstruct = pd.tstruct AND pd.dname = 'dc1';
>>
<<
CREATE  OR ALTER VIEW vw_pegv2_activetasks AS
SELECT DISTINCT 
    a.touser,
    a.processname,
    a.taskname,
    a.taskid,
    a.tasktype,
    a.eventdatetime AS edatetime,
    CONVERT(varchar, CAST(a.eventdatetime AS datetime), 103) AS eventdatetime, -- Adjusted for SQL Server
    a.fromuser,
    a.fromrole,
    a.displayicon,
    a.displaytitle,
    a.displaymcontent,
    a.displaycontent,
    a.displaybuttons,
    a.keyfield,
    a.keyvalue,
    a.transid,
    a.priorindex,
    a.indexno,
    a.subindexno,
    a.approvereasons,
    a.defapptext,
    a.returnreasons,
    a.defrettext,
    a.rejectreasons,
    a.defregtext,
    aa.recordid,
    a.approvalcomments,
    a.rejectcomments,
    a.returncomments,
    'PEG' AS rectype,
    'NA' AS msgtype,
    a.returnable,
    a.initiator,
    a.initiator_approval,
    a.displaysubtitle,
    p.amendment,
    a.allowsend,
    a.allowsendflg,
    b.cmsg_appcheck,
    b.cmsg_return,
    b.cmsg_reject,
    b.showbuttons,
    CAST(NULL AS varchar) AS hlink, -- NULL handling in SQL Server
    CAST(NULL AS varchar) AS hlink_transid,
    CAST(NULL AS varchar) AS hlink_params
FROM axactivetasks a
JOIN axprocessdefv2 b ON a.processname = b.processname AND a.taskname = b.taskname
JOIN axpdef_peg_processmaster p ON a.processname = p.caption
LEFT JOIN axactivetasks aa ON a.processname = aa.processname AND a.keyvalue = aa.keyvalue 
AND a.transid = aa.transid AND aa.tasktype = 'Make' AND aa.recordid IS NOT NULL
WHERE NOT EXISTS (
    SELECT 1 FROM axactivetaskstatus b1 WHERE a.taskid = b1.taskid
) 
AND a.removeflg = 'F'
UNION ALL
SELECT 
    axactivemessages.touser,
    axactivemessages.processname,
    axactivemessages.taskname,
    axactivemessages.taskid,
    axactivemessages.tasktype,
    axactivemessages.eventdatetime AS edatetime,
    CONVERT(varchar, CAST(axactivemessages.eventdatetime AS datetime), 103) AS eventdatetime, -- Adjusted
    axactivemessages.fromuser,
    CAST(NULL AS varchar) AS fromrole,
    axactivemessages.displayicon,
    axactivemessages.displaytitle,
    CAST(NULL AS varchar) AS displaymcontent,
    axactivemessages.displaycontent,
    CAST(NULL AS varchar) AS displaybuttons,
    axactivemessages.keyfield,
    axactivemessages.keyvalue,
    axactivemessages.transid,
    0 AS priorindex,
    axactivemessages.indexno,
    0 AS subindexno,
    CAST(NULL AS varchar) AS approvereasons,
    CAST(NULL AS varchar) AS defapptext,
    CAST(NULL AS varchar) AS returnreasons,
    CAST(NULL AS varchar) AS defrettext,
    CAST(NULL AS varchar) AS rejectreasons,
    CAST(NULL AS varchar) AS defregtext,
    0 AS recordid,
    CAST(NULL AS varchar) AS approvalcomments,
    CAST(NULL AS varchar) AS rejectcomments,
    CAST(NULL AS varchar) AS returncomments,
    'MSG' AS rectype,
    axactivemessages.msgtype,
    'F' AS returnable,
    CAST(NULL AS varchar) AS initiator,
    CAST(NULL AS varchar) AS initiator_approval,
    CAST(NULL AS varchar) AS displaysubtitle,
    p.amendment,
    'F' AS allowsend,
    'F' AS allowsendflg,
    CAST(NULL AS varchar) AS cmsg_appcheck,
    CAST(NULL AS varchar) AS cmsg_return,
    CAST(NULL AS varchar) AS cmsg_reject,
    CAST(NULL AS varchar) AS showbuttons,
    axactivemessages.hlink,
    axactivemessages.hlink_transid,
    axactivemessages.hlink_params
FROM axactivemessages
LEFT JOIN axpdef_peg_processmaster p ON axactivemessages.processname = p.caption
WHERE NOT EXISTS (
    SELECT 1 FROM axactivetaskstatus b WHERE axactivemessages.taskid = b.taskid
);
>>
<<
CREATE   OR ALTER  VIEW vw_pegv2_alltasks AS 
SELECT DISTINCT 
    a.touser,
    a.processname,
    a.taskname,
    a.taskid,
    a.tasktype,
    a.eventdatetime AS edatetime,
    FORMAT(
        TRY_CAST(
            STUFF(STUFF(STUFF(STUFF(a.eventdatetime, 13, 0, ':'), 11, 0, ':'), 9, 0, ' '), 5, 0, '-') 
        AS DATETIME2),
        'dd/MM/yyyy HH:mm:ss'
    ) AS eventdatetime,
    a.fromuser,
    a.fromrole,
    a.displayicon,
    a.displaytitle,
    a.displaymcontent,
    a.displaycontent,
    a.displaybuttons,
    a.keyfield,
    a.keyvalue,
    a.transid,
    a.priorindex,
    a.indexno,
    a.subindexno,
    a.approvereasons,
    a.defapptext,
    a.returnreasons,
    a.defrettext,
    a.rejectreasons,
    a.defregtext,
    aa.recordid,
    a.approvalcomments,
    a.rejectcomments,
    a.returncomments,
    'PEG' AS rectype,
    'NA' AS msgtype,
    a.returnable,
    a.initiator,
    a.initiator_approval,
    a.displaysubtitle,
    p.amendment,
    a.allowsend,
    a.allowsendflg,
    b.cmsg_appcheck,
    b.cmsg_return,
    b.cmsg_reject,
    b.showbuttons,
    NULL AS hlink,
    NULL AS hlink_transid,
    NULL AS hlink_params,
    NULL AS taskstatus,
    NULL AS statusreason,
    NULL AS statustext,
    NULL AS cancelremarks,
    NULL AS cancelledby,
    NULL AS cancelledon,
    NULL AS cancel,
    NULL AS username,
    'Active' AS cstatus
FROM axactivetasks a
JOIN axprocessdefv2 b 
    ON a.processname = b.processname AND a.taskname = b.taskname
JOIN axpdef_peg_processmaster p 
    ON a.processname = p.caption
LEFT JOIN axactivetasks aa 
    ON a.processname = aa.processname 
    AND a.keyvalue = aa.keyvalue 
    AND a.transid = aa.transid 
    AND aa.tasktype = 'Make' 
    AND aa.recordid IS NOT NULL
WHERE NOT EXISTS (
    SELECT 1 
    FROM axactivetaskstatus b1 
    WHERE a.taskid = b1.taskid
)
AND a.removeflg = 'F'
UNION ALL
SELECT 
    a.touser,
    a.processname,
    a.taskname,
    a.taskid,
    a.tasktype,
    a.eventdatetime AS edatetime,
    -- Convert eventdatetime from YYYYMMDDHH24MISSmmm to formatted string
    FORMAT(
        TRY_CAST(
            STUFF(STUFF(STUFF(STUFF(a.eventdatetime, 13, 0, ':'), 11, 0, ':'), 9, 0, ' '), 5, 0, '-') 
        AS DATETIME2),
        'dd/MM/yyyy HH:mm:ss'
    ) AS eventdatetime,
    a.fromuser,
    NULL AS fromrole,
    a.displayicon,
    a.displaytitle,
    NULL AS displaymcontent,
    a.displaycontent,
    NULL AS displaybuttons,
    a.keyfield,
    a.keyvalue,
    a.transid,
    0 AS priorindex,
    a.indexno,
    0 AS subindexno,
    NULL AS approvereasons,
    NULL AS defapptext,
    NULL AS returnreasons,
    NULL AS defrettext,
    NULL AS rejectreasons,
    NULL AS defregtext,
    0 AS recordid,
    NULL AS approvalcomments,
    NULL AS rejectcomments,
    NULL AS returncomments,
    'MSG' AS rectype,
    a.msgtype,
    'F' AS returnable,
    NULL AS initiator,
    NULL AS initiator_approval,
    NULL AS displaysubtitle,
    p.amendment,
    'F' AS allowsend,
    'F' AS allowsendflg,
    NULL AS cmsg_appcheck,
    NULL AS cmsg_return,
    NULL AS cmsg_reject,
    NULL AS showbuttons,
    a.hlink,
    a.hlink_transid,
    a.hlink_params,
    NULL AS taskstatus,
    NULL AS statusreason,
    NULL AS statustext,
    NULL AS cancelremarks,
    NULL AS cancelledby,
    NULL AS cancelledon,
    NULL AS cancel,
    NULL AS username,
    'Active' AS cstatus
FROM axactivemessages a
LEFT JOIN axpdef_peg_processmaster p 
    ON a.processname = p.caption
WHERE NOT EXISTS (
    SELECT 1 
    FROM axactivetaskstatus b 
    WHERE a.taskid = b.taskid
)
UNION ALL
 SELECT 
    a.touser,
    a.processname,
    a.taskname,
    a.taskid,
    a.tasktype,
    a.eventdatetime AS edatetime,
    -- Convert eventdatetime from YYYYMMDDHH24MISSmmm format
    FORMAT(
        TRY_CAST(
            STUFF(STUFF(STUFF(STUFF(a.eventdatetime, 13, 0, ':'), 11, 0, ':'), 9, 0, ' '), 5, 0, '-') 
        AS DATETIME2),
        'dd/MM/yyyy HH:mm:ss'
    ) AS eventdatetime,
    a.fromuser,
    a.fromrole,
    a.displayicon,
    a.displaytitle,
    a.displaymcontent,
    a.displaycontent,
    a.displaybuttons,
    a.keyfield,
    a.keyvalue,
    a.transid,
    a.priorindex,
    a.indexno,
    a.subindexno,
    a.approvereasons,
    a.defapptext,
    a.returnreasons,
    a.defrettext,
    a.rejectreasons,
    a.defregtext,
    a.recordid,
    a.approvalcomments,
    a.rejectcomments,
    a.returncomments,
    'PEG' AS rectype,
    'NA' AS msgtype,
    a.returnable,
    a.initiator,
    a.initiator_approval,
    a.displaysubtitle,
    NULL AS amendment,
    a.allowsend,
    a.allowsendflg,
    NULL AS cmsg_appcheck,
    NULL AS cmsg_return,
    NULL AS cmsg_reject,
    NULL AS showbuttons,
    NULL AS hlink,
    NULL AS hlink_transid,
    NULL AS hlink_params,
    --pr_pegv2_transcurstatus(a.transid, a.keyvalue, a.processname) AS taskstatus,
    null taskstatus, 
    b.statusreason,
    b.statustext,
    b.cancelremarks,
    b.cancelledby,
    CAST(b.cancelledon AS VARCHAR) AS cancelledon,  -- Equivalent of ::character varying
    b.cancel,
    CASE
        WHEN a.indexno = 1 THEN a.fromuser  -- ::numeric not needed in SQL Server
        ELSE a.touser
    END AS username,
    'Completed' AS cstatus
FROM axactivetasks a
JOIN axactivetaskstatus b 
    ON a.taskid = b.taskid;
>>
<<
CREATE   OR ALTER  VIEW vw_pegv2_completed_tasks
AS
SELECT
    a.processname,
    a.taskname,
    a.tasktype,
    CONVERT(
        VARCHAR(19),
        CONVERT(
            DATETIME2,
            STUFF(
                STUFF(
                    STUFF(
                        STUFF(CAST(b.eventdatetime AS VARCHAR(20)),
                              13, 0, ':'),
                        11, 0, ':'),
                    9, 0, ' '),
                7, 0, '-'),
        120
    )) AS eventdatetime,
    a.eventdatetime AS edatetime,
    a.fromuser,
    a.displayicon,
    a.displaytitle,
    a.taskid,
    a.keyfield,
    a.keyvalue,
    a.recordid,
    a.transid,
    a.displaycontent,
    a.indexno,
    b.taskstatus,
    b.statusreason,
    b.statustext,
    b.cancelremarks,
    b.cancelledby,
    b.cancelledon,
    b.cancel,
    b.username
FROM axactivetasks a
JOIN axactivetaskstatus b
    ON a.taskid = b.taskid
   AND (
        CASE
            WHEN a.indexno = 1 THEN a.fromuser
            ELSE a.touser
        END
       ) = b.username;
>>
<<
CREATE  OR ALTER  VIEW vw_pegv2_process_cards AS
WITH a AS (
    SELECT
        TRIM(
            CASE 
                WHEN CHARINDEX('-(', value) > 0 
                THEN SUBSTRING(value, CHARINDEX('-(', value) + 2, LEN(value)) 
                ELSE value 
            END
        ) AS card,
        TRIM(
            CASE 
                WHEN CHARINDEX('-(', value) > 0 
                THEN LEFT(value, CHARINDEX('-(', value) - 1) 
                ELSE value 
            END
        ) AS ctype,
        b.axprocessdefv2id,
        b.processname,
        b.taskname
    FROM axpdef_peg_processmaster a
    INNER JOIN axprocessdefv2 b ON a.caption = b.processname
    CROSS APPLY STRING_SPLIT(a.cards, ',')
    WHERE b.stransid <> 'pgv2c' AND 
          CASE WHEN CHARINDEX('-(', value) > 0 
               THEN LEFT(value, CHARINDEX('-(', value) - 1) 
               ELSE value 
          END = 'Process'
),
b AS (
    SELECT
        TRIM(
            CASE 
                WHEN CHARINDEX('-(', value) > 0 
                THEN SUBSTRING(value, CHARINDEX('-(', value) + 2, LEN(value)) 
                ELSE value 
            END
        ) AS hidecard,
        TRIM(
            CASE 
                WHEN CHARINDEX('-(', value) > 0 
                THEN LEFT(value, CHARINDEX('-(', value) - 1) 
                ELSE value 
            END
        ) AS ctype,
        b.axprocessdefv2id,
        b.processname,
        b.taskname
    FROM axprocessdefv2 b
    CROSS APPLY STRING_SPLIT(b.hidecards, ',')
    WHERE b.stransid <> 'pgv2c' AND 
          CASE WHEN CHARINDEX('-(', value) > 0 
               THEN LEFT(value, CHARINDEX('-(', value) - 1) 
               ELSE value 
          END = 'Process'
)
SELECT
    a.axprocessdefv2id,
    a.processname,
    a.taskname,
    d.cardname,
    d.axpdef_prcardsid AS cardsid,
    d.sql_editor_cardsql AS cardsql,
    d.cardtype,
    d.charttype,
    d.chartjson,
    'col-md-12' AS width,
    'Process' AS ctype,
    'NA' AS accessstring
FROM a
LEFT JOIN b ON a.processname = b.processname AND a.taskname = b.taskname AND a.card = b.hidecard
INNER JOIN axpdef_prcards d ON a.card = d.cardname
WHERE b.hidecard IS NULL;
>>
<<
CREATE   OR ALTER  VIEW vw_pegv2_processdef_tree
AS SELECT axprocessdefv2.processname,
    axprocessdefv2.taskname,
    axprocessdefv2.tasktype,
    axprocessdefv2.taskgroupname AS taskgroup,
    axprocessdefv2.active AS taskactive,
    axprocessdefv2.indexno,
    axprocessdefv2.subindexno AS subindex,
    axprocessdefv2.groupwithprior AS details,
    axprocessdefv2.transid,
    axprocessdefv2.axprocessdefv2id AS recordid,
    axprocessdefv2.displayicon,
    axprocessdefv2.groupwithprior,
    axprocessdefv2.keyfield
   FROM axprocessdefv2;
>>
<<
CREATE  OR ALTER   VIEW vw_username_role_menu_access
AS
SELECT a2.username,a3.groupname,a5.rname,a5.sname,a5.stype,
CASE a5.stype WHEN 't' THEN t.caption
WHEN 'i' THEN i.caption
WHEN 'p' THEN p.caption ELSE NULL END AS caption
FROM axusergroups a3
JOIN axusergroupsdetail a4 ON a3.axusergroupsid = a4.axusergroupsid
JOIN axuseraccess a5 ON a4.roles_id = a5.rname
LEFT JOIN axuserlevelgroups a2 ON a2.usergroup = a3.groupname AND a2.usergroup <> 'default'
LEFT JOIN tstructs t ON a5.sname = t.name AND t.blobno = 1
LEFT JOIN iviews i ON a5.sname = i.name and i.blobno=1
LEFT JOIN axpages p ON a5.sname = p.name
UNION ALL
SELECT a2.username,'default' AS groupname,'default' AS rname,
    t.name     AS sname,
    't'        AS stype,
    t.caption
FROM tstructs t
LEFT JOIN axuserlevelgroups a2
    ON a2.usergroup = 'default'
WHERE t.blobno = 1
UNION ALL
SELECT 
    a2.username,
    'default' AS groupname,
    'default' AS rname,
    i.name     AS sname,
    'i'        AS stype,
    i.caption
FROM iviews i
LEFT JOIN axuserlevelgroups a2
    ON a2.usergroup = 'default'
    where i.blobno=1
UNION ALL
SELECT DISTINCT
    a2.username,
    'default' AS groupname,
    'default' AS rname,
    p.name     AS sname,
    'p'        AS stype,
    p.caption
FROM axpages p
LEFT JOIN axuserlevelgroups a2
    ON a2.usergroup = 'default';
>>    
<<
CREATE or alter  PROCEDURE execute_sql_list
(
    @sql_list NVARCHAR(MAX),
    @sql_separator NVARCHAR(100)
)
AS
BEGIN
   SET NOCOUNT ON;

    DECLARE @query NVARCHAR(MAX);


    SET @query = REPLACE(@sql_list, @sql_separator, ';' + CHAR(10));

    IF @query IS NOT NULL AND LTRIM(RTRIM(@query)) <> ''
    BEGIN
        EXEC sp_executesql @query;
    END
END;
>>
<<
CREATE or alter function fn_axpanalytics_chartdata(
    @psource NVARCHAR(MAX),
    @pentity_transid NVARCHAR(MAX),
    @pcondition NVARCHAR(MAX),
    @pcriteria NVARCHAR(MAX),
    @pfilter NVARCHAR(MAX) = 'NA',
    @pusername NVARCHAR(MAX) = 'admin',
    @papplydac NVARCHAR(MAX) = 'T',
    @puserrole varchar(max) ='All',
    @pconstraints varchar(max) =NULL)
    returns nvarchar(max)    
AS
BEGIN

    DECLARE 
        @rec NVARCHAR(MAX),
        @rec_filters NVARCHAR(MAX),
        @dacrec NVARCHAR(MAX),
        @v_primarydctable NVARCHAR(MAX),
        @v_subentitytable NVARCHAR(MAX),
        @v_transid NVARCHAR(MAX),
        @v_grpfld NVARCHAR(MAX),
        @v_aggfld NVARCHAR(MAX),
        @v_aggfnc NVARCHAR(MAX),
        @v_srckey NVARCHAR(MAX),
        @v_srctbl NVARCHAR(MAX),
        @v_srcfld NVARCHAR(MAX),
        @v_aempty NVARCHAR(MAX),
        @v_tablename NVARCHAR(MAX),
        @v_sql NVARCHAR(MAX),
        @v_normalizedjoin NVARCHAR(MAX),
        @v_keyname NVARCHAR(MAX),
        @v_keyname_coalesce NVARCHAR(MAX),
        @v_entitycond NVARCHAR(MAX),
        @v_keyfld_fname NVARCHAR(MAX),
        @v_keyfld_fval NVARCHAR(MAX),
        @v_keyfld_srckey NVARCHAR(MAX),
        @v_keyfld_srctbl NVARCHAR(MAX),
        @v_keyfld_srcfld NVARCHAR(MAX),
        @v_final_sqls NVARCHAR(MAX) = '',
        @v_fldname_transidcnd INT,
        @v_sql1 NVARCHAR(MAX),
        @v_jointables NVARCHAR(MAX) = '',
        @v_filter_srcfld NVARCHAR(MAX),
        @v_filter_srctxt NVARCHAR(MAX),
        @v_filter_join NVARCHAR(MAX),
        @v_filter_joinsary NVARCHAR(MAX) = '',
        @v_filter_cnd NVARCHAR(MAX),
        @v_filter_cndary NVARCHAR(MAX) = '',
        @v_filter_joinreq INT,
        @v_filter_dcjoinsary NVARCHAR(MAX) = '',
        @v_filter_col NVARCHAR(MAX),
        @v_filter_normalized NVARCHAR(MAX),
        @v_filter_sourcetbl NVARCHAR(MAX),
        @v_filter_sourcefld NVARCHAR(MAX),
        @v_filter_datatype NVARCHAR(MAX),
        @v_filter_listedfld NVARCHAR(MAX),
        @v_filter_tablename NVARCHAR(MAX),
        @v_emptyary NVARCHAR(MAX) = '',
        @v_dacenabled INT,
        @v_dactype INT,
        @v_dac_join NVARCHAR(MAX),
        @v_dac_joinsary NVARCHAR(MAX) = '',
        @v_dac_cnd NVARCHAR(MAX),
        @v_dac_cndary NVARCHAR(MAX) = '',
        @v_dac_joinreq INT,
        @v_dac_normalizedjoinreq INT;

    SELECT @v_primarydctable = tablename 
    FROM axpdc 
    WHERE tstruct = @pentity_transid AND dname = 'dc1';

    SET @v_jointables = @v_primarydctable;

    IF @pcondition = 'Custom'
	    BEGIN
	        SELECT @v_fldname_transidcnd = COUNT(1)
	        FROM axpflds
	        WHERE tstruct = @pentity_transid AND dcname = 'dc1' AND LOWER(fname) = 'transid';
	
	        DECLARE criteria_cursor CURSOR FOR
	        SELECT VALUE
	        FROM STRING_SPLIT(@pcriteria, '^');
	
	        OPEN criteria_cursor;
	        FETCH NEXT FROM criteria_cursor INTO @rec;
	
	        WHILE @@FETCH_STATUS = 0
	        BEGIN
	            SET @v_transid = dbo.split_part(@rec,'~',1);
	            SET @v_grpfld = dbo.split_part(@rec,'~',2);
	            SET @v_aggfld = CASE WHEN dbo.split_part(@rec,'~',3)='count' THEN '1' ELSE dbo.split_part(@rec,'~',3) END;
	            SET @v_aggfnc = dbo.split_part(@rec,'~',4);
	            SET @v_srckey = dbo.split_part(@rec,'~',5);
	            SET @v_srctbl = dbo.split_part(@rec,'~',6);
	            SET @v_srcfld = dbo.split_part(@rec,'~',7);
	            SET @v_aempty = dbo.split_part(@rec,'~',8);
	            SET @v_tablename = dbo.split_part(@rec,'~',9);
				SET @v_keyfld_fval = dbo.split_part(@rec,'~',11);
				SET @v_keyfld_fname = dbo.split_part(@rec,'~',10);
			
				set @v_jointables = case when @v_srckey='T' then concat(@v_jointables,',',@v_srctbl) end;
				set @v_normalizedjoin = case when @v_srckey='T' then concat(' left join ',@v_srctbl,' b on ',@v_primarydctable,'.',@v_grpfld,' = b.',@v_srctbl,'id ') else ' ' end;
		
		        IF LEN(@v_grpfld) > 0
			        BEGIN
	                SET @v_keyname = CASE WHEN @v_srckey = 'T' THEN CONCAT(@v_srctbl, '.', @v_srcfld) ELSE CONCAT(@v_primarydctable, '.', @v_grpfld) END;
	                SET @v_keyname_coalesce = CONCAT('COALESCE(LTRIM(', @v_keyname, '), '''')');
	        	    END;
	
		        IF LOWER(@v_tablename) = LOWER(@v_primarydctable)
			    	BEGIN
			        SET @v_sql = CONCAT('SELECT ', @v_keyname_coalesce, ' AS keyname, ',
			        	CASE WHEN LOWER(LTRIM(@v_aggfnc)) IN ('sum', 'avg') THEN CONCAT('ROUND(', @v_aggfnc, '(', @v_aggfld, '), 2)') ELSE CONCAT(@v_aggfnc, '(', @v_aggfld, ')') END,
			            ' AS keyvalue, ''Custom'' AS cnd, ''', @rec, ''' AS criteria FROM ', @v_tablename);
			        END
		        ELSE
			        BEGIN
			                -- Add joins and build SQL
			        SET @v_sql = CONCAT('SELECT ', @v_keyname, ' AS keyname, ',CASE WHEN LOWER(LTRIM(@v_aggfnc)) IN ('sum', 'avg') THEN CONCAT('ROUND(', @v_aggfnc, '(', @v_aggfld, '), 2)')
			                     ELSE CONCAT(@v_aggfnc, '(', @v_aggfld, ')') END,
			                     ' AS keyvalue, ''Custom'' AS cnd, ''', @rec, ''' AS criteria FROM ', @v_primarydctable, 
			                     ' JOIN ', @v_tablename, ' ON ', @v_primarydctable, '.', @v_primarydctable, 'id = ', @v_tablename, '.', @v_primarydctable, 'id');
			        END
		            		           
	       ----DAC to be include
	       
		---------filters	        
		IF @pfilter = 'NA'
		    	BEGIN
		        SET @v_sql1 = CONCAT(
		            @v_sql, ' ',
		            @v_dac_joinsary,
		            ' WHERE ', @v_primarydctable, '.cancel = ''F''',
		            CASE WHEN @v_fldname_transidcnd > 0 THEN CONCAT(' AND ', @v_primarydctable, '.transid = ''', @pentity_transid, '''') ELSE '' END,
		            CASE WHEN @v_dacenabled > 0 THEN CONCAT(' AND ', @v_dac_cndary) ELSE '' END,
		            ' --axp_filter',
		            CASE WHEN LEN(@v_grpfld) > 0 THEN CONCAT(' GROUP BY ', @v_keyname_coalesce) ELSE '' END
		        );
		    	END
	    ELSE
		    BEGIN
		        DECLARE @filterList TABLE (filter NVARCHAR(MAX));
		
		        INSERT INTO @filterList
		        SELECT value
		        FROM STRING_SPLIT(@pfilter, '^');
		
		        DECLARE @filter NVARCHAR(MAX);
		        --DECLARE @v_filter_srcfld NVARCHAR(MAX);
		        --DECLARE @v_filter_srctxt NVARCHAR(MAX);
		        --DECLARE @v_filter_tablename NVARCHAR(MAX);
		
		        DECLARE filterCursor CURSOR FOR 
		        SELECT filter 
		        FROM @filterList;
		
		        OPEN filterCursor;
		
		        FETCH NEXT FROM filterCursor INTO @filter;
		
		        WHILE @@FETCH_STATUS = 0
		        BEGIN
		            SET @v_filter_srcfld =  dbo.split_part(@filter,'|',1);
		            SET @v_filter_srctxt = dbo.split_part(@filter,'|',2);
		            SET @v_filter_col = dbo.split_part(@v_filter_srcfld,'~',1);
					SET @v_filter_normalized = dbo.split_part(@v_filter_srcfld,'~',2);
		 			SET @v_filter_sourcetbl = dbo.split_part(@v_filter_srcfld,'~',3);
		 			SET @v_filter_sourcefld = dbo.split_part(@v_filter_srcfld,'~',4);
					SET @v_filter_datatype = dbo.split_part(@v_filter_srcfld,'~',5);
					SET @v_filter_listedfld =dbo.split_part(@v_filter_srcfld,'~',6);
		            SET @v_filter_tablename = dbo.split_part(@v_filter_srcfld,'~',7);
		           
		           
		          	if  @v_filter_listedfld = 'F' begin
					    set @v_filter_joinreq = case when lower(@v_tablename)=lower(@v_filter_tablename) then 1 else 0 end; 			    		
								
						if @v_filter_joinreq = 0  
							begin 
								set @v_filter_dcjoinsary = concat(@v_filter_dcjoinsary,',',concat(' join ',@v_filter_tablename,' on ',@v_primarydctable,'.',@v_primarydctable,'id=',@v_filter_tablename,'.',@v_primarydctable,'id') );
							end
						    				    					  
					    select @v_filter_join  = case when @v_filter_normalized='T' 
						then concat(' join ',@v_filter_sourcetbl,' ',@v_filter_col,' on ',@v_filter_tablename,'.',@v_filter_col,' = ',@v_filter_col,'.',@v_filter_sourcetbl,'id')
						end from dual where @v_filter_normalized='T';
														 
						set @v_filter_joinsary =concat(@v_filter_joinsary,',',@v_filter_join);														
					end
		
		           	select @v_filter_cnd = case when @v_filter_normalized='F' then 
		            concat(case when @v_filter_datatype='c' then 'lower(' end,@v_filter_tablename,'.',@v_filter_col,case when @v_filter_datatype='c' then ')' end,' ',@v_filter_srctxt) else 
					concat(case when @v_filter_datatype='c' then 'lower(' end,@v_filter_col,'.',@v_filter_sourcefld,case when @v_filter_datatype='c' then ')' end,' ',@v_filter_srctxt) end;
		
		            SET @v_filter_cndary = CONCAT(@v_filter_cndary, ' AND ', @v_filter_cnd);
		
		            FETCH NEXT FROM filterCursor INTO @filter;
		        END;
		
		        CLOSE filterCursor;
		        DEALLOCATE filterCursor;
		end
	        
		SET @v_sql1 = CONCAT(@v_sql,@v_filter_dcjoinsary, ' ',@v_filter_joinsary, ' ',@v_dac_joinsary, ' WHERE ', @v_primarydctable, '.cancel = ''F''',
	            CASE WHEN @v_fldname_transidcnd > 0 THEN CONCAT(' AND ', @v_primarydctable, '.transid = ''', @pentity_transid, '''') ELSE '' END,
	            @v_filter_cndary,CASE WHEN @v_dacenabled > 0 THEN CONCAT(' AND ', @v_dac_cndary) ELSE '' END,
	            ' 
				--axp_filter
				',CASE WHEN LEN(@v_grpfld) > 0 THEN CONCAT(' GROUP BY ', @v_keyname_coalesce) ELSE '' END);
	
	       
	       set @v_final_sqls = concat(@v_final_sqls,'^^^',@v_sql1);
	       
	       	FETCH NEXT FROM criteria_cursor INTO @rec;
	        END;
				
	        
			CLOSE criteria_cursor;
	        DEALLOCATE criteria_cursor;
end

IF @pcondition = 'General'
    BEGIN
        IF @psource = 'Entity'
        BEGIN
            SELECT @v_fldname_transidcnd = COUNT(1)
            FROM axpflds
            WHERE tstruct = @pentity_transid AND dcname = 'dc1' AND LOWER(fname) = 'transid';

            SET @v_sql = CONCAT(
                'SELECT COUNT(*) AS totrec,',
                'SUM(CASE WHEN YEAR(', @v_primarydctable, '.createdon) = YEAR(GETDATE()) THEN 1 ELSE 0 END) AS cyear,',
                'SUM(CASE WHEN MONTH(', @v_primarydctable, '.createdon) = MONTH(GETDATE()) THEN 1 ELSE 0 END) AS cmonth,',
                'SUM(CASE WHEN DATEPART(WEEK, ', @v_primarydctable, '.createdon) = DATEPART(WEEK, GETDATE()) THEN 1 ELSE 0 END) AS cweek,',
                'SUM(CASE WHEN CAST(', @v_primarydctable, '.createdon AS DATE) = CAST(GETDATE() - 1 AS DATE) THEN 1 ELSE 0 END) AS cyesterday,',
                'SUM(CASE WHEN CAST(', @v_primarydctable, '.createdon AS DATE) = CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) AS ctoday,',
                '''General'' AS cnd, NULL AS criteria ',
                'FROM ', @v_primarydctable, 
                ' WHERE cancel = ''F''',
                CASE WHEN @v_fldname_transidcnd > 0 THEN CONCAT(' AND transid = ''', @pentity_transid, '''') ELSE '' END,
                ' --axp_filter'
            );

            SET @v_final_sqls = @v_sql;
        END
        ELSE IF @psource = 'Subentity'
        BEGIN
            DECLARE rec_cursor CURSOR FOR
            SELECT value AS criteria
            FROM STRING_SPLIT(@pcriteria, '^');

            OPEN rec_cursor;
            FETCH NEXT FROM rec_cursor INTO @rec;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                set @v_transid = dbo.split_part(@rec,'~',1);
	      		set @v_tablename = dbo.split_part(@rec,'~',9);
				set @v_keyfld_fname = dbo.split_part(@rec,'~',10);
				set @v_keyfld_fval = dbo.split_part(@rec,'~',11);
				set @v_keyfld_srckey = dbo.split_part(@rec,'~',5);
				set @v_keyfld_srctbl = dbo.split_part(@rec,'~',6);
				set @v_keyfld_srcfld = dbo.split_part(@rec,'~',7);

                -- Fetch subentity table name
                SELECT TOP 1 @v_subentitytable = tablename
                FROM axpdc
                WHERE tstruct = @v_transid AND dname = 'dc1';
               
               	SELECT @v_fldname_transidcnd = COUNT(1)
        		FROM axpflds
        		WHERE tstruct = @v_transid AND dcname = 'dc1' AND LOWER(fname) = 'transid';

                
				if lower(@v_tablename)=lower(@v_subentitytable) 
				begin			
				 	set @v_sql = concat('select ','''',@v_transid,'''transid',',count(*) totrec,''General'' cnd,','''',replace(@rec,'''',''),'''  criteria from '
						  ,@v_tablename
						  ,case when @v_keyfld_srckey='T' then ' join '+@v_keyfld_srctbl+' on '+@v_keyfld_srctbl+'.'+@v_keyfld_srctbl+'id = '+@v_tablename+'.'+@v_keyfld_fname end
						  ,' where ',@v_tablename,'.cancel=''F'' and '
						  ,case when @v_fldname_transidcnd > 0 then concat(@v_tablename,'.transid=''',@v_transid,''' and ') end
				 		  ,case when @v_keyfld_srckey='T' then @v_keyfld_srctbl+'.'+@v_keyfld_srcfld else @v_keyfld_fname end,'=',@v_keyfld_fval);				
				end
				else 
				begin
					set @v_sql = concat('select ','''',@v_transid,'''transid',',count(*) totrec,''General''::varchar cnd,','''',replace(@rec,'''',''),'''  criteria from '
						,@v_tablename,' a join ',@v_subentitytable,' b on a.',@v_subentitytable,'id=b.',@v_subentitytable,'id '
						,case when @v_keyfld_srckey='T' then ' join '+@v_keyfld_srctbl+' on '+@v_keyfld_srctbl+'.'+@v_keyfld_srctbl+'id = a.'+@v_keyfld_fname end
						,' where b.cancel=''F'' and ',
						case when @v_fldname_transidcnd > 0 then concat(' b.transid=''',@v_transid,''' and ') end
				 		,case when @v_keyfld_srckey='T' then @v_keyfld_srctbl+'.'+@v_keyfld_srcfld else @v_keyfld_fname end,'=',@v_keyfld_fval);								
				end;
			
				set @v_final_sqls = concat(@v_final_sqls,',',@v_sql);	

                FETCH NEXT FROM rec_cursor INTO @v_transid;
            END;

            CLOSE rec_cursor;
            DEALLOCATE rec_cursor;
        END
    END;
    
      
     return @v_final_sqls;

end;
>>
<<
CREATE or alter  PROCEDURE fn_axpanalytics_filterdata
(
    @ptransid VARCHAR(255),   
    @pflds    VARCHAR(MAX),   -- fld~normalized~schema.table~sourcefield
    @debug    BIT = 0        
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @v_sql        NVARCHAR(MAX),
        @normalized  CHAR(1),
        @fldname     SYSNAME,
        @schema      SYSNAME,
        @table       SYSNAME,
        @sourcefld   SYSNAME,
        @fulltable   NVARCHAR(300);

    SELECT
        @fldname    = dbo.split_part(@pflds, '~', 1),
        @normalized = dbo.split_part(@pflds, '~', 2),
        @fulltable  = dbo.split_part(@pflds, '~', 3),
        @sourcefld  = dbo.split_part(@pflds, '~', 4);

    IF @normalized = 'T'
    BEGIN
        SET @v_sql = N'
            SELECT DISTINCT ' + QUOTENAME(@sourcefld) + N' AS datavalue
            FROM ' + QUOTENAME(@fulltable);
    END
    ELSE
    BEGIN
        SET @v_sql = N'
            SELECT DISTINCT ' + @fldname + N' AS datavalue
            FROM ' + @fulltable;
    END

    IF @debug = 1
        PRINT @v_sql;

    EXEC sp_executesql @v_sql;
END;
>>
<<
CREATE or alter PROCEDURE fn_axpanalytics_ins_axreltn
AS
BEGIN
	
	SET ROWCOUNT 0;

DELETE FROM axentityrelations
    WHERE rtype != 'custom';

    INSERT INTO axentityrelations (
        axentityrelationsid,
        cancel,
        username,
        modifiedon,
        createdby,
        createdon,
        app_level,
        app_desc,
        rtype,
        mstruct,
        mfield,
        mtable,
        primarytable,
        dstruct,
        dfield,
        dtable,
        rtypeui,
        mstructui,
        mfieldui,
        dstructui,
        dfieldui,
        dprimarytable
    )    
    SELECT
       NEXT VALUE FOR ax_entity_relseq axentityrelationsid,
        cancel,
        username,
        modifiedon,
        createdby,
        createdon,
        app_level,
        app_desc,
        rtype,
        mstruct,
        mfield,
        mtable,
        primarytable,
        dstruct,
        dfield,
        dtable,
        rtypeui,
        mstructui,
        mfieldui,
        dstructui,
        dfieldui,
        dprimarytable
    FROM vw_entityrelations;

END;
>>
<<
CREATE or alter function fn_axpanalytics_listdata(
	@ptransid VARCHAR(255), 
    @pflds varchar(max) = 'All', 
    @ppagesize NUMERIC = 25, 
    @ppageno NUMERIC = 1, 
    @pfilter nvarchar(max) = 'NA', 
    @pusername VARCHAR(255) = 'admin', 
    @papplydac VARCHAR(1)='T',
    @puserrole varchar(max) ='All',
    @pconstraints varchar(max) =NULL
    )
    RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE 
        @v_sql NVARCHAR(MAX),
        @v_sql1 NVARCHAR(MAX),
        @v_primarydctable VARCHAR(255),
        @v_allflds VARCHAR(MAX),
        @v_fldname_dctablename VARCHAR(255),
        @v_fldname_dcflds VARCHAR(MAX),
        @v_fldname_col VARCHAR(255),
        @v_fldname_normalized VARCHAR(255),
        @v_fldname_srctbl VARCHAR(255),
        @v_fldname_srcfld VARCHAR(255),
        @v_fldname_allowempty VARCHAR(255), 
        @v_fldname_joinsary NVARCHAR(MAX),
        @v_fldnamesary NVARCHAR(MAX),
        @v_fldname_transidcnd NUMERIC,
        @v_filter_srcfld NVARCHAR(MAX),
		@v_filter_srctxt NVARCHAR(MAX),
		@v_filter_join NVARCHAR(MAX),
		@v_filter_joinsary NVARCHAR(MAX),
		@v_filter_cnd NVARCHAR(MAX),
		@v_filter_cndary NVARCHAR(MAX),
		@v_filter_joinreq numeric,
		@v_filter_dcjoinsary NVARCHAR(MAX),
		@v_filter_col NVARCHAR(MAX),
		@v_filter_normalized NVARCHAR(MAX),
		@v_filter_sourcetbl NVARCHAR(MAX),
		@v_filter_sourcefld NVARCHAR(MAX),
		@v_filter_datatype NVARCHAR(MAX),
		@v_filter_listedfld NVARCHAR(MAX),
		@v_filter_tablename NVARCHAR(MAX),
		@v_fldname_tables NVARCHAR(MAX),
		@v_dacenabled numeric=0,
		@v_dactype numeric,
		@v_dac_join NVARCHAR(MAX),
		@v_dac_joinsary NVARCHAR(MAX),
		@v_dac_cnd NVARCHAR(MAX),
		@v_dac_cndary NVARCHAR(MAX),
		@v_dac_joinreq numeric,
		@v_dac_normalizedjoinreq numeric,
		@v_tablename nvarchar(max)

       

    -- Retrieve primary DC table based on tstruct
    SELECT @v_primarydctable = tablename 
    FROM axpdc 
    WHERE tstruct = @ptransid AND dname = 'dc1';
    
    -- Retrieve transid condition
    SELECT @v_fldname_transidcnd = COUNT(1) 
    FROM axpflds 
    WHERE tstruct = @ptransid AND dcname = 'dc1' AND LOWER(fname) = 'transid';
    
    -- If pflds is 'All', get all fields for primary table
    IF @pflds = 'All'
    BEGIN
        SELECT @v_allflds = concat(tablename, '=', string_agg(CONCAT(fname, '~', srckey, '~', srctf, '~', srcfld, '~', allowempty),'|'))
        FROM axpflds 
        WHERE tstruct = @ptransid 
          AND dcname = 'dc1' 
          AND asgrid = 'F' 
          AND hidden = 'F' 
          AND savevalue = 'T' 
          AND tablename = @v_primarydctable 
          AND datatype NOT IN ('i', 't')
         group by tablename;
    END
    
    -- Iterate over the fields in pflds or all fields if 'All' is passed
    DECLARE @dcdtls VARCHAR(MAX);
    DECLARE @fldname VARCHAR(255);
    
    DECLARE cur1 CURSOR FOR
    SELECT value
    FROM STRING_SPLIT(CASE WHEN @pflds = 'All' THEN @v_allflds ELSE @pflds END, '^');
    
    OPEN cur1;
    FETCH NEXT FROM cur1 INTO @dcdtls;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Split the field details into variables
        SET @v_fldname_dctablename = dbo.split_part(@dcdtls,'=',1);
        SET @v_fldname_dcflds = dbo.split_part(@dcdtls,'=',2);

        -- Join DC tables if needed
        IF @v_fldname_dctablename != @v_primarydctable
        BEGIN
            SET @v_fldname_joinsary = CONCAT(@v_fldname_joinsary, ' LEFT JOIN ', @v_fldname_dctablename, 
                                               ' ON ', @v_primarydctable, '.', @v_primarydctable, 'id = ', 
                                               @v_fldname_dctablename, '.', @v_primarydctable, 'id');
        END
        
        -- Iterate over fields to join or select
        DECLARE cur2 CURSOR FOR 
        SELECT value
        FROM STRING_SPLIT(@v_fldname_dcflds, '|');
        
        OPEN cur2;
        FETCH NEXT FROM cur2 INTO @fldname;
        
WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @v_fldname_col = dbo.split_part(@fldname,'~',1);
            SET @v_fldname_normalized = dbo.split_part(@fldname,'~',2);
            SET @v_fldname_srctbl = dbo.split_part(@fldname,'~',3);
            SET @v_fldname_srcfld = dbo.split_part(@fldname,'~',4);
            SET @v_fldname_allowempty = dbo.split_part(@fldname,'~',5);
            
            IF @v_fldname_normalized = 'F'
            BEGIN
                SET @v_fldnamesary = CONCAT(@v_fldnamesary, @v_fldname_dctablename, '.', @v_fldname_col, ',');
            END
            ELSE IF @v_fldname_normalized = 'T'
            BEGIN
                SET @v_fldnamesary = CONCAT(@v_fldnamesary, @v_fldname_col, '.', @v_fldname_srcfld, ' ', @v_fldname_col, ',');
                SET @v_fldname_joinsary = CONCAT(@v_fldname_joinsary, 
                    CASE WHEN @v_fldname_allowempty = 'F' THEN ' JOIN ' ELSE ' LEFT JOIN ' END, 
@v_fldname_srctbl, ' ', @v_fldname_col, 
                    ' ON ', @v_fldname_dctablename, '.', @v_fldname_col, ' = ', @v_fldname_col, '.', @v_fldname_srctbl, 'id');
            END
            
            FETCH NEXT FROM cur2 INTO @fldname;
        END
        
        CLOSE cur2;
        DEALLOCATE cur2;
        
        FETCH NEXT FROM cur1 INTO @dcdtls;
    END
    
    CLOSE cur1;
    DEALLOCATE cur1;
	set @v_fldnamesary = LEFT(@v_fldnamesary, LEN(@v_fldnamesary) - 1); 	
    -- Construct the final SQL statement
    SET @v_sql = CONCAT('SELECT ''', @ptransid, ''' AS transid, ', @v_primarydctable, '.', @v_primarydctable, 
                        'id AS recordid, ', @v_primarydctable, '.username AS modifiedby, ', 
                        @v_primarydctable, '.modifiedon, ', @v_primarydctable, '.createdon, ', 
                        @v_primarydctable, '.createdby, ', @v_fldnamesary, 
                        ' FROM ', @v_primarydctable, ' ', @v_fldname_joinsary);
                       
                       
---------filters	        
		IF @pfilter = 'NA'
		    	BEGIN
			    	if @ppagesize > 0 begin
		        SET @v_sql1 =  
    'SELECT b.* FROM (' +
    '    SELECT a.*, ' +
    '        ROW_NUMBER() OVER(ORDER BY modifiedon DESC) AS rno, ' +
    '        CASE ' +
    '            WHEN ROW_NUMBER() OVER(ORDER BY modifiedon DESC) %' + CAST(@ppagesize AS NVARCHAR) + ' = 0 ' +
    '                THEN ROW_NUMBER() OVER(ORDER BY modifiedon DESC) / ' + CAST(@ppagesize AS NVARCHAR) + ' ' +
    '            ELSE ROW_NUMBER() OVER(ORDER BY modifiedon DESC) / ' + CAST(@ppagesize AS NVARCHAR) + ' + 1 ' +
    '        END AS pageno ' +
    '    FROM (' +    
    '        ' + @v_sql + ' ' +    
    '        WHERE ' + @v_primarydctable + '.cancel = ''F'' ' +
    '        ' + CASE WHEN @v_fldname_transidcnd > 0 THEN 'AND ' + @v_primarydctable + '.transid = ''' + @ptransid + '''' ELSE '' END + ' ' +
    '        ' + CASE WHEN @v_dacenabled > 0 THEN 'AND ' + @v_dac_cndary ELSE '' END + ' ' +
    '    ) a ' +
    '    ORDER BY modifiedon DESC ' +
    '    OFFSET ' + CAST(@ppagesize * (@ppageno - 1) AS NVARCHAR) + ' ROWS ' +
    '    FETCH NEXT ' + CAST(@ppagesize AS NVARCHAR) + ' ROWS ONLY' +
    ') b ' +
    CASE WHEN @ppageno = 0 THEN '' ELSE 'WHERE pageno = ' + CAST(@ppageno AS NVARCHAR) END;
   end
   else begin
	    SET @v_sql1 =  
    'SELECT b.* FROM (' +
    '    SELECT a.*, ' +
    '        ROW_NUMBER() OVER(ORDER BY modifiedon DESC) AS rno, ' +
    '       1 AS pageno ' +
    '    FROM (' +    
    '        ' + @v_sql + ' ' +    
    '        WHERE ' + @v_primarydctable + '.cancel = ''F'' ' +
    '        ' + CASE WHEN @v_fldname_transidcnd > 0 THEN 'AND ' + @v_primarydctable + '.transid = ''' + @ptransid + '''' ELSE '' END + ' ' +
    '        ' + CASE WHEN @v_dacenabled > 0 THEN 'AND ' + @v_dac_cndary ELSE '' END + ' ' +
    '    ) a ' +
    '    ) b ORDER BY modifiedon DESC ' ;
	   end
		    	END
	    ELSE
		    BEGIN
		        DECLARE @filterList TABLE (filter NVARCHAR(MAX));
		
		        INSERT INTO @filterList
		        SELECT value
		        FROM STRING_SPLIT(@pfilter, '^');
		
		        DECLARE @filter NVARCHAR(MAX);
		        
		
		        DECLARE filterCursor CURSOR FOR 
		        SELECT filter 
		        FROM @filterList;
		
		        OPEN filterCursor;
		
		        FETCH NEXT FROM filterCursor INTO @filter;
		
		        WHILE @@FETCH_STATUS = 0
		        BEGIN
		            SET @v_filter_srcfld =  dbo.split_part(@filter,'|',1);
		            SET @v_filter_srctxt = dbo.split_part(@filter,'|',2);
		            SET @v_filter_col = dbo.split_part(@v_filter_srcfld,'~',1);
					SET @v_filter_normalized = dbo.split_part(@v_filter_srcfld,'~',2);
		 			SET @v_filter_sourcetbl = dbo.split_part(@v_filter_srcfld,'~',3);
		 			SET @v_filter_sourcefld = dbo.split_part(@v_filter_srcfld,'~',4);
					SET @v_filter_datatype = dbo.split_part(@v_filter_srcfld,'~',5);
					SET @v_filter_listedfld =dbo.split_part(@v_filter_srcfld,'~',6);
		            SET @v_filter_tablename = dbo.split_part(@v_filter_srcfld,'~',7);
		           
		           
		          	if  @v_filter_listedfld = 'F' begin
					    set @v_filter_joinreq = case when lower(@v_tablename)=lower(@v_filter_tablename) then 1 else 0 end; 			    		
								
						if @v_filter_joinreq = 0  
							begin 
								set @v_filter_dcjoinsary = concat(@v_filter_dcjoinsary,',',concat(' join ',@v_filter_tablename,' on ',@v_primarydctable,'.',@v_primarydctable,'id=',@v_filter_tablename,'.',@v_primarydctable,'id') );
							end
						    				    					  
					    select @v_filter_join  = case when @v_filter_normalized='T' 
						then concat(' join ',@v_filter_sourcetbl,' ',@v_filter_col,' on ',@v_filter_tablename,'.',@v_filter_col,' = ',@v_filter_col,'.',@v_filter_sourcetbl,'id')
						end from dual where @v_filter_normalized='T';
														 
						set @v_filter_joinsary =concat(@v_filter_joinsary,',',@v_filter_join);														
					end
		
		           	select @v_filter_cnd = case when @v_filter_normalized='F' then 
		            concat(case when @v_filter_datatype='c' then 'lower(' end,@v_filter_tablename,'.',@v_filter_col,case when @v_filter_datatype='c' then ')' end,' ',@v_filter_srctxt) else 
					concat(case when @v_filter_datatype='c' then 'lower(' end,@v_filter_col,'.',@v_filter_sourcefld,case when @v_filter_datatype='c' then ')' end,' ',@v_filter_srctxt) end;
		
		            SET @v_filter_cndary = CONCAT(@v_filter_cndary, ' AND ', @v_filter_cnd);
		
		            FETCH NEXT FROM filterCursor INTO @filter;
		        END;
		
		        CLOSE filterCursor;
		        DEALLOCATE filterCursor;
		       
		       if @ppagesize > 0 begin
		        SET @v_sql1 = 
    'SELECT b.* FROM (' +
    '    SELECT a.*, ' +
    '           ROW_NUMBER() OVER (ORDER BY modifiedon DESC) AS rno, ' +
    '           CASE ' +
    '               WHEN ROW_NUMBER() OVER (ORDER BY modifiedon DESC)% ' + CAST(@ppagesize AS NVARCHAR) + ' = 0 ' +
    '                   THEN ROW_NUMBER() OVER (ORDER BY modifiedon DESC) / ' + CAST(@ppagesize AS NVARCHAR) + ' ' +
    '               ELSE ROW_NUMBER() OVER (ORDER BY modifiedon DESC) / ' + CAST(@ppagesize AS NVARCHAR) + ' + 1 ' +
    '           END AS pageno ' +
    '    FROM (' + @v_sql + ' ' +
    ISNULL(@v_filter_dcjoinsary, '') + ' ' +
    ISNULL(@v_filter_joinsary, '') + ' ' +
    'WHERE ' + @v_primarydctable + '.cancel = ''F'' ' +
    + CASE WHEN @v_fldname_transidcnd > 0 
        THEN 'AND ' +@v_primarydctable + '.transid = ''' + @ptransid + ''' AND '
        ELSE '' END + 
    ISNULL(@v_filter_cndary, '') + 
    CASE WHEN @v_dacenabled > 0 
        THEN ' AND ' + ISNULL(@v_dac_cndary, '') 
        ELSE '' END + 
    ') a ' +
    'ORDER BY modifiedon DESC ' +
    'OFFSET ' + CAST(@ppagesize * (@ppageno - 1) AS NVARCHAR) + ' ROWS ' +
    'FETCH NEXT ' + CAST(@ppagesize AS NVARCHAR) + ' ROWS ONLY) b ' +
    CASE WHEN @ppageno = 0 
        THEN '' 
        ELSE 'WHERE pageno = ' + CAST(@ppageno AS NVARCHAR) 
    END;
   end
   else begin
	     SET @v_sql1 = 
    'SELECT b.* FROM (' +
    '    SELECT a.*, ' +
    '           ROW_NUMBER() OVER (ORDER BY modifiedon DESC) AS rno, ' +
    '          1 AS pageno ' +
    '    FROM (' + @v_sql + ' ' +
    ISNULL(@v_filter_dcjoinsary, '') + ' ' +
    ISNULL(@v_filter_joinsary, '') + ' ' +
    'WHERE ' + @v_primarydctable + '.cancel = ''F'' ' +
    + CASE WHEN @v_fldname_transidcnd > 0 
        THEN 'AND ' +@v_primarydctable + '.transid = ''' + @ptransid + ''' AND '
        ELSE '' END + 
    ISNULL(@v_filter_cndary, '') + 
    CASE WHEN @v_dacenabled > 0 
        THEN ' AND ' + ISNULL(@v_dac_cndary, '') 
        ELSE '' END + 
    ') a ' +') b ORDER BY modifiedon DESC ';
	end
		end

    return @v_sql1;
END;
>>
<<
CREATE or alter PROCEDURE fn_axpanalytics_metadata
    @ptransid NVARCHAR(50),
    @psubentity NVARCHAR(1) = 'F',
    @language nvarchar(100) ='English' 
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_primarydctable NVARCHAR(50);
    DECLARE @v_sql NVARCHAR(MAX);
    DECLARE @v_subentitysql NVARCHAR(MAX);

    -- Temporary table to hold results
    CREATE TABLE #axpdef_axpanalytics_mdata (
        ftransid NVARCHAR(50),
        fcaption NVARCHAR(500),
        fldname NVARCHAR(50),
        fldcap NVARCHAR(500),
        cdatatype NVARCHAR(50),
        fdatatype NVARCHAR(50),
        fmodeofentry NVARCHAR(50),
        hide NVARCHAR(10), 
        props NVARCHAR(4000),
        normalized NVARCHAR(50),
        srctable NVARCHAR(50),
        srcfield NVARCHAR(50),
        srctransid NVARCHAR(50),
        allowempty NVARCHAR(10),
        filtertype NVARCHAR(50),
        grpfield NVARCHAR(10),
        aggfield NVARCHAR(10),
        subentity NVARCHAR(1),
        datacnd TINYINT,
        entityrelfld NVARCHAR(100),
        allowduplicate NVARCHAR(1),
        tablename NVARCHAR(100),
        dcname NVARCHAR(10),
        fordno INT,
        dccaption NVARCHAR(100),
        griddc NVARCHAR(2),
        listingfld NVARCHAR(1)
    );

    -- Query to get primary DC table
    SELECT @v_primarydctable = tablename
    FROM axpdc
    WHERE tstruct = @ptransid AND dname = 'dc1';

    -- Dynamic SQL for primary query
    SET @v_sql = 'SELECT axpflds.tstruct AS transid, COALESCE(lf.compcaption, t.caption) AS formcap, fname, COALESCE(l.compcaption, axpflds.caption) AS fcap,
                    customdatatype AS cdatatype, datatype AS dt, modeofentry, hidden AS fhide, NULL AS props,srckey, srctf, srcfld, 
     srctrans, axpflds.allowempty,
                    CASE WHEN modeofentry = ''select'' THEN 
                         CASE WHEN srckey = ''T'' THEN ''Dropdown'' ELSE ''Text'' END
                         ELSE ''Text'' END AS filtercnd,
                    CASE WHEN (modeofentry = ''select'' OR datatype = ''c'') THEN ''T'' ELSE ''F'' END AS grpfld,
                    CASE WHEN datatype = ''n'' THEN ''T'' ELSE ''F'' END AS aggfld, ''F'' AS subentity, 1 AS datacnd,
                    NULL AS entityrelfld, allowduplicate, axpflds.tablename, dcname, ordno, d.caption AS dccaption,
                    d.asgrid, CASE WHEN d.asgrid = ''F'' THEN ''T'' ELSE ''F'' END AS listingfld
                 FROM axpflds
                 JOIN tstructs t ON axpflds.tstruct = t.name
                 JOIN axpdc d ON axpflds.tstruct = d.tstruct AND axpflds.dcname = d.dname
     left join axlanguage l on SUBSTRING(l.sname, 2, LEN(l.sname))= t.name and lower(l.dispname)='''+ lower(@language) +''' and ''lbl''+axpflds.fname =  l.compname
     left join axlanguage lf on SUBSTRING(lf.sname, 2, LEN(lf.sname))= t.name and lower(lf.dispname)='''+ lower(@language) +''' and lf.compname=''x__headtext''       
                 WHERE axpflds.tstruct = ''' + @ptransid + ''' AND savevalue = ''T''';

    -- Insert dynamic SQL results into temporary table
    INSERT INTO #axpdef_axpanalytics_mdata
    EXEC sp_executesql @v_sql;

    -- Handle subentity logic
    IF @psubentity = 'T'
    BEGIN
        DECLARE rec_cursor CURSOR FOR
            SELECT DISTINCT a.dstruct, a.rtype, a.dprimarytable
            FROM axentityrelations a
            WHERE rtype IN ('md', 'custom', 'gm') AND mstruct = @ptransid;

        OPEN rec_cursor;

        DECLARE @dstruct NVARCHAR(50), @rtype NVARCHAR(50), @dprimarytable NVARCHAR(50);

        FETCH NEXT FROM rec_cursor INTO @dstruct, @rtype, @dprimarytable;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @v_subentitysql = 'SELECT axpflds.tstruct AS transid, COALESCE(lf.compcaption, t.caption) AS formcap, fname, 
                                      COALESCE(l.compcaption, axpflds.caption) AS fcap, customdatatype AS cdatatype, datatype AS dt,
                   modeofentry, hidden AS fhide, NULL AS props, srckey, srctf, srcfld,
                                      srctrans, axpflds.allowempty,
                                      CASE WHEN modeofentry = ''select'' THEN 
                                           CASE WHEN srckey = ''T'' THEN ''Dropdown'' ELSE ''Text'' END
                                           ELSE ''Text'' END AS filtercnd,
                                      CASE WHEN modeofentry = ''select'' THEN ''T'' ELSE ''F'' END AS grpfld,
                                      CASE WHEN datatype = ''n'' THEN ''T'' ELSE ''F'' END AS aggfld, ''T'' AS subentity,
                                      2 AS datacnd, r.mfield AS entityrelfld, allowduplicate, axpflds.tablename, 
                                      dcname, ordno, d.caption AS dccaption, d.asgrid, 
                                      CASE WHEN d.asgrid = ''F'' THEN ''T'' ELSE ''F'' END AS listingfld
                                   FROM axpflds
                                   JOIN tstructs t ON axpflds.tstruct = t.name
                                   JOIN axpdc d ON axpflds.tstruct = d.tstruct AND axpflds.dcname = d.dname
           left join axlanguage l on SUBSTRING(l.sname, 2, LEN(l.sname))= t.name and lower(l.dispname)='''+ lower(@language) +''' and ''lbl''+axpflds.fname =  l.compname
           left join axlanguage lf on SUBSTRING(lf.sname, 2, LEN(lf.sname))= t.name and lower(lf.dispname)='''+ lower(@language) +''' and lf.compname=''x__headtext''
                                   LEFT JOIN axentityrelations r ON axpflds.tstruct = r.dstruct AND 
                                                                   axpflds.fname = r.dfield AND 
                                                                   r.mstruct = ''' + @ptransid + '''
                                   WHERE axpflds.tstruct = ''' + @dstruct + ''' AND savevalue = ''T''';

            -- Insert subentity results into temporary table
            INSERT INTO #axpdef_axpanalytics_mdata
            EXEC sp_executesql @v_subentitysql;

            FETCH NEXT FROM rec_cursor INTO @dstruct, @rtype, @dprimarytable;
        END;

        CLOSE rec_cursor;
        DEALLOCATE rec_cursor;
    END;

    SELECT * FROM #axpdef_axpanalytics_mdata;

    DROP TABLE #axpdef_axpanalytics_mdata;

END;
>>
<<
CREATE or alter FUNCTION fn_axpanalytics_se_listdata(
    @pentity_transid NVARCHAR(MAX),
    @pflds_keyval NVARCHAR(MAX),
    @ppagesize INT = 50,
    @ppageno INT = 1
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @v_sql NVARCHAR(MAX);
    DECLARE @v_sql1 NVARCHAR(MAX);
    DECLARE @v_fldname_table NVARCHAR(MAX);
    DECLARE @v_fldname_col NVARCHAR(MAX);
    DECLARE @v_fldname_normalized NVARCHAR(MAX);
    DECLARE @v_fldname_srctbl NVARCHAR(MAX);
    DECLARE @v_fldname_srcfld NVARCHAR(MAX);
    DECLARE @v_fldname_allowempty NVARCHAR(MAX);
    DECLARE @v_fldname_transidcnd INT;
   	DECLARE @v_fldname_tblflds NVARCHAR(MAX);
    DECLARE @v_allflds NVARCHAR(MAX);
   	DECLARE @v_fldnamesary NVARCHAR(MAX) = '';
    DECLARE @v_pflds_transid NVARCHAR(MAX);
    DECLARE @v_pflds_flds NVARCHAR(MAX);
    DECLARE @v_pflds_keyvalue NVARCHAR(MAX);
    DECLARE @v_pflds_keytable NVARCHAR(MAX);
    DECLARE @v_keyvalue_fname NVARCHAR(MAX);
    DECLARE @v_keyvalue_fvalue NVARCHAR(MAX);
    DECLARE @v_keyvalue_fname_srckey NVARCHAR(MAX);
    DECLARE @v_keyvalue_fname_srctbl NVARCHAR(MAX);
    DECLARE @v_keyvalue_fname_srcfld NVARCHAR(MAX);
    DECLARE @v_final_sqls NVARCHAR(MAX) = '';
    DECLARE @v_primarydctable NVARCHAR(MAX);
    DECLARE @v_fldname_dcjoinsary NVARCHAR(MAX) = '';
    DECLARE @v_fldname_joinsary  NVARCHAR(MAX) = '';
   
   
   
   	/*
	 * * pflds_keyval - transid=tablename!~fldname~normalized~source_table~source_fld~allowempty|fldname2~normalized~source_table~source_fld~allowempty^tablename2!~fldname~normalized~srctbl~srcfld~allowempty=dependfld~dependval++
	 * transid2=tablename!~fldname~normalized~source_table~source_fld~allowempty|fldname2~normalized~source_table~source_fld~allowempty=dependfld~dependval		 
	 */

       -- Split the input @pflds_keyval using a table-valued function
    DECLARE @rec TABLE (fldkeyvals NVARCHAR(MAX));
    INSERT INTO @rec SELECT value FROM STRING_SPLIT(@pflds_keyval, '+');

    DECLARE @rec1 TABLE (tblflds NVARCHAR(MAX));
    DECLARE @rec2 TABLE (fldname NVARCHAR(MAX));

    -- Loop through @rec table for processing
    DECLARE @fldkeyvals NVARCHAR(MAX);
    DECLARE cur CURSOR FOR SELECT fldkeyvals FROM @rec;
    OPEN cur;

    FETCH NEXT FROM cur INTO @fldkeyvals;
    WHILE @@FETCH_STATUS = 0
    BEGIN
             
       	SET @v_pflds_transid = dbo.split_part(@fldkeyvals,'=',1) ;	    	
	    SET @v_pflds_flds = dbo.split_part(@fldkeyvals,'=',2) ;--tablename=~fldname~normalized~source_table~source_fld~mandatory|fldname2~normalized~source_table~source_fld~mandatory^tablename2=~fldname~normalized~srctbl~srcfld~mandatory
	    SET @v_pflds_keyvalue = dbo.split_part(@fldkeyvals,'=',3) ;
	    SET @v_pflds_keytable = dbo.split_part(@v_pflds_keyvalue,'~',3) ;  	    
		SET @v_keyvalue_fname = dbo.split_part(@v_pflds_keyvalue,'~',1);
		SET @v_keyvalue_fvalue = dbo.split_part(@v_pflds_keyvalue,'~',2);		
		SET @v_keyvalue_fname_srckey = dbo.split_part(@v_pflds_keyvalue,'~',4) ;
		SET @v_keyvalue_fname_srctbl = dbo.split_part(@v_pflds_keyvalue,'~',5) ;
		SET @v_keyvalue_fname_srcfld = dbo.split_part(@v_pflds_keyvalue,'~',6) ;		
			

        -- Retrieve the primary data collection table
        SELECT @v_primarydctable = tablename 
        FROM axpdc 
        WHERE tstruct = @v_pflds_transid AND dname = 'dc1';

        -- Check if 'transid' exists in the table
        SELECT @v_fldname_transidcnd = COUNT(1) 
        FROM axpflds 
        WHERE tstruct = @v_pflds_transid AND dcname = 'dc1' AND LOWER(fname) = 'transid';

        IF LOWER(@v_pflds_keytable) = LOWER(@v_primarydctable) AND @v_pflds_flds = 'All'
        BEGIN
            SELECT @v_allflds = CONCAT(tablename, '!~', STRING_AGG(CONCAT(fname, '~', srckey, '~', srctf, '~', srcfld, '~', allowempty), '|'))
            FROM axpflds
            WHERE tstruct = @v_pflds_transid AND dcname = 'dc1' AND asgrid = 'F' AND hidden = 'F' AND savevalue = 'T' AND datatype NOT IN ('i', 't')
        GROUP BY tablename;
        END
  ELSE IF LOWER(@v_pflds_keytable) != LOWER(@v_primarydctable) AND @v_pflds_flds = 'All'
        BEGIN
            SELECT @v_allflds = CONCAT(tablename, '!~', STRING_AGG(CONCAT(fname, '~', srckey, '~', srctf, '~', srcfld, '~', allowempty), '|'), '^', @v_pflds_keytable, '!~', 
                dbo.split_part(dbo.split_part(@v_pflds_keyvalue,'~',1),'.',2),'~',dbo.split_part(@v_pflds_keyvalue,'~',4),'~',dbo.split_part(@v_pflds_keyvalue,'~',5),'~',dbo.split_part(@v_pflds_keyvalue,'~',6),'~',dbo.split_part(@v_pflds_keyvalue,'~',7))
            FROM axpflds
            WHERE tstruct = @v_pflds_transid AND dcname = 'dc1' AND asgrid = 'F' AND hidden = 'F' AND savevalue = 'T' AND datatype NOT IN ('i', 't')
            GROUP BY tablename;
        END

        -- Process each field in the fields list
        INSERT INTO @rec1 SELECT value FROM STRING_SPLIT(CASE WHEN @v_pflds_flds = 'All' THEN @v_allflds ELSE @v_pflds_flds END, '^');

        DECLARE @tblflds NVARCHAR(MAX);
        DECLARE cur1 CURSOR FOR SELECT tblflds FROM @rec1;
        OPEN cur1;

        FETCH NEXT FROM cur1 INTO @tblflds;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @v_fldname_table = dbo.split_part(@tblflds,'!~',1);
            SET @v_fldname_tblflds = dbo.split_part(@tblflds,'!~',2);
           

            IF LOWER(@v_fldname_table) != LOWER(@v_primarydctable)
            BEGIN
                SET @v_fldname_dcjoinsary += CONCAT(' LEFT JOIN ', @v_fldname_table, ' ON ', @v_primarydctable, '.', @v_primarydctable, 'id = ', @v_fldname_table, '.', @v_primarydctable, 'id');
            END
            
            if lower(@v_fldname_table)!=lower(@v_pflds_keytable) 
            BEGIN
				set @v_fldname_dcjoinsary += concat(@v_fldname_dcjoinsary,concat('left join ',@v_pflds_keytable,' on ',@v_primarydctable,'.',@v_primarydctable,'id=',@v_pflds_keytable,'.',@v_primarydctable,'id') );			
			END
				
			if @v_keyvalue_fname_srckey='T' 
			BEGIN			
				set @v_fldname_joinsary += concat(@v_fldname_joinsary,concat(' join ' ,@v_keyvalue_fname_srctbl,' ',' on ',@v_keyvalue_fname,' = ',@v_keyvalue_fname_srctbl,'.',@v_keyvalue_fname_srctbl,'id'));
			end

            INSERT INTO @rec2 SELECT value FROM STRING_SPLIT(@v_fldname_tblflds, '|');

            DECLARE @fldname NVARCHAR(MAX);
            DECLARE cur2 CURSOR FOR SELECT fldname FROM @rec2;
            OPEN cur2;

            FETCH NEXT FROM cur2 INTO @fldname;
            WHILE @@FETCH_STATUS = 0
            BEGIN                             
	            SET @v_fldname_col = dbo.split_part(@fldname,'~',1);
				SET @v_fldname_normalized = dbo.split_part(@fldname,'~',2);
				SET @v_fldname_srctbl = dbo.split_part(@fldname,'~',3);
				SET @v_fldname_srcfld = dbo.split_part(@fldname,'~',4);														
				SET @v_fldname_allowempty = dbo.split_part(@fldname,'~',5);

                IF @v_fldname_normalized = 'F'
                BEGIN
                    SET @v_fldnamesary += CONCAT(@v_fldnamesary,concat(@v_fldname_table, '.', @v_fldname_col, ','));
                END
                ELSE IF @v_fldname_normalized = 'T'
                BEGIN
                    SET @v_fldnamesary += concat(@v_fldnamesary,CONCAT(@v_fldname_col, '.', @v_fldname_srcfld, ' ', @v_fldname_col, ','));
                    SET @v_fldname_dcjoinsary += CONCAT(' LEFT JOIN ', @v_fldname_srctbl, ' ', @v_fldname_col, ' ON ', @v_fldname_table, '.', @v_fldname_col, ' = ', @v_fldname_col, '.', @v_fldname_srctbl, 'id');
                END

                FETCH NEXT FROM cur2 INTO @fldname;
            END

            CLOSE cur2;
            DEALLOCATE cur2;

            FETCH NEXT FROM cur1 INTO @tblflds;
        END

        CLOSE cur1;
        DEALLOCATE cur1;
       
         -- Build SQL Query
        SET @v_sql = CONCAT(
            'SELECT ''', @v_pflds_transid, ''' AS transid, ', @v_primarydctable, '.', @v_primarydctable, 'id AS recordid, ',
 @v_primarydctable, '.username AS modifiedby, ', @v_primarydctable, '.modifiedon, ',
            @v_primarydctable, '.createdon, ', @v_primarydctable, '.createdby,',LEFT(@v_fldnamesary, LEN(@v_fldnamesary) - 1),' FROM ', @v_primarydctable,@v_fldname_dcjoinsary,' ',@v_fldname_joinsary,' ',
            ' where ',@v_primarydctable,'.cancel=''F'' and ',case when @v_fldname_transidcnd>0 then concat(@v_primarydctable,'.transid=','''',@v_pflds_transid,''' and ') end ,
					case when @v_keyvalue_fname_srckey='T'  then @v_keyvalue_fname_srctbl+'.'+@v_keyvalue_fname_srcfld else @v_keyvalue_fname end ,'=',@v_keyvalue_fvalue,'
					--axp_filter
					');

        SET @v_sql1 = CONCAT(
            'SELECT * FROM (SELECT a.*, ROW_NUMBER() OVER (ORDER BY modifiedon DESC) AS rno, ',
            'CASE WHEN (ROW_NUMBER() OVER (ORDER BY modifiedon DESC) % ', @ppagesize, ') = 0 THEN ',
            'ROW_NUMBER() OVER (ORDER BY modifiedon DESC) / ', @ppagesize, ' ELSE ',
            'ROW_NUMBER() OVER (ORDER BY modifiedon DESC) / ', @ppagesize, ' + 1 END AS pageno ',
            'FROM (', @v_sql, ') a ORDER BY modifiedon DESC) b ',
            CASE WHEN @ppageno = 0 THEN '' ELSE CONCAT('WHERE pageno = ', @ppageno) END
        );

        SET @v_final_sqls = CONCAT(@v_final_sqls, @v_sql, '^^^');

        FETCH NEXT FROM cur INTO @fldkeyvals;
    END

    CLOSE cur;
    DEALLOCATE cur;

    RETURN @v_final_sqls;
END;
>>
<<
CREATE or alter  PROCEDURE fn_axprocessdefv2_index_update
(
    @pprocessname  VARCHAR(255),
    @pindexno      NUMERIC(18,0),
    @dbevent       VARCHAR(10),
    @recordid      NUMERIC(18,0),
    @poldindexno   NUMERIC(18,0) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @v_axprocessdefv2id NUMERIC(18,0);

        IF @dbevent = 'Insert'
        BEGIN
            SELECT @v_axprocessdefv2id = axprocessdefv2id
            FROM axprocessdefv2
            WHERE processname = @pprocessname
              AND indexno = @pindexno
              AND axprocessdefv2id <> @recordid;

            IF @v_axprocessdefv2id IS NOT NULL
            BEGIN
                UPDATE axprocessdefv2
                SET indexno = indexno + 1
                WHERE axprocessdefv2id = @v_axprocessdefv2id;

                UPDATE axprocessdefv2
                SET indexno = indexno + 1
                WHERE processname = @pprocessname
                  AND indexno > @pindexno
                  AND axprocessdefv2id NOT IN (@v_axprocessdefv2id, @recordid);
            END
        END
        
        IF @dbevent = 'Update'
        BEGIN
            UPDATE axprocessdefv2
            SET indexno = indexno + 1
            WHERE processname = @pprocessname
              AND indexno >= @pindexno
              AND indexno < @poldindexno
              AND axprocessdefv2id <> @recordid;
        END

        IF @dbevent = 'Delete'
        BEGIN
            UPDATE axprocessdefv2
            SET indexno = indexno - 1
            WHERE processname = @pprocessname
              AND indexno > @pindexno
              AND axprocessdefv2id <> @recordid;
        END

    END TRY
    BEGIN CATCH
        RETURN;
    END CATCH
END;
>>
<<
CREATE  or alter PROCEDURE fn_axusers_usergrp
(
    @pusername   VARCHAR(255),
    @pusergroup  VARCHAR(MAX)   
)
AS
BEGIN
    SET NOCOUNT ON;

    DELETE
    FROM axpdef_peg_usergroups
    WHERE username = @pusername
      AND fromuser = 'T';

     INSERT INTO axpdef_peg_usergroups
    (
        username,
        usergroupname,
        usergroupcode,
        fromuser,
        effectivefrom,
        active
    )
    SELECT
        @pusername,
        value,
        value,
        'T',
        CAST(GETDATE() AS DATE),
        'T'
    FROM STRING_SPLIT(@pusergroup, ',');
END;
>>
<<
create or alter FUNCTION fn_generate_cardjson(@pchartprops NVARCHAR(MAX))
RETURNS table
AS
   return( 
   select '{"attributes":{' +
        '"cck":"' + dbo.split_part( @pchartprops,'|',1) + '",' +
        '"shwLgnd":' + lower(dbo.split_part(@pchartprops,'|',2)) + ',' +
        '"xAxisL":"' + dbo.split_part(@pchartprops,'|',3) + '",' +
        '"yAxisL":"' + dbo.split_part(@pchartprops,'|',4) + '",' +
        '"gradClrChart":' + lower(dbo.split_part(@pchartprops,'|',5)) + ',' +
        '"shwChartVal":' + lower(dbo.split_part(@pchartprops,'|',6)) + ',' +
        '"threeD":"' +case when dbo.split_part(@pchartprops,'|',7)='True' then 'create' else 'remove' end+ '",' +
        '"enableSlick":' + lower(dbo.split_part(@pchartprops,'|',8)) + ',' +
        '"numbSym":' + lower(dbo.split_part(@pchartprops,'|',9)) +
    '}}' cjson);
>>
<<
CREATE or alter  FUNCTION fn_pegv2_editabletask
(
    @p_processname   VARCHAR(255),
    @p_taskname      VARCHAR(255),
    @p_keyvalue      VARCHAR(255),
    @p_currentuser   VARCHAR(255),
    @p_indexno       INT
)
RETURNS CHAR(1)
AS
BEGIN
    DECLARE
        @v_flag            CHAR(1),
        @v_finalapproved   CHAR(1),
        @v_finalappqry     NVARCHAR(MAX),
        @v_currentuserflg  CHAR(1),
        @v_editable        CHAR(1),
        @v_nextleveluser   INT,
        @v_activeuser      INT;

    SELECT
        @v_finalappqry =
            'SELECT @out = CASE WHEN status = 0 THEN ''F'' ELSE ''T'' END
             FROM axpeg_' + CAST(transid AS VARCHAR) +
            ' WHERE keyvalue = @keyvalue'
    FROM axprocessdefv2
    WHERE processname = @p_processname
      AND indexno =
          (
              SELECT MAX(indexno)
              FROM axprocessdefv2
              WHERE processname = @p_processname
                AND stransid <> 'pgv2c'
          );

    EXEC sp_executesql
        @v_finalappqry,
        N'@keyvalue VARCHAR(255), @out CHAR(1) OUTPUT',
        @keyvalue = @p_keyvalue,
        @out      = @v_finalapproved OUTPUT;

    SELECT
        @v_activeuser =
            SUM(CASE
                WHEN taskname = @p_taskname
                 AND touser   = @p_currentuser THEN 1 ELSE 0 END),

        @v_nextleveluser =
            SUM(CASE
                WHEN indexno = @p_indexno + 1
                 AND touser  = @p_currentuser THEN 1 ELSE 0 END)
    FROM vw_pegv2_activetasks
    WHERE processname = @p_processname
      AND keyvalue    = @p_keyvalue;

    SELECT
        @v_currentuserflg =
            CASE WHEN username = @p_currentuser THEN 'T' ELSE 'F' END
    FROM axactivetaskstatus
    WHERE processname = @p_processname
      AND taskname    = @p_taskname
      AND keyvalue    = @p_keyvalue;

    ;WITH a AS
    (
        SELECT
            CAST(value AS INT) AS defid,
            a1.axprocessdefv2id
        FROM axprocessdefv2 a1
        CROSS APPLY STRING_SPLIT(a1.allowedittasksid, ',')
        WHERE a1.processname = @p_processname
          AND a1.allowedit   = 'T'
    )
    SELECT
        @v_flag =
            CASE WHEN COUNT(*) = 0 THEN 'F' ELSE 'T' END
    FROM axprocessdefv2 b
    JOIN a
        ON a.axprocessdefv2id = b.axprocessdefv2id
    JOIN axprocessdefv2 c
        ON a.defid = c.axprocessdefv2id
       AND c.taskname = @p_taskname
    JOIN axactivetasks t
        ON b.processname = @p_processname
       AND t.keyvalue    = @p_keyvalue
       AND b.taskname    = t.taskname
       AND t.touser      = @p_currentuser;

      SELECT
        @v_editable =
        CASE
            WHEN @v_finalapproved = 'T' THEN 'F'
            ELSE
                CASE
                    WHEN @v_activeuser > 0 THEN 'T'
                    WHEN @v_currentuserflg = 'T'
                         AND @v_nextleveluser > 0 THEN 'T'
                    WHEN @v_currentuserflg = 'F'
                         AND @v_activeuser = 0 THEN @v_flag
                    ELSE @v_flag
                END
        END;

    RETURN @v_editable;
END;
>>
<<
CREATE or alter  PROCEDURE fn_pegv2_tasklists
(
    @pprocessname VARCHAR(255),
    @pindexno     NUMERIC(18,0),
    @ptaskname    VARCHAR(255) = NULL,
    @ptransid     VARCHAR(255) = NULL,
    @precordid    NUMERIC(18,0) = 0,
    @pusername    VARCHAR(255) = NULL,
    @ptaskid      NUMERIC(18,0) = 0,
    @pkeyvalue    VARCHAR(255) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_sql NVARCHAR(MAX);

    SET @v_sql = N'
        SELECT taskname
        FROM axprocessdefv2
        WHERE processname = @processname
          AND indexno > @indexno
        ORDER BY indexno;';

    EXEC sp_executesql
        @v_sql,
        N'@processname VARCHAR(255), @indexno NUMERIC(18,0)',
        @processname = @pprocessname,
        @indexno     = @pindexno;
END;
>>
<<
CREATE or alter  PROCEDURE fn_pegv2_updapp_reporting
(
    @p_fromuser     VARCHAR(255),
    @p_existingapp  VARCHAR(255),
    @p_newapp       VARCHAR(255)
)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO axactivetasks
    (
        eventdatetime, taskid, processname, tasktype, taskname,
        taskdescription, assigntorole, transid, keyfield,
        execonapprove, keyvalue, transdata, fromrole, fromuser,
        touser, priorindex, priortaskname, corpdimension,
        orgdimension, department, grade, datavalue,
        displayicon, displaytitle, displaysubtitle,
        displaycontent, displaybuttons, groupfield,
        groupvalue, priorusername, initiator, mapfieldvalue,
        useridentificationfilter, useridentificationfilter_of,
        mapfield_group, mapfield, grouped, indexno, subindexno,
        processowner, assigntoflg, assigntoactor, actorfilter,
        recordid, processownerflg, pownerfilter,
        approvereasons, defapptext, returnreasons, defrettext,
        rejectreasons, defregtext, approvalcomments,
        rejectcomments, returncomments, escalation, reminder,
        displaymcontent, groupwithpriorindex, returnable,
        allowsend, allowsendflg, sendtoactor,
        initiator_approval, usebusinessdatelogic,
        initonbehalf, changedusr
    )
    SELECT
        a.eventdatetime, a.taskid, a.processname, a.tasktype, a.taskname,
        a.taskdescription, a.assigntorole, a.transid, a.keyfield,
        a.execonapprove, a.keyvalue, a.transdata, a.fromrole,
        a.fromuser, @p_newapp,
        a.priorindex, a.priortaskname, a.corpdimension,
        a.orgdimension, a.department, a.grade, a.datavalue,
        a.displayicon, a.displaytitle, a.displaysubtitle,
        a.displaycontent, a.displaybuttons, a.groupfield,
        a.groupvalue, a.priorusername, a.initiator,
        a.mapfieldvalue, a.useridentificationfilter,
        a.useridentificationfilter_of, a.mapfield_group,
        a.mapfield, 'T', a.indexno, a.subindexno,
        a.processowner, a.assigntoflg, a.assigntoactor,
        a.actorfilter, a.recordid, a.processownerflg,
        a.pownerfilter, a.approvereasons, a.defapptext,
        a.returnreasons, a.defrettext, a.rejectreasons,
        a.defregtext, a.approvalcomments, a.rejectcomments,
        a.returncomments, a.escalation, a.reminder,
        a.displaymcontent, a.groupwithpriorindex, a.returnable,
        a.allowsend, a.allowsendflg, a.sendtoactor,
        a.initiator_approval, a.usebusinessdatelogic,
        a.initonbehalf, 'T'
    FROM axactivetasks a
    WHERE a.assigntoflg = '1'
      AND a.delegation  = 'F'
      AND a.pownerflg   = 'F'
      AND a.grouped    = 'T'
      AND a.fromuser   = @p_fromuser
      AND a.touser     = @p_existingapp
      AND a.removeflg  = 'F'
      AND NOT EXISTS (
            SELECT 1
            FROM axactivetaskstatus b
            WHERE b.taskid = a.taskid
      );

    UPDATE a
    SET removeflg = 'T'
    FROM axactivetasks a
    WHERE a.assigntoflg = '1'
      AND a.delegation  = 'F'
      AND a.pownerflg   = 'F'
      AND a.fromuser   = @p_fromuser
      AND a.touser     = @p_existingapp
      AND NOT EXISTS (
            SELECT 1
            FROM axactivetaskstatus b
            WHERE b.taskid = a.taskid
      );
END;
>>
<<
CREATE or alter  FUNCTION fn_permissions_axupscript()
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @v_sqlary TABLE (sql_cmd NVARCHAR(MAX));
    DECLARE @rec_fname NVARCHAR(256);
    DECLARE @v_sql NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);

    DECLARE field_cursor CURSOR FOR 
    SELECT fname 
    FROM axpflds 
    WHERE tstruct = 'a__ua' 
      AND dcname = 'dc4' 
      AND fname NOT IN ('sqltext1', 'cnd1');

    OPEN field_cursor;
    FETCH NEXT FROM field_cursor INTO @rec_fname;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Constructing the dynamic SQL string
        SET @v_sql = 'select ''exists(select 1 from STRING_SPLIT(REPLACE(''' + REPLACE(@rec_fname, 'axug_', '{primarytable.}axg_') + ''','''','''','''','''')) val where val in('''''' + REPLACE( :' + @rec_fname + ', '','', '''''','''''') + ''''''))'' cnd ' +
                     'from (select ''' + @rec_fname + ''' gname, value as gval from STRING_SPLIT(:' + @rec_fname + ', '','')) a ' +
                     'group by gname having sum(case when gval=''All'' then 1 else 0 end) = 0';

        INSERT INTO @v_sqlary (sql_cmd) VALUES (@v_sql);

        FETCH NEXT FROM field_cursor INTO @rec_fname;
    END;

    CLOSE field_cursor;
    DEALLOCATE field_cursor;

    -- Aggregate the results
    IF EXISTS (SELECT 1 FROM @v_sqlary)
    BEGIN
        SELECT @result = 'select STRING_AGG(cnd, '' and '') from ( ' + 
                         STRING_AGG(sql_cmd, ' UNION ALL ') + 
                         ' ) b'
        FROM @v_sqlary;
    END
    ELSE
    BEGIN
        SET @result = 'select null';
    END

    RETURN @result;
END;
>>
<<
CREATE or alter     PROCEDURE fn_permissions_create_grpcol
(
    @ptransid VARCHAR(50),
    @ptable   SYSNAME
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @schema SYSNAME = OBJECT_SCHEMA_NAME(@@PROCID);
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @grpname SYSNAME;

        DECLARE grp_cursor CURSOR FOR
            SELECT grpname FROM axgroupingmst;

        OPEN grp_cursor;
        FETCH NEXT FROM grp_cursor INTO @grpname;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @sql =
                N'ALTER TABLE '
                + QUOTENAME(@schema) + N'.' + QUOTENAME(@ptable)
                + N' ADD ' + QUOTENAME('axg_' + @grpname)
                + N' VARCHAR(4000);';

            EXEC sys.sp_executesql @sql;

            FETCH NEXT FROM grp_cursor INTO @grpname;
        END;

        CLOSE grp_cursor;
        DEALLOCATE grp_cursor;

END;
>>
<<
CREATE or alter FUNCTION fn_permissions_getadscnd(
    @ptransid VARCHAR(MAX),
    @padsname VARCHAR(MAX),
    @pusername VARCHAR(MAX),
    @proles VARCHAR(MAX) = 'All',
    @pkeyfield VARCHAR(MAX) = NULL,
    @pkeyvalue VARCHAR(MAX) = NULL
)
RETURNS @ResultTable TABLE (
    fullcontrol VARCHAR(1),
    userrole VARCHAR(255), 
    view_access VARCHAR(10),
    view_includeflds VARCHAR(MAX),
    view_excludeflds VARCHAR(MAX),
    maskedflds VARCHAR(MAX),
    filtercnd NVARCHAR(MAX)
)
AS
BEGIN
    DECLARE @rolesql NVARCHAR(MAX);
    DECLARE @v_permissionsql NVARCHAR(MAX);
    DECLARE @v_permissionexists INT;

        INSERT INTO @ResultTable (fullcontrol, userrole, view_access, view_includeflds, view_excludeflds, maskedflds, filtercnd)
        VALUES ('T', NULL, NULL, NULL, NULL, NULL, NULL);
   
    RETURN;
END;
>>
<<
CREATE or alter FUNCTION fn_permissions_getadssql
(
    @ptransid   VARCHAR(255),
    @padsname   VARCHAR(255),
    @pcond      NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE
        @v_adssql        NVARCHAR(MAX),
        @v_filtersql     NVARCHAR(MAX),
        @v_primarydctable VARCHAR(255),
        @v_filtercnd     NVARCHAR(MAX);

    SELECT @v_adssql = sqltext
    FROM axdirectsql
    WHERE sqlname = @padsname;

    IF @pcond <> 'NA'
    BEGIN
        SELECT @v_primarydctable = tablename
        FROM axpdc
        WHERE tstruct = @ptransid
          AND dname = 'dc1';

        SET @v_filtercnd =
            ' AND (' +
            REPLACE(@pcond, '{primarytable.}', @v_primarydctable + '.') +
            ')';

        SET @v_filtersql =
            REPLACE(@v_adssql, '--permission_filter', @v_filtercnd);
    END

    RETURN
        CASE
            WHEN @pcond = 'NA' THEN @v_adssql
            ELSE @v_filtersql
        END;
END;
>>
<<
CREATE or alter PROCEDURE fn_permissions_getcnd
    @pmode         VARCHAR(MAX),
    @ptransid      VARCHAR(MAX),
    @pkeyfield       VARCHAR(MAX),
    @pkeyvalue     VARCHAR(MAX),
    @pusername     VARCHAR(MAX),
    @proles        VARCHAR(MAX) = 'All'
AS
BEGIN
    SET NOCOUNT ON;

    
    DECLARE @v_keyfld_normalized   VARCHAR(1);
    DECLARE @v_keyfld_srctbl       VARCHAR(100);
    DECLARE @v_keyfld_srcfld       VARCHAR(100);
    DECLARE @v_keyfld_mandatory    VARCHAR(1);

    DECLARE @v_transid_primetable    VARCHAR(100);
    DECLARE @v_transid_primetableid  VARCHAR(100);
    DECLARE @v_keyfld_joins        VARCHAR(500);
    DECLARE @v_keyfld_cnd          VARCHAR(500);

    DECLARE @sql_permission_cnd    NVARCHAR(MAX); 
    DECLARE @sql_permission_cnd_result BIGINT;    
    DECLARE @v_dcfldslist          NVARCHAR(MAX);
    DECLARE @v_recordid            BIGINT;
    DECLARE @v_permissionsql       NVARCHAR(MAX);
    DECLARE @v_permissionexists    BIGINT;
    DECLARE @v_menuaccess          BIGINT;
    DECLARE @v_fullcontrolsql      NVARCHAR(MAX);
    DECLARE @v_fullcontrolrecid    BIGINT;

    -- Variables to hold data for the result set    
    DECLARE @fullcontrol_out         VARCHAR(1);
    DECLARE @userrole_out            VARCHAR(250);
    DECLARE @allowcreate_out         VARCHAR(1);
    DECLARE @view_access_out         VARCHAR(250);
    DECLARE @view_includedc_out      VARCHAR(MAX);
    DECLARE @view_excludedc_out      VARCHAR(MAX);
    DECLARE @view_includeflds_out    VARCHAR(MAX);
    DECLARE @view_excludeflds_out    VARCHAR(MAX);
    DECLARE @edit_access_out         VARCHAR(250);
    DECLARE @edit_includedc_out      VARCHAR(MAX);
    DECLARE @edit_excludedc_out      VARCHAR(MAX);
    DECLARE @edit_includeflds_out    VARCHAR(MAX);
    DECLARE @edit_excludeflds_out    VARCHAR(MAX);
    DECLARE @maskedflds_out          VARCHAR(MAX);
    DECLARE @filtercnd_out           NVARCHAR(MAX);
   	DECLARE @recordid_out            numeric;
 	DECLARE @v_encryptedflds		 NVARCHAR(MAX);
 
    -- Temp table to store results if multiple rows are processed
    CREATE TABLE #fn_permissions_getcnd_results (
        fullcontrol     VARCHAR(1),
        userrole        VARCHAR(250),
        allowcreate     VARCHAR(1),
        view_access     VARCHAR(250),
        view_includedc  VARCHAR(MAX),
        view_excludedc  VARCHAR(MAX),
        view_includeflds VARCHAR(MAX),
        view_excludeflds VARCHAR(MAX),
        edit_access     VARCHAR(250),
        edit_includedc  VARCHAR(MAX),
        edit_excludedc  VARCHAR(MAX),
        edit_includeflds VARCHAR(MAX),
        edit_excludeflds VARCHAR(MAX),
        maskedflds      VARCHAR(MAX),
        filtercnd       NVARCHAR(MAX),
        recordid        BIGINT,
        encryptedflds NVARCHAR(MAX));

    -- 1. Get key field details from axpflds
    SELECT
        @v_keyfld_normalized = srckey,
        @v_keyfld_srctbl = srctf,
        @v_keyfld_srcfld = srcfld,
        @v_keyfld_mandatory = allowempty
    FROM axpflds
    WHERE tstruct = @ptransid AND fname = @pkeyfield;

    -- 2. Get primary table name from axpdc
    SELECT @v_transid_primetable = tablename
    FROM axpdc
    WHERE tstruct = @ptransid AND dname = 'dc1';

    -- 3. Determine the primary table ID field
    SET @v_transid_primetableid = CASE WHEN LOWER(@pkeyfield) = 'recordid' THEN @v_transid_primetable + 'id' ELSE @pkeyfield END;

    -- 4. Construct the key field condition (@v_keyfld_cnd)
    SET @v_keyfld_cnd = CASE WHEN @v_keyfld_normalized = 'T'
                             THEN QUOTENAME(@v_keyfld_srctbl) + '.' + QUOTENAME(@v_keyfld_srcfld) -- Use QUOTENAME for safety
                             ELSE QUOTENAME(@v_transid_primetable) + '.' + QUOTENAME(@v_transid_primetableid)
                        END + '=' + @pkeyvalue + ' AND ';

    -- 5. Construct the key field joins (@v_keyfld_joins)
    SET @v_keyfld_joins = NULL; -- Initialize
    IF @v_keyfld_normalized = 'T'
    BEGIN
        SET @v_keyfld_joins = CASE WHEN @v_keyfld_mandatory = 'T' THEN ' JOIN ' ELSE ' LEFT JOIN ' END
                              + QUOTENAME(@v_keyfld_srctbl) + ' ' + QUOTENAME(@pkeyfield) + ' ON ' -- Alias it
                              + QUOTENAME(@v_transid_primetable) + '.' + QUOTENAME(@pkeyfield) + '=' + QUOTENAME(@v_keyfld_srctbl) + '.' + QUOTENAME(@v_keyfld_srctbl) + 'id';
    END;

    -- 6. Calculate @v_menuaccess (equivalent to PostgreSQL's sum(cnt) from subquery)
    SELECT @v_menuaccess = COUNT(*)
    FROM (
        SELECT 1 AS cnt FROM axusergroups a
        JOIN axusergroupsdetail b ON a.axusergroupsid = b.axusergroupsid
        JOIN axuseraccess a2 ON b.roles_id = a2.rname AND a2.stype = 't'
        WHERE a2.sname = @ptransid
          AND EXISTS (SELECT 1 FROM STRING_SPLIT(@proles, ',') AS val WHERE val.value = a.groupname) -- unnest(string_to_array) -> STRING_SPLIT
        UNION ALL
        SELECT 1 WHERE @proles LIKE '%default%' -- DUAL table not needed in SQL Server
        UNION ALL
        SELECT 1 FROM axuserlevelgroups WHERE username = @pusername AND usergroup = 'default'
        UNION ALL
        SELECT 1 AS cnt FROM axusergroups a
        JOIN axusergroupsdetail b ON a.axusergroupsid = b.axusergroupsid
        JOIN axuseraccess a2 ON b.roles_id = a2.rname AND a2.stype = 't'
        JOIN axuserlevelgroups u ON a.groupname = u.usergroup AND u.username = @pusername
        WHERE a2.sname = @ptransid AND @proles = 'All'
    ) AS MenuAccessSubquery; 

    -- Dynamic SQL for rolesql and v_permissionsql
    DECLARE @rolesql NVARCHAR(MAX);

        SET @v_fullcontrolsql = CONCAT('SELECT @fullcontrolrecid_output=', @v_transid_primetable, 'id FROM ', @v_transid_primetable, ' ', @v_keyfld_joins, ' WHERE ', REPLACE(@v_keyfld_cnd, ' AND ', ''));

        -- Execute dynamic SQL to get a single value into a variable
        EXEC sp_executesql @v_fullcontrolsql,
                           N'@fullcontrolrecid_output BIGINT OUTPUT',
                           @fullcontrolrecid_output = @v_fullcontrolrecid OUTPUT;
                          

        SET @fullcontrol_out = 'T';
        SET @recordid_out = @v_fullcontrolrecid; 
        SET @userrole_out = NULL;
        SET @allowcreate_out = NULL;
        SET @view_access_out = NULL;
        SET @view_includedc_out = NULL;
        SET @view_excludedc_out = NULL;
        SET @view_includeflds_out = NULL;
        SET @view_excludeflds_out = NULL;
        SET @edit_access_out = NULL;
        SET @edit_includedc_out = NULL;
        SET @edit_excludedc_out = NULL;
        SET @edit_includeflds_out = NULL;
        SET @edit_excludeflds_out = NULL;
        SET @maskedflds_out = NULL;
        SET @filtercnd_out = NULL;
		SELECT @v_encryptedflds = STRING_AGG(fname, ',') WITHIN GROUP (ORDER BY ordno) FROM axpflds WHERE tstruct = @ptransid 
		AND encrypted = 'T';
       
       
        INSERT INTO #fn_permissions_getcnd_results (
            fullcontrol, userrole, allowcreate, view_access,
            view_includedc, view_excludedc, view_includeflds, view_excludeflds,
            edit_access, edit_includedc, edit_excludedc, edit_includeflds, edit_excludeflds,
            maskedflds, filtercnd, recordid,encryptedflds)
        VALUES (
            @fullcontrol_out, @userrole_out, @allowcreate_out, @view_access_out,
            @view_includedc_out, @view_excludedc_out, @view_includeflds_out, @view_excludeflds_out,
            @edit_access_out, @edit_includedc_out, @edit_excludedc_out, @edit_includeflds_out, @edit_excludeflds_out,
            @maskedflds_out, @filtercnd_out, @recordid_out,@v_encryptedflds);
    
    SELECT * FROM #fn_permissions_getcnd_results;

    DROP TABLE #fn_permissions_getcnd_results; 

END;
>>
<<
CREATE or alter  PROCEDURE fn_permissions_getdcrecid
(
    @ptransid   VARCHAR(255),
    @precordid  NUMERIC(18,0),
    @pdcstring  VARCHAR(MAX)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @v_pair             VARCHAR(MAX),
        @v_dcname           VARCHAR(255),
        @v_rowstring        VARCHAR(MAX),
        @v_dctable          VARCHAR(255),
        @v_primarydctable   VARCHAR(255),
        @v_sql              NVARCHAR(MAX);


    CREATE TABLE #result
    (
        dcname   VARCHAR(255),
        rowno    NUMERIC(18,0),
        recordid NUMERIC(18,0)
    );

    /* primary dc table */
    SELECT @v_primarydctable = tablename
    FROM axpdc
    WHERE tstruct = @ptransid
      AND dname = 'dc1';

    DECLARE dc_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT value
        FROM STRING_SPLIT(@pdcstring, '|');

    OPEN dc_cursor;
    FETCH NEXT FROM dc_cursor INTO @v_pair;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @v_dcname    = dbo.split_part(@v_pair,'~',1);
        SET @v_rowstring = dbo.split_part(@v_pair,'~',2);

        SELECT @v_dctable = tablename
        FROM axpdc
        WHERE tstruct = @ptransid
          AND dname = @v_dcname;

        IF @v_rowstring = '0'
        BEGIN
            SET @v_sql = N'
                INSERT INTO #result (dcname, rowno, recordid)
                SELECT
                    ''' + @v_dcname + ''',
                    0,
                    ' + QUOTENAME(@v_dctable + 'id') + '
                FROM ' + QUOTENAME(@v_dctable) + '
                WHERE ' + QUOTENAME(@v_primarydctable + 'id') + ' = @rid';
        END
        ELSE
        BEGIN
            SET @v_sql = N'
                INSERT INTO #result (dcname, rowno, recordid)
                SELECT
                    ''' + @v_dcname + ''',
                    ' + QUOTENAME(@v_dctable + 'row') + ',
                    ' + QUOTENAME(@v_dctable + 'id') + '
                FROM ' + QUOTENAME(@v_dctable) + '
                WHERE ' + QUOTENAME(@v_primarydctable + 'id') + ' = @rid
                  AND ' + QUOTENAME(@v_dctable + 'row') + ' IN
                      (SELECT TRY_CAST(value AS INT)
                       FROM STRING_SPLIT(@rows,'',''))';
        END

        EXEC sp_executesql
            @v_sql,
            N'@rid NUMERIC(18,0), @rows VARCHAR(MAX)',
            @rid  = @precordid,
            @rows = @v_rowstring;

        FETCH NEXT FROM dc_cursor INTO @v_pair;
    END

    CLOSE dc_cursor;
    DEALLOCATE dc_cursor;

    SELECT * FROM #result;

    DROP TABLE #result;
END;
>>
<<
CREATE or alter PROCEDURE fn_permissions_getpermission
    @pmode         VARCHAR(MAX),
    @ptransid      VARCHAR(MAX), -- Now handles comma-separated values
    @pusername     VARCHAR(MAX),
    @proles        VARCHAR(MAX) = 'All'
AS
BEGIN
    SET NOCOUNT ON;

    
    DECLARE @current_transid VARCHAR(MAX);

    -- Declare variables for internal logic
    DECLARE @v_permissionsql       NVARCHAR(MAX);
    DECLARE @v_permissionexists    BIGINT;
    DECLARE @v_menuaccess          BIGINT;
    DECLARE @rolesql               NVARCHAR(MAX);

    -- Variables to hold data for the result set
    DECLARE @transid_out         VARCHAR(MAX);
    DECLARE @fullcontrol_out     VARCHAR(1);
    DECLARE @userrole_out        VARCHAR(250);
    DECLARE @allowcreate_out     VARCHAR(1);
    DECLARE @view_access_out     VARCHAR(250);
    DECLARE @view_includedc_out  VARCHAR(MAX);
    DECLARE @view_excludedc_out  VARCHAR(MAX);
    DECLARE @view_includeflds_out VARCHAR(MAX);
    DECLARE @view_excludeflds_out VARCHAR(MAX);
    DECLARE @edit_access_out     VARCHAR(250);
    DECLARE @edit_includedc_out  VARCHAR(MAX);
    DECLARE @edit_excludedc_out  VARCHAR(MAX);
    DECLARE @edit_includeflds_out VARCHAR(MAX);
    DECLARE @edit_excludeflds_out VARCHAR(MAX);
    DECLARE @maskedflds_out      VARCHAR(MAX);
    DECLARE @filtercnd_out       NVARCHAR(MAX);
   	DECLARE @v_encryptedflds		 NVARCHAR(MAX);

    -- Temporary table to accumulate all results, similar to PostgreSQL's RETURNS TABLE + RETURN NEXT
    CREATE TABLE #PermissionsResults (
        transid         VARCHAR(MAX),
        fullcontrol     VARCHAR(1),
        userrole        VARCHAR(250),
        allowcreate     VARCHAR(1),
        view_access     VARCHAR(250),
        view_includedc  VARCHAR(MAX),
        view_excludedc  VARCHAR(MAX),
        view_includeflds VARCHAR(MAX),
        view_excludeflds VARCHAR(MAX),
        edit_access     VARCHAR(250),
        edit_includedc  VARCHAR(MAX),
        edit_excludedc  VARCHAR(MAX),
        edit_includeflds VARCHAR(MAX),
        edit_excludeflds VARCHAR(MAX),
        maskedflds      VARCHAR(MAX),
        filtercnd       NVARCHAR(MAX),
        encryptedflds NVARCHAR(MAX));

    
    DECLARE transid_cursor CURSOR LOCAL FOR
    SELECT value FROM STRING_SPLIT(@ptransid, ',');

    OPEN transid_cursor;
    FETCH NEXT FROM transid_cursor INTO @current_transid;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Reset variables for each transid iteration
        SET @v_permissionexists = 0;
        SET @v_menuaccess = 0;
        SET @rolesql = NULL;
        SET @v_permissionsql = NULL;

        -- Calculate v_menuaccess for the current transid
        SELECT @v_menuaccess = COUNT(*)
        FROM (
            SELECT 1 AS cnt FROM axusergroups a
            JOIN axusergroupsdetail b ON a.axusergroupsid = b.axusergroupsid
            JOIN axuseraccess a2 ON b.roles_id = a2.rname AND a2.stype = 't'
            WHERE a2.sname = @current_transid
              AND EXISTS (SELECT 1 FROM STRING_SPLIT(@proles, ',') AS val WHERE val.value = a.groupname)
            UNION ALL
            SELECT 1 WHERE @proles LIKE '%default%' 
            UNION ALL
            SELECT 1 FROM axuserlevelgroups WHERE username = @pusername AND usergroup = 'default'
            UNION ALL            
            SELECT 1 AS cnt FROM axusergroups a
            JOIN axusergroupsdetail b ON a.axusergroupsid = b.axusergroupsid
            JOIN axuseraccess a2 ON b.roles_id = a2.rname AND a2.stype = 't'
            JOIN axuserlevelgroups u ON a.groupname = u.usergroup AND u.username = @pusername
            WHERE a2.sname = @current_transid AND @proles = 'All' 
        ) AS MenuAccessSubquery;

      
            SET @transid_out = @current_transid;
            SET @fullcontrol_out = 'T';
            SET @userrole_out = NULL;
            SET @allowcreate_out = NULL;
            SET @view_access_out = NULL;
            SET @view_includedc_out = NULL;
            SET @view_excludedc_out = NULL;
            SET @view_includeflds_out = NULL;
            SET @view_excludeflds_out = NULL;
            SET @edit_access_out = NULL;
            SET @edit_includedc_out = NULL;
            SET @edit_excludedc_out = NULL;
            SET @edit_includeflds_out = NULL;
            SET @edit_excludeflds_out = NULL;
            SET @maskedflds_out = NULL;
            SET @filtercnd_out = NULL;
           	SELECT @v_encryptedflds = STRING_AGG(fname, ',') WITHIN GROUP (ORDER BY ordno) FROM axpflds WHERE tstruct = @current_transid 
		AND encrypted = 'T';

            -- Insert the row into the temporary results table
            INSERT INTO #PermissionsResults (
                transid, fullcontrol, userrole, allowcreate, view_access,
                view_includedc, view_excludedc, view_includeflds, view_excludeflds,
                edit_access, edit_includedc, edit_excludedc, edit_includeflds, edit_excludeflds,
    maskedflds, filtercnd,encryptedflds  )
            VALUES (
                @transid_out, @fullcontrol_out, @userrole_out, @allowcreate_out, @view_access_out,
                @view_includedc_out, @view_excludedc_out, @view_includeflds_out, @view_excludeflds_out,
                @edit_access_out, @edit_includedc_out, @edit_excludedc_out, @edit_includeflds_out, @edit_excludeflds_out,
                @maskedflds_out, @filtercnd_out,@v_encryptedflds);
         
        FETCH NEXT FROM transid_cursor INTO @current_transid;
    END;

    CLOSE transid_cursor;
    DEALLOCATE transid_cursor;

  
    SELECT * FROM #PermissionsResults;

    DROP TABLE #PermissionsResults; 

END;
>>
<<
CREATE or alter  PROCEDURE fn_permissions_getsqls (
    @pmode VARCHAR(MAX),
    @ptransid VARCHAR(MAX),
    @pkeyfld VARCHAR(MAX),
    @pkeyvalue VARCHAR(MAX),
    @pcond NVARCHAR(MAX),
    @pincdc VARCHAR(MAX),
    @pexcdc VARCHAR(MAX),
    @pincflds NVARCHAR(MAX),
    @pexcflds NVARCHAR(MAX)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Variable Declarations
    DECLARE @v_primarydctable NVARCHAR(255);
    DECLARE @v_transid_primetable NVARCHAR(255);
    DECLARE @v_transid_primetableid NVARCHAR(255);
    DECLARE @v_keyfld_normalized CHAR(1);
    DECLARE @v_keyfld_srctbl NVARCHAR(255);
    DECLARE @v_keyfld_srcfld NVARCHAR(255);
    DECLARE @v_keyfld_mandatory CHAR(1);
    DECLARE @v_keyfld_joins NVARCHAR(MAX) = '';
    DECLARE @v_keyfld_cnd NVARCHAR(MAX);
    DECLARE @v_alldcs NVARCHAR(MAX);
    DECLARE @v_allflds NVARCHAR(MAX);
    DECLARE @v_sql NVARCHAR(MAX);

    -- Result Table Variable
    DECLARE @Results TABLE (dcno VARCHAR(100), dcsql NVARCHAR(MAX));

    -- Initial Lookups
    SELECT TOP 1 @v_primarydctable = tablename, @v_transid_primetable = tablename 
    FROM axpdc WHERE tstruct = @ptransid AND dname = 'dc1';

    SELECT TOP 1 
        @v_keyfld_normalized = srckey,
        @v_keyfld_srctbl = srctf,
        @v_keyfld_srcfld = srcfld,
        @v_keyfld_mandatory = allowempty
    FROM axpflds WHERE tstruct = @ptransid AND fname = @pkeyfld;

    SET @v_transid_primetableid = CASE WHEN LOWER(@pkeyfld) = 'recordid' 
                                       THEN @v_transid_primetable + 'id' 
                                       ELSE @pkeyfld END;

    SET @v_keyfld_cnd = CASE WHEN @v_keyfld_normalized = 'T' 
                             THEN @v_keyfld_srctbl + '.' + @v_keyfld_srcfld 
                             ELSE @v_transid_primetable + '.' + @v_transid_primetableid END + '=' + @pkeyvalue;

    IF @v_keyfld_normalized = 'T'
    BEGIN
        SET @v_keyfld_joins = CASE WHEN @v_keyfld_mandatory = 'T' THEN ' JOIN ' ELSE ' LEFT JOIN ' END
                             + @v_keyfld_srctbl + ' ' + @pkeyfld + ' ON ' + @v_transid_primetable + '.' + @pkeyfld 
                             + '=' + @v_keyfld_srctbl + '.' + @v_keyfld_srctbl + 'id';
    END

    -- Determine DCNames to process
    IF @pincdc IS NULL
    BEGIN
        SELECT @v_alldcs = STRING_AGG(dname, ',')
        FROM axpdc 
        WHERE tstruct = @ptransid 
        AND dname NOT IN (SELECT value FROM STRING_SPLIT(ISNULL(@pexcdc, ''), ','));
    END
    ELSE
    BEGIN

        SELECT @v_alldcs = STRING_AGG(val, ',')
        FROM (SELECT value AS val FROM STRING_SPLIT('dc1,dc2,dc3', ',')) a
        WHERE val NOT IN (SELECT value FROM STRING_SPLIT(ISNULL(@pexcdc, ''), ','));
    END

    -- Main Loop through DCs
    DECLARE dc_cursor CURSOR FOR SELECT value FROM STRING_SPLIT(@v_alldcs, ',');
    DECLARE @curr_dcname VARCHAR(100);

    OPEN dc_cursor;
    FETCH NEXT FROM dc_cursor INTO @curr_dcname;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @v_onlydcselect INT;
        SELECT @v_onlydcselect = COUNT(1) FROM axpflds 
        WHERE tstruct = @ptransid AND dcname = @curr_dcname AND savevalue = 'T'
        AND fname IN (SELECT value FROM STRING_SPLIT(@pincflds, ','));

        -- Field Aggregation logic
        SELECT @v_allflds = (
            SELECT TOP 1 tablename + '=' + STRING_AGG(fname + '~' + srckey + '~' + srctf + '~' + srcfld + '~' + allowempty, '|')
            FROM axpflds
            WHERE tstruct = @ptransid AND dcname = @curr_dcname AND savevalue = 'T'
            AND (@v_onlydcselect = 0 OR fname IN (SELECT value FROM STRING_SPLIT(@pincflds, ',')))
            AND fname NOT IN (SELECT value FROM STRING_SPLIT(ISNULL(@pexcflds, ''), ','))
            GROUP BY tablename
        );


        DECLARE @v_fldnames TABLE (val NVARCHAR(MAX));
        DECLARE @v_joins TABLE (val NVARCHAR(MAX));
        DELETE FROM @v_fldnames; DELETE FROM @v_joins;


        DECLARE @v_fldname_dctablename NVARCHAR(255) = LEFT(@v_allflds, CHARINDEX('=', @v_allflds) - 1);
        DECLARE @v_fldname_dcflds NVARCHAR(MAX) = SUBSTRING(@v_allflds, CHARINDEX('=', @v_allflds) + 1, LEN(@v_allflds));

        IF @v_fldname_dctablename <> @v_primarydctable
        BEGIN
            INSERT INTO @v_joins VALUES (' LEFT JOIN ' + @v_fldname_dctablename + ' ON ' + @v_primarydctable + '.' + @v_primarydctable + 'id=' + @v_fldname_dctablename + '.' + @v_primarydctable + 'id');
        END

        -- Internal Loop for individual fields
        INSERT INTO @v_fldnames
        SELECT 
            CASE 
                WHEN PARSENAME(REPLACE(value, '~', '.'), 4) = 'F' -- normalized bit
                THEN @v_fldname_dctablename + '.' + PARSENAME(REPLACE(value, '~', '.'), 5)
                ELSE PARSENAME(REPLACE(value, '~', '.'), 5) + '.' + PARSENAME(REPLACE(value, '~', '.'), 2) + ' ' + PARSENAME(REPLACE(value, '~', '.'), 5)
            END
        FROM STRING_SPLIT(@v_fldname_dcflds, '|');

        -- Build Joins for normalized fields
        INSERT INTO @v_joins
        SELECT 
            CASE WHEN PARSENAME(REPLACE(value, '~', '.'), 1) = 'F' THEN ' JOIN ' ELSE ' LEFT JOIN ' END -- allowempty
            + PARSENAME(REPLACE(value, '~', '.'), 3) + ' ' + PARSENAME(REPLACE(value, '~', '.'), 5)
            + ' ON ' + @v_fldname_dctablename + '.' + PARSENAME(REPLACE(value, '~', '.'), 5) + ' = ' + PARSENAME(REPLACE(value, '~', '.'), 5) + '.' + PARSENAME(REPLACE(value, '~', '.'), 3) + 'id'
        FROM STRING_SPLIT(@v_fldname_dcflds, '|')
        WHERE PARSENAME(REPLACE(value, '~', '.'), 4) = 'T';

        -- Construct Final SQL for this DC
        DECLARE @final_flds NVARCHAR(MAX), @final_joins NVARCHAR(MAX);
        SELECT @final_flds = STRING_AGG(val, ', ') FROM @v_fldnames;
        SELECT @final_joins = STRING_AGG(val, ' ') FROM @v_joins;

        SET @v_sql = 'SELECT ' + @v_primarydctable + '.' + @v_primarydctable + 'id AS recordid, ' 
                     + @final_flds + ' FROM ' + @v_primarydctable + ' ' 
                     + ISNULL(@final_joins, '') + ' WHERE ' + @v_keyfld_cnd;

        INSERT INTO @Results VALUES (@curr_dcname, @v_sql);

        FETCH NEXT FROM dc_cursor INTO @curr_dcname;
    END

    CLOSE dc_cursor;
    DEALLOCATE dc_cursor;

    SELECT * FROM @Results;
END;
>>
<<
CREATE or alter  PROCEDURE fn_permissions_grpmaster
(
    @pgrpname VARCHAR(255),
    @result   CHAR(1) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @tablename SYSNAME,
        @sql NVARCHAR(MAX);

    BEGIN TRY
        DECLARE grp_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT d.tablename
            FROM axgrouptstructs a
            JOIN axpdc d
              ON a.ftransid = d.tstruct
             AND d.dcno = 1;

        OPEN grp_cursor;
        FETCH NEXT FROM grp_cursor INTO @tablename;

        WHILE @@FETCH_STATUS = 0
        BEGIN
   
            IF NOT EXISTS (
                SELECT 1
                FROM sys.columns
                WHERE name = 'axg_' + @pgrpname
                  AND object_id = OBJECT_ID(@tablename)
            )
            BEGIN
                SET @sql =
                    N'ALTER TABLE ' + QUOTENAME(@tablename) +
                    N' ADD ' + QUOTENAME('axg_' + @pgrpname) +
                    N' VARCHAR(4000);';

                EXEC sp_executesql @sql;
            END

            FETCH NEXT FROM grp_cursor INTO @tablename;
        END

        CLOSE grp_cursor;
        DEALLOCATE grp_cursor;

        SET @result = 'T';
    END TRY
    BEGIN CATCH
        SET @result = 'F';
    END CATCH
END;
>>
<<
create or alter FUNCTION fn_queue_text_split(@ptext nvarchar(max))
RETURNS nvarchar(max)
AS
BEGIN
declare
    @v_fldnames nvarchar(max);

SELECT @v_fldnames = STRING_AGG(fname, ',') 
FROM (
    SELECT 
        SUBSTRING(
            value, 
            CHARINDEX('-(', value) + 2, 
            LEN(value) - (CHARINDEX('-(', value) + 2)
        ) AS fname
    FROM STRING_SPLIT(@ptext, ',')
    WHERE @ptext IS NOT NULL
) a;

return @v_fldnames; 
end;
>>
<<
CREATE or alter FUNCTION fn_ruledef_formula (
    @formula NVARCHAR(MAX),
    @applicability VARCHAR(50),
    @nexttask VARCHAR(50),
    @nexttask_true VARCHAR(50),
    @nexttask_false VARCHAR(50),
    @pegversion VARCHAR(50) = 'v1'
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @v_formula NVARCHAR(MAX);
    
    -- Create a temporary table to store split values
    DECLARE @TempTable TABLE (cols NVARCHAR(MAX));
    
    INSERT INTO @TempTable (cols)
    SELECT value FROM STRING_SPLIT(@formula, '~');

    IF @pegversion = 'v1'
    BEGIN
        -- Build the formula logic dynamically
        SELECT @v_formula = STRING_AGG(
            CASE 
                WHEN CHARINDEX('|In|', cols) = 0 AND CHARINDEX('|Not in|', cols) = 0 
                THEN 
                    CASE 
                        WHEN CHARINDEX('-(', cols) > 0 
                        THEN SUBSTRING(cols, CHARINDEX('-(', cols) + 2, LEN(cols) - CHARINDEX('-(', cols) - 2) 
                        ELSE cols 
                    END
                ELSE ''
            END + ' ' +
            CASE 
                WHEN CHARINDEX('|Equal to|', cols) > 0 THEN '='
                WHEN CHARINDEX('|Not equal to|', cols) > 0 THEN '#'
                WHEN CHARINDEX('|Greater than|', cols) > 0 THEN '>'
                WHEN CHARINDEX('|Lesser than|', cols) > 0 THEN '<'
                WHEN CHARINDEX('|In|', cols) > 0 THEN 'StringPOS(' + 
                    CASE 
                        WHEN CHARINDEX('-(', cols) > 0 
                        THEN SUBSTRING(cols, CHARINDEX('-(', cols) + 2, LEN(cols) - CHARINDEX('-(', cols) - 2) 
                        ELSE cols 
                    END + ','
                WHEN CHARINDEX('|Not in|', cols) > 0 THEN 'StringPOS(' + 
                    CASE 
                        WHEN CHARINDEX('-(', cols) > 0 
                        THEN SUBSTRING(cols, CHARINDEX('-(', cols) + 2, LEN(cols) - CHARINDEX('-(', cols) - 2) 
                        ELSE cols 
                    END + ','
                ELSE ''
            END + ' ' +
            CASE 
                WHEN CHARINDEX('|And|', cols) > 0 THEN '&'
                WHEN CHARINDEX('|Or|', cols) > 0 THEN '|'
                WHEN CHARINDEX('|And(|', cols) > 0 THEN '&('
                WHEN CHARINDEX('|Or(|', cols) > 0 THEN '|('
                ELSE ''
            END, ' ') 
        FROM @TempTable;

        IF @applicability = 'T' 
            SET @v_formula = 'IIF(' + @v_formula + ',{T},{F})';
        ELSE IF @nexttask = 'T' 
            SET @v_formula = 'IIF(' + @v_formula + ',{' + @nexttask_true + '},' + '{' + @nexttask_false + '})';
    END
    ELSE IF @pegversion = 'v2'
    BEGIN
        -- PEG condition logic
        SELECT @v_formula = 'IIF(' + STRING_AGG(
            CASE 
                WHEN CHARINDEX('|Equal to|', cols) > 0 THEN '='
                WHEN CHARINDEX('|Not equal to|', cols) > 0 THEN '#'
                WHEN CHARINDEX('|Greater than|', cols) > 0 THEN '>'
                WHEN CHARINDEX('|Lesser than|', cols) > 0 THEN '<'
                WHEN CHARINDEX('|In|', cols) > 0 THEN 'StringPOS(' + 
                    CASE 
                        WHEN CHARINDEX('-(', cols) > 0 
                        THEN SUBSTRING(cols, CHARINDEX('-(', cols) + 2, LEN(cols) - CHARINDEX('-(', cols) - 2) 
                        ELSE cols 
                    END + ','
                WHEN CHARINDEX('|Not in|', cols) > 0 THEN 'StringPOS(' + 
                    CASE 
                        WHEN CHARINDEX('-(', cols) > 0 
                        THEN SUBSTRING(cols, CHARINDEX('-(', cols) + 2, LEN(cols) - CHARINDEX('-(', cols) - 2) 
                        ELSE cols 
                    END + ','
                ELSE ''
            END + ' ' +
            CASE 
                WHEN CHARINDEX('|And|', cols) > 0 THEN '&'
                WHEN CHARINDEX('|Or|', cols) > 0 THEN '|'
                WHEN CHARINDEX('|And(|', cols) > 0 THEN '&('
                WHEN CHARINDEX('|Or(|', cols) > 0 THEN '|('
                ELSE ''
            END, ' ') + ',{T},{F})'
        FROM @TempTable;
    END

    RETURN @v_formula;
END;
>>
<<
CREATE or alter PROCEDURE fn_tstruct_getdcrecid
(
    @ptransid   VARCHAR(255),
    @precordid  NUMERIC(18,0),
    @pdcstring  VARCHAR(MAX)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @v_pair             VARCHAR(MAX),
        @v_dcname           VARCHAR(255),
        @v_dctable          SYSNAME,
        @v_isgrid           CHAR(1),
        @v_primarydctable   SYSNAME,
        @sql                NVARCHAR(MAX);

    /* temp table to collect results */
    CREATE TABLE #result
    (
        dcname   VARCHAR(255),
        rowno    NUMERIC(18,0),
        recordid NUMERIC(18,0)
    );

    /* primary dc table */
    SELECT @v_primarydctable = tablename
    FROM axpdc
    WHERE tstruct = @ptransid
      AND dname = 'dc1';

    /* split dc list */
    DECLARE dc_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT value
        FROM STRING_SPLIT(@pdcstring, ',');

    OPEN dc_cursor;
    FETCH NEXT FROM dc_cursor INTO @v_dcname;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT
            @v_dctable = tablename,
            @v_isgrid  = asgrid
        FROM axpdc
        WHERE tstruct = @ptransid
          AND dname = @v_dcname;

        IF @v_isgrid = 'F'
        BEGIN
            SET @sql = N'
                INSERT INTO #result (dcname, rowno, recordid)
                SELECT
                    ''' + @v_dcname + ''',
                    0,
                    ' + QUOTENAME(@v_dctable + 'id') + '
                FROM ' + QUOTENAME(@v_dctable) + '
                WHERE ' + QUOTENAME(@v_primarydctable + 'id') + ' = @rid';
        END
        ELSE
        BEGIN
            SET @sql = N'
                INSERT INTO #result (dcname, rowno, recordid)
                SELECT
                    ''' + @v_dcname + ''',
                    ' + QUOTENAME(@v_dctable + 'row') + ',
                    ' + QUOTENAME(@v_dctable + 'id') + '
                FROM ' + QUOTENAME(@v_dctable) + '
                WHERE ' + QUOTENAME(@v_primarydctable + 'id') + ' = @rid';
        END

        EXEC sp_executesql
            @sql,
            N'@rid NUMERIC(18,0)',
            @rid = @precordid;

        FETCH NEXT FROM dc_cursor INTO @v_dcname;
    END

    CLOSE dc_cursor;
    DEALLOCATE dc_cursor;

    SELECT * FROM #result;

    DROP TABLE #result;
END;
>>
<<
CREATE or alter FUNCTION fn_utl_notify_periodic_json(@projname varchar(100),@name varchar(300),@fromuser varchar(200),@startdate date,@frequency varchar(100),@Sendday varchar(100),@sendon varchar(100),@sendtime varchar(20))
RETURNS table
AS
return
(select replace(replace(dbo.fn_dbo_notify_periodic_json(@projname,@name,@fromuser,@startdate ,@frequency ,@Sendday ,@sendon ,@sendtime ),'"{','{'),'}"','}') pjson) ;
>>
<<
CREATE or alter  FUNCTION get_sql_columns (@sql_query NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @column_names NVARCHAR(MAX);
    DECLARE @formatted_query NVARCHAR(MAX);
    DECLARE @param_names NVARCHAR(MAX);
    DECLARE @i INT;
    DECLARE @pos INT;
    DECLARE @param NVARCHAR(100);
    DECLARE @temp_table_name NVARCHAR(128) = 'Ax_GetColumn_temp_table';
    DECLARE @sql NVARCHAR(MAX);

    -- Initialize
    SET @formatted_query = @sql_query;
    SET @param_names = '';

    -- Extract parameter names from the query using CHARINDEX and SUBSTRING
    SET @pos = 1;
    WHILE @pos > 0
    BEGIN
        SET @pos = CHARINDEX(':', @sql_query, @pos);
        IF @pos > 0
        BEGIN
            SET @param = SUBSTRING(@sql_query, @pos + 1, CHARINDEX(' ', @sql_query + ' ', @pos) - @pos - 1);
            SET @param_names = @param_names + ',' + @param;
            SET @pos = @pos + LEN(@param) + 1; -- Move to the next parameter
        END
    END

    -- If parameters exist, replace them with NULL in the query
    IF LEN(@param_names) > 0
    BEGIN
        -- Remove leading comma
        SET @param_names = SUBSTRING(@param_names, 2, LEN(@param_names));
        
        -- Replace parameters with NULL
        SET @formatted_query = @sql_query;
        SET @i = 1;
        WHILE @i <= LEN(@param_names)
        BEGIN
            SET @param = SUBSTRING(@param_names, @i, CHARINDEX(',', @param_names + ',', @i) - @i);
            SET @formatted_query = REPLACE(@formatted_query, ':' + @param, 'NULL');
            SET @i = CHARINDEX(',', @param_names + ',', @i) + 1;
        END
    END

    -- Create the temporary table with the same structure as the result of the query
    SET @sql = 'SELECT * INTO #Ax_GetColumn_temp_table FROM (' + @formatted_query + ') AS subquery WHERE 1 = 0'; 
    EXEC sp_executesql @sql;

    -- Retrieve column names from the temporary table
    SET @sql = 'SELECT @column_names = STRING_AGG(COLUMN_NAME, '','') 
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_NAME = ''#Ax_GetColumn_temp_table''';
    EXEC sp_executesql @sql, N'@column_names NVARCHAR(MAX) OUTPUT', @column_names OUTPUT;

    -- Drop the temporary table
    SET @sql = 'DROP TABLE IF EXISTS #Ax_GetColumn_temp_table';
    EXEC sp_executesql @sql;

    -- Return the column names
    RETURN @column_names;
END;
>>
<<
create procedure  GetNextVal(@val as int OUTPUT) as begin UPDATE ConnectNoSeq SET cno = (case when (cno > 9999) then  1 else cno + 1 end), @val = cno; end;
>>
<<
CREATE  or alter PROCEDURE pr_executescript_new
(
    @ptablename SYSNAME
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @sqlstmt NVARCHAR(MAX),
        @execsql NVARCHAR(MAX);

    TRUNCATE TABLE axonlineconvlog;

    CREATE TABLE #scripts
    (
        psqlquery NVARCHAR(MAX)
    );

    SET @sqlstmt = N'
        INSERT INTO #scripts (psqlquery)
        SELECT
            CASE
                WHEN LEFT(LOWER(psqlquery), 1) IN (''i'',''u'',''d'')
                    THEN psqlquery
                ELSE SUBSTRING(psqlquery, 2, LEN(psqlquery))
            END
        FROM ' + QUOTENAME(@ptablename);

    EXEC sp_executesql @sqlstmt;

    DECLARE cur_exec CURSOR LOCAL FAST_FORWARD FOR
        SELECT psqlquery FROM #scripts;

    OPEN cur_exec;
    FETCH NEXT FROM cur_exec INTO @execsql;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC (@execsql);
        END TRY
        BEGIN CATCH
            INSERT INTO axonlineconvlog
            (
                script,
                tablename,
                errmsg
            )
            VALUES
            (
                @execsql,
                @ptablename,
                ERROR_MESSAGE()
            );
        END CATCH;

        FETCH NEXT FROM cur_exec INTO @execsql;
    END;

    CLOSE cur_exec;
    DEALLOCATE cur_exec;

    DROP TABLE #scripts;

    SET @sqlstmt = N'DROP TABLE ' + QUOTENAME(@ptablename);
    EXEC (@sqlstmt);
END;
>>
<<
CREATE  or alter PROCEDURE pr_executescript_thread_new
(
    @ptablename   SYSNAME,
    @pfieldname   SYSNAME,
    @pgroupfield  SYSNAME,
    @pthread      INT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @sql_createtbl  NVARCHAR(MAX),
        @sql_createidx NVARCHAR(MAX),
        @sql_update    NVARCHAR(MAX),
        @sql_drop      NVARCHAR(MAX);

    SET @sql_createtbl = N'
        SELECT
            b1.' + QUOTENAME(@pgroupfield) + N',
            (RANK() OVER (ORDER BY b1.' + QUOTENAME(@pgroupfield) + N') % ' 
                + CAST(@pthread AS NVARCHAR) + N') AS ' + QUOTENAME(@pfieldname) + N'
        INTO #' + @ptablename + N'_t
        FROM
        (
            SELECT ' + QUOTENAME(@pgroupfield) + N'
            FROM ' + QUOTENAME(@ptablename) + N'
            GROUP BY ' + QUOTENAME(@pgroupfield) + N'
        ) b1;';

    EXEC sp_executesql @sql_createtbl;

    SET @sql_createidx = N'
        CREATE INDEX i_' + @ptablename + N'
        ON #' + @ptablename + N'_t (' + QUOTENAME(@pgroupfield) + N');';

    EXEC sp_executesql @sql_createidx;

    SET @sql_update = N'
        UPDATE a
        SET ' + QUOTENAME(@pfieldname) + N' = b.' + QUOTENAME(@pfieldname) + N'
        FROM ' + QUOTENAME(@ptablename) + N' a
        JOIN #' + @ptablename + N'_t b
          ON b.' + QUOTENAME(@pgroupfield) + N' = a.' + QUOTENAME(@pgroupfield) + N';';

    EXEC sp_executesql @sql_update;

    SET @sql_drop = N'DROP TABLE #' + @ptablename + N'_t;';
    EXEC sp_executesql @sql_drop;
END;
>>
<<
CREATE or alter  PROCEDURE pr_pegv2_processlist
(
    @pprocessname VARCHAR(255)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @v_processtable SYSNAME,
        @sql NVARCHAR(MAX);

    SELECT @v_processtable = processtable
    FROM axpdef_peg_processmaster
    WHERE LOWER(caption) = LOWER(@pprocessname);

    IF @v_processtable IS NULL
        RETURN;

    SET @sql = N'
    SELECT
        taskname,
        tasktype,
        CONVERT(
            VARCHAR(19),
            CONVERT(
                DATETIME2,
                STUFF(
                    STUFF(
                        STUFF(
                            STUFF(eventdatetime, 13, 0, '':''),
                            11, 0, '':''),
                        9, 0, '' ''),
                    7, 0, ''-'')
            ),
            120
        ) AS tasktime,
        username AS taskfromuser,
        taskstatus,
        displayicon,
        displaytitle,
        taskid,
        keyfield,
        keyvalue,
        recordid,
        transid
    FROM ' + QUOTENAME(@v_processtable) + N';';

    EXEC sp_executesql @sql;
END;
>>
<<
CREATE or alter  PROCEDURE pr_pegv2_processprogress
(
    @pprocessname VARCHAR(255),
    @pkeyvalue    VARCHAR(2000)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @v_processtable SYSNAME,
        @sql NVARCHAR(MAX);

    SELECT @v_processtable = processtable
    FROM axpdef_peg_processmaster
    WHERE LOWER(caption) = LOWER(@pprocessname);

    IF @v_processtable IS NULL
        RETURN;

    SET @sql = N'
    WITH c AS
    (
        SELECT DISTINCT
            a.processname,
            a.taskname,
            a.indexno,
            a.eventdatetime,
            COALESCE(b.taskstatus, ''active'') AS taskstatus,
            a.taskid,
            a.transid,
            a.keyfield,
            a.keyvalue,
            a.recordid
        FROM ' + QUOTENAME(@v_processtable) + N' a
        JOIN
        (
            SELECT
                processname,
                taskname,
                indexno,
                transid,
                keyvalue,
                taskstatus,
                eventdatetime
            FROM axactivetaskstatus
            WHERE LOWER(processname) = LOWER(@pprocessname)
              AND LOWER(keyvalue)    = LOWER(@pkeyvalue)
        ) b
          ON a.taskname      = b.taskname
         AND a.indexno       = b.indexno
         AND a.eventdatetime = b.eventdatetime
        WHERE LOWER(a.processname) = LOWER(@pprocessname)
          AND LOWER(a.keyvalue)    = LOWER(@pkeyvalue)
    )
    SELECT
        COALESCE(c.processname, d.processname) AS processname,
        COALESCE(c.taskname,   d.taskname)     AS taskname,
        COALESCE(c.indexno,    d.indexno)      AS indexno,
        CONVERT(
            VARCHAR(19),
            CONVERT(
                DATETIME2,
                STUFF(
                    STUFF(
                        STUFF(
                            STUFF(LEFT(COALESCE(c.eventdatetime, d.eventdatetime), 14),
                                  13, 0, '':''),
                            11, 0, '':''),
                        9, 0, '' ''),
                    7, 0, ''-'')
            ),
            120
        ) AS eventdatetime,
        COALESCE(c.taskstatus, ''Active'') AS taskstatus,
        COALESCE(c.taskid, d.taskid)       AS taskid,
        COALESCE(c.transid, d.transid)     AS transid,
        COALESCE(c.keyfield, d.keyfield)   AS keyfield,
        COALESCE(c.keyvalue, d.keyvalue)   AS keyvalue,
        COALESCE(c.recordid, d.recordid)   AS recordid,
        CAST(
            ROW_NUMBER() OVER
            (
                PARTITION BY COALESCE(c.indexno, d.indexno)
                ORDER BY
                    COALESCE(c.indexno, d.indexno),
                    COALESCE(c.eventdatetime, d.eventdatetime) DESC
            ) AS NUMERIC(18,0)
        ) AS rnum
    FROM c
    RIGHT JOIN
    (
        SELECT
            j.indexno,
            j.transid,
            j.keyfield,
            j.keyvalue,
            j.eventdatetime,
            j.processname,
            j.taskname,
            j.taskid,
            j.recordid
        FROM axactivetasks j
        WHERE LOWER(processname) = LOWER(@pprocessname)
          AND LOWER(keyvalue)    = LOWER(@pkeyvalue)
          AND removeflg = ''F''
    ) d
      ON c.indexno  = d.indexno
     AND c.transid  = d.transid
     AND c.keyfield = d.keyfield
     AND c.keyvalue = d.keyvalue
     AND c.taskid   = d.taskid
    GROUP BY
        COALESCE(c.processname, d.processname),
        COALESCE(c.taskname,   d.taskname),
        COALESCE(c.indexno,    d.indexno),
        COALESCE(c.eventdatetime, d.eventdatetime),
        COALESCE(c.taskstatus, ''Active''),
        COALESCE(c.taskid, d.taskid),
        COALESCE(c.transid, d.transid),
        COALESCE(c.keyfield, d.keyfield),
        COALESCE(c.keyvalue, d.keyvalue),
        COALESCE(c.recordid, d.recordid)
    ORDER BY
        COALESCE(c.indexno, d.indexno);';

    EXEC sp_executesql
        @sql,
        N'@pprocessname VARCHAR(255), @pkeyvalue VARCHAR(2000)',
        @pprocessname = @pprocessname,
        @pkeyvalue    = @pkeyvalue;
END;
>>
<<
CREATE or alter  FUNCTION pr_pegv2_sendto_userslist
(
    @pallowsendflg  INT,
    @pactor         VARCHAR(255),
    @pprocessname   VARCHAR(255),
    @pkeyvalue      VARCHAR(255),
    @ptaskname      VARCHAR(255)
)
RETURNS @result TABLE
(
    pusername VARCHAR(255)
)
AS
BEGIN
    DECLARE
        @v_usergroup_in        VARCHAR(MAX),
        @v_usergroup_notin     VARCHAR(MAX),
        @v_usergroup_in_cnt    INT,
        @v_usergroup_notin_cnt INT;

    SELECT
        @v_usergroup_in        = senduser_in,
        @v_usergroup_notin     = senduser_notin,
        @v_usergroup_in_cnt    = ISNULL(LEN(senduser_in), 0),
        @v_usergroup_notin_cnt = ISNULL(LEN(senduser_notin), 0)
    FROM axprocessdefv2
    WHERE processname = @pprocessname
      AND taskname    = @ptaskname;

    /* -------------------------------------------------------
       2 = Any user
       Case: both IN and NOT IN empty
    -------------------------------------------------------*/
    IF @pallowsendflg = 2
       AND @v_usergroup_in_cnt = 0
       AND @v_usergroup_notin_cnt = 0
    BEGIN
        INSERT INTO @result (pusername)
        SELECT username
        FROM axusers;
    END

    /* -------------------------------------------------------
       2 = Any user, IN present, NOT IN empty
    -------------------------------------------------------*/
    IF @pallowsendflg = 2
       AND @v_usergroup_in_cnt > 0
       AND @v_usergroup_notin_cnt = 0
    BEGIN
        INSERT INTO @result (pusername)
        SELECT DISTINCT a.username
        FROM axusers a
        JOIN axpdef_peg_usergroups b
          ON a.username = b.username
        WHERE b.usergroupname IN (
            SELECT value FROM STRING_SPLIT(@v_usergroup_in, ',')
        );
    END

    /* -------------------------------------------------------
       2 = Any user, IN empty, NOT IN present
    -------------------------------------------------------*/
    IF @pallowsendflg = 2
       AND @v_usergroup_in_cnt = 0
       AND @v_usergroup_notin_cnt > 0
    BEGIN
        INSERT INTO @result (pusername)
        SELECT DISTINCT a.username
        FROM axusers a
        JOIN axpdef_peg_usergroups b
          ON a.username = b.username
        WHERE b.usergroupname NOT IN (
            SELECT value FROM STRING_SPLIT(@v_usergroup_notin, ',')
        );
    END

    /* -------------------------------------------------------
       2 = Any user, both IN and NOT IN present
    -------------------------------------------------------*/
    IF @pallowsendflg = 2
       AND @v_usergroup_in_cnt > 0
       AND @v_usergroup_notin_cnt > 0
    BEGIN
        INSERT INTO @result (pusername)
        SELECT DISTINCT a.username
        FROM axusers a
        JOIN axpdef_peg_usergroups b
          ON a.username = b.username
        WHERE b.usergroupname IN (
            SELECT value FROM STRING_SPLIT(@v_usergroup_in, ',')
        )
        AND b.usergroupname NOT IN (
            SELECT value FROM STRING_SPLIT(@v_usergroup_notin, ',')
        );
    END

    /* -------------------------------------------------------
       3 = Users in this process
    -------------------------------------------------------*/
    IF @pallowsendflg = 3
    BEGIN
        INSERT INTO @result (pusername)
        SELECT DISTINCT touser
        FROM axactivetasks
        WHERE grouped     = 'T'
          AND processname = @pprocessname
          AND keyvalue    = @pkeyvalue
          AND removeflg   = 'F';
    END

    RETURN;
END;
>>
<<
CREATE or alter PROCEDURE pr_pegv2_transactionstatus
(
    @ptransid  VARCHAR(255),
    @pkeyvalue VARCHAR(255)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @v_processes NVARCHAR(MAX),
        @v_sql       NVARCHAR(MAX),
        @log_union   NVARCHAR(MAX) = N'';

    SET @v_sql = N'
        SELECT @out =
            STRING_AGG(b.processtable, '','')
        FROM ' + QUOTENAME('axpeg_' + @ptransid) + N' a
        JOIN axpdef_peg_processmaster b
          ON a.processname = b.caption
        WHERE a.keyvalue = @keyvalue;
    ';

    EXEC sp_executesql
        @v_sql,
        N'@keyvalue VARCHAR(255), @out NVARCHAR(MAX) OUTPUT',
        @keyvalue = @pkeyvalue,
        @out      = @v_processes OUTPUT;

    IF @v_processes IS NOT NULL
    BEGIN
        SELECT
            @log_union = STRING_AGG(
                'SELECT processname, taskname, taskstatus, tasktype,
                        recordid, keyvalue, username, eventdatetime,
                        CAST(indexno AS NUMERIC(18,0)) AS indexno,
                        CAST(1 AS NUMERIC(18,0)) AS cnd
                 FROM ' + QUOTENAME(value) +
                ' WHERE keyvalue = ''' + @pkeyvalue + '''',
                ' UNION ALL '
            )
        FROM STRING_SPLIT(@v_processes, ',');
    END

    IF @log_union IS NOT NULL
    BEGIN
        SET @v_sql = N'
        SELECT processname, NULL AS taskname,
               CAST(status AS VARCHAR(2)) AS status,
               statustext, recordid, keyvalue,
               ''NA'' AS username,
               CAST(eventdatetime AS VARCHAR(100)) AS eventdatetime,
               CAST(0 AS NUMERIC(18,0)) AS indexno,
               CAST(0 AS NUMERIC(18,0)) AS cnd
        FROM ' + QUOTENAME('axpeg_' + @ptransid) + N'
        WHERE status IN (1,2)
          AND keyvalue = @keyvalue

        UNION ALL

        SELECT a.processname, a.taskname,
               CAST(b.status AS VARCHAR(20)) AS status,
               a.taskname + '' is pending '' + STRING_AGG(a.touser,'',''),
               b.recordid, b.keyvalue,
               ''NA'' AS username,
               NULL AS eventdatetime,
               CAST(0 AS NUMERIC(18,0)) AS indexno,
               CAST(0 AS NUMERIC(18,0)) AS cnd
        FROM vw_pegv2_activetasks a
        JOIN ' + QUOTENAME('axpeg_' + @ptransid) + N' b
          ON a.processname = b.processname
         AND a.keyvalue    = b.keyvalue
        WHERE b.status = 0
          AND a.keyvalue = @keyvalue
        GROUP BY a.processname, a.taskname, b.recordid, b.keyvalue, b.status
        UNION ALL
        ' + @log_union + N';';
    END
    ELSE
    BEGIN
        SET @v_sql = N'
        SELECT processname, NULL AS taskname,
               CAST(status AS VARCHAR(2)) AS status,
               statustext, recordid, keyvalue,
               ''NA'' AS username,
               CAST(eventdatetime AS VARCHAR(100)) AS eventdatetime,
               CAST(0 AS NUMERIC(18,0)) AS indexno,
               CAST(0 AS NUMERIC(18,0)) AS cnd
        FROM ' + QUOTENAME('axpeg_' + @ptransid) + N'
        WHERE status IN (1,2)
          AND keyvalue = @keyvalue

        UNION ALL

        SELECT a.processname, a.taskname,
               CAST(b.status AS VARCHAR(20)) AS status,
               a.taskname + '' is pending '' + STRING_AGG(a.touser,'',''),
               b.recordid, b.keyvalue,
               ''NA'' AS username,
               NULL AS eventdatetime,
CAST(a.indexno AS NUMERIC(18,0)) AS indexno,
               CAST(0 AS NUMERIC(18,0)) AS cnd
        FROM vw_pegv2_activetasks a
        JOIN ' + QUOTENAME('axpeg_' + @ptransid) + N' b
          ON a.processname = b.processname
         AND a.keyvalue    = b.keyvalue
        WHERE b.status = 0
          AND a.keyvalue = @keyvalue
        GROUP BY a.processname, a.taskname, b.recordid,
                 b.keyvalue, b.status, a.indexno;';
    END

    EXEC sp_executesql
        @v_sql,
        N'@keyvalue VARCHAR(255)',
        @keyvalue = @pkeyvalue;
END;
>>
<<
CREATE  or alter PROCEDURE pr_pegv2_transcurstatus
(
    @ptransid   VARCHAR(255),
    @pkeyvalue  VARCHAR(255),
    @pprocess   VARCHAR(255),
    @pstatus    VARCHAR(50) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @sql      NVARCHAR(MAX),
        @v_output INT;


    SET @sql = N'
        SELECT @out_status = status
        FROM ' + QUOTENAME('axpeg_' + @ptransid) + N'
        WHERE keyvalue    = @keyvalue
          AND processname = @processname;
    ';

    EXEC sp_executesql
        @sql,
        N'@keyvalue VARCHAR(255),
          @processname VARCHAR(255),
          @out_status INT OUTPUT',
        @keyvalue    = @pkeyvalue,
        @processname = @pprocess,
        @out_status  = @v_output OUTPUT;

    SET @pstatus =
        CASE @v_output
            WHEN 1 THEN 'Approved'
            WHEN 2 THEN 'Rejected'
            WHEN 3 THEN 'Withdrawn'
            ELSE 'In Progress'
        END;
END;
>>
<<
CREATE or alter  PROCEDURE pr_source_trigger
    @phltype NVARCHAR(100),
    @pstructname NVARCHAR(100),
    @psearchtext NVARCHAR(200),
    @psrctable NVARCHAR(255),
    @psrcfield NVARCHAR(255),
    @pparams NVARCHAR(150),
    @pdocid NVARCHAR(50),
    @psrcmultipletransid NVARCHAR(255),
    @pparamchange CHAR(1)
AS
BEGIN
    DECLARE @pscripts NVARCHAR(MAX);
    DECLARE @triggerName NVARCHAR(255);
    DECLARE @deleteTriggerName NVARCHAR(255);

    -- Define trigger names based on the docid
    SET @triggerName = 'axp_sch_' + @pdocid;
    SET @deleteTriggerName = @triggerName + '_delete';

    -- Drop existing triggers if they exist
    IF @pparamchange = 'T'
    BEGIN
        -- Drop the INSERT/UPDATE trigger
        IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = @triggerName)
        BEGIN
            SET @pscripts = 'DROP TRIGGER ' + QUOTENAME(@triggerName) + ';';
            EXEC sp_executesql @pscripts;
        END;

        -- Drop the DELETE trigger
        IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = @deleteTriggerName)
        BEGIN
            SET @pscripts = 'DROP TRIGGER ' + QUOTENAME(@deleteTriggerName) + ';';
            EXEC sp_executesql @pscripts;
        END;

        -- Delete existing data in axp_appsearch_data_v2 for the docid
        DELETE FROM axp_appsearch_data_v2 WHERE docid = @pdocid;
    END;

    -- Build trigger logic dynamically for INSERT and UPDATE
    SET @pscripts = '
        CREATE TRIGGER ' + QUOTENAME(@triggerName) + '
        ON ' + QUOTENAME(@psrctable) + '
        AFTER INSERT, UPDATE
        AS
        BEGIN
            SET NOCOUNT ON;

            -- Handle INSERT and UPDATE operations
            IF EXISTS (SELECT * FROM INSERTED)
            BEGIN
                INSERT INTO axp_appsearch_data_v2 (hltype, structname, searchtext, params, docid)
                SELECT
                    ''' + @phltype + ''',
                    ''' + @pstructname + ''',
                    CAST(INSERTED.' + @psrcfield + ' AS NVARCHAR(255)) + ''' + @psearchtext + ''',
                    ''' + REPLACE(REPLACE(@pparams, '@' + @psrcfield, ''' + CAST(INSERTED.' + @psrcfield + ' AS NVARCHAR(255)) + '''), '&', '&''') + ''',
                    ''' + @pdocid + '''
                FROM INSERTED;
            END;
        END;
    ';
    EXEC sp_executesql @pscripts;

    -- Build trigger logic dynamically for DELETE
    SET @pscripts = '
        CREATE TRIGGER ' + QUOTENAME(@deleteTriggerName) + '
        ON ' + QUOTENAME(@psrctable) + '
        AFTER DELETE
        AS
        BEGIN
            SET NOCOUNT ON;

            -- Handle DELETE operations
            IF EXISTS (SELECT * FROM DELETED)
            BEGIN
                DELETE FROM axp_appsearch_data_v2
                WHERE hltype = ''' + @phltype + ''' 
                  AND params = ''' + REPLACE(REPLACE(@pparams, '@' + @psrcfield, ''' + CAST(INSERTED.' + @psrcfield + ' AS NVARCHAR(255)) + '''), '&', '&''') + '''
                  AND docid = ''' + @pdocid + ''';
            END;
        END;
    ';
    EXEC sp_executesql @pscripts;

    SET @pscripts = 'UPDATE ' + QUOTENAME(@psrctable) + ' SET cancel = cancel;';
    EXEC sp_executesql @pscripts;
END;
>>
<<
CREATE or alter FUNCTION pr_utl_forms_menutree (
    @ppagetype VARCHAR(255)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @v_mtree VARCHAR(MAX);

    -- Recursive CTE to build hierarchy
    WITH cte AS (
        SELECT 
            name,
            caption,
            1 AS level,
            pagetype,
            caption AS a,
            name AS b,
            visible
        FROM axpages
        UNION ALL
        SELECT 
            t.name,
            t.caption,
            c.level + 1,
            t.pagetype,
            c.a,
            c.b,
            t.visible
        FROM cte c
        JOIN axpages t ON t.parent = c.name
    ),
    filtered AS (
        SELECT a, level
        FROM cte
        WHERE LEFT(pagetype, 1) = 't' 
          AND visible = 'T' 
          AND pagetype = @ppagetype
    )

    -- Build the path using FOR XML PATH
    SELECT TOP 1 @v_mtree = STUFF((
        SELECT '/' + f2.a
        FROM filtered f2
        ORDER BY f2.level DESC
        FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)')
    , 1, 1, '')
    FROM filtered f1;

    RETURN 'Menu - ' + ISNULL(@v_mtree, '') + '</br>';
END;
>>
<<
CREATE SEQUENCE ax_entity_relseq
    AS BIGINT
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE;
>>
<<
   CREATE SEQUENCE ax_notify_seq
    AS BIGINT
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE;
>>
<<
   CREATE SEQUENCE axpdef_genseq
    AS BIGINT
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE;
>>
<<
CREATE  or alter TRIGGER t1_axlanguage11x
ON axlanguage11x
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    MERGE axlanguage AS tgt
    USING
    (
        SELECT
            lngname,
            sname,
            fontname,
            fontsize,
            compname,
            compcaption,
            comphint,
            dispname
        FROM inserted
    ) AS src
    ON
        tgt.lngname  = src.lngname
    AND tgt.sname    = src.sname
    AND tgt.compname = src.compname

    WHEN MATCHED THEN
        UPDATE SET
            tgt.fontname    = src.fontname,
            tgt.fontsize    = src.fontsize,
            tgt.compcaption = src.compcaption,
            tgt.comphint    = src.comphint,
            tgt.dispname    = src.dispname

    WHEN NOT MATCHED THEN
        INSERT
        (
            lngname,
            sname,
            fontname,
            fontsize,
            compname,
            compcaption,
            comphint,
            dispname
        )
        VALUES
        (
            src.lngname,
            src.sname,
            src.fontname,
            src.fontsize,
            src.compname,
            src.compcaption,
            src.comphint,
            src.dispname
        );
END;
>>
<<
CREATE or alter TRIGGER [t1_AXUSERLEVELGROUPS]
   ON  [axuserlevelgroups]
   AFTER INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
	declare @usr nvarchar(50), @ugp nvarchar(50),@axid numeric(15)
	set @usr=(select axusername from inserted)
	set @ugp=(select axusergroup from inserted)
	set @axid=(select AXUSERLEVELGROUPSid from inserted)
update AXUSERLEVELGROUPS set username=@usr,usergroup = @ugp  where AXUSERLEVELGROUPSid = @axid
    
END;
>>
<<
CREATE or alter TRIGGER [t1_axusers]
   ON  [axusers]
   AFTER INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
	declare @usr nvarchar(50), @pwd nvarchar(50)
	
	set @usr=(select pusername from inserted)
	set @pwd=(select ppassword from inserted)
	
	IF EXISTS(SELECT * FROM INSERTED)  AND NOT EXISTS(SELECT * FROM DELETED)
		update axusers set username=@usr, password=@pwd where pusername=@usr
	ELSE
		update axusers set username=@usr where pusername=@usr
    
END;
>>
<<
CREATE   or alter  TRIGGER trg_axpdef_peg_actor
ON axpdef_peg_actor
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM inserted i
        JOIN deleted d
          ON i.axpdef_peg_actorid = d.axpdef_peg_actorid
        WHERE ISNULL(d.olddefusername, '') <> ISNULL(i.defusername, '')
    )
        RETURN;

    DECLARE
        @olddefusername   VARCHAR(4000),
        @defusername      VARCHAR(4000),
        @actorname        VARCHAR(255),
        @v_newusers       VARCHAR(4000),
        @v_delusers       VARCHAR(4000),
        @v_retainedusers  VARCHAR(4000);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            d.olddefusername,
            i.defusername,
            i.actorname
        FROM inserted i
        JOIN deleted d
          ON i.axpdef_peg_actorid = d.axpdef_peg_actorid
        WHERE ISNULL(d.olddefusername, '') <> ISNULL(i.defusername, '');

    OPEN cur;
    FETCH NEXT FROM cur INTO
        @olddefusername,
        @defusername,
        @actorname;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        SELECT
            @v_delusers =
                STRING_AGG(a.value, ',')
        FROM STRING_SPLIT(@olddefusername, ',') a
        LEFT JOIN STRING_SPLIT(@defusername, ',') b
               ON a.value = b.value
        WHERE b.value IS NULL;

        SELECT
            @v_newusers =
                STRING_AGG(b.value, ',')
        FROM STRING_SPLIT(@defusername, ',') b
        LEFT JOIN STRING_SPLIT(@olddefusername, ',') a
               ON a.value = b.value
        WHERE a.value IS NULL;


        SELECT
            @v_retainedusers =
                STRING_AGG(b.value, ',')
        FROM STRING_SPLIT(@defusername, ',') b
        JOIN STRING_SPLIT(@olddefusername, ',') a
             ON a.value = b.value;

        UPDATE a
        SET removeflg = 'T'
        FROM axactivetasks a
        WHERE a.assigntoflg = '2'
          AND a.delegation = 'F'
          AND a.pownerflg = 'F'
          AND a.removeflg = 'F'
          AND a.actor_default_users = 'T'
          AND a.grouped = 'T'
          AND a.assigntoactor = @actorname
          AND a.touser IN (
                SELECT value
                FROM STRING_SPLIT(@v_delusers, ',')
          )
          AND NOT EXISTS (
                SELECT 1
                FROM axactivetaskstatus b
                WHERE b.taskid = a.taskid
          );

        INSERT INTO axactivetasks
        (
            eventdatetime, taskid, processname, tasktype, taskname,
            taskdescription, assigntorole, transid, keyfield,
            execonapprove, keyvalue, transdata, fromrole, fromuser,
            touser, priorindex, priortaskname, corpdimension,
            orgdimension, department, grade, datavalue,
            displayicon, displaytitle, displaysubtitle,
            displaycontent, displaybuttons, groupfield,
            groupvalue, priorusername, initiator, mapfieldvalue,
            useridentificationfilter, useridentificationfilter_of,
            mapfield_group, mapfield, grouped, indexno, subindexno,
            processowner, assigntoflg, assigntoactor, actorfilter,
            recordid, processownerflg, pownerfilter,
            approvereasons, defapptext, returnreasons, defrettext,
            rejectreasons, defregtext, approvalcomments,
            rejectcomments, returncomments, escalation, reminder,
            displaymcontent, groupwithpriorindex, returnable,
            allowsend, allowsendflg, sendtoactor,
            initiator_approval, usebusinessdatelogic,
            initonbehalf, changedusr, actor_default_users
        )
        SELECT DISTINCT
            a.eventdatetime, a.taskid, a.processname, a.tasktype, a.taskname,
            a.taskdescription, a.assigntorole, a.transid, a.keyfield,
            a.execonapprove, a.keyvalue, a.transdata, a.fromrole,
            a.fromuser, u.value,
            a.priorindex, a.priortaskname, a.corpdimension,
            a.orgdimension, a.department, a.grade, a.datavalue,
            a.displayicon, a.displaytitle, a.displaysubtitle,
            a.displaycontent, a.displaybuttons, a.groupfield,
            a.groupvalue, a.priorusername, a.initiator,
            a.mapfieldvalue, a.useridentificationfilter,
            a.useridentificationfilter_of, a.mapfield_group,
            a.mapfield, 'T', a.indexno, a.subindexno,
            a.processowner, a.assigntoflg, a.assigntoactor,
            a.actorfilter, a.recordid, a.processownerflg,
            a.pownerfilter, a.approvereasons, a.defapptext,
            a.returnreasons, a.defrettext, a.rejectreasons,
            a.defregtext, a.approvalcomments, a.rejectcomments,
            a.returncomments, a.escalation, a.reminder,
            a.displaymcontent, a.groupwithpriorindex, a.returnable,
            a.allowsend, a.allowsendflg, a.sendtoactor,
            a.initiator_approval, a.usebusinessdatelogic,
            a.initonbehalf, 'T', 'T'
        FROM axactivetasks a
        CROSS APPLY STRING_SPLIT(@v_newusers, ',') u
        WHERE a.assigntoflg = '2'
          AND a.delegation = 'F'
          AND a.pownerflg = 'F'
          AND a.removeflg = 'F'
          AND a.grouped = 'T'
          AND a.actor_default_users = 'T'
          AND a.assigntoactor = @actorname
          AND NOT EXISTS (
                SELECT 1
                FROM axactivetaskstatus b
                WHERE b.taskid = a.taskid
          );

        FETCH NEXT FROM cur INTO
            @olddefusername,
            @defusername,
            @actorname;
    END;

    CLOSE cur;
    DEALLOCATE cur;
END;
>>
<<
CREATE   or alter  TRIGGER trg_axpdef_peg_actorusergrp
ON axpdef_peg_actorusergrp
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM inserted i
        JOIN deleted d
          ON i.axpdef_peg_actorusergrpid = d.axpdef_peg_actorusergrpid
        WHERE ISNULL(d.oldugrpusername, '') <> ISNULL(i.ugrpusername, '')
    )
        RETURN;

    DECLARE
        @oldugrpusername   VARCHAR(4000),
        @ugrpusername      VARCHAR(4000),
        @ug_actorname      VARCHAR(255),
        @usergroupname     VARCHAR(255),
        @v_newusers        VARCHAR(4000),
        @v_delusers        VARCHAR(4000),
        @v_retainedusers  VARCHAR(4000);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            d.oldugrpusername,
            i.ugrpusername,
            i.ug_actorname,
            i.usergroupname
        FROM inserted i
        JOIN deleted d
          ON i.axpdef_peg_actorusergrpid = d.axpdef_peg_actorusergrpid
        WHERE ISNULL(d.oldugrpusername, '') <> ISNULL(i.ugrpusername, '');

    OPEN cur;
    FETCH NEXT FROM cur INTO
        @oldugrpusername,
        @ugrpusername,
        @ug_actorname,
        @usergroupname;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        SELECT
            @v_delusers =
                STRING_AGG(a.value, ',')
        FROM STRING_SPLIT(@oldugrpusername, ',') a
        LEFT JOIN STRING_SPLIT(@ugrpusername, ',') b
               ON a.value = b.value
        WHERE b.value IS NULL;


        SELECT
            @v_newusers =
                STRING_AGG(b.value, ',')
        FROM STRING_SPLIT(@ugrpusername, ',') b
        LEFT JOIN STRING_SPLIT(@oldugrpusername, ',') a
               ON a.value = b.value
        WHERE a.value IS NULL;

        SELECT
            @v_retainedusers =
                STRING_AGG(b.value, ',')
        FROM STRING_SPLIT(@ugrpusername, ',') b
        JOIN STRING_SPLIT(@oldugrpusername, ',') a
             ON a.value = b.value;

        UPDATE a
        SET removeflg = 'T'
        FROM axactivetasks a
        WHERE a.assigntoflg = '2'
          AND a.delegation = 'F'
          AND a.pownerflg = 'F'
          AND a.removeflg = 'F'
          AND a.grouped = 'T'
          AND a.assigntoactor = @ug_actorname
          AND a.actor_user_groups = @usergroupname
          AND a.touser IN (
                SELECT value
                FROM STRING_SPLIT(@v_delusers, ',')
          )
          AND NOT EXISTS (
                SELECT 1
                FROM axactivetaskstatus b
                WHERE b.taskid = a.taskid
          );
         
        INSERT INTO axactivetasks
        (
            eventdatetime, taskid, processname, tasktype, taskname,
            taskdescription, assigntorole, transid, keyfield,
            execonapprove, keyvalue, transdata, fromrole, fromuser,
            touser, priorindex, priortaskname, corpdimension,
            orgdimension, department, grade, datavalue,
            displayicon, displaytitle, displaysubtitle,
            displaycontent, displaybuttons, groupfield,
            groupvalue, priorusername, initiator, mapfieldvalue,
            useridentificationfilter, useridentificationfilter_of,
            mapfield_group, mapfield, grouped, indexno, subindexno,
            processowner, assigntoflg, assigntoactor, actorfilter,
            recordid, processownerflg, pownerfilter,
            approvereasons, defapptext, returnreasons, defrettext,
            rejectreasons, defregtext, approvalcomments,
            rejectcomments, returncomments, escalation, reminder,
            displaymcontent, groupwithpriorindex, returnable,
            allowsend, allowsendflg, sendtoactor,
            initiator_approval, usebusinessdatelogic,
            initonbehalf, changedusr, actor_user_groups
        )
        SELECT DISTINCT
            a.eventdatetime, a.taskid, a.processname, a.tasktype, a.taskname,
            a.taskdescription, a.assigntorole, a.transid, a.keyfield,
            a.execonapprove, a.keyvalue, a.transdata, a.fromrole,
            a.fromuser, u.value,
            a.priorindex, a.priortaskname, a.corpdimension,
            a.orgdimension, a.department, a.grade, a.datavalue,
            a.displayicon, a.displaytitle, a.displaysubtitle,
            a.displaycontent, a.displaybuttons, a.groupfield,
            a.groupvalue, a.priorusername, a.initiator,
            a.mapfieldvalue, a.useridentificationfilter,
            a.useridentificationfilter_of, a.mapfield_group,
            a.mapfield, 'T', a.indexno, a.subindexno,
            a.processowner, a.assigntoflg, a.assigntoactor,
            a.actorfilter, a.recordid, a.processownerflg,
            a.pownerfilter, a.approvereasons, a.defapptext,
            a.returnreasons, a.defrettext, a.rejectreasons,
            a.defregtext, a.approvalcomments, a.rejectcomments,
            a.returncomments, a.escalation, a.reminder,
            a.displaymcontent, a.groupwithpriorindex, a.returnable,
            a.allowsend, a.allowsendflg, a.sendtoactor,
            a.initiator_approval, a.usebusinessdatelogic,
            a.initonbehalf, 'T', @usergroupname
        FROM axactivetasks a
        CROSS APPLY STRING_SPLIT(@v_newusers, ',') u
        WHERE a.assigntoflg = '2'
          AND a.delegation = 'F'
          AND a.pownerflg = 'F'
          AND a.removeflg = 'F'
          AND a.grouped = 'T'
          AND a.assigntoactor = @ug_actorname
          AND a.actor_user_groups = @usergroupname
          AND NOT EXISTS (
                SELECT 1
                FROM axactivetaskstatus b
                WHERE b.taskid = a.taskid
          );

        FETCH NEXT FROM cur INTO
            @oldugrpusername,
            @ugrpusername,
            @ug_actorname,
            @usergroupname;
    END;

    CLOSE cur;
    DEALLOCATE cur;
END;
>>
<<
CREATE   or alter  TRIGGER trg_axpdef_peg_grpfilter
ON axpdef_peg_grpfilter
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted d
          ON i.axpdef_peg_grpfilterid = d.axpdef_peg_grpfilterid
        WHERE ISNULL(d.olddatagrpusers, '') <> ISNULL(i.datagrpusers, '')
    )
        RETURN;


    DECLARE
        @olddatagrpusers   VARCHAR(4000),
        @datagrpusers      VARCHAR(4000),
        @dg_actorname      VARCHAR(255),
        @dgname            VARCHAR(255),
        @v_newusers        VARCHAR(4000),
        @v_delusers        VARCHAR(4000),
        @v_retainedusers   VARCHAR(4000);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            d.olddatagrpusers,
            i.datagrpusers,
            i.dg_actorname,
            i.dgname
        FROM inserted i
        JOIN deleted d
          ON i.axpdef_peg_grpfilterid = d.axpdef_peg_grpfilterid
        WHERE ISNULL(d.olddatagrpusers, '') <> ISNULL(i.datagrpusers, '');

    OPEN cur;
    FETCH NEXT FROM cur INTO
        @olddatagrpusers,
        @datagrpusers,
        @dg_actorname,
        @dgname;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT
            @v_delusers =
                STRING_AGG(a.value, ',')
        FROM STRING_SPLIT(@olddatagrpusers, ',') a
        LEFT JOIN STRING_SPLIT(@datagrpusers, ',') b
               ON a.value = b.value
        WHERE b.value IS NULL;

        SELECT
            @v_newusers =
                STRING_AGG(b.value, ',')
        FROM STRING_SPLIT(@datagrpusers, ',') b
        LEFT JOIN STRING_SPLIT(@olddatagrpusers, ',') a
               ON a.value = b.value
        WHERE a.value IS NULL;

        SELECT
            @v_retainedusers =
                STRING_AGG(b.value, ',')
        FROM STRING_SPLIT(@datagrpusers, ',') b
        JOIN STRING_SPLIT(@olddatagrpusers, ',') a
             ON a.value = b.value;

        UPDATE a
        SET removeflg = 'T'
        FROM axactivetasks a
        WHERE a.assigntoflg   = '2'
          AND a.delegation    = 'F'
          AND a.pownerflg     = 'F'
          AND a.removeflg     = 'F'
          AND a.grouped       = 'T'
          AND a.assigntoactor = @dg_actorname
          AND a.actor_data_grp = @dgname
          AND a.touser IN (
                SELECT value
                FROM STRING_SPLIT(@v_delusers, ',')
          )
          AND NOT EXISTS (
                SELECT 1
                FROM axactivetaskstatus b
                WHERE b.taskid = a.taskid
          );

        INSERT INTO axactivetasks
        (
            eventdatetime, taskid, processname, tasktype, taskname,
            taskdescription, assigntorole, transid, keyfield, execonapprove,
            keyvalue, transdata, fromrole, fromuser, touser,
            priorindex, priortaskname, corpdimension, orgdimension,
            department, grade, datavalue, displayicon, displaytitle,
            displaysubtitle, displaycontent, displaybuttons, groupfield,
            groupvalue, priorusername, initiator, mapfieldvalue,
            useridentificationfilter, useridentificationfilter_of,
            mapfield_group, mapfield, grouped, indexno, subindexno,
            processowner, assigntoflg, assigntoactor, actorfilter,
            recordid, processownerflg, pownerfilter,
            approvereasons, defapptext, returnreasons, defrettext,
            rejectreasons, defregtext, approvalcomments, rejectcomments,
            returncomments, escalation, reminder, displaymcontent,
            groupwithpriorindex, returnable, allowsend, allowsendflg,
            sendtoactor, initiator_approval, usebusinessdatelogic,
            initonbehalf, changedusr, actor_data_grp
        )
        SELECT DISTINCT
            a.eventdatetime, a.taskid, a.processname, a.tasktype, a.taskname,
            a.taskdescription, a.assigntorole, a.transid, a.keyfield,
            a.execonapprove, a.keyvalue, a.transdata, a.fromrole, a.fromuser,
            u.value,
            a.priorindex, a.priortaskname, a.corpdimension, a.orgdimension,
            a.department, a.grade, a.datavalue, a.displayicon, a.displaytitle,
            a.displaysubtitle, a.displaycontent, a.displaybuttons,
            a.groupfield, a.groupvalue, a.priorusername, a.initiator,
            a.mapfieldvalue, a.useridentificationfilter,
            a.useridentificationfilter_of, a.mapfield_group, a.mapfield,
            'T', a.indexno, a.subindexno, a.processowner, a.assigntoflg,
            a.assigntoactor, a.actorfilter, a.recordid, a.processownerflg,
            a.pownerfilter, a.approvereasons, a.defapptext,
            a.returnreasons, a.defrettext, a.rejectreasons, a.defregtext,
            a.approvalcomments, a.rejectcomments, a.returncomments,
            a.escalation, a.reminder, a.displaymcontent,
            a.groupwithpriorindex, a.returnable, a.allowsend,
            a.allowsendflg, a.sendtoactor, a.initiator_approval,
            a.usebusinessdatelogic, a.initonbehalf,
            'T', @dgname
        FROM axactivetasks a
        CROSS APPLY STRING_SPLIT(@v_newusers, ',') u
        WHERE a.assigntoflg   = '2'
          AND a.delegation    = 'F'
          AND a.pownerflg     = 'F'
          AND a.removeflg     = 'F'
          AND a.grouped       = 'T'
          AND a.assigntoactor = @dg_actorname
          AND a.actor_data_grp = @dgname
          AND NOT EXISTS (
                SELECT 1
                FROM axactivetaskstatus b
                WHERE b.taskid = a.taskid
          );

        FETCH NEXT FROM cur INTO
            @olddatagrpusers,
            @datagrpusers,
            @dg_actorname,
            @dgname;
    END;

    CLOSE cur;
    DEALLOCATE cur;
END;
>>
<<
CREATE   or alter  TRIGGER trg_axpeg_sendmsg
ON axpeg_sendmsg
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO axactivemessages
    (
        eventdatetime,
        msgtype,
        fromuser,
        touser,
        displaytitle,
        displaycontent,
        effectivefrom,
        effectiveto,
        hlink_transid,
        hlink_params
    )
    SELECT
        FORMAT(SYSDATETIME(), 'yyyyMMddHHmmssfff'),  -- YYYYMMDDHH24MISSSS
        i.msgtype,
        i.fromuser,
        i.touser,
        i.msgtitle,
        i.message,
        CAST(GETDATE() AS DATE),
        i.effectiveto,
        i.hlink_transid,
        i.hlink_params
    FROM inserted i;
END;
>>
<<
CREATE   or alter  TRIGGER trg_axprocessdefv2
ON axprocessdefv2
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;
    INSERT INTO axprocessdefv2
    (
        --processid,
        processname,
        rem_esc_startfrom,
        taskparamsui,
        taskparams,
        createdon
    )
    SELECT
        --i.processid,
        i.processname,
        i.rem_esc_startfrom,
        CONCAT(
            ISNULL(i.taskparamsui, ''),
            ',',
            s1.v_rem_esc_sfrom
        ) AS taskparamsui,
        CONCAT(
            ISNULL(i.taskparams, ''),
            ',',
            s2.v_rem_esc_taskparam
        ) AS taskparams,
        i.createdon
    FROM inserted i
    CROSS APPLY
    (
        SELECT
            STRING_AGG(value, ',') AS v_rem_esc_sfrom
        FROM (
            SELECT DISTINCT value
            FROM STRING_SPLIT(i.rem_esc_startfrom, ',')
        ) x
    ) s1
    CROSS APPLY
    (
        SELECT
            STRING_AGG(
                SUBSTRING(
                    value,
                    CHARINDEX('-(', value) + 2,
                    LEN(value) - (CHARINDEX('-(', value) + 1)
                ),
                ','
            ) AS v_rem_esc_taskparam
        FROM STRING_SPLIT(s1.v_rem_esc_sfrom, ',')
        WHERE s1.v_rem_esc_sfrom IS NOT NULL
    ) s2;
END;
>>
<<
CREATE   or alter  TRIGGER trg_axrelations
ON axrelations
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    DELETE er
    FROM axentityrelations er
    JOIN inserted i
      ON er.mstruct = i.mstruct
     AND er.mfield  = i.mfield
     AND er.dstruct = i.dstruct
     AND er.dfield  = i.dfield
     AND i.rtype    = 'md';


    DELETE er
    FROM axentityrelations er
    JOIN inserted i
      ON er.mstruct = i.mstruct
     AND er.dstruct = i.dstruct
     AND i.rtype    = 'gm';


    INSERT INTO axentityrelations
    (
        axentityrelationsid,
        cancel,
        username,
        modifiedon,
        createdby,
        createdon,
        app_level,
        app_desc,
        rtype,
        mstruct,
        mfield,
        mtable,
        primarytable,
        dstruct,
        dfield,
        dtable,
        rtypeui,
        mstructui,
        mfieldui,
        dstructui,
        dfieldui,
        dprimarytable
    )
    SELECT
        NEXT VALUE FOR ax_entity_relseq,
        'F',
        'admin',
        SYSDATETIME(),
        'admin',
        SYSDATETIME(),
        1,
        1,
        x.rtype,
        x.mstruct,
        x.mfield,
        x.mtable,
        x.primarytable,
        x.dstruct,
        x.dfield,
        x.dtable,
        'Dropdown',
        x.mstructui,
        x.mfieldui,
        x.dstructui,
        x.dfieldui,
        x.dprimarytable
    FROM
    (
        SELECT DISTINCT
            i.rtype,
            i.mstruct,
            i.mfield,
            m.tablename  AS mtable,
            dc.tablename AS primarytable,
            i.dstruct,
            i.dfield,
            d.tablename  AS dtable,
            CONCAT(mt.caption, '-(', mt.name, ')') AS mstructui,
            CONCAT(m.caption,  '-(', m.fname, ')') AS mfieldui,
            CONCAT(dt.caption, '-(', dt.name, ')') AS dstructui,
            CONCAT(d.caption,  '-(', d.fname, ')') AS dfieldui,
            ddc.tablename AS dprimarytable
        FROM inserted i
        JOIN tstructs mt
            ON i.mstruct = mt.name AND mt.blobno = 1
        JOIN tstructs dt
            ON i.dstruct = dt.name AND dt.blobno = 1
        LEFT JOIN axpflds m
            ON i.mstruct = m.tstruct AND i.mfield = m.fname
        LEFT JOIN axpflds d
            ON i.dstruct = d.tstruct AND i.dfield = d.fname
        LEFT JOIN axpdc dc
            ON i.mstruct = dc.tstruct AND dc.dname = 'dc1'
        LEFT JOIN axpdc ddc
            ON i.dstruct = ddc.tstruct AND ddc.dname = 'dc1'
        WHERE i.rtype = 'md'
    ) x;


    INSERT INTO axentityrelations
    (
        axentityrelationsid,
        cancel,
        username,
        modifiedon,
        createdby,
        createdon,
        app_level,
        app_desc,
        rtype,
        mstruct,
        mfield,
        mtable,
        primarytable,
        dstruct,
        dfield,
        dtable,
        rtypeui,
        mstructui,
        mfieldui,
        dstructui,
        dfieldui,
        dprimarytable
    )
    SELECT
        NEXT VALUE FOR ax_entity_relseq,
        'F',
        'admin',
        SYSDATETIME(),
        'admin',
        SYSDATETIME(),
        1,
        1,
        'gm',
        x.mstruct,
        NULL,
        NULL,
        x.primarytable,
        x.dstruct,
        'sourceid',
        x.dtable,
        'Genmap',
        x.mstructui,
        NULL,
        x.dstructui,
        NULL,
        x.dprimarytable
    FROM
    (
        SELECT DISTINCT
            i.mstruct,
            i.dstruct,
            pd.tablename AS primarytable,
            td.tablename AS dtable,
            CONCAT(mt.caption, '-(', mt.name, ')') AS mstructui,
            CONCAT(dt.caption, '-(', dt.name, ')') AS dstructui,
            td.tablename AS dprimarytable
        FROM inserted i
        JOIN tstructs mt
            ON i.mstruct = mt.name AND mt.blobno = 1
        JOIN tstructs dt
            ON i.dstruct = dt.name AND dt.blobno = 1
        LEFT JOIN axpdc td
            ON i.dstruct = td.tstruct AND td.dname = 'dc1'
        LEFT JOIN axpdc pd
            ON i.mstruct = pd.tstruct AND pd.dname = 'dc1'
        WHERE i.rtype = 'gm'
    ) x;

 
    INSERT INTO axrelations
    SELECT * FROM inserted;
END;
>>
<<
CREATE or alter  TRIGGER AXP_TR_SEARCH_APPSEARCH
ON AXP_APPSEARCH_DATA_PERIOD
INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @cnt INT;

        -- Handle INSERT operation
        IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
        BEGIN
            INSERT INTO axp_appsearch_data_v2 (hltype, structname, searchtext, params, docid)
            SELECT 
                hltype,
                structname,
                CASE 
                    WHEN periodically = 'T' THEN searchtext 
                    ELSE caption 
                END,
                params,
                docid
            FROM inserted;
        END

        -- Handle UPDATE operation
        IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        BEGIN
            INSERT INTO axp_appsearch_data_v2 (hltype, structname, searchtext, params, docid)
            SELECT 
                d.hltype,
                d.structname,
                CASE 
                    WHEN d.periodically = 'T' THEN d.searchtext 
                    ELSE d.caption 
                END,
                d.params,
                d.docid
            FROM deleted d;
        END

        -- Handle DELETE operation
        IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
        BEGIN
            DELETE FROM axp_appsearch_data_v2
            WHERE docid IN (SELECT docid FROM deleted);

            -- Check if a trigger exists for the deleted docid
            SELECT TOP 1 @cnt = COUNT(1)
            FROM sys.triggers
            WHERE LOWER(name) = LOWER('axp_sch_' + CAST((SELECT TOP 1 docid FROM deleted) AS NVARCHAR(MAX)));

            -- Drop the trigger if it exists
            IF @cnt > 0
            BEGIN
                DECLARE @dropTrigger NVARCHAR(MAX);
                SET @dropTrigger = 'DROP TRIGGER axp_sch_' + CAST((SELECT TOP 1 docid FROM deleted) AS NVARCHAR(MAX));
                EXEC sp_executesql @dropTrigger;
            END
        END
    END TRY
    BEGIN CATCH
        -- Handle DUP_VAL_ON_INDEX equivalent (unique constraint violations)
        IF ERROR_NUMBER() = 2627 -- Unique constraint violation error number in SQL Server
        BEGIN
            UPDATE axp_appsearch_data_v2
            SET hltype = i.hltype, 
                structname = i.structname, 
                searchtext = CASE 
                    WHEN i.periodically = 'T' THEN i.searchtext 
                    ELSE i.caption 
                END, 
                params = i.params
            FROM inserted i
            WHERE axp_appsearch_data_v2.docid = i.docid;
        END
        ELSE
        BEGIN
            -- Log other errors or handle them as necessary
            PRINT 'Error occurred: ' + ERROR_MESSAGE();
        END
    END CATCH;
END;
>>
<<
CREATE   FUNCTION dbo.fn_dimensiondc2props
(
    @dc2caption NVARCHAR(200) = NULL,
    @grpname NVARCHAR(100) = NULL,
    @grpcaption NVARCHAR(200) = NULL
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @json NVARCHAR(MAX);
    DECLARE @safe_grpname NVARCHAR(100) = ISNULL(@grpname, '');
    DECLARE @safe_dc2caption NVARCHAR(200) = ISNULL(@dc2caption, '');
    DECLARE @safe_grpcaption NVARCHAR(200) = ISNULL(@grpcaption, '');
    DECLARE @sqltext NVARCHAR(MAX);

    -- Sanitize inputs to remove line breaks
    SET @safe_dc2caption = REPLACE(REPLACE(@safe_dc2caption, CHAR(13), ''), CHAR(10), '');
    SET @safe_grpcaption = REPLACE(REPLACE(@safe_grpcaption, CHAR(13), ''), CHAR(10), '');
    SET @safe_grpname = REPLACE(REPLACE(@safe_grpname, CHAR(13), ''), CHAR(10), '');

    -- Build sqltext only if required params are present
    IF @safe_grpname <> ''
    BEGIN
        SET @sqltext = 
            'select grpvalue from axgrouping where grpnamedb = ''' + 
            REPLACE(@safe_grpname, '''', '''''') + ''' order by 1';

        -- Remove line breaks from sqltext
        SET @sqltext = REPLACE(REPLACE(@sqltext, CHAR(13), ''), CHAR(10), '');
        -- Escape double quotes in sqltext for JSON
        SET @sqltext = REPLACE(@sqltext, '"', '""');
    END

    -- Construct JSON string
    SET @json = 
        '{' +
        '"saveValue": "T", ' +
        '"dcName": "dc2", ' +
        '"dcNo": 2, ' +
        '"dcCaption": ' + 
            CASE WHEN @dc2caption IS NULL THEN 'null' ELSE '"' + REPLACE(@safe_dc2caption, '"', '""') + '"' END + ', ' +
        '"asgrid": "F", ' +
        '"source": "select from sql", ' +
        '"MOE": "select from sql", ' +
        '"name": "axug_' + REPLACE(@safe_grpname, '"', '""') + '", ' +
        '"caption": ' +
            CASE WHEN @grpcaption IS NULL THEN 'null' ELSE '"' + REPLACE(@safe_grpcaption, '"', '""') + '"' END + ', ' +
        '"fieldType": "DropDown", ' +
        '"dataType": "Character", ' +
        '"width": 500, ' +
        '"allowEmpty": "T", ' +
        '"allowDuplicate": "T", ' +
        '"SqlText": ' + 
            CASE WHEN @sqltext IS NULL THEN 'null' ELSE '"' + @sqltext + '"' END + ', ' +
        '"hidden": "F", ' +
        '"saveNomralized": "F", ' +
        '"firstcolvalue": "grpvalue", ' +
        '"firstcoldtype": "c", ' +
        '"tablename": "axgrouping"' +
        '}';

    -- Final clean-up to remove any accidental line breaks
    SET @json = REPLACE(REPLACE(@json, CHAR(13), ''), CHAR(10), '');

    RETURN @json;
END;
>>
<<
CREATE   FUNCTION dbo.fn_dimensiondc3props
(
    @dc3caption NVARCHAR(200) = NULL,
    @grpname NVARCHAR(100) = NULL,
    @grpcaption NVARCHAR(200) = NULL
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @json NVARCHAR(MAX);

    SET @json = 
        '{' +
        '"saveValue":"T",' +
        '"dcName":"dc3",' +
        '"dcNo":3,' +
        '"dcCaption":' + 
            CASE WHEN @dc3caption IS NULL THEN 'null' ELSE '"' + REPLACE(@dc3caption, '"', '""') + '"' END + ',' +

        '"asgrid":"T",' +
        '"source":"select from sql",' +
        '"MOE":"select from sql",' +

        '"name":"axup_' + ISNULL(@grpname, '') + '",' +

        '"caption":' + 
            CASE WHEN @grpcaption IS NULL THEN 'null' ELSE '"' + REPLACE(@grpcaption, '"', '""') + '"' END + ',' +

        '"fieldType":"Multi Select",' +
        '"dataType":"Character",' +
        '"width":500,' +
        '"allowEmpty":"T",' +
        '"allowDuplicate":"T",' +

        '"SqlText":"select mslist, groupby, grouporder, selected from (select grpvalue as mslist, ''' +
            ISNULL(REPLACE(@grpcaption, '"', '""'), '') + ''' as groupby, 1 as grouporder, ''false'' as selected, 2 as ord from axgrouping where grpnamedb = ''' +
            ISNULL(REPLACE(@grpname, '"', '""'), '') + ''' union all select ''All'' as mslist, ''' +
            ISNULL(REPLACE(@grpcaption, '"', '""'), '') + ''' as groupby, 1 as grouporder, ''false'' as selected, 1 as ord) a order by ord",' +

        '"hidden":"F",' +
        '"saveNomralized":"F",' +
        '"firstcolvalue":"mslist",' +
        '"firstcoldtype":"c",' +
        '"tablename":"axgrouping",' +
        '"fldPosition":"Before field",' +
        '"position":"scripttext2-(cnd)"' +
        '}';

    RETURN @json;
END;
>>
<<
<<
delete from axmmetadatamaster a 
where structtype||structname in('tstructa__ap',
'tstructa__fn',
'tstructa__iq',
'tstructa__pn',
'tstructa__qm',
'tstructad__q',
'tstructad_af',
'tstructad_am',
'tstructad_at',
'tstructad_cp',
'tstructad_it',
'tstructad_lg',
'tstructad_li',
'tstructad_pm',
'tstructad_pn',
'tstructad_pr',
'tstructad_td',
'tstructagspr',
'tstructappsr',
'tstructastcp',
'tstructaxadx',
'tstructaxcal',
'tstructaxcht',
'tstructaxclr',
'tstructaxerr',
'tstructaxfin',
'tstructaxglo',
'tstructaxlov',
'tstructaxpub',
'tstructaxrol',
'tstructaxstc',
'tstructjob_s',
'tstructpgv2a',
'tstructpgv2c',
'tstructpgv2m',
'tstructruldf',
'tstructtemps',
'tstructad__e',
'tstructa__ug',
'tstructaxusr',
'tstructad_pa',
'tstructa__sm',
'iviewad___apt',
'iviewad___ntn',
'iviewad___oqm',
'iviewad__act',
'iviewad__alog',
'iviewad__pgal',
'iviewad__pgnt',
'iviewad__prcd',
'iviewad__qlog',
'iviewad__qls',
'iviewad_implg',
'iviewad_lngst',
'iviewad_pgv2',
'iviewad_txalg',
'iviewadxconfv',
'iviewadxinlog',
'iviewadxoutlo',
'iviewapplogsm',
'iviewauditlog',
'iviewaxapilog',
'iviewaxchtdtl',
'iviewaxemllog',
'iviewaxfinyrs',
'iviewaximpfrc',
'iviewaximplog',
'iviewaxlangs',
'iviewaxnxtlst',
'iviewaxpfinhs',
'iviewaxpubls',
'iviewaxroles',
'iviewaxscrlog',
'iviewaxusers',
'iviewaxusracc',
'iviewcerrm',
'iviewdmlscrpt',
'iviewemaillog',
'iviewemlexcp',
'iviewesmsco',
'iviewiaxex',
'iviewiaxpscon',
'iviewidsco',
'iviewikywd',
'iviewimobc',
'iviewinmemdb',
'iviewitimtk',
'iviewivconfdt',
'iviewivhelpto',
'iviewloview1',
'iviewprintlog',
'iviewprnfail',
'iviewpservers',
'iviewpublist',
'iviewpublsdtl',
'iviewresponse',
'iviewsmslog',
'iviewthint',
'iviewad__papi',
'iviewad___fpr',
'iviewad___red',
'iviewad___rel',
'iviewad___pth',
'tstructa__er',
'iviewad___erc',
'tstructaxurg',
'iviewad_pbcs',
'iviewad___ugu',
'iviewad___ual',
'iviewad___url',
'tstructa__ua',
'tstructad_ur',
'tstructa__cd',
'tstructa__td',
'tstructad_vc',
'tstructapidg',
'tstructaxapi',
'tstructaxcdm',
'tstructaxeml',
'tstructaxipd',
'tstructaxvar',
'tstructb_sql',
'tstructctype',
'tstructsect',
'iviewad___tbd',
'iviewad___ugp',
'iviewappvars',
'iviewaximpdef',
'iviewaxjobs',
'iviewaxpcards',
'iviewaxvars',
'iviewcdlist',
'iviewcsqlist',
'iviewdop_list',
'iviewemaildef',
'iviewexapidef',
'iviewhplist',
'iviewjobcdtl',
'iviewjobtsk',
'iviewad___nwa',
'tstructa__na',
'tstructa_pgm',
'tstructa__ag',
'tstructa__up',
'iviewad___ups',
'iviewad___upg',
'tstructa__re',
'tstructad_db',
'iviewad___upm',
'iviewad___rla',
'tstructa__pu',
'tstructa__hp',
'tstructa__hc',
'tstructad__g',
'tstructad__p',
'tstructad__t',
'tstructad_cd',
'tstructad_cg',
'tstructad_cs',
'tstructad_fg',
'tstructad_fp',
'tstructad_ge',
'tstructad_lm',
'tstructad_md',
'tstructad_rm',
'tstructad_ve',
'tstructaxcad',
'tstructaxctx',
'tstructaxfsc',
'tstructaxftp',
'tstructaxmme',
'tstructaxnxt',
'tstructaxpwf',
'tstructaxrlr',
'tstructaxsrr',
'tstructchcon',
'tstructcusto',
'tstructdgmal',
'tstructdsgcn',
'tstructdsigc',
'tstructerrcd',
'tstructhptst',
'tstructiconf',
'tstructkword',
'tstructmntss',
'tstructmntst',
'tstructNF_AG',
'tstructofcon',
'tstructsendm',
'tstructtconf',
'tstructthelp',
'tstructtstco',
'tstructa__bl',
'tstructa__ur',
'tstructa__co',
'tstructa__ul',
'tstructa__uc',
'tstructad_re',
'iviewad___ucl',
'iviewad___ulg',
'iviewad___cmp',
'iviewad___brn',
'iviewad___acr',
'iviewad___acs',
'iviewad___cfd',
'iviewad___hcg',
'iviewad__fstp',
'iviewad__lgex',
'iviewad_cnfgp',
'iviewaxlngexp',
'iviewForms',
'iviewmainrepo',
'tstructa_guc',
'tstructa_dcm',
'tstructa__dm',
'tstructax_ac',
'iviewad_daccf',
'iviewad_dacmc',
'tstructa_pgt',
'tstructa_dup',
'tstructad__d')
>>
<<
ALTER TABLE axp_vp ADD CONSTRAINT axp_vp_unique UNIQUE (vpname)
>>
<<
ALTER TABLE axvarcore ADD CONSTRAINT axvarcore_unique UNIQUE (vpname)
>>
