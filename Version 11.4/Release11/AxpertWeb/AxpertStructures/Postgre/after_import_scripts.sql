<<

CREATE OR REPLACE FUNCTION fn_axpanalytics_listdata(ptransid character varying, pflds text DEFAULT 'All'::text, ppagesize numeric DEFAULT 25, ppageno numeric DEFAULT 1, pfilter text DEFAULT 'NA'::text, puser character varying DEFAULT 'admin'::character varying, papplydac character varying DEFAULT 'T'::character varying, puserrole character varying DEFAULT 'All'::character varying, pconstraints text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare 
rec record;
rec1 record;
rec2 record;
v_sql text;
v_sql1 text;
v_primarydctable varchar;
v_fldnamesary varchar[] DEFAULT  ARRAY[]::varchar[];
v_fldname_joinsary varchar[] DEFAULT  ARRAY[]::varchar[];
v_fldname_col varchar;
v_fldname_normalized varchar;
v_fldname_srctbl varchar;
v_fldname_srcfld varchar;
v_fldname_allowempty varchar;
v_fldname_dcjoinsary varchar[] DEFAULT  ARRAY[]::varchar[];
v_fldname_dctablename varchar;
v_fldname_dcflds text;
v_fldname_dctables varchar[] DEFAULT  ARRAY[]::varchar[];
v_fldname_normalizedtables varchar[] DEFAULT  ARRAY[]::varchar[];
v_fldname_transidcnd numeric;
v_allflds varchar;
v_filter_srcfld varchar;
v_filter_srctxt varchar;
v_filter_join varchar;
v_filter_joinsary varchar[] DEFAULT  ARRAY[]::varchar[];
v_filter_cnd varchar;
v_filter_cndary varchar[] DEFAULT  ARRAY[]::varchar[];
v_filter_joinreq numeric;
v_filter_dcjoinsary varchar[] DEFAULT  ARRAY[]::varchar[];
v_filter_col varchar;
v_filter_normalized varchar;
v_filter_sourcetbl varchar;
v_filter_sourcefld varchar;
v_filter_datatype varchar;
v_filter_listedfld varchar;
v_filter_tablename varchar;
v_fldname_tables varchar[] DEFAULT  ARRAY[]::varchar[];
v_dac_cnd varchar;
 

begin

/*
---pflds - tbl1=fldname~normalized~source_table~source_fld~mandatory|fldname~normalized~source_table~source_fld~mandatory^
		tb12=fldname~normalized~source_table~source_fld~mandatory|fldname~normalized~source_table~source_fld~mandatory
 */
	
/* pfilter
search field|operator search text^ 
fldname~normalized~sourcetable~sourcefld~datatype~listedfield~tablename| operator search text^
*/
		

	select tablename into v_primarydctable from axpdc where tstruct = ptransid and dname ='dc1';



	select count(1) into v_fldname_transidcnd from axpflds where tstruct = ptransid and dcname ='dc1' and lower(fname)='transid';

		if pflds = 'All' then 		
			select concat(tablename,'=',string_agg(str,'|'))  into v_allflds From(
			select tablename, concat(fname,'~',srckey,'~',srctf,'~',srcfld,'~',allowempty) str,dcname,ordno
			from axpflds where tstruct=ptransid and dcname='dc1' and 
			asgrid ='F' and hidden ='F' and savevalue='T' and tablename = v_primarydctable and datatype not in('i','t')
			union all
			select tablename,'app_desc~F~~~T' str,dname,1 from axpdc where tstruct=ptransid and dname='dc1'
			order by dcname ,ordno)a group by a.tablename;		
		end if;
						
		FOR rec1 IN
    		select unnest(string_to_array(case when pflds='All' then v_allflds else pflds end,'^')) dcdtls
    		loop	
    			v_fldname_dctablename := split_part(rec1.dcdtls,'=',1);
				v_fldname_dcflds := split_part(rec1.dcdtls,'=',2);
			
			if v_fldname_dctablename!=v_primarydctable then
						v_fldname_dcjoinsary := array_append(v_fldname_dcjoinsary,concat('left join ',v_fldname_dctablename,' on ',v_primarydctable,'.',v_primarydctable,'id=',v_fldname_dctablename,'.',v_primarydctable,'id') );						
					end if;
					v_fldname_dctables := array_append(v_fldname_dctables,v_fldname_dctablename);

			FOR rec2 IN
    		select unnest(string_to_array(v_fldname_dcflds,'|')) fldname    		    	       			
				loop		    	
					v_fldname_col := split_part(rec2.fldname,'~',1);
					v_fldname_normalized := split_part(rec2.fldname,'~',2);
					v_fldname_srctbl := split_part(rec2.fldname,'~',3);
					v_fldname_srcfld := split_part(rec2.fldname,'~',4);	
					v_fldname_allowempty := split_part(rec2.fldname,'~',5);
			    
				
					
					if v_fldname_normalized ='F' and lower(v_fldname_col)!='app_desc' then 						
						v_fldnamesary := array_append(v_fldnamesary,concat(v_fldname_dctablename,'.',v_fldname_col)::varchar);
					elsif v_fldname_normalized ='F' and lower(v_fldname_col)='app_desc' then						
						v_fldnamesary:= array_append(v_fldnamesary,concat('case when length(',v_primarydctable,'.wkid)>2 then case ',v_primarydctable,'.app_desc when 0 then  ''Created''
  when  1 then ''Approved''
  when  2 then ''Review''
  when  3 then ''Return''
  when  4 then ''Approve''
  when  5 then ''Rejected''
  when  9 then ''Orphan'' end else null end app_desc'));
					elsif v_fldname_normalized ='T' then	
						v_fldnamesary := array_append(v_fldnamesary,concat(v_fldname_col,'.',v_fldname_srcfld,' ',v_fldname_col)::varchar);	
						v_fldname_joinsary := array_append(v_fldname_joinsary,concat(case when v_fldname_allowempty='F' then ' join ' else ' left join ' end,v_fldname_srctbl,' ',v_fldname_col,' on ',v_fldname_dctablename,'.',v_fldname_col,' = ',v_fldname_col,'.',v_fldname_srctbl,'id')::Varchar);
						v_fldname_normalizedtables := array_append(v_fldname_normalizedtables,lower(v_fldname_srctbl));
					end if;
								
			    end loop;
		   
			   end loop;
		   	v_sql := concat(' select ','''',ptransid,''' transid,',v_primarydctable,'.',v_primarydctable,'id recordid,',v_primarydctable,'.username modifiedby,',v_primarydctable,'.modifiedon,',v_primarydctable,'.createdon,',v_primarydctable,'.createdby,',
		   			 array_to_string(v_fldnamesary,','),',null axpeg_processname,null axpeg_keyvalue,null axpeg_status,null axpeg_statustext from ',v_primarydctable,' ',
		   			 array_to_string(v_fldname_dcjoinsary,' '),' ',array_to_string(v_fldname_joinsary,' '));
 

		   			
---------DAC filters
			   if papplydac = 'T' then					
					v_dac_cnd := replace(pconstraints,'{primarytable.}',v_primarydctable||'.');											   					   			   										
			   end if;		   			
		   			
			
		if coalesce(pfilter,'NA') ='NA' then 

			v_sql1 := concat('select b.* from(select a.*,row_number() over(order by modifiedon desc)::Numeric rno,
			case when mod(row_number() over(order by modifiedon desc),',ppagesize,')=0 then row_number() over(order by modifiedon desc)/',ppagesize,' else row_number() over(order by modifiedon desc)/',ppagesize,'+1 end::numeric pageno from 
			(',concat(v_sql,' where ',v_primarydctable,'.cancel=''F''',case when v_fldname_transidcnd>0 then concat(' and ',v_primarydctable,'.transid=','''',ptransid,'''') else '' end,
			case when papplydac ='T' then concat(' and (',v_dac_cnd,')') end),'
			--axp_filter
			',')a order by modifiedon desc limit ',ppagesize*ppageno,' )b ',case when ppageno=0 then '' else concat('where pageno=',ppageno) end);
	
		else 
			FOR rec IN
    			select unnest(string_to_array(pfilter,'^')) ifilter
			    loop		    	
			    	v_filter_srcfld := split_part(rec.ifilter,'|',1);
			    	v_filter_srctxt := split_part(rec.ifilter,'|',2);
			    	v_filter_col := split_part(v_filter_srcfld,'~',1);
				    v_filter_normalized := split_part(v_filter_srcfld,'~',2);
 				    v_filter_sourcetbl := split_part(v_filter_srcfld,'~',3);
 				    v_filter_sourcefld := split_part(v_filter_srcfld,'~',4);
					   v_filter_datatype := split_part(v_filter_srcfld,'~',5);
					v_filter_listedfld :=split_part(v_filter_srcfld,'~',6);
				v_filter_tablename:=split_part(v_filter_srcfld,'~',7);
					
		
			    				    	
			    	if  v_filter_listedfld = 'F' then
			    	
					select count(1) into v_filter_joinreq from (select distinct unnest(v_fldname_dctables)tbls )a where lower(a.tbls)=lower(v_filter_tablename);			    		
					
			    	if v_filter_joinreq = 0  then 
				    	v_filter_dcjoinsary := array_append(v_filter_dcjoinsary,concat(' join ',v_filter_tablename,' on ',v_primarydctable,'.',v_primarydctable,'id=',v_filter_tablename,'.',v_primarydctable,'id') );
				    	v_fldname_tables := array_append(v_fldname_tables,v_filter_tablename);
			    	end if;
			    
			    	
			    
		    		select case when v_filter_normalized='T' 
					then concat(' join ',v_filter_sourcetbl,' ',v_filter_col,' on ',v_filter_tablename,'.',v_filter_col,' = ',v_filter_col,'.',v_filter_sourcetbl,'id')
					end into v_filter_join from dual where v_filter_normalized='T';
					
					 
					v_filter_joinsary :=array_append(v_filter_joinsary,v_filter_join);				
					
				
					end if;
			
									
					select case when v_filter_normalized='F' 
					then concat(case when v_filter_datatype='c' then 'lower(' end,v_filter_tablename,'.',v_filter_col,case when v_filter_datatype='c' then ')' end,' ',v_filter_srctxt) 
					else concat(case when v_filter_datatype='c' then 'lower(' end,v_filter_col,'.',v_filter_sourcefld,case when v_filter_datatype='c' then ')' end,' ',v_filter_srctxt) 
					end into v_filter_cnd;
		    	
					v_filter_cndary := array_append(v_filter_cndary,v_filter_cnd);				
			
									
			    end loop;
			   
			   	v_filter_dcjoinsary := ARRAY(SELECT DISTINCT UNNEST(v_filter_dcjoinsary));				   					   
			   
			   
				v_sql1 := concat('select b.* from(select a.*,row_number() over(order by modifiedon desc)::Numeric rno,
						case when mod(row_number() over(order by modifiedon desc),',ppagesize,')=0 then row_number() over(order by modifiedon desc)/',ppagesize,' else row_number() over(order by modifiedon desc)/',ppagesize,'+1 end::numeric pageno from 
						(',v_sql,concat(array_to_string(v_filter_dcjoinsary,' '),array_to_string(v_filter_joinsary,' '),' where ',v_primarydctable,'.cancel=''F'' and ',case when v_fldname_transidcnd>0 then concat(v_primarydctable,'.transid=','''',ptransid,''' and ') else '' end,
						array_to_string(v_filter_cndary,' and '),case when papplydac ='T' then concat(' and (',v_dac_cnd,')') end),'
						--axp_filter
						',')a order by modifiedon desc limit ',ppagesize*ppageno,' )b ',case when ppageno=0 then '' else concat('where pageno=',ppageno) end);					    						
		end if;

return v_sql1;


END; $function$
;

>>

<<

-- DROP FUNCTION fn_axpanalytics_metadata(varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION fn_axpanalytics_metadata(ptransid character varying, psubentity character varying DEFAULT 'F'::character varying, planguage character varying DEFAULT 'English'::character varying)
 RETURNS SETOF axpdef_axpanalytics_mdata
 LANGUAGE plpgsql
AS $function$
declare
r axpdef_axpanalytics_mdata%rowtype;
rec record;
v_subentitytable varchar;
v_sql text;
v_subentitysql text;
v_primarydctable varchar;
begin
 

	select tablename into v_primarydctable from axpdc where tstruct = ptransid and dname ='dc1';

	select concat('select axpflds.tstruct transid,coalesce(lf.compcaption,t.caption) formcap, fname ,coalesce(l.compcaption,axpflds.caption) fcap,customdatatype cdatatype,"datatype" dt,modeofentry,
	hidden fhide,cast(null as varchar) props,srckey ,srctf ,srcfld ,srctrans ,axpflds.allowempty,
	case when modeofentry =''select'' then case when srckey =''T'' then ''Dropdown'' else ''Text'' end else ''Text'' end::varchar filtercnd,
	case when (modeofentry =''select'' or datatype=''c'') then ''T'' else ''F'' end::varchar grpfld,
	case when "datatype" =''n'' then ''T'' else ''F'' end::varchar aggfld,''F'' subentity,1 datacnd,null entityrelfld,allowduplicate,axpflds.tablename,
	dcname,ordno,d.caption dccaption,d.asgrid,case when d.asgrid=''F'' then ''T'' else ''F'' end listingfld,encrypted,masking,lastcharmask,firstcharmask,maskchar,maskroles,customdecimal
	from axpflds join tstructs t on axpflds.tstruct = t.name join axpdc d on axpflds.tstruct = d.tstruct and axpflds.dcname = d.dname
	left join axlanguage l on substring(l.sname FROM 2)= t.name and lower(l.dispname)=''',lower(planguage),''' and axpflds.fname = l.compname
	left join axlanguage lf on substring(lf.sname FROM 2)= t.name and lower(lf.dispname)=''',lower(planguage),''' and lf.compname=''x__headtext'' 		
	where axpflds.tstruct=','''',ptransid,''' and savevalue =''T'' 
	union all
	select a.name,coalesce(lf.compcaption,t.caption),key,coalesce(l.compcaption,title),	''button'',null,null,''F'',	concat(script, ''~'', icon),''F'',null,null,null,null,null,null,null,''F'' subentity,1,null,
	null,null,null,ordno,null,''F'',''F'',null encrypted,null masking,null lastcharmask,null firstcharmask,null maskchar,null maskroles,null customdecimal
	from axtoolbar a join tstructs t on a.name = t.name
	left join axlanguage l on substring(l.sname FROM 2)= t.name and lower(l.dispname)=''',lower(planguage),''' and a.key = l.compname
	left join axlanguage lf on substring(lf.sname FROM 2)= t.name and lower(lf.dispname)=''',lower(planguage),''' and lf.compname=''x__headtext''
	where visible = ''true'' and script is not null and a.name= ','''',ptransid,'''','
	union all 
	select t.name transid,coalesce(lf.compcaption,t.caption) formcap, ''app_desc'' ,''Workflow status'' fcap,
	null cdatatype,''c'' dt,null modeofentry,
	''F'' fhide,null props,''F'' srckey ,null srctf ,null srcfld ,null srctrans ,''T'' allowempty,
	''Text'' filtercnd,
	''F'' grpfld,
	''F'' aggfld,''F'' subentity,1 datacnd,null entityrelfld,''T'' allowduplicate,d.tablename,
	dname,1000,d.caption dccaption,d.asgrid,case when d.asgrid=''F'' then ''T'' else ''F'' end listingfld,
	''F'' encrypted,null masking,null lastcharmask,null firstcharmask,null maskchar,null maskroles,null customdecimal
	from axattachworkflow a join tstructs t on a.transid = t.name 		
	join axpdc d on a.transid = d.tstruct and d.dname =''dc1''
	left join axlanguage lf on substring(lf.sname FROM 2)= t.name and lower(lf.dispname)=''',lower(planguage),''' and lf.compname=''x__headtext'' 		
	where t.name=','''',ptransid,'''') into v_sql;

	for r in execute v_sql
		loop	    	
			RETURN NEXT r; -- return current row of select
		END LOOP;	
	

if psubentity ='T' then		

    FOR rec IN
        select distinct a.dstruct,a.rtype,dprimarytable  from axentityrelations a 		
		where rtype in('md','custom','gm') and mstruct = ptransid 
   	loop		
	


select concat('select distinct axpflds.tstruct transid,coalesce(lf.compcaption,t.caption) formcap, fname ,coalesce(l.compcaption,axpflds.caption) fcap,customdatatype cdatatype,"datatype" dt,modeofentry ,hidden fhide,
		cast(null as varchar) props,srckey ,srctf ,srcfld ,srctrans ,axpflds.allowempty,
		case when modeofentry =''select'' then case when srckey =''T'' then ''Dropdown'' else ''Text'' end else ''Text'' end::varchar filtercnd,
		case when modeofentry =''select'' then ''T'' else ''F'' end::varchar grpfld,
		case when "datatype" =''n'' then ''T'' else ''F'' end::varchar aggfld,''T'' subentity,2 datacnd,
		r.mfield entityrelfld,
		allowduplicate,axpflds.tablename,dcname,ordno,d.caption,d.asgrid,case when d.asgrid=''F'' then ''T'' else ''F'' end listingfld,
		encrypted,masking,lastcharmask,firstcharmask,maskchar,maskroles,customdecimal	
		from axpflds join tstructs t on axpflds.tstruct = t.name join axpdc d on axpflds.tstruct = d.tstruct and axpflds.dcname = d.dname
		left join axentityrelations r on axpflds.tstruct = r.dstruct and axpflds.fname = r.dfield and r.mstruct=''',ptransid,'''
		left join axlanguage l on substring(l.sname FROM 2)=''',rec.dstruct,''' and lower(l.dispname)=''',lower(planguage),''' and axpflds.fname = l.compname
		left join axlanguage lf on substring(lf.sname FROM 2)= t.name and lower(lf.dispname)=''',lower(planguage),''' and lf.compname=''x__headtext''		
		where axpflds.tstruct=','''',rec.dstruct,''' and savevalue =''T'' 
		union all select ','''',rec.dstruct,''',null,''sourceid'',''sourceid'',''Simple Text'',''c'',''accept'',''T'',
		null,''F'',null,null,null,''F'',null,''F'',''F'',''T'',2,''recordid'',''T'',','''',rec.dprimarytable,'''',',null,1000,null,''F'',''F'',
		null encrypted,null masking,null lastcharmask,null firstcharmask,null maskchar,null maskroles,null customdecimal
		from dual where ''gm''=','''',rec.rtype,''' 
		union all
		','select distinct t.name transid,coalesce(lf.compcaption,t.caption) formcap, ''app_desc'' ,''Workflow status'' fcap,null cdatatype,''c'' dt,null modeofentry ,''F'' fhide,
		null props,''F'' srckey ,null srctf ,null srcfld ,null srctrans ,''T'' allowempty,
		''Text'' filtercnd,''F'' grpfld,''F'' ,''T'' subentity,2 datacnd,
		null entityrelfld,''T'' allowduplicate,d.tablename,d.dname,1000,d.caption,d.asgrid,
		''T'' listingfld,''F'' encrypted,null masking,null lastcharmask,null firstcharmask,null maskchar,null maskroles,null customdecimal	
		from axattachworkflow a join tstructs t on a.transid = t.name 		
		join axpdc d on a.transid = d.tstruct and d.dname =''dc1''		
		left join axlanguage lf on substring(lf.sname FROM 2)= t.name and lower(lf.dispname)=''',lower(planguage),''' and lf.compname=''x__headtext''		
		where t.name=','''',rec.dstruct,'''') into v_subentitysql;


	   	

	    for r in execute v_subentitysql
      		loop	    	
        		RETURN NEXT r; -- return current row of select        		
        	END LOOP;


    END LOOP;


end if;

END; $function$
;
>>

<<

-- DROP FUNCTION fn_axpanalytics_se_listdata(varchar, text, numeric, numeric);

CREATE OR REPLACE FUNCTION fn_axpanalytics_se_listdata(pentity_transid character varying, pflds_keyval text, ppagesize numeric DEFAULT 50, ppageno numeric DEFAULT 1)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
rec record;
rec1 record;
rec2 record;
v_sql text;
v_sql1 text;
v_fldname_table varchar;
v_fldname_col varchar;
v_fldname_normalized varchar;
v_fldname_srctbl varchar;
v_fldname_srcfld varchar;
v_fldname_allowempty varchar;
v_fldname_transidcnd numeric;
v_allflds varchar;
v_fldnamesary varchar[] DEFAULT  ARRAY[]::varchar[];
v_fldname_join varchar;
v_fldname_tblflds text;
v_fldname_joinsary varchar[] DEFAULT  ARRAY[]::varchar[];
v_emptyary varchar[] DEFAULT  ARRAY[]::varchar[];
v_pflds_transid varchar;
v_pflds_flds varchar;
v_pflds_keyvalue varchar;
v_pflds_keytable varchar;
v_keyvalue_fname varchar;
v_keyvalue_fvalue varchar;
v_keyvalue_fname_srckey varchar;
v_keyvalue_fname_srctbl varchar;
v_keyvalue_fname_srcfld varchar;
v_final_sqls text[] DEFAULT  ARRAY[]::text[];
v_primarydctable varchar;
v_fldname_dcjoinsary varchar[] DEFAULT  ARRAY[]::varchar[];

begin	

	/*
	 * transid=fldlist=dependfld~depvalue~dependtblname~dependfldprops++transid2=fldlist=dependfld~depvalue
	 * pflds_keyval - transid=tablename!~fldname~normalized~source_table~source_fld~allowempty|fldname2~normalized~source_table~source_fld~allowempty^tablename2!~fldname~normalized~srctbl~srcfld~allowempty=dependfld~dependval++
	 * transid2=tablename!~fldname~normalized~source_table~source_fld~allowempty|fldname2~normalized~source_table~source_fld~allowempty=dependfld~dependval		 
	 */
	
	
	FOR rec in select unnest(string_to_array(pflds_keyval,'++')) fldkeyvals ---- multiple transid split   	 
    loop
	    	
	    	v_pflds_transid := split_part(rec.fldkeyvals,'=',1) ;	    	
	    	v_pflds_flds := split_part(rec.fldkeyvals,'=',2) ;--tablename=~fldname~normalized~source_table~source_fld~mandatory|fldname2~normalized~source_table~source_fld~mandatory^tablename2=~fldname~normalized~srctbl~srcfld~mandatory
	    	v_pflds_keyvalue := split_part(rec.fldkeyvals,'=',3) ;
	    	v_pflds_keytable := split_part(v_pflds_keyvalue,'~',3) ;  	    
			v_keyvalue_fname := split_part(v_pflds_keyvalue,'~',1);
			v_keyvalue_fvalue := split_part(v_pflds_keyvalue,'~',2);		
			v_keyvalue_fname_srckey := split_part(v_pflds_keyvalue,'~',4) ;
			v_keyvalue_fname_srctbl := split_part(v_pflds_keyvalue,'~',5) ;
			v_keyvalue_fname_srcfld := split_part(v_pflds_keyvalue,'~',6) ;		
						
	    	

	    	select tablename into v_primarydctable from axpdc where tstruct =v_pflds_transid and dname ='dc1';
	    
	    	select count(1) into v_fldname_transidcnd from axpflds where tstruct = v_pflds_transid and dcname ='dc1' and lower(fname)='transid';
	    	    	    
	    
	    	if lower(v_pflds_keytable) = lower(v_primarydctable) and v_pflds_flds ='All' then
		    	select concat(tablename ,'!~',string_agg(str,'|'))  into v_allflds From(
				select tablename,concat(fname,'~',srckey,'~',srctf,'~',srcfld,'~',allowempty) str
				from axpflds where tstruct=v_pflds_transid and 
				dcname ='dc1' and 
				asgrid ='F' and hidden ='F' and savevalue='T' and datatype not in('i','t')
				order by dcname ,ordno)a group by a.tablename;
			elsif lower(v_pflds_keytable) != lower(v_primarydctable) and v_pflds_flds ='All' then
				select concat(tablename ,'!~',string_agg(str,'|'),'^',v_pflds_keytable,'!~',split_part(split_part(v_pflds_keyvalue,'~',1),'.',2),'~',split_part(v_pflds_keyvalue,'~',4),'~',split_part(v_pflds_keyvalue,'~',5),'~',split_part(v_pflds_keyvalue,'~',6),'~',split_part(v_pflds_keyvalue,'~',7))  into v_allflds From(
				select tablename,concat(fname,'~',srckey,'~',srctf,'~',srcfld,'~',allowempty) str
				from axpflds where tstruct=v_pflds_transid and 
				dcname ='dc1' and 
				asgrid ='F' and hidden ='F' and savevalue='T' and datatype not in('i','t')
				order by dcname ,ordno)a group by a.tablename;				
		    end if;
	    
	    for rec1 in select unnest(string_to_array(case when v_pflds_flds='All' then v_allflds else v_pflds_flds end,'^')) tblflds --single transid & single table split --tablename=~fldname~normalized~source_table~source_fld~mandatory|fldname2~normalized~source_table~source_fld~mandatory 
	    	loop		    			    			    			     
		    		v_fldname_table := 	split_part(rec1.tblflds,'!~',1);
		    		v_fldname_tblflds := 	split_part(rec1.tblflds,'!~',2);
		    		
		    	if lower(v_fldname_table)!=lower(v_primarydctable) then
					v_fldname_dcjoinsary := array_append(v_fldname_dcjoinsary,concat('left join ',v_fldname_table,' on ',v_primarydctable,'.',v_primarydctable,'id=',v_fldname_table,'.',v_primarydctable,'id') );		    							
				end if;
		    
				if lower(v_fldname_table)!=lower(v_pflds_keytable) then
					v_fldname_dcjoinsary := array_append(v_fldname_dcjoinsary,concat('left join ',v_pflds_keytable,' on ',v_primarydctable,'.',v_primarydctable,'id=',v_pflds_keytable,'.',v_primarydctable,'id') );		    							
				end if;
				
					if v_keyvalue_fname_srckey='T' then 
							v_fldname_joinsary := array_append(v_fldname_joinsary,concat(' join ' ,v_keyvalue_fname_srctbl,' ',' on ',v_keyvalue_fname,' = ',v_keyvalue_fname_srctbl,'.',v_keyvalue_fname_srctbl,'id')::Varchar);
					
							end if;
							
		
		    			    	
			    FOR rec2 in			    	
    				select unnest(string_to_array(v_fldname_tblflds,'|')) fldname--tablename=~fldname~normalized~source_table~source_fld~mandatory
						loop							
							v_fldname_col := split_part(rec2.fldname,'~',1);
							v_fldname_normalized := split_part(rec2.fldname,'~',2);
							v_fldname_srctbl := split_part(rec2.fldname,'~',3);
							v_fldname_srcfld := split_part(rec2.fldname,'~',4);														
							v_fldname_allowempty := split_part(rec2.fldname,'~',5);
								
						
							
							
							
							if v_fldname_normalized ='F' and lower(v_fldname_col)!='app_desc' then 
								v_fldnamesary := array_append(v_fldnamesary,concat(v_fldname_table,'.',v_fldname_col)::varchar);
							elsif v_fldname_normalized ='F' and lower(v_fldname_col)='app_desc' then						
								v_fldnamesary:= array_append(v_fldnamesary,concat('case when length(',v_fldname_table,'.wkid)>2 then case ',v_fldname_table,'.app_desc when 0 then  ''Created''
												  when  1 then ''Approved''
												  when  2 then ''Review''
												  when  3 then ''Return''
												  when  4 then ''Approve''
												  when  5 then ''Rejected''
												  when  9 then ''Orphan'' end else null end app_desc'));
							elsif v_fldname_normalized ='T' then	
								v_fldnamesary := array_append(v_fldnamesary,concat(v_fldname_col,'.',v_fldname_srcfld,' ',v_fldname_col)::varchar);	
								
								v_fldname_joinsary := array_append(v_fldname_joinsary,concat(case when v_fldname_allowempty='F' then ' join ' else ' left join ' end,v_fldname_srctbl,' ',v_fldname_col,' on ',v_fldname_table,'.',v_fldname_col,' = ',v_fldname_col,'.',v_fldname_srctbl,'id')::Varchar);
							end if;								
												
						

						

			    		end loop;
		   end loop;
		  
		  v_fldname_dcjoinsary := ARRAY(SELECT DISTINCT UNNEST(v_fldname_dcjoinsary));	
		  v_fldname_joinsary := ARRAY(SELECT DISTINCT UNNEST(v_fldname_joinsary));
		
		   
		   	v_sql := concat(' select ','''',v_pflds_transid,''' transid,',v_primarydctable,'.',v_primarydctable,'id recordid,',v_primarydctable,'.username modifiedby,',v_primarydctable,'.modifiedon,',v_primarydctable,'.createdon,',v_primarydctable,'.createdby,',
		   			 array_to_string(v_fldnamesary,','),',null axpeg_processname,null axpeg_keyvalue,null axpeg_status,null axpeg_statustext from ',v_primarydctable,' ',array_to_string(v_fldname_dcjoinsary,' '),' ',array_to_string(v_fldname_joinsary,' '),
					' where ',v_primarydctable,'.cancel=''F'' and ',case when v_fldname_transidcnd>0 then concat(v_primarydctable,'.transid=','''',v_pflds_transid,''' and ') end ,
					case when v_keyvalue_fname_srckey='T'  then v_keyvalue_fname_srctbl||'.'||v_keyvalue_fname_srcfld else v_keyvalue_fname end ,'=',v_keyvalue_fvalue,'
					--axp_filter
					');

		   				v_fldnamesary:= v_emptyary;
		   				v_fldname_joinsary:= v_emptyary;	   				
		   				v_fldname_dcjoinsary:= v_emptyary;	   				
	 
	    
	    
	   v_sql1 := concat('select * from(select a.*,row_number() over(order by modifiedon desc)::Numeric rno,
			case when mod(row_number() over(order by modifiedon desc),',ppagesize,')=0 then row_number() over(order by modifiedon desc)/',ppagesize,' else row_number() over(order by modifiedon desc)/',ppagesize,'+1 end::numeric pageno from 
			(',v_sql,')a order by modifiedon desc limit ',ppagesize*ppageno,' )b ',case when ppageno=0 then '' else concat('where pageno=',ppageno) end);
		
		
		
v_final_sqls := array_append(v_final_sqls,v_sql1);

    END LOOP;
  
    return array_to_string(v_final_sqls,'^^^') ;

END;
$function$
;

>>