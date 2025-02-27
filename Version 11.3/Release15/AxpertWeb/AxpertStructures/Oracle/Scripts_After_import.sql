<<

CREATE OR REPLACE FUNCTION fn_axpanalytics_ap_charts(pentity_transid varchar2, pcriteria varchar2, pfilter varchar2, pusername varchar2 DEFAULT 'admin', papplydac varchar2 DEFAULT 'T')
RETURN SYS.ODCIVARCHAR2LIST
IS
v_primarydctable varchar2(100);
v_subentitytable varchar2(100);
v_transid varchar2(10);
v_grpfld varchar2(100);
v_aggfld varchar2(100);
v_aggfnc varchar2(100);
v_srckey varchar2(100);
v_srctbl varchar2(100);
v_srcfld varchar2(100);
v_aempty varchar2(10);
v_aggfldtable varchar2(100);
v_sql clob;
v_normalizedjoin varchar2(2000);
v_keyname varchar2(100);
v_entitycond varchar2(100);
v_keyfld_fname varchar2(100);
v_keyfld_fval varchar2(4000);
v_final_sqls SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_fldname_transidcnd number;
v_sql1 clob;
v_filter_srcfld varchar2(100);
v_filter_srctxt varchar2(100);
v_filter_join varchar2(4000);
v_filter_joinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_filter_cnd varchar2(100);
v_filter_cndary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_filter_joinreq number;
v_filter_dcjoinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_filter_col varchar2(1000);
v_filter_normalized varchar2(4000);
v_filter_sourcetbl varchar2(100);
v_filter_sourcefld varchar2(100);
v_filter_datatype varchar2(100);
v_filter_listedfld varchar2(10);
v_filter_tablename varchar2(100);
v_emptyary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_grpfld_tbl varchar2(100);
v_grpfld_tablejoins varchar2(4000);
v_aggfld_tablejoins varchar2(4000);
v_tablejoins varchar2(4000);
v_aggfldtransid varchar2(10);
v_aggfld_primarydctable varchar2(100);
v_entityrelation varchar2(4000);
v_aggfldname_transidcnd numeric;
v_entity_parent_reltable varchar2(100);
v_entity_child_reltable varchar2(100);
v_filter_dcjoinuniq varchar2(4000);
v_dacenabled number;
v_dactype number;
v_dac_join varchar2(4000);
v_dac_joinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_dac_cnd varchar2(4000);
v_dac_cndary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_dac_joinreq number;
v_dac_normalizedjoinreq number; 
v_tablenames SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
begin

	/*	  
	 * pcriteria_v1 - transid~aggfnc~groupfld~normalized~srctable~srcfld~allowempty~grpfld_tablename~aggfld~aggfld_tablename(Not in use)	 
	 * pcriteria_v2 - aggfnc~grpfld_transid~groupfld~normalized~srctable~srcfld~allowempty~grpfld_tablename~aggfld_transid~aggfld~aggfld_tablename~grpfld_transid_AND_aggfld_transid_relation
	 * Ex1(agg fld in Non grid dc) - sum~gcust~party_name~F~~~~mg_partyhdr~slord~total_discount~salesorder_header~mg_partyhdr.mg_partyhdrid = salesorder_header.customer
	 * Ex2(agg fld in grid dc) - sum~gcust~party_name~F~~~~mg_partyhdr~slord~taxableamount~salesorder_items~mg_partyhdr.mg_partyhdrid = salesorder_header.customer

	*/ 	 
	
	
	select lower(trim(tablename)) into v_primarydctable from axpdc where tstruct = pentity_transid and dname ='dc1';

	v_tablenames.Extend;
	v_tablenames(v_tablenames.COUNT) := v_primarydctable;
	
	select count(1) into v_fldname_transidcnd from axpflds where tstruct = pentity_transid and lower(tablename)=lower(v_primarydctable) and lower(fname)='transid';	
	

	IF papplydac ='T' then
		select sum(cnt),sum(appl) into v_dacenabled,v_dactype from
		(select count(*) cnt,2 appl from axpdef_dac_config a  
		where a.uname = pusername and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
		having count(*) > 0
		union all
		select count(*),1 appl from axpdef_dac_config a  join axuserlevelgroups a2 on a.urole = a2.usergroup 
		where a2.username = pusername and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
		and ((a2.startdate is not null and current_date  >= startdate) or (startdate is null)) 
		and ((enddate is not null and current_date  <= enddate) or (enddate is null))
		having count(*) > 0
		)a
		where 'T' = papplydac;
	END IF;

	
	    FOR rec IN(SELECT column_value criteria  from table(string_to_array(pcriteria,'^')))  
    	    -----aggfnc~grpfld_transid~groupfld~normalized~srctable~srcfld~allowempty~grpfld_tablename~aggfld_transid~aggfld~aggfld_tablename~grpfld_transid_AND_aggfld_transid_relation
		    loop
			    	
			    v_aggfnc := split_part(rec.criteria,'~',1);---- agg function
			    v_transid := split_part(rec.criteria,'~',2);---grpfld_transid  			    
		    	v_grpfld := split_part(rec.criteria,'~',3);---grpfld_name
			    v_srckey := split_part(rec.criteria,'~',4);---normalized_grpfld_flag
	   			v_srctbl := split_part(rec.criteria,'~',5);---normalied_source table	   			
		   		v_srcfld := split_part(rec.criteria,'~',6);---normalied_source field
			   	v_aempty := split_part(rec.criteria,'~',7);---grpfld_allowempty - to franme left join or join
			    v_grpfld_tbl := lower(trim(split_part(rec.criteria,'~',8)));--grpfld_tablename
			    v_aggfldtransid :=split_part(rec.criteria,'~',9);--aggfld_transid;
				v_aggfld := case when split_part(rec.criteria,'~',10)='count' then '1' else split_part(rec.criteria,'~',10) end;				
				v_aggfldtable := lower(trim(split_part(rec.criteria,'~',11)));---aggfld_tablename
				v_entityrelation := split_part(rec.criteria,'~',12);---grpfld_transid_aggfld_transid_relation
				v_entity_parent_reltable := lower(trim(split_part(split_part(v_entityrelation,'=',1),'.',1)));
				v_entity_child_reltable := lower(trim(split_part(split_part(v_entityrelation,'=',2),'.',1)));
				
				
				v_normalizedjoin := case when v_srckey='T' then ' left join '||v_srctbl||' b on '||v_grpfld_tbl||'.'||v_grpfld||' = b.'||v_srctbl||'id ' else ' ' end;
				v_keyname := case when length(v_grpfld) > 0 then case when v_srckey='T' then 'b.'||v_srcfld else v_grpfld_tbl||'.'||v_grpfld end else ' ' end;			
			
				v_tablenames.Extend;
				v_tablenames(v_tablenames.COUNT) := case when v_srckey='T' then  v_srctbl end;
				
				v_tablenames.Extend;				
				v_tablenames(v_tablenames.COUNT) := case when v_srckey='T' then  v_grpfld_tbl end;
			
				v_tablenames.Extend;
				v_tablenames(v_tablenames.COUNT) := v_aggfldtable;
			
			
			if v_transid = v_aggfldtransid then
			
				if lower(v_aggfldtable)=lower(v_primarydctable) and lower(v_grpfld_tbl)=lower(v_primarydctable) then
					v_tablejoins := v_primarydctable;								   			   									
				elsif lower(v_grpfld_tbl) != lower(v_primarydctable) and lower(v_aggfldtable)=lower(v_primarydctable) then
					v_tablejoins := v_primarydctable||' left join '||v_grpfld_tbl||' on '||v_grpfld_tbl||'.'||v_primarydctable||'id='||v_primarydctable||'.'||v_primarydctable||'id';
				elsif lower(v_aggfldtable) != lower(v_primarydctable) and lower(v_grpfld_tbl)=lower(v_primarydctable) then
					v_tablejoins := v_primarydctable||' left join '||v_aggfldtable||' on '||v_aggfldtable||'.'||v_primarydctable||'id='||v_primarydctable||'.'||v_primarydctable||'id';
				elsif lower(v_aggfldtable) != lower(v_primarydctable) and lower(v_grpfld_tbl)=lower(v_aggfldtable) then
					v_tablejoins := v_primarydctable||' left join '||v_aggfldtable||' on '||v_aggfldtable||'.'||v_primarydctable||'id='||v_primarydctable||'.'||v_primarydctable||'id';
				elsif lower(v_aggfldtable) != lower(v_primarydctable) and lower(v_grpfld_tbl)!=lower(v_aggfldtable) then
					v_tablejoins := v_primarydctable||' left join '||v_aggfldtable||' on '||v_aggfldtable||'.'||v_primarydctable||'id='||v_primarydctable||'.'||v_primarydctable||'id left join '||v_grpfld_tbl||' on '||v_grpfld_tbl||'.'||v_primarydctable||'id='||v_primarydctable||'.'||v_primarydctable||'id';
				end if;	----------------- v_tablejoins																						
			
			elsif v_transid != v_aggfldtransid then
				select lower(trim(tablename)) into v_aggfld_primarydctable from axpdc where tstruct = v_aggfldtransid and dname ='dc1';	
			
				select count(1) into v_aggfldname_transidcnd from axpflds where tstruct = v_aggfldtransid and lower(tablename) = lower(v_aggfld_primarydctable) 
				and lower(fname)='transid';

				------------group field joins
				if lower(v_grpfld_tbl)=lower(v_primarydctable)  and lower(v_entity_parent_reltable)=lower(v_primarydctable) then 
					v_grpfld_tablejoins := v_grpfld_tbl;
				elsif lower(v_grpfld_tbl)!=lower(v_primarydctable) and lower(v_entity_parent_reltable)=lower(v_primarydctable) then 
					v_grpfld_tablejoins := v_primarydctable||' join '||v_grpfld_tbl||' on '||v_grpfld_tbl||'.'||v_primarydctable||'id='||v_primarydctable||'.'||v_primarydctable||'id';
				elsif lower(v_grpfld_tbl)=lower(v_primarydctable) and lower(v_entity_parent_reltable)!=lower(v_primarydctable) then 
					v_grpfld_tablejoins := v_primarydctable||' join '||v_entity_parent_reltable||' on '||v_entity_parent_reltable||'.'||v_primarydctable||'id='||v_primarydctable||'.'||v_primarydctable||'id';	
				elsif lower(v_grpfld_tbl)!=lower(v_primarydctable) and lower(v_entity_parent_reltable)!=lower(v_primarydctable) then
					v_grpfld_tablejoins := v_primarydctable||' join '||v_grpfld_tbl||' on '||v_grpfld_tbl||'.'||v_primarydctable||'id='||v_primarydctable||'.'||v_primarydctable||'id'
									||' join '||v_entity_parent_reltable||' on '||v_entity_parent_reltable||'.'||v_primarydctable||'id='||v_primarydctable||'.'||v_primarydctable||'id';
				end if;								
					
				--------------agg field joins	
				if lower(v_aggfldtable)=lower(v_aggfld_primarydctable)  and lower(v_entity_child_reltable)=lower(v_aggfld_primarydctable) then 
					v_aggfld_tablejoins := ' join '||v_aggfldtable||' on '||v_entityrelation;
				elsif lower(v_aggfldtable)!=lower(v_aggfld_primarydctable) and lower(v_entity_child_reltable)=lower(v_aggfld_primarydctable) then 
					v_aggfld_tablejoins := ' join '||v_entity_child_reltable||' on '||v_entityrelation||' join '||v_aggfldtable||' on '||v_aggfldtable||'.'||v_aggfld_primarydctable||'id='||v_aggfld_primarydctable||'.'||v_aggfld_primarydctable||'id';
				elsif lower(v_aggfldtable)=lower(v_aggfld_primarydctable) and lower(v_entity_child_reltable)!=lower(v_aggfld_primarydctable) then 
					v_aggfld_tablejoins := ' join '||v_entity_child_reltable||' on '||v_entityrelation||' join '||v_aggfld_primarydctable||' on '||v_aggfld_primarydctable||'.'||v_aggfld_primarydctable||'id='||v_entity_child_reltable||'.'||v_aggfld_primarydctable||'id';	
				elsif lower(v_aggfldtable)!=lower(v_aggfld_primarydctable) and lower(v_entity_child_reltable)!=lower(v_aggfld_primarydctable) then
					v_aggfld_tablejoins := ' join '||v_entity_child_reltable||' on '||v_entityrelation||' join '||v_aggfld_primarydctable||' on '||v_aggfld_primarydctable||'.'||v_aggfld_primarydctable||'id='||v_entity_child_reltable||'.'||v_aggfld_primarydctable||'id'||
											' join '||v_aggfldtable||' on '||v_aggfldtable||'.'||v_aggfld_primarydctable||'id='||v_aggfld_primarydctable||'.'||v_aggfld_primarydctable||'id';									
				end if;											
				
				v_tablejoins := v_grpfld_tablejoins||' '||v_aggfld_tablejoins;
			
			end if; ------- v_transid = v_aggfldtransid
				
			
			
			select 'select '||v_keyname||' keyname,'||case when lower(trim(v_aggfnc)) in ('sum','avg') then 'round('||v_aggfnc||'('||v_aggfld||'),2)'else v_aggfnc||'('||v_aggfld||')' END||
			'keyvalue,'||''''||rec.criteria||''''||' criteria from '||v_tablejoins||' '||v_normalizedjoin into v_sql FROM dual;
		
		
			 if v_dacenabled > 0 then
				for dacrec in 			   
					(select fname,tablename,srckey,srctf,srcfld,
					case when filtercnd in('like','not like') then case when isglovar='F' then '''%'||attribvalue||'%''' else 
					case when lower(trim(attribvalue))=':username' then  '''%'||pusername||'%''' else '''%''||'||attribvalue||'||''%''' end end
					when filtercnd in('in','not in') then case when isglovar='F' then ''''||replace(attribvalue,',',''',''')||'''' else case when lower(trim(attribvalue))=':username' then  ''''||pusername||'''' else attribvalue end end
					when filtercnd in('=','!=','>','<') then case when isglovar='F' then ''''||attribvalue||'''' else case when lower(trim(attribvalue))=':username' then  ''''||pusername||'''' else attribvalue end end  end cnd,
					ord,filtercnd  from
					(
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					f.fname,f.tablename,1 ord, b.filtercnd,b.isglovar,f.srckey,f.srctf,f.srcfld
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpflds f on a.stransid =f.tstruct and b.fldname = f.fname 
					where a.uname = pusername  and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
					and a.dataaccesscnd = 30 and v_dactype in(2,3)					
					union all			
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					b.fldname ,d.tablename,1 ord, b.filtercnd,b.isglovar,'F',null,null
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1' 
					where a.uname = pusername  and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
					and a.dataaccesscnd = 30 and b.fldname in('createdby','username')  and v_dactype in(2,3)
					union all		
					select  pusername attribvalue, 'createdby' ,d.tablename,1 ord,'='filtercnd,'F','F' srckey,null srctf, null srcfld
					from axpdef_dac_config a 
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1' 
					where a.uname = pusername and a.dataaccesscnd in (10,11,12) and a.stransid = pentity_transid 
					and a.editmode in('View','ViewEdit') and v_dactype in(2,3)					
					union all					
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					f.fname,f.tablename,2 ord, b.filtercnd,b.isglovar,f.srckey,f.srctf,f.srcfld
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpflds f on a.stransid =f.tstruct and b.fldname = f.fname 
					join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
					and u.username = pusername and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
					where a.dataaccesscnd =30 and v_dactype = 1
					union all
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					b.fldname,d.tablename,2 ord, b.filtercnd,b.isglovar,'F',null,null
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1'
					join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
					and u.username = pusername and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
					where a.dataaccesscnd =30 and v_dactype = 1	and  b.fldname in('createdby','username') 						
					union all
					select  pusername attribvalue, 'createdby' ,d.tablename,2 ord,'='filtercnd ,'F','F' srckey,null srctf, null srcfld
					from axpdef_dac_config a 
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1'
					join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
					and u.username = pusername and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
					where a.dataaccesscnd in (10,11,12) and v_dactype = 1
					)a
					order by ord)
					
					loop
						
						
						select count(1) into v_dac_joinreq from (
						select distinct column_value tbls from  table(v_tablenames))a 
						where lower(a.tbls)=lower(dacrec.tablename);	


						if dacrec.srckey ='T' then
							select count(1) into v_dac_normalizedjoinreq from (
							select distinct column_value tbls FROM table(v_tablenames))a 
							where lower(a.tbls)=lower(dacrec.srctf);	
						
							if v_dac_normalizedjoinreq = 0 then
								v_dac_joinsary.extend();
								v_dac_joinsary(v_dac_joinsary.COUNT) := ' join '||dacrec.srctf||' on '||dacrec.srctf||'.'||dacrec.srctf||'id='||dacrec.tablename||'.'||dacrec.fname;													
							end if;

						end if;		


	
							
						if v_dac_joinreq = 0 THEN
						v_dac_joinsary.extend();
						v_dac_joinsary(v_dac_joinsary.COUNT) := ' join '||dacrec.tablename||' on '||v_primarydctable||'.'||v_primarydctable||'id='||dacrec.tablename||'.'||v_primarydctable||'id';
						end if;							

						v_dac_cnd := case 
									 when dacrec.srckey='F' then  dacrec.tablename||'.'||dacrec.fname||' '||dacrec.filtercnd||'('|| case when dacrec.filtercnd in('in','not in') then 'SELECT REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) FROM dual CONNECT BY REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) IS NOT NULL' else dacrec.cnd	end||')'  
									 when 	dacrec.srckey='T' then  
									 case when v_dac_normalizedjoinreq = 0 then (dacrec.srctf||'.'||dacrec.srcfld||' '||dacrec.filtercnd||'('||case when dacrec.filtercnd in('in','not in') then 'SELECT REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) FROM dual CONNECT BY REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) IS NOT NULL' else dacrec.cnd	end	||')') 
									else (dacrec.fname||'.'||dacrec.srcfld||' '||dacrec.filtercnd||'('||case when dacrec.filtercnd in('in','not in') then 'SELECT REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) FROM dual CONNECT BY REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) IS NOT NULL' else dacrec.cnd	end	||')') end
									end;
					
						v_dac_cndary.extend();
						v_dac_cndary(v_dac_cndary.COUNT) := v_dac_cnd;									
					
					end loop;		
			   
			   
			   END IF;
																											
			
			
				if coalesce(pfilter,'NA') ='NA' then 
				
				
			v_sql1 := v_sql||array_to_string(v_dac_joinsary,' ')||' where '||v_primarydctable||'.cancel=''F'''
						||case when v_fldname_transidcnd > 0 then ' and '||v_primarydctable||'.transid='''||pentity_transid||'''' END
						||case when v_transid != v_aggfldtransid then ' and '||v_aggfld_primarydctable||'.cancel=''F''' END
						||case when v_aggfldname_transidcnd > 0 then ' and '||v_aggfld_primarydctable||'.transid='''||v_aggfldtransid||'''' END
						||case when v_dacenabled > 0 then concat(' and ',array_to_string(v_dac_cndary,' and ')) end
						||case when length(v_grpfld) > 0 then ' group by '||v_keyname else '' end;
	
		else 
			FOR rec_filters IN(select column_value ifilter FROM table(string_to_array(pfilter,'^'))  )
			    loop		    	
			    	v_filter_srcfld := split_part(rec_filters.ifilter,'|',1);
			    	v_filter_srctxt := split_part(rec_filters.ifilter,'|',2);
			    	v_filter_col := split_part(v_filter_srcfld,'~',1);
				    v_filter_normalized := split_part(v_filter_srcfld,'~',2);
 				    v_filter_sourcetbl := split_part(v_filter_srcfld,'~',3);
 				    v_filter_sourcefld := split_part(v_filter_srcfld,'~',4);
					v_filter_datatype := split_part(v_filter_srcfld,'~',5);
					v_filter_listedfld :=split_part(v_filter_srcfld,'~',6);
					v_filter_tablename:=split_part(v_filter_srcfld,'~',7);
					
		
			    				    	
			    	if  v_filter_listedfld = 'F' then
			    	
					v_filter_joinreq := case when lower(v_aggfldtable)=lower(v_filter_tablename) then 1 else 0 end; 			    		
					
			    	if v_filter_joinreq = 0  then 
				    	v_filter_dcjoinsary.Extend;
				    	v_filter_dcjoinsary(v_filter_dcjoinsary.COUNT):= (' join '||v_filter_tablename||' on '||v_primarydctable||'.'||v_primarydctable||'id='||v_filter_tablename||'.'||v_primarydctable||'id');
			    	end if;
			    
			    	
			    
		    		select case when v_filter_normalized='T' 
					then ' join '||v_filter_sourcetbl||' '||v_filter_col||' on '||v_filter_tablename||'.'||v_filter_col||' = '||v_filter_col||'.'||v_filter_sourcetbl||'id'
					end into v_filter_join from dual where v_filter_normalized='T';
					
					 						
					v_filter_dcjoinsary.Extend;
					v_filter_dcjoinsary(v_filter_dcjoinsary.COUNT):=(v_filter_join);
					
				
					end if;
			
									
					select case when v_filter_normalized='F' 
					then case when v_filter_datatype='c' then 'lower(' END||v_filter_tablename||'.'||v_filter_col||case when v_filter_datatype='c' then ')' END||' '||v_filter_srctxt 
					else case when v_filter_datatype='c' then 'lower(' END||v_filter_col||'.'||v_filter_sourcefld||case when v_filter_datatype='c' then ')' END||' '||v_filter_srctxt 
					end into v_filter_cnd FROM dual;
		    										
					v_filter_cndary.Extend;
					v_filter_cndary(v_filter_cndary.COUNT):=(v_filter_cnd);				
					
			    end loop;
			   	
			   	SELECT listagg(column_value,' ') WITHIN group(ORDER BY 1) INTO v_filter_dcjoinuniq from(select distinct column_value from   table(v_filter_dcjoinsary));
			   			   	
			   
				v_sql1 := v_sql||array_to_string(v_filter_dcjoinsary,' ')||array_to_string(v_filter_joinsary,' ')||array_to_string(v_dac_joinsary,' ')
						||' where '||v_primarydctable||'.cancel=''F'''
						||case when v_fldname_transidcnd > 0 then ' and '||v_primarydctable||'.transid='''||pentity_transid||''' and ' END
						||case when v_transid != v_aggfldtransid then v_aggfld_primarydctable||'.cancel=''F''' END
						||case when v_aggfldname_transidcnd > 0 then ' and '||v_aggfld_primarydctable||'.transid='''||v_aggfldtransid||'''' END
						||array_to_string(v_filter_cndary,' and ')
						||case when v_dacenabled > 0 then concat(' and ',array_to_string(v_dac_cndary,' and ')) end
						||case when length(v_grpfld) > 0 then ' group by '||v_keyname else '' end;					    						
		end if;
			
			v_final_sqls.Extend;
			v_final_sqls(v_final_sqls.COUNT):=(v_sql1);				
			v_filter_cndary:= v_emptyary;
			
	    	END LOOP;
	      	

   return v_final_sqls ;
END;

>>

<<

CREATE OR REPLACE FUNCTION fn_axpanalytics_chartdata(psource in varchar2, pentity_transid in varchar2, pcondition in varchar2, pcriteria in varchar2,pfilter clob DEFAULT 'NA', pusername varchar2 DEFAULT 'admin', papplydac varchar2 DEFAULT 'T' )
RETURN  SYS.ODCIVARCHAR2LIST
--RETURN clob
IS 
v_primarydctable varchar2(3000);
v_subentitytable varchar2(3000);
v_transid varchar2(3000);
v_grpfld varchar2(3000);
v_aggfld varchar2(3000);
v_aggfnc varchar2(3000);
v_srckey varchar2(3000);
v_srctbl varchar2(3000); 
v_srcfld varchar2(3000);
v_aempty varchar2(3000);
v_tablename varchar2(100);
v_sql clob;
v_normalizedjoin varchar2(3000);
v_keyname varchar2(3000);
v_entitycond varchar2(3000);
v_keyfld_fname varchar2(3000);
v_keyfld_fval varchar2(3000);  
v_keyfld_srckey varchar2(10);
v_keyfld_srctbl varchar2(50);
v_keyfld_srcfld varchar2(50);
v_final_sqls SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_fldname_transidcnd number;
v_sql1 clob;
v_filter_srcfld varchar2(200);
v_filter_srctxt varchar2(2000);
v_filter_join varchar2(2000);
v_filter_joinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_filter_cnd varchar2(2000);
v_filter_cndary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_filter_joinreq numeric;
v_filter_dcjoin varchar2(3000);
v_filter_dcjoinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_filter_dcjoinuniq varchar2(3000);
v_filter_col varchar2(2000);
v_filter_normalized varchar2(20); 
v_filter_sourcetbl varchar2(200);
v_filter_sourcefld varchar2(200);
v_filter_datatype varchar2(20);
v_filter_listedfld varchar2(20);
v_filter_tablename varchar2(200);
v_emptyary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_dacenabled numeric;
v_dactype numeric;
v_dac_join varchar2(4000);
v_dac_joinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_dac_cnd varchar2(4000);
v_dac_cndary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_dac_joinreq numeric;
v_dac_normalizedjoinreq numeric; 
v_jointables SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();

begin

	/*
	 * psource - Entity / Subentity	
	 *  pcriteria - transid~groupfld~aggfld~aggfnc~normalized~srctable~srcfld~allowempty~tablename~keyfld~keyval^
	 * transid~groupfld~aggfld~aggfnc~normalized~srctable~srcfld~allowempty~tablename~keyfld~keyval	 	 
	*/
	
	IF papplydac ='T' then
	select sum(cnt),sum(appl) into v_dacenabled,v_dactype from
	(select count(*) cnt,2 appl from axpdef_dac_config a  
	where a.uname = pusername and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
	having count(*) > 0
	union all
	select count(*),1 appl from axpdef_dac_config a  join axuserlevelgroups a2 on a.urole = a2.usergroup 
	where a2.username = pusername and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
	and ((a2.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
	having count(*) > 0
	)a
	where 'T' = papplydac;
END IF;

	select tablename into v_primarydctable from axpdc where tstruct = pentity_transid and dname ='dc1';
	
	v_jointables.extend();
	v_jointables(v_jointables.COUNT) := v_primarydctable;
	
	if pcondition ='Custom' THEN
		select count(1) into v_fldname_transidcnd from axpflds where tstruct = pentity_transid and dcname ='dc1' and lower(fname)='transid';
	    FOR rec IN
    	    (select column_value as criteria from table(string_to_array(pcriteria,'^')) )
		    loop		    			    
			    v_transid := split_part(rec.criteria,'~',1);
		    	v_grpfld := split_part(rec.criteria,'~',2);
				v_aggfld := case when split_part(rec.criteria,'~',3)='count' then '1' else split_part(rec.criteria,'~',3) end;
				v_aggfnc := split_part(rec.criteria,'~',4);
				v_srckey := split_part(rec.criteria,'~',5);
				v_srctbl := split_part(rec.criteria,'~',6);
				v_srcfld := split_part(rec.criteria,'~',7);
				v_aempty := split_part(rec.criteria,'~',8);
				v_tablename := split_part(rec.criteria,'~',9);
				v_keyfld_fname := split_part(rec.criteria,'~',10);
				v_keyfld_fval := split_part(rec.criteria,'~',11);
				v_normalizedjoin := case when v_srckey='T' then (' left join '||v_srctbl||' b on '||v_primarydctable||'.'||v_grpfld||' = b.'||v_srctbl||'id ') else ' ' end;
				v_keyname := case when length(v_grpfld) > 0 then case when v_srckey='T' then ('b.'||v_srcfld) else (v_primarydctable||'.'||v_grpfld) end else 'null' end;			
			
				v_jointables.extend();
				v_jointables(v_jointables.COUNT) := case when v_srckey='T' then v_srctbl end;	
	
				

	
                	if lower(v_tablename)=lower(v_primarydctable) then
		                v_sql := ('select '||' '||v_keyname||' keyname,'||case when lower(trim(v_aggfnc)) in ('sum','avg') then 'round('||v_aggfnc||'('||v_aggfld||'),2)'else v_aggfnc||'('||v_aggfld||')' END||' keyvalue,'||'''Custom'''||' '||'cnd,'''||replace(rec.criteria,'''','')||''' criteria from '||
						v_primarydctable||' '||v_normalizedjoin);	
						v_jointables.extend();
						v_jointables(v_jointables.COUNT) := v_tablename;
                	ELSE
                	 	v_sql := ('select '||' '||v_keyname||' keyname,'||case when lower(trim(v_aggfnc)) in ('sum','avg') then 'round('||v_aggfnc||'('||v_aggfld||'),2)'else v_aggfnc||'('||v_aggfld||')' end||' keyvalue,'||'''Custom'''||' '||'cnd,'''||replace(rec.criteria,'''','')||''' criteria from '||
						v_primarydctable||' join '||v_tablename||' on '||v_primarydctable||'.'||v_primarydctable||'.id='||v_tablename||'.'||v_primarydctable||'id '||v_normalizedjoin);
						v_jointables.extend();
						v_jointables(v_jointables.COUNT) := v_tablename;
                	END IF;
                
                ---------DAC filters
			   if v_dacenabled > 0 then
				for dacrec in 			   
					(select fname,tablename,srckey,srctf,srcfld,
					case when filtercnd in('like','not like') then case when isglovar='F' then '''%'||attribvalue||'%''' else 
					case when lower(trim(attribvalue))=':username' then  '''%'||pusername||'%''' else '''%''||'||attribvalue||'||''%''' end end
					when filtercnd in('in','not in') then case when isglovar='F' then ''''||replace(attribvalue,',',''',''')||'''' else case when lower(trim(attribvalue))=':username' then  ''''||pusername||'''' else attribvalue end end
					when filtercnd in('=','!=','>','<') then case when isglovar='F' then ''''||attribvalue||'''' else case when lower(trim(attribvalue))=':username' then  ''''||pusername||'''' else attribvalue end end  end cnd,
					ord,filtercnd  from
					(
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					f.fname,f.tablename,1 ord, b.filtercnd,b.isglovar,f.srckey,f.srctf,f.srcfld
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpflds f on a.stransid =f.tstruct and b.fldname = f.fname 
					where a.uname = pusername  and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
					and a.dataaccesscnd = 30 and v_dactype in(2,3)					
					union all			
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					b.fldname ,d.tablename,1 ord, b.filtercnd,b.isglovar,'F',null,null
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1' 
					where a.uname = pusername  and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
					and a.dataaccesscnd = 30 and b.fldname in('createdby','username')  and v_dactype in(2,3)
					union all		
					select  pusername attribvalue, 'createdby' ,d.tablename,1 ord,'='filtercnd,'F','F' srckey,null srctf, null srcfld
					from axpdef_dac_config a 
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1' 
					where a.uname = pusername and a.dataaccesscnd in (10,11,12) and a.stransid = pentity_transid 
					and a.editmode in('View','ViewEdit') and v_dactype in(2,3)					
					union all					
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					f.fname,f.tablename,2 ord, b.filtercnd,b.isglovar,f.srckey,f.srctf,f.srcfld
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpflds f on a.stransid =f.tstruct and b.fldname = f.fname 
					join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
					and u.username = pusername and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
					where a.dataaccesscnd =30 and v_dactype = 1
					union all
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					b.fldname,d.tablename,2 ord, b.filtercnd,b.isglovar,'F',null,null
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1'
					join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
					and u.username = pusername and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
					where a.dataaccesscnd =30 and v_dactype = 1	and  b.fldname in('createdby','username') 						
					union all
					select  pusername attribvalue, 'createdby' ,d.tablename,2 ord,'='filtercnd ,'F','F' srckey,null srctf, null srcfld
					from axpdef_dac_config a 
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1'
					join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
					and u.username = pusername and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
					where a.dataaccesscnd in (10,11,12) and v_dactype = 1
					)a
					order by ord)
					
					loop
						
						select count(1) into v_dac_joinreq from 
						(select distinct column_value tbls from  table(v_jointables))a 
						where trim(lower(a.tbls))=trim(lower(dacrec.tablename));
						
															
						if dacrec.srckey ='T' then					
							select count(1) into v_dac_normalizedjoinreq from (
							select distinct column_value tbls from  table(v_jointables))a 
							where lower(a.tbls)=lower(dacrec.srctf);
						
							if v_dac_normalizedjoinreq = 0 then
								v_dac_joinsary.extend();
								v_dac_joinsary(v_dac_joinsary.COUNT) := ' join '||dacrec.srctf||' on '||dacrec.srctf||'.'||dacrec.srctf||'id='||dacrec.tablename||'.'||dacrec.fname;
								v_jointables.extend();
								v_jointables(v_jointables.COUNT) := dacrec.srctf;
							end if;
						
						end if;		


						
	
							
						if v_dac_joinreq = 0 THEN
						v_dac_joinsary.extend();
						v_dac_joinsary(v_dac_joinsary.COUNT) := ' join '||dacrec.tablename||' on '||v_primarydctable||'.'||v_primarydctable||'id='||dacrec.tablename||'.'||v_primarydctable||'id' ;
						v_jointables.extend();
						v_jointables(v_jointables.COUNT) := dacrec.tablename;	
						end if;							

						v_dac_cnd := case 
									 when dacrec.srckey='F' then  dacrec.tablename||'.'||dacrec.fname||' '||dacrec.filtercnd||'('||case when dacrec.filtercnd in('in','not in') then 'SELECT REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) FROM dual CONNECT BY REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) IS NOT NULL' else dacrec.cnd	end		||')'  
									 when 	dacrec.srckey='T' then  dacrec.srctf||'.'||dacrec.srcfld||' '||dacrec.filtercnd||'('||case when dacrec.filtercnd in('in','not in') then 'SELECT REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) FROM dual CONNECT BY REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) IS NOT NULL' else dacrec.cnd	end		||')'
									 end;
					
						v_dac_cndary.extend();
						v_dac_cndary(v_dac_cndary.COUNT) := v_dac_cnd;									
					
					end loop;		
			   
			   
			  END IF; 
                
                if pfilter ='NA' then 

        v_sql1 := v_sql||'where '||v_primarydctable||'.cancel=''F'''||
        		CASE WHEN v_fldname_transidcnd > 0 THEN ' and '||v_primarydctable||'.transid='''||pentity_transid||'''' end||
        		case when v_dacenabled > 0 then ' and '||array_to_string(v_dac_cndary,' and ') ELSE ' ' end||
        		'
				  --axp_filter
				'||case when length(v_grpfld) > 0 then (' group by '||v_keyname) else '' END;
		else
			FOR rec_filters IN
    			(select column_value as ifilter from table(string_to_array(pfilter,'^')) )
			    loop		    	
			    	v_filter_srcfld := split_part(rec_filters.ifilter,'|',1); -- tstfm~empcode~F~~
			    	v_filter_srctxt := split_part(rec_filters.ifilter,'|',2);--   = 'EMP-001'
			    	v_filter_col := split_part(v_filter_srcfld,'~',1);
				    v_filter_normalized := split_part(v_filter_srcfld,'~',2);
 				    v_filter_sourcetbl := split_part(v_filter_srcfld,'~',3);
 				    v_filter_sourcefld := split_part(v_filter_srcfld,'~',4);
					v_filter_datatype := split_part(v_filter_srcfld,'~',5);
					v_filter_listedfld :=split_part(v_filter_srcfld,'~',6);
					v_filter_tablename:=split_part(v_filter_srcfld,'~',7);
					
			    if  v_filter_listedfld='F' then 
								    	
			    	v_filter_joinreq := case when lower(v_tablename)=lower(v_filter_tablename) then 1 else 0 end;
			    	
			    	if v_filter_joinreq = 0  then  
				    	v_filter_dcjoin := ' join '||v_filter_tablename||' on '||v_primarydctable||'.'||v_primarydctable||'id='||v_filter_tablename||'.'||v_primarydctable||'id';
				    	v_filter_dcjoinsary.EXTEND;
	                   	v_filter_dcjoinsary(v_filter_dcjoinsary.COUNT) := v_filter_dcjoin;
			    	end if;
			    				    		  	
                   	if v_filter_normalized='T' then  	
 		           		v_filter_join := (' join '||v_filter_sourcetbl||' '||v_filter_col||' on '||v_filter_tablename||'.'||v_filter_col||' = '||v_filter_col||'.'||v_filter_sourcetbl||'id');
        	    	   	v_filter_joinsary.EXTEND;
            	       	v_filter_joinsary(v_filter_joinsary.COUNT) := v_filter_join;
                  	end if;
                    
				END IF;
				if v_filter_normalized='F' then                    
                	v_filter_cnd := case when v_filter_datatype='c' then 'lower(' END ||(v_filter_tablename||'.'||v_filter_col||case when v_filter_datatype='c' then ')' end||' '||v_filter_srctxt) ;
                else 
                  	v_filter_cnd := case when v_filter_datatype='c' then 'lower(' END||(v_filter_col||'.'||v_filter_sourcefld||case when v_filter_datatype='c' then ')' end||' '||v_filter_srctxt) ;
                end if; 

                    v_filter_cndary.EXTEND;
                    v_filter_cndary(v_filter_cndary.COUNT) := v_filter_cnd;

			    end loop;
					
			   		SELECT listagg(column_value,' ') WITHIN group(ORDER BY 1) INTO v_filter_dcjoinuniq from(select distinct column_value from   table(v_filter_dcjoinsary));
			   		
                	 v_sql1 := v_sql||' '||v_filter_dcjoinuniq||' ' ||array_to_string(v_filter_joinsary,' ')||' where '||v_primarydctable||'.cancel=''F'' and '||
                           CASE WHEN v_fldname_transidcnd>0 THEN v_primarydctable||'.transid='''||pentity_transid||''' and 'END||
                           case when v_dacenabled > 0 then ' and '||array_to_string(v_dac_cndary,' and ') end||
                           '
							--axp_filter 
							'||array_to_string(v_filter_cndary,' and ')||case when length(v_grpfld) > 0 then (' group by '||v_keyname) else '' end;
				end if;


	                    v_final_sqls.EXTEND;
                         v_final_sqls(v_final_sqls.COUNT) := (v_sql1);
				
			
			v_filter_cndary:= v_emptyary;
			v_dac_cndary:= v_emptyary;
			v_dac_joinsary :=v_emptyary;
			v_jointables :=v_emptyary;
			
		end loop;


   elsif pcondition = 'General' then 

		if psource ='Entity' then    

			select count(1) into v_fldname_transidcnd from axpflds where tstruct = pentity_transid and dcname ='dc1' and lower(fname)='transid';
			
			v_sql:=	 ('select count(*) totrec,
				sum(case when EXTRACT(YEAR FROM createdon) = EXTRACT(YEAR FROM SYSDATE) then 1 else 0 end) cyear,
	            sum(case when EXTRACT(MONTH FROM createdon) = EXTRACT(MONTH FROM SYSDATE) then 1 else 0 end) cmonth,
	            sum(case when TO_NUMBER(TO_CHAR(createdon, ''IW'')) = TO_NUMBER(TO_CHAR(SYSDATE, ''IW''))  then 1 else 0 end) cweek,
	            sum(case when trunc('||v_primarydctable||'.createdon) = to_date(sysdate) - 1 then 1 else 0 end) cyesterday,
	            sum(case when trunc('||v_primarydctable||'.createdon) = to_date(sysdate) then 1 else 0 end) ctoday,''General'' cnd,null criteria 
				from '||v_primarydctable);				
	
				  ---------DAC filters
				   if v_dacenabled > 0 then
					for dacrec in 			   
						(select fname,tablename,srckey,srctf,srcfld,
						case when filtercnd in('like','not like') then case when isglovar='F' then '''%'||attribvalue||'%''' else 
						case when lower(trim(attribvalue))=':username' then  '''%'||pusername||'%''' else '''%''||'||attribvalue||'||''%''' end end
						when filtercnd in('in','not in') then case when isglovar='F' then ''''||replace(attribvalue,',',''',''')||'''' else case when lower(trim(attribvalue))=':username' then  ''''||pusername||'''' else attribvalue end end
						when filtercnd in('=','!=','>','<') then case when isglovar='F' then ''''||attribvalue||'''' else case when lower(trim(attribvalue))=':username' then  ''''||pusername||'''' else attribvalue end end  end cnd,
						ord,filtercnd  from
						(
						select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
						f.fname,f.tablename,1 ord, b.filtercnd,b.isglovar,f.srckey,f.srctf,f.srcfld
						from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
						join axpflds f on a.stransid =f.tstruct and b.fldname = f.fname 
						where a.uname = pusername  and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
						and a.dataaccesscnd = 30 and v_dactype in(2,3)					
						union all			
						select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
						b.fldname ,d.tablename,1 ord, b.filtercnd,b.isglovar,'F',null,null
						from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
						join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1' 
						where a.uname = pusername  and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
						and a.dataaccesscnd = 30 and b.fldname in('createdby','username')  and v_dactype in(2,3)
						union all		
						select  pusername attribvalue, 'createdby' ,d.tablename,1 ord,'='filtercnd,'F','F' srckey,null srctf, null srcfld
						from axpdef_dac_config a 
						join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1' 
						where a.uname = pusername and a.dataaccesscnd in (10,11,12) and a.stransid = pentity_transid 
						and a.editmode in('View','ViewEdit') and v_dactype in(2,3)					
						union all					
						select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
						f.fname,f.tablename,2 ord, b.filtercnd,b.isglovar,f.srckey,f.srctf,f.srcfld
						from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
						join axpflds f on a.stransid =f.tstruct and b.fldname = f.fname 
						join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
						and u.username = pusername and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
						where a.dataaccesscnd =30 and v_dactype = 1
						union all
						select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
						b.fldname,d.tablename,2 ord, b.filtercnd,b.isglovar,'F',null,null
						from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
						join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1'
						join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
						and u.username = pusername and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
						where a.dataaccesscnd =30 and v_dactype = 1	and  b.fldname in('createdby','username') 						
						union all
						select  pusername attribvalue, 'createdby' ,d.tablename,2 ord,'='filtercnd ,'F','F' srckey,null srctf, null srcfld
						from axpdef_dac_config a 
						join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1'
						join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
						and u.username = pusername and a.stransid = pentity_transid and a.editmode in('View','ViewEdit')
						where a.dataaccesscnd in (10,11,12) and v_dactype = 1
						)a
						order by ord)
						
						loop
							
							select count(1) into v_dac_joinreq from 
							(select distinct column_value tbls from  table(v_jointables))a 
							where trim(lower(a.tbls))=trim(lower(dacrec.tablename));
							
																
							if dacrec.srckey ='T' then					
								select count(1) into v_dac_normalizedjoinreq from (
								select distinct column_value tbls from  table(v_jointables))a 
								where lower(a.tbls)=lower(dacrec.srctf);
								if v_dac_normalizedjoinreq = 0 then
									v_dac_joinsary.extend();
									v_dac_joinsary(v_dac_joinsary.COUNT) := ' join '||dacrec.srctf||' on '||dacrec.srctf||'.'||dacrec.srctf||'id='||dacrec.tablename||'.'||dacrec.fname;
									v_jointables.extend();
									v_jointables(v_jointables.COUNT) := dacrec.srctf;
								end if;
							end if;		
	
							
								
							if v_dac_joinreq = 0 THEN
							v_dac_joinsary.extend();
							v_dac_joinsary(v_dac_joinsary.COUNT) := ' join '||dacrec.tablename||' on '||v_primarydctable||'.'||v_primarydctable||'id='||dacrec.tablename||'.'||v_primarydctable||'id' ;
							v_jointables.extend();
							v_jointables(v_jointables.COUNT) := dacrec.tablename;	
							end if;							
	
							v_dac_cnd := case 
										 when dacrec.srckey='F' then  dacrec.tablename||'.'||dacrec.fname||' '||dacrec.filtercnd||'('||case when dacrec.filtercnd in('in','not in') then 'SELECT REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) FROM dual CONNECT BY REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) IS NOT NULL' else dacrec.cnd	end		||')'  
										 when 	dacrec.srckey='T' then  dacrec.srctf||'.'||dacrec.srcfld||' '||dacrec.filtercnd||'('||case when dacrec.filtercnd in('in','not in') then 'SELECT REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) FROM dual CONNECT BY REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) IS NOT NULL' else dacrec.cnd	end		||')'
										 end;
						
							v_dac_cndary.extend();
							v_dac_cndary(v_dac_cndary.COUNT) := v_dac_cnd;									
						
						end loop;		
				   	
					v_sql := (v_sql||' '||array_to_string(v_dac_joinsary,' ')||' where '||v_primarydctable||'.cancel=''F'''||
									case when v_fldname_transidcnd > 0 then ' and '||v_primarydctable||'.transid='''||pentity_transid||'''' END||
									case when v_dacenabled > 0 then ' and '||array_to_string(v_dac_cndary,' and ') END||
									'
									--axp_filter
									');			
					else 
							v_sql := (v_sql||' where cancel=''F'''||
									case when v_fldname_transidcnd > 0 then ' and transid='''||pentity_transid||'''' END||
							' 
							--axp_filter
							');								
				   end if;
			
						     v_final_sqls.EXTEND;
	                         v_final_sqls(v_final_sqls.COUNT) := (v_sql);
	                        v_dac_cndary:= v_emptyary;
							v_dac_joinsary :=v_emptyary;

		elsif psource= 'Subentity' then 		
		    FOR rec IN
	    	    (select column_value as criteria from table(string_to_array(pcriteria,'^'))) 
		    loop		    			    
	      		v_transid := split_part(rec.criteria,'~',1);
	      		v_tablename := split_part(rec.criteria,'~',9);
				v_keyfld_fname := split_part(rec.criteria,'~',10);
				v_keyfld_fval := split_part(rec.criteria,'~',11);
				v_keyfld_srckey := split_part(rec.criteria,'~',5);
				v_keyfld_srctbl := split_part(rec.criteria,'~',6);
				v_keyfld_srcfld := split_part(rec.criteria,'~',7);

				select tablename into v_subentitytable from axpdc where tstruct = v_transid and dname ='dc1';
			
				if lower(v_tablename)=lower(v_subentitytable) then
			
				v_sql :=  ('select '||''''||v_transid||'''transid'||',count(*) totrec,''General'' cnd,'''||replace(rec.criteria,'''','')||''' criteria  
							from '||v_subentitytable||
							case when v_keyfld_srckey='T' then ' join '||v_keyfld_srctbl||' on '||v_keyfld_srctbl||'.'||v_keyfld_srctbl||'id = '||v_tablename||'.'||v_keyfld_fname end
                             ||' where '||v_tablename||'.cancel=''F'' and '
                             ||CASE WHEN v_fldname_transidcnd > 0 THEN v_tablename||'.transid='''||pentity_transid end
                             ||case when v_keyfld_srckey='T' then v_keyfld_srctbl||'.'||v_keyfld_srcfld else v_keyfld_fname END||'='||v_keyfld_fval
                             ||'
								--axp_filter');				
				ELSE
				
				v_sql :=  ('select '||''''||v_transid||'''transid'||',count(*) totrec,''General'' cnd,'''||replace(rec.criteria,'''','')||''' criteria  from '
							||v_tablename||' a join '
							||v_subentitytable||' b on a.' ||v_subentitytable||'id=b.'||v_subentitytable||'id '
							||case when v_keyfld_srckey='T' then ' join '||v_keyfld_srctbl||' on '||v_keyfld_srctbl||'.'||v_keyfld_srctbl||'id = a.'||v_keyfld_fname end
							||' where b.cancel=''F'' and '
							||CASE WHEN v_fldname_transidcnd > 0 THEN ' b.transid='''||pentity_transid||''' and ' end 
							||case when v_keyfld_srckey='T' then v_keyfld_srctbl||'.'||v_keyfld_srcfld else v_keyfld_fname END||'='||v_keyfld_fval
							||'
								--axp_filter'); 
                            
				END IF;
			                                                  
                          
               		 v_final_sqls.EXTEND;
                         v_final_sqls(v_final_sqls.COUNT) := (v_sql);
                

			end loop;	
	
		end if;
	end if;

   return v_final_sqls;

END;

>>

<<

CREATE OR REPLACE FUNCTION fn_axpanalytics_edittxn(ptransid varchar2, precordid NUMERIC, pusername varchar2 DEFAULT 'admin', papplydac varchar2 DEFAULT 'T')
RETURN varchar2
IS 
v_sql clob;
v_sql1 clob;
v_primarydctable  varchar2(3000);
v_fldnamesary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_fldname_join  varchar2(3000);
v_fldname_joinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_fldname_col  varchar2(3000);
v_fldname_normalized  varchar2(3000);
v_fldname_srctbl  varchar2(3000);
v_fldname_srcfld  varchar2(3000);
v_fldname_allowempty  varchar2(3000); 
v_fldname_dcjoinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_fldname_dctablename varchar2(3000);
v_fldname_dcflds varchar2(4000);
v_fldname_transidcnd number;
v_fldname_dctables SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_fldname_normalizedtables SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_allflds  varchar2(4000);
v_dacenabled numeric;
v_dactype numeric;
v_dac_join varchar2(4000);
v_dac_joinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_dac_cnd varchar2(4000);
v_dac_cndary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_dac_joinreq numeric;
v_dac_normalizedjoinreq numeric;
v_editable varchar2(1);
v_dac_entry numeric;
v_dac_onlyview numeric;

 begin
 
 
	select tablename into v_primarydctable from axpdc where tstruct = ptransid and dname ='dc1';	

	select count(*) into v_dac_entry from axpdef_dac_config where stransid = ptransid and editmode in('Edit','ViewEdit');

	----DAC V5
	IF papplydac ='T' then
		select sum(cnt),sum(appl),sum(onlyview) into v_dacenabled,v_dactype,v_dac_onlyview from
		(select count(*) cnt,2 appl,0 onlyview  from axpdef_dac_config a  
		where a.uname = pusername and a.stransid = ptransid and a.editmode in('Edit','ViewEdit')
		having count(*) > 0
		union all
		select count(*),1 appl,0 onlyview from axpdef_dac_config a  join axuserlevelgroups a2 on a.urole = a2.usergroup 
		where a2.username = pusername and a.stransid = ptransid and a.editmode in('Edit','ViewEdit')
		and ((a2.startdate is not null and current_date  >= startdate) or (startdate is null)) 
		and ((enddate is not null and current_date  <= enddate) or (enddate is null))
		having count(*) > 0
		union all
		select 0 cnt,0 appl,1 onlyview from axpdef_dac_config a  
		where a.uname = pusername and a.stransid = ptransid and a.editmode='View'
		having count(*) > 0
		union all
		select 0,0 appl,1 onlyview from axpdef_dac_config a  join axuserlevelgroups a2 on a.urole = a2.usergroup 
		where a2.username = pusername and a.stransid = ptransid and a.editmode='View'
		and ((a2.startdate is not null and current_date  >= startdate) or (startdate is null)) 
		and ((enddate is not null and current_date  <= enddate) or (enddate is null))
		having count(*) > 0
		)a
		where 'T' = papplydac;
	END IF;


		           select LISTAGG(str,'^') WITHIN GROUP(ORDER BY 1) into v_allflds 
					from 
					(
					select f.tablename||'='||listagg(f.fname||'~'||f.srckey||'~'||f.srctf||'~'||f.srcfld||'~'||f.allowempty,'|') WITHIN group(ORDER BY b.axpdef_dac_configdtlrow) str
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpflds f on a.stransid =f.tstruct and b.fldname = f.fname 
					where a.uname = pusername  and a.stransid = ptransid and a.editmode in('Edit','ViewEdit')
					and a.dataaccesscnd = 30 and v_dactype in(2,3) 
					group by f.tablename									
					union all					
					select  tablename||'='||'createdby~F~~~F'
					from axpdef_dac_config a 
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1' 
					where a.uname = pusername and a.dataaccesscnd in (10,11,12) 
					and a.stransid = ptransid and a.editmode in('Edit','ViewEdit') and v_dactype in(2,3)					
					union all					
					select f.tablename||'='||listagg(f.fname||'~'||f.srckey||'~'||f.srctf||'~'||f.srcfld||'~'||f.allowempty,'|') WITHIN GROUP(ORDER BY b.axpdef_dac_configdtlrow) str
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpflds f on a.stransid =f.tstruct and b.fldname = f.fname 
					join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
					and u.username = pusername and a.stransid = ptransid and a.editmode in('Edit','ViewEdit')
					where a.dataaccesscnd =30 and v_dactype = 1					
					group by f.tablename	
					union all
					select tablename||'='||'createdby~F~~~F'
					from axpdef_dac_config a 
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1'
					join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
					and u.username = pusername and a.stransid = ptransid and a.editmode in('Edit','ViewEdit')
					where a.dataaccesscnd in (10,11,12) and v_dactype = 1
					)a;


FOR rec2 IN (select column_value as dcdtls from table(string_to_array(v_allflds,'^')) )
LOOP
	v_fldname_dctablename := split_part(rec2.dcdtls,'=',1);
	v_fldname_dcflds := split_part(rec2.dcdtls,'=',2);
	
	if v_fldname_dctablename!=v_primarydctable THEN
		v_fldname_dcjoinsary.Extend;
		v_fldname_dcjoinsary(v_fldname_dcjoinsary.COUNT):= ('left join '||v_fldname_dctablename||' on '||v_primarydctable||'.'||v_primarydctable||'id='||v_fldname_dctablename||'.'||v_primarydctable||'id');				    									
	end if;
		v_fldname_dctables.Extend;
		v_fldname_dctables(v_fldname_dctables.COUNT):= v_fldname_dctablename;
					
 	FOR rec1 in  (select column_value as fldname from table(string_to_array(v_fldname_dcflds,'|')))
loop		    	
					v_fldname_col := split_part(rec1.fldname,'~',1);
					v_fldname_normalized := split_part(rec1.fldname,'~',2);
					v_fldname_srctbl := split_part(rec1.fldname,'~',3);
					v_fldname_srcfld := split_part(rec1.fldname,'~',4);					
					v_fldname_allowempty := split_part(rec1.fldname,'~',5);
					
					if v_fldname_normalized ='F' then 
                         v_fldnamesary.EXTEND;
                         v_fldnamesary(v_fldnamesary.COUNT) := (v_fldname_dctablename||'.'||v_fldname_col);

					elsif v_fldname_normalized ='T' then
                         v_fldnamesary.EXTEND;
						 v_fldnamesary(v_fldnamesary.COUNT) := (v_fldname_col||'.'||v_fldname_srcfld||' '||v_fldname_col);
                         v_fldname_joinsary.EXTEND;
						 v_fldname_joinsary(v_fldname_joinsary.count) := (CASE WHEN v_fldname_allowempty='F' THEN ' join ' ELSE ' left join ' end||v_fldname_srctbl||' '||v_fldname_col||' on '||v_primarydctable||'.'||v_fldname_col||' = '||v_fldname_col||'.'||v_fldname_srctbl||'id');
						v_fldname_normalizedtables.Extend;
						v_fldname_normalizedtables(v_fldname_normalizedtables.COUNT):= v_fldname_srctbl;
					end if;
			    end loop;
END LOOP;
		   	v_sql := (' select count(*)  from '||v_primarydctable||' '||array_to_string(v_fldname_dcjoinsary,' ')||' '||array_to_string(v_fldname_joinsary,' '));
					
										
---------DAC filters
			   if v_dacenabled > 0 then
				for dacrec in 			   
					(select fname,tablename,srckey,srctf,srcfld,
					case when filtercnd in('like','not like') then case when isglovar='F' then '''%'||attribvalue||'%''' else 
					case when lower(trim(attribvalue))=':username' then  '''%'||pusername||'%''' else '''%''||'||attribvalue||'||''%''' end end
					when filtercnd in('in','not in') then case when isglovar='F' then ''''||replace(attribvalue,',',''',''')||'''' else case when lower(trim(attribvalue))=':username' then  ''''||pusername||'''' else attribvalue end end
					when filtercnd in('=','!=','>','<') then case when isglovar='F' then ''''||attribvalue||'''' else case when lower(trim(attribvalue))=':username' then  ''''||pusername||'''' else attribvalue end end  end cnd,
					ord,filtercnd  from
					(
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					f.fname,f.tablename,1 ord, b.filtercnd,b.isglovar,f.srckey,f.srctf,f.srcfld
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpflds f on a.stransid =f.tstruct and b.fldname = f.fname 
					where a.uname = pusername  and a.stransid = ptransid and a.editmode in('Edit','ViewEdit')
					and a.dataaccesscnd = 30 and v_dactype in(2,3)					
					union all			
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					b.fldname ,d.tablename,1 ord, b.filtercnd,b.isglovar,'F',null,null
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1' 
					where a.uname = pusername  and a.stransid = ptransid and a.editmode in('Edit','ViewEdit')
					and a.dataaccesscnd = 30 and b.fldname in('createdby','username')  and v_dactype in(2,3)
					union all		
					select  pusername attribvalue, 'createdby' ,d.tablename,1 ord,'='filtercnd,'F','F' srckey,null srctf, null srcfld
					from axpdef_dac_config a 
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1' 
					where a.uname = pusername and a.dataaccesscnd in (10,11,12) and a.stransid = ptransid 
					and a.editmode in('Edit','ViewEdit') and v_dactype in(2,3)					
					union all					
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					f.fname,f.tablename,2 ord, b.filtercnd,b.isglovar,f.srckey,f.srctf,f.srcfld
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpflds f on a.stransid =f.tstruct and b.fldname = f.fname 
					join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
					and u.username = pusername and a.stransid = ptransid and a.editmode in('Edit','ViewEdit')
					where a.dataaccesscnd =30 and v_dactype = 1
					union all
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					b.fldname,d.tablename,2 ord, b.filtercnd,b.isglovar,'F',null,null
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1'
					join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
					and u.username = pusername and a.stransid = ptransid and a.editmode in('Edit','ViewEdit')
					where a.dataaccesscnd =30 and v_dactype = 1	and  b.fldname in('createdby','username') 						
					union all
					select  pusername attribvalue, 'createdby' ,d.tablename,2 ord,'='filtercnd ,'F','F' srckey,null srctf, null srcfld
					from axpdef_dac_config a 
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1'
					join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
					and u.username = pusername and a.stransid = ptransid and a.editmode in('Edit','ViewEdit')
					where a.dataaccesscnd in (10,11,12) and v_dactype = 1
					)a
					order by ord)
					
					loop
						
						select count(1) into v_dac_joinreq from (
						select distinct column_value tbls from  table(v_fldname_dctables)
						union 
						select distinct column_value tbls from  table(v_fldname_normalizedtables)								
						)a 
						where lower(a.tbls)=lower(dacrec.tablename);	


						if dacrec.srckey ='T' then
							select count(1) into v_dac_normalizedjoinreq from (
							select distinct column_value tbls FROM table(v_fldname_dctables)
							union 
							select distinct column_value tbls FROM table(v_fldname_normalizedtables)								
							)a 
							where lower(a.tbls)=lower(dacrec.srctf);	
						
							if v_dac_normalizedjoinreq = 0 then
								v_dac_joinsary.extend();
								v_dac_joinsary(v_dac_joinsary.COUNT) := ' join '||dacrec.srctf||' on '||dacrec.srctf||'.'||dacrec.srctf||'id='||dacrec.tablename||'.'||dacrec.fname;
								v_fldname_dctables.extend();
								v_fldname_dctables(v_fldname_dctables.COUNT) := dacrec.srctf;						
							end if;

						end if;		


	
							
						if v_dac_joinreq = 0 THEN
						v_dac_joinsary.extend();
						v_dac_joinsary(v_dac_joinsary.COUNT) := ' join '||dacrec.tablename||' on '||v_primarydctable||'.'||v_primarydctable||'id='||dacrec.tablename||'.'||v_primarydctable||'id';
						v_fldname_dctables.EXTEND();
						v_fldname_dctables(v_fldname_dctables.COUNT) := dacrec.tablename;		
						end if;			
								

						v_dac_cnd := case 
									 when dacrec.srckey='F' then  
									 dacrec.tablename||'.'||dacrec.fname||' '||dacrec.filtercnd||'('|| case when dacrec.filtercnd in('in','not in') then 'SELECT REGEXP_SUBSTR('||replace(dacrec.cnd,':','axglovar.')||', ''[^,]+'', 1, LEVEL) FROM dual CONNECT BY REGEXP_SUBSTR('||replace(dacrec.cnd,':','axglovar.')||', ''[^,]+'', 1, LEVEL) IS NOT NULL' else replace(dacrec.cnd,':','axglovar.')	end||')'  
									 when 	dacrec.srckey='T' then  
									 (dacrec.fname||'.'||dacrec.srcfld||' '||dacrec.filtercnd||'('||case when dacrec.filtercnd in('in','not in') then 'SELECT REGEXP_SUBSTR('||replace(dacrec.cnd,':','axglovar.')||', ''[^,]+'', 1, LEVEL) FROM dual CONNECT BY REGEXP_SUBSTR('||replace(dacrec.cnd,':','axglovar.')||', ''[^,]+'', 1, LEVEL) IS NOT NULL' else replace(dacrec.cnd,':','axglovar.')	end	||')') 
									end;
					
						v_dac_cndary.extend();
						v_dac_cndary(v_dac_cndary.COUNT) := v_dac_cnd;									
					
					end loop;		
			   
			   
			   END IF;

				   
	v_sql1 := v_sql||' join axglovar on axglovar.username = '||''''||pusername||''''||' where '||v_primarydctable||'id='||precordid||CASE WHEN v_dacenabled > 0 THEN ' and '||array_to_string(v_dac_cndary,' and ') ELSE ' and 1=2 ' END;


EXECUTE IMMEDIATE v_sql1 INTO v_editable;


return case when v_dac_entry > 0 and v_dac_onlyview = 0 then 
case when v_editable = '0' then 'F' else 'T' end 
when v_dac_entry > 0 and v_dac_onlyview =2 then 'F'
when v_dac_entry > 0 and v_dac_onlyview in (1,3) then case when v_editable = '0' then 'F' else 'T' end
when v_dac_entry = 0 and v_dac_onlyview in (1,2,3) then 'F'
else 'T' end;

END;

>>

<<

CREATE OR REPLACE FUNCTION fn_axpanalytics_filterdata(ptransid varchar2, pflds clob)
 RETURN  SYS.ODCIVARCHAR2LIST
is 
v_sql clob;
v_result_array SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
begin
---pflds - fldname~normalized~source table~source fld


	if split_part(pflds,'~',2)='T' then	
		v_sql := ('select distinct '||split_part(pflds,'~',4)||' from '||split_part(pflds,'~',3));
	ELSIF split_part(pflds,'~',2)='F' then
		v_sql := ('select distinct '||split_part(pflds,'~',1)||' from '||split_part(pflds,'~',3));      
	end if;

	--Bulk collect into Array.       
	execute immediate v_sql bulk collect into v_result_array;

return v_result_array;

 
END;

>>

<<

CREATE OR REPLACE FUNCTION fn_axpanalytics_listdata(ptransid varchar2, pflds clob DEFAULT 'All', ppagesize numeric DEFAULT 25, ppageno numeric DEFAULT 1, pfilter clob DEFAULT 'NA', pusername varchar2 DEFAULT 'admin', papplydac varchar2 DEFAULT 'T')
-- RETURN  clob
RETURN SYS.ODCIVARCHAR2LIST


IS 
 
v_sql clob;
v_sql1 clob;
v_primarydctable  varchar2(3000);
v_fldnamesary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_fldname_join  varchar2(3000);
v_fldname_joinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_fldname_col  varchar2(3000);
v_fldname_normalized  varchar2(3000);
v_fldname_srctbl  varchar2(3000);
v_fldname_srcfld  varchar2(3000);
v_fldname_allowempty  varchar2(3000); 
v_fldname_dcjoinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_fldname_dctablename varchar2(3000);
v_fldname_dcflds varchar2(4000);
v_fldname_transidcnd number;
v_fldname_dctables SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_fldname_normalizedtables SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_allflds  varchar2(4000);
v_filter_srcfld varchar2(3000);
v_filter_srctxt  varchar2(3000);
v_filter_join  varchar2(3000);
v_filter_joinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_filter_dcjoin varchar2(3000);
v_filter_dcjoinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_filter_cnd  varchar2(3000);
v_filter_cndary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_filter_col varchar2(3000);
v_filter_normalized varchar2(3000);
v_filter_sourcetbl varchar2(3000);
v_filter_sourcefld varchar2(3000);
v_filter_datatype varchar2(3000);
v_filter_listedfld varchar2(3000);
v_filter_tablename varchar2(3000);
v_filter_joinreq number;
-- v_recdata_json clob;
t_temp_field_list clob;
v_filter_dcjoinuniq varchar2(3000);
v_final_sqls SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_pegenabled NUMERIC;
v_dacenabled numeric;
v_dactype numeric;
v_dac_join varchar2(4000);
v_dac_joinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_dac_cnd varchar2(4000);
v_dac_cndary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_dac_joinreq numeric;
v_dac_normalizedjoinreq numeric; 
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


	SELECT count(1) INTO v_pegenabled FROM AXPROCESSDEFV2 WHERE TRANSID = ptransid;


	----DAC V5
IF papplydac ='T' then
	select sum(cnt),sum(appl) into v_dacenabled,v_dactype from
	(select count(*) cnt,2 appl from axpdef_dac_config a  
	where a.uname = pusername and a.stransid = ptransid and a.editmode in('View','ViewEdit')
	having count(*) > 0
	union all
	select count(*),1 appl from axpdef_dac_config a  join axuserlevelgroups a2 on a.urole = a2.usergroup 
	where a2.username = pusername and a.stransid = ptransid and a.editmode in('View','ViewEdit')
	and ((a2.startdate is not null and current_date  >= startdate) or (startdate is null)) 
	and ((enddate is not null and current_date  <= enddate) or (enddate is null))
	having count(*) > 0
	)a
	where 'T' = papplydac;
END IF;


		if pflds = 'All' then 

            select tablename||'='||listagg(str,'|')WITHIN GROUP(order by  dcname ,ordno)   into  v_allflds From(	
			select tablename,fname||'~'||srckey||'~'||srctf||'~'||srcfld||'~'||allowempty str,
             dcname ,ordno			
			 from axpflds where tstruct=ptransid and 
			dcname ='dc1' and asgrid ='F' and hidden ='F' and savevalue='T' and tablename = v_primarydctable and datatype not in('i','t')
			order by dcname ,ordno			
		          	)a GROUP BY tablename;

		end if;

t_temp_field_list := case when pflds='All' then v_allflds else pflds end;

FOR rec2 IN (select column_value as dcdtls from table(string_to_array(t_temp_field_list,'^')) )
LOOP
	v_fldname_dctablename := split_part(rec2.dcdtls,'=',1);
	v_fldname_dcflds := split_part(rec2.dcdtls,'=',2);
	
	if v_fldname_dctablename!=v_primarydctable THEN
		v_fldname_dcjoinsary.Extend;
		v_fldname_dcjoinsary(v_fldname_dcjoinsary.COUNT):= ('left join '||v_fldname_dctablename||' on '||v_primarydctable||'.'||v_primarydctable||'id='||v_fldname_dctablename||'.'||v_primarydctable||'id');				    									
	end if;
		v_fldname_dctables.Extend;
		v_fldname_dctables(v_fldname_dctables.COUNT):= v_fldname_dctablename;
					
 	FOR rec1 in  (select column_value as fldname from table(string_to_array(v_fldname_dcflds,'|')))
loop		    	
					v_fldname_col := split_part(rec1.fldname,'~',1);
					v_fldname_normalized := split_part(rec1.fldname,'~',2);
					v_fldname_srctbl := split_part(rec1.fldname,'~',3);
					v_fldname_srcfld := split_part(rec1.fldname,'~',4);					
					v_fldname_allowempty := split_part(rec1.fldname,'~',5);
					
					if v_fldname_normalized ='F' then 
                         v_fldnamesary.EXTEND;
                         v_fldnamesary(v_fldnamesary.COUNT) := (v_fldname_dctablename||'.'||v_fldname_col);

					elsif v_fldname_normalized ='T' then
                         v_fldnamesary.EXTEND;
						 v_fldnamesary(v_fldnamesary.COUNT) := (v_fldname_col||'.'||v_fldname_srcfld||' '||v_fldname_col);
                         v_fldname_joinsary.EXTEND;
						 v_fldname_joinsary(v_fldname_joinsary.count) := (CASE WHEN v_fldname_allowempty='F' THEN ' join ' ELSE ' left join ' end||v_fldname_srctbl||' '||v_fldname_col||' on '||v_primarydctable||'.'||v_fldname_col||' = '||v_fldname_col||'.'||v_fldname_srctbl||'id');
					end if;
			    end loop;
END LOOP;
		   	v_sql := (' select '||''''||ptransid||''' transid,'||v_primarydctable||'.'||v_primarydctable||'id recordid,'||v_primarydctable||'.username modifiedby,'
		   			||v_primarydctable||'.modifiedon,'||v_primarydctable||'.createdon,'||v_primarydctable||'.createdby,'||array_to_string(v_fldnamesary,',')||
		   			CASE WHEN v_pegenabled > 0 THEN ',b.axpeg_processname,b.axpeg_keyvalue,b.axpeg_status,b.axpeg_statustext from ' ELSE ' from ' END 
		   			||v_primarydctable||' '||array_to_string(v_fldname_dcjoinsary,' ')||' '||array_to_string(v_fldname_joinsary,' ')||
		   			CASE WHEN v_pegenabled > 0 THEN ' left join ('||
		   		    'select processname axpeg_processname,keyvalue axpeg_keyvalue,status axpeg_status,statustext axpeg_statustext,RECORDID axpeg_RECORDID  from axpeg_'||ptransid||' where status in (1,2)'||' union all '||
					'select a.processname,keyvalue,0,a.taskname||'' is pending ''||listagg(touser,'','') WITHIN group(ORDER BY touser),RECORDID from vw_pegv2_activetasks a '||
					'where  a.transid= '''||ptransid||'''group by a.processname,a.keyvalue,a.taskname,a.recordid) b ON '||v_primarydctable||'.'||v_primarydctable||'id =b.axpeg_recordid'  ELSE ' ' end
					 );
					
					
					
---------DAC filters
			   if v_dacenabled > 0 then
				for dacrec in 			   
					(select fname,tablename,srckey,srctf,srcfld,
					case when filtercnd in('like','not like') then case when isglovar='F' then '''%'||attribvalue||'%''' else 
					case when lower(trim(attribvalue))=':username' then  '''%'||pusername||'%''' else '''%''||'||attribvalue||'||''%''' end end
					when filtercnd in('in','not in') then case when isglovar='F' then ''''||replace(attribvalue,',',''',''')||'''' else case when lower(trim(attribvalue))=':username' then  ''''||pusername||'''' else attribvalue end end
					when filtercnd in('=','!=','>','<') then case when isglovar='F' then ''''||attribvalue||'''' else case when lower(trim(attribvalue))=':username' then  ''''||pusername||'''' else attribvalue end end  end cnd,
					ord,filtercnd  from
					(
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					f.fname,f.tablename,1 ord, b.filtercnd,b.isglovar,f.srckey,f.srctf,f.srcfld
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpflds f on a.stransid =f.tstruct and b.fldname = f.fname 
					where a.uname = pusername  and a.stransid = ptransid and a.editmode in('View','ViewEdit')
					and a.dataaccesscnd = 30 and v_dactype in(2,3)					
					union all			
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					b.fldname ,d.tablename,1 ord, b.filtercnd,b.isglovar,'F',null,null
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1' 
					where a.uname = pusername  and a.stransid = ptransid and a.editmode in('View','ViewEdit')
					and a.dataaccesscnd = 30 and b.fldname in('createdby','username')  and v_dactype in(2,3)
					union all		
					select  pusername attribvalue, 'createdby' ,d.tablename,1 ord,'='filtercnd,'F','F' srckey,null srctf, null srcfld
					from axpdef_dac_config a 
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1' 
					where a.uname = pusername and a.dataaccesscnd in (10,11,12) and a.stransid = ptransid 
					and a.editmode in('View','ViewEdit') and v_dactype in(2,3)					
					union all					
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					f.fname,f.tablename,2 ord, b.filtercnd,b.isglovar,f.srckey,f.srctf,f.srcfld
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpflds f on a.stransid =f.tstruct and b.fldname = f.fname 
					join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
					and u.username = pusername and a.stransid = ptransid and a.editmode in('View','ViewEdit')
					where a.dataaccesscnd =30 and v_dactype = 1
					union all
					select case when b.dynamicval ='No' and a.dataaccesscnd = 30 then b.fldstaticval when b.dynamicval ='Yes' and a.dataaccesscnd = 30 then b.fldmastvalue end  attribvalue,
					b.fldname,d.tablename,2 ord, b.filtercnd,b.isglovar,'F',null,null
					from axpdef_dac_config a join axpdef_dac_configdtl b on a.axpdef_dac_configid =  b.axpdef_dac_configid
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1'
					join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
					and u.username = pusername and a.stransid = ptransid and a.editmode in('View','ViewEdit')
					where a.dataaccesscnd =30 and v_dactype = 1	and  b.fldname in('createdby','username') 						
					union all
					select  pusername attribvalue, 'createdby' ,d.tablename,2 ord,'='filtercnd ,'F','F' srckey,null srctf, null srcfld
					from axpdef_dac_config a 
					join axpdc d on a.stransid =d.tstruct and d.dname= 'dc1'
					join axuserlevelgroups u on a.urole = u.usergroup and ((u.startdate is not null and current_date  >= startdate) or (startdate is null)) and ((enddate is not null and current_date  <= enddate) or (enddate is null))
					and u.username = pusername and a.stransid = ptransid and a.editmode in('View','ViewEdit')
					where a.dataaccesscnd in (10,11,12) and v_dactype = 1
					)a
					order by ord)
					
					loop
						
						
						select count(1) into v_dac_joinreq from (
						select distinct column_value tbls from  table(v_fldname_dctables)
						union 
						select distinct column_value tbls from  table(v_fldname_normalizedtables)								
						)a 
						where lower(a.tbls)=lower(dacrec.tablename);	


						if dacrec.srckey ='T' then
							select count(1) into v_dac_normalizedjoinreq from (
							select distinct column_value tbls FROM table(v_fldname_dctables)
							union 
							select distinct column_value tbls FROM table(v_fldname_normalizedtables)								
							)a 
							where lower(a.tbls)=lower(dacrec.srctf);	
						
							if v_dac_normalizedjoinreq = 0 then
								v_dac_joinsary.extend();
								v_dac_joinsary(v_dac_joinsary.COUNT) := ' join '||dacrec.srctf||' on '||dacrec.srctf||'.'||dacrec.srctf||'id='||dacrec.tablename||'.'||dacrec.fname;
								v_fldname_dctables.extend();
								v_fldname_dctables(v_fldname_dctables.COUNT) := dacrec.srctf;						
							end if;

						end if;		


	
							
						if v_dac_joinreq = 0 THEN
						v_dac_joinsary.extend();
						v_dac_joinsary(v_dac_joinsary.COUNT) := ' join '||dacrec.tablename||' on '||v_primarydctable||'.'||v_primarydctable||'id='||dacrec.tablename||'.'||v_primarydctable||'id';
						v_fldname_dctables.EXTEND();
						v_fldname_dctables(v_fldname_dctables.COUNT) := dacrec.tablename;		
						end if;							

						v_dac_cnd := case 
									 when dacrec.srckey='F' then  dacrec.tablename||'.'||dacrec.fname||' '||dacrec.filtercnd||'('|| case when dacrec.filtercnd in('in','not in') then 'SELECT REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) FROM dual CONNECT BY REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) IS NOT NULL' else dacrec.cnd	end||')'  
									 when 	dacrec.srckey='T' then  
									 case when v_dac_normalizedjoinreq = 0 then (dacrec.srctf||'.'||dacrec.srcfld||' '||dacrec.filtercnd||'('||case when dacrec.filtercnd in('in','not in') then 'SELECT REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) FROM dual CONNECT BY REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) IS NOT NULL' else dacrec.cnd	end	||')') 
									else (dacrec.fname||'.'||dacrec.srcfld||' '||dacrec.filtercnd||'('||case when dacrec.filtercnd in('in','not in') then 'SELECT REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) FROM dual CONNECT BY REGEXP_SUBSTR('||dacrec.cnd||', ''[^,]+'', 1, LEVEL) IS NOT NULL' else dacrec.cnd	end	||')') end
									end;
					
						v_dac_cndary.extend();
						v_dac_cndary(v_dac_cndary.COUNT) := v_dac_cnd;									
					
					end loop;		
			   
			   
			   END IF;

		if pfilter ='NA' then 

        v_sql1 :='select * from(                        
                        select a.*,row_number() over(order by modifiedon desc) rno,'||ppageno||' as  pageno  
                           from ( '||v_sql||array_to_string(v_dac_joinsary,' ')||' where '||v_primarydctable||'.cancel=''F'' 
							--axp_filter 
							'||
                           CASE WHEN v_fldname_transidcnd>0 THEN ' and '||v_primarydctable||'.transid='''||ptransid||''''end||
                           case when v_dacenabled > 0 then ' and '||array_to_string(v_dac_cndary,' and ') end||' )a  order by modifiedon desc             
                                ) b  where rno between '||(ppagesize*(ppageno-1)+1)||' and '||(ppagesize*ppageno);
		else
			FOR rec IN
    			(select column_value as ifilter from table(string_to_array(pfilter,'^')) )
			    loop		    	
			    	v_filter_srcfld := split_part(rec.ifilter,'|',1); -- tstfm~empcode~F~~
			    	v_filter_srctxt := split_part(rec.ifilter,'|',2);--   = 'EMP-001'
			    	v_filter_col := split_part(v_filter_srcfld,'~',1);
				    v_filter_normalized := split_part(v_filter_srcfld,'~',2);
 				    v_filter_sourcetbl := split_part(v_filter_srcfld,'~',3);
 				    v_filter_sourcefld := split_part(v_filter_srcfld,'~',4);
					v_filter_datatype := split_part(v_filter_srcfld,'~',5);
					v_filter_listedfld :=split_part(v_filter_srcfld,'~',6);
					v_filter_tablename:=split_part(v_filter_srcfld,'~',7);
					
			    if  v_filter_listedfld='F' then 
								    	
			    	select count(1) into v_filter_joinreq FROM (select distinct column_value from   table(v_fldname_dctables))a where lower(a.column_value)=lower(v_filter_tablename);
			    	
			    	if v_filter_joinreq = 0  then  
				    	v_filter_dcjoin := ' join '||v_filter_tablename||' on '||v_primarydctable||'.'||v_primarydctable||'id='||v_filter_tablename||'.'||v_primarydctable||'id';
				    	v_filter_dcjoinsary.EXTEND;
	                   	v_filter_dcjoinsary(v_filter_dcjoinsary.COUNT) := v_filter_dcjoin;
			    	end if;
			    				    		  	
                   	if v_filter_normalized='T' then  	
 		           		v_filter_join := (' join '||v_filter_sourcetbl||' '||v_filter_col||' on '||v_filter_tablename||'.'||v_filter_col||' = '||v_filter_col||'.'||v_filter_sourcetbl||'id');
        	    	   	v_filter_joinsary.EXTEND;
            	       	v_filter_joinsary(v_filter_joinsary.COUNT) := v_filter_join;
                  	end if;
                    
				END IF;
				    if v_filter_normalized='F' then                    
                   		v_filter_cnd := case when v_filter_datatype='c' then 'lower(' END ||(v_filter_tablename||'.'||v_filter_col||case when v_filter_datatype='c' then ')' end||' '||v_filter_srctxt) ;
                    else 
                    	v_filter_cnd := case when v_filter_datatype='c' then 'lower(' END||(v_filter_col||'.'||v_filter_sourcefld||case when v_filter_datatype='c' then ')' end||' '||v_filter_srctxt) ;
                    end if; 

                    v_filter_cndary.EXTEND;
                    v_filter_cndary(v_filter_cndary.COUNT) := v_filter_cnd;

			    end loop;
					SELECT listagg(column_value,' ') WITHIN group(ORDER BY 1) INTO v_filter_dcjoinuniq from(select distinct column_value from   table(v_filter_dcjoinsary));
			   		
                	 v_sql1 := 'select * from(                        
                        select a.*,row_number() over(order by modifiedon desc) rno,'||ppageno||' as  pageno  
                           from ( '||v_sql||' '||v_filter_dcjoinuniq||' '||array_to_string(v_dac_joinsary,' ') ||array_to_string(v_filter_joinsary,' ')||' where '||v_primarydctable||'.cancel=''F'' and '||'
							--axp_filter
							'||CASE WHEN v_fldname_transidcnd>0 THEN v_primarydctable||'.transid='''||ptransid||''' and 'end
                           ||array_to_string(v_filter_cndary,' and ')||CASE WHEN v_dacenabled > 0 THEN 'and '||array_to_string(v_dac_cndary,' and ') END ||' )a  order by modifiedon desc             
                                ) b  where rno between '||(ppagesize*(ppageno-1)+1)||' and '||(ppagesize*ppageno) ;
		end if;


		   
	v_final_sqls.EXTEND;
	v_final_sqls(v_final_sqls.COUNT) := (v_sql1);

return v_final_sqls;
--RETURN v_dac_cndary;



 END;

>>

<<

CREATE OR REPLACE FUNCTION fn_axpanalytics_metadata(ptransid varchar2, psubentity varchar2 DEFAULT 'F')
 RETURN  axpdef_axpanalytics_mdata
IS
recdata_consoliate_array axpdef_axpanalytics_mdata := axpdef_axpanalytics_mdata();
recdata_dc1_array axpdef_axpanalytics_mdata := axpdef_axpanalytics_mdata();
recdata_subentity_array axpdef_axpanalytics_mdata := axpdef_axpanalytics_mdata();
temp_recdata_subentity_array axpdef_axpanalytics_mdata := axpdef_axpanalytics_mdata();
v_primarydctable varchar2(3000);
v_subentitytable varchar2(3000);
v_sql clob;
v_subentitysql clob;
BEGIN  
  
-- Retrieve primary data table name.
select tablename into v_primarydctable from axpdc where tstruct = ptransid and dname ='dc1';

-- Construct and execute SQL query for primary data.
v_sql :=' select axpdef_axpanalytics_mdata_obj(transid, formcap, fname , fcap, cdatatype, dt,modeofentry , fhide,
	  props,srckey ,srctf ,srcfld ,srctrans ,allowempty,filtercnd,grpfld,aggfld,subentity, datacnd, entityrelfld,allowduplicate,tablename,dcname,fordno,dccaption,griddc,listingfld) from (
select axpflds.tstruct transid,t.caption formcap, fname ,axpflds.caption fcap,customdatatype cdatatype,datatype dt,modeofentry ,hidden fhide,
	null as props,srckey ,srctf ,srcfld ,srctrans ,axpflds.allowempty,
	case when modeofentry =''select'' then case when srckey =''T'' then ''Dropdown'' else ''Text'' end else ''Text'' end filtercnd,
	case when (modeofentry =''select'' or datatype=''c'') then ''T'' else ''F'' end grpfld,
	case when datatype =''n'' then ''T'' else ''F'' end aggfld,''F'' subentity,1 datacnd,null entityrelfld,allowduplicate,axpflds.tablename,
	dcname,ordno fordno,d.caption dccaption,d.asgrid griddc,case when d.asgrid=''F'' then ''T'' else ''F'' end listingfld
	from axpflds join tstructs t on axpflds.tstruct = t.name
	join axpdc d on axpflds.tstruct = d.tstruct and axpflds.dcname = d.dname
	where axpflds.tstruct=:1  and savevalue =''T''	
	union all
	select a.name,t.caption,key,title,	''button'',null,null,''F'',	script|| ''~''|| icon,''F'',null,null,null,null,null,null,null,''F'' subentity,1,null,null
	,null,null,ordno,null,''F'',''F''
	from axtoolbar a join tstructs t on a.name = t.name
	where visible = ''true'' and script is not null and a.name= :2
    ) x'; 
 
--Bulk collect into Array.    
   execute immediate v_sql bulk collect into recdata_dc1_array using ptransid,ptransid;

-- If subentities are requested.  
  if psubentity ='T' then		

 -- Iterate over distinct subentity data structures.   
    FOR rec IN (
        select distinct a.dstruct ,a.rtype--,dc.tablename,a.dfield,a.rtype,a.mfield
		from axentityrelations a 
		join axpdc dc on a.dstruct = dc.tstruct --and dc.dname ='dc1' 
		--join axpflds d on a.dstruct =d.tstruct  and a.dfield = d.fname and d.asgrid ='F'
		where  mstruct = ptransid )
   	loop	
 	 
	   	
	   	v_subentitysql :=  'select  axpdef_axpanalytics_mdata_obj( transid,formcap, fname ,fcap,cdatatype,dt,modeofentry ,fhide,
		 props,srckey ,srctf ,srcfld ,srctrans ,allowempty, filtercnd,grpfld,aggfld,subentity,datacnd,entityrelfld,allowduplicate,
		tablename,dcname,fordno,dccaption,griddc,listingfld) from (
        select axpflds.tstruct transid,t.caption formcap, fname ,axpflds.caption fcap,customdatatype cdatatype,datatype dt,modeofentry,
		hidden fhide,null props,srckey ,srctf ,srcfld ,srctrans ,axpflds.allowempty,
		case when modeofentry =''select'' then case when srckey =''T'' then ''Dropdown'' else ''Text'' end else ''Text'' end filtercnd,
		case when modeofentry =''select'' then ''T'' else ''F'' end grpfld,
		case when datatype =''n'' then ''T'' else ''F'' end aggfld,''T'' subentity,2 datacnd,
		r.mfield entityrelfld,
		allowduplicate,axpflds.tablename,axpflds.dcname,axpflds.ordno fordno,d.caption dccaption,d.asgrid griddc,
		case when d.asgrid=''F'' then ''T'' else ''F'' end listingfld
		from axpflds join tstructs t on axpflds.tstruct = t.name  join axpdc d on axpflds.tstruct = d.tstruct and axpflds.dcname = d.dname
		left join axentityrelations r on axpflds.tstruct = r.dstruct and axpflds.fname = r.dfield and r.mstruct=:3 
		where axpflds.tstruct=:4 and savevalue =''T'' 
		 union all select '''||rec.dstruct||''',null,''sourceid'',''sourceid'',''Simple Text'',''c'',''accept'',''T'',
		null,''F'',null,null,null,''T'',''F'',''F'',''F'',''T'',2,''recordid'',''T'',null,null,1000,null,''F'',''F''
		 from dual where ''gm''='''||rec.rtype||''') x' ;

--Bulk collect into Array.         
       execute immediate v_subentitysql bulk collect into temp_recdata_subentity_array using  ptransid,ptransid,ptransid,rec.dstruct;

-- Merge subentity data into main array.       
        recdata_subentity_array := recdata_subentity_array multiset union all temp_recdata_subentity_array; 

   end loop;    

   end if;

 -- Consolidate data arrays.  
   recdata_consoliate_array := recdata_dc1_array multiset union all recdata_subentity_array;

-- Return consolidated metadata. 
    RETURN recdata_consoliate_array;
  
--   EXCEPTION WHEN OTHERS THEN dbms_output.put_Line(v_Sql);
   	 

END;

>>

<<

CREATE OR REPLACE FUNCTION fn_axpanalytics_se_listdata(pentity_transid varchar2, pflds_keyval clob, ppagesize numeric DEFAULT 50, ppageno numeric DEFAULT 1)
RETURN SYS.ODCIVARCHAR2LIST
--RETURN varchar2
is 
    
v_sql clob;
v_sql1 clob;
--v_pfldtablename varchar2(3000);
v_fldname_table varchar2(300);
v_fldname_transid  varchar2(3000);
v_fldname_col  varchar2(3000);
v_fldname_normalized  varchar2(3000);
v_fldname_srctbl  varchar2(3000);
v_fldname_srcfld  varchar2(3000);
v_fldname_allowempty  varchar2(3000);
v_fldname_transidcnd number;
v_allflds  varchar2(3000);
v_fldnamesary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_fldname_join  varchar2(3000);
v_fldname_joinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_fldname_tblflds varchar2(4000);
v_emptyary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_pflds_transid  varchar2(3000); 
v_pflds_flds  varchar2(3000);
v_pflds_keyvalue  varchar2(3000);
v_pflds_keytable varchar2(200);
v_keyvalue_fname  varchar2(3000);
v_keyvalue_fvalue  varchar2(3000);
v_keyvalue_fname_srckey varchar2(10);
v_keyvalue_fname_srctbl varchar2(50);
v_keyvalue_fname_srcfld varchar2(50);
v_final_sqls SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_fldname_dcjoinsary SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
v_primarydctable varchar2(3000);
v_fields_list varchar2(3000);
v_filter_dcjoinuniq varchar2(3000);
v_fldname_joinsuniq varchar2(3000);
--v_recdata_json clob;
begin	


	
	/*
	 * transid=fldlist=dependfld~depvalue~dependtblname~dependfldprops++transid2=fldlist=dependfld~depvalue
	 * pflds_keyval - transid=tablename!~fldname~normalized~source_table~source_fld~allowempty|fldname2~normalized~source_table~source_fld~allowempty^tablename2!~fldname~normalized~srctbl~srcfld~allowempty=dependfld~dependval++
	 * transid2=tablename!~fldname~normalized~source_table~source_fld~allowempty|fldname2~normalized~source_table~source_fld~allowempty=dependfld~dependval		 
	 */

	FOR rec in  (select column_value as fldkeyvals from  table(string_to_array(pflds_keyval,'++')))    	 
    loop

	    	v_pflds_transid := split_part(rec.fldkeyvals,'=',1);
	    	v_pflds_flds := split_part(rec.fldkeyvals,'=',2);
	    	v_pflds_keyvalue := split_part(rec.fldkeyvals,'=',3);
	    	v_pflds_keytable := split_part(v_pflds_keyvalue,'~',3) ;  
	    	v_keyvalue_fname := split_part(v_pflds_keyvalue,'~',1);
			v_keyvalue_fvalue := split_part(v_pflds_keyvalue,'~',2);		
			v_keyvalue_fname_srckey := split_part(v_pflds_keyvalue,'~',4) ;
			v_keyvalue_fname_srctbl := split_part(v_pflds_keyvalue,'~',5) ;
			v_keyvalue_fname_srcfld := split_part(v_pflds_keyvalue,'~',6) ;	
	    
	    	select tablename into v_primarydctable from axpdc where tstruct =v_pflds_transid and dname ='dc1';
	    
	    	select count(1) into v_fldname_transidcnd from axpflds where tstruct = v_pflds_transid and dcname ='dc1' and lower(fname)='transid';
	    
	    	if  lower(v_pflds_keytable) = lower(v_primarydctable) and v_pflds_flds ='All' then
	    		select tablename||'!~'||listagg(str,'|') within group ( order by dcname ,ordno)  into  v_allflds From(
				select tablename,(fname||'~'||srckey||'~'||srctf||'~'||srcfld||'~'||allowempty) str,
                dcname,ordno
				from axpflds where tstruct=v_pflds_transid and 
				dcname ='dc1' and asgrid ='F' and hidden ='F' and savevalue='T' AND datatype not in('i','t') )a GROUP BY tablename;		    	
			ELSIF lower(v_pflds_keytable) != lower(v_primarydctable) and v_pflds_flds ='All' THEN
				select tablename||'!~'||listagg(str,'|') within group ( order by dcname ,ordno)||'^'||
				v_pflds_keytable||'!~'||split_part(split_part(v_pflds_keyvalue,'~',1),'.',2)||'~'||
				split_part(v_pflds_keyvalue,'~',4)||'~'||split_part(v_pflds_keyvalue,'~',5)||'~'||
				split_part(v_pflds_keyvalue,'~',6)||'~'||split_part(v_pflds_keyvalue,'~',7)
				into  v_allflds From(
				select tablename,(fname||'~'||srckey||'~'||srctf||'~'||srcfld||'~'||allowempty) str,
                dcname,ordno
				from axpflds where tstruct=v_pflds_transid and 
				dcname ='dc1' and asgrid ='F' and hidden ='F' and savevalue='T' AND datatype not in('i','t'))a GROUP BY tablename;	
	    	end if;
			
	    	v_fields_list := case when v_pflds_flds='All' then v_allflds else v_pflds_flds end;

	    for rec1 in (select column_value as tblflds from table(string_to_array(v_fields_list,'^'))) 
	    	loop
			    v_fldname_table := 	split_part(rec1.tblflds,'!~',1);
		    	v_fldname_tblflds := 	split_part(rec1.tblflds,'!~',2);  	
		    
		    if 	lower(v_fldname_table)!=lower(v_primarydctable) then								
				v_fldname_dcjoinsary.EXTEND;
	            v_fldname_dcjoinsary(v_fldname_dcjoinsary.COUNT) := ('left join '||v_fldname_table||' on '||v_primarydctable||'.'||v_primarydctable||'id='||v_fldname_table||'.'||v_primarydctable||'id');
			end if;
		
		
			IF	lower(v_fldname_table)!=lower(v_pflds_keytable) then								
				v_fldname_dcjoinsary.EXTEND;
				v_fldname_dcjoinsary(v_fldname_dcjoinsary.COUNT) := ('left join '||v_pflds_keytable||' on '||v_primarydctable||'.'||v_primarydctable||'id='||v_pflds_keytable||'.'||v_primarydctable||'id');
			end if;
		
			IF	v_keyvalue_fname_srckey='T' then 				
				v_fldname_joinsary .EXTEND;
				v_fldname_joinsary (v_fldname_joinsary.COUNT):= (' join ' ||v_keyvalue_fname_srctbl||' on '||v_keyvalue_fname||' = '||v_keyvalue_fname_srctbl||'.'||v_keyvalue_fname_srctbl||'id');
			end if;
		    	                
			    FOR rec2 in			    	
    				(select column_value as fldname from table(string_to_array(v_fldname_tblflds,'|'))) 
						loop		    									
							v_fldname_col := split_part(rec2.fldname,'~',1);
							v_fldname_normalized := split_part(rec2.fldname,'~',2);
							v_fldname_srctbl := split_part(rec2.fldname,'~',3);
							v_fldname_srcfld := split_part(rec2.fldname,'~',4);														
							v_fldname_allowempty := split_part(rec2.fldname,'~',5);
							--v_keyvalue_fname := split_part(v_pflds_keyvalue,'~',1);
							--v_keyvalue_fvalue := split_part(v_pflds_keyvalue,'~',2);		
													

							if v_fldname_normalized ='F' then 
                             v_fldnamesary.EXTEND;
                             v_fldnamesary(v_fldnamesary.COUNT) := (v_fldname_table||'.'||v_fldname_col);

							elsif v_fldname_normalized ='T' then	
                             v_fldnamesary.EXTEND;
                             v_fldnamesary(v_fldnamesary.COUNT) := (v_fldname_col||'.'||v_fldname_srcfld||' '||v_fldname_col);	

                             v_fldname_joinsary.EXTEND;
                             v_fldname_joinsary(v_fldname_joinsary.COUNT) := (case when v_fldname_allowempty='F' then ' join ' else ' left join ' end||v_fldname_srctbl||' '||v_fldname_col||' on '||v_fldname_table||'.'||v_fldname_col||' = '||v_fldname_col||'.'||v_fldname_srctbl||'id');

							 end if;	

			    		end loop;
	    	end loop;
	    
	    	
	    	SELECT listagg(column_value,' ') WITHIN group(ORDER BY 1) INTO v_filter_dcjoinuniq from(select distinct column_value from   table(v_fldname_dcjoinsary));
			SELECT listagg(column_value,' ') WITHIN group(ORDER BY 1) INTO v_fldname_joinsuniq from(select distinct column_value from   table(v_fldname_joinsary));
		
		   					v_sql := (' select '||''''||v_pflds_transid||''' transid,'||v_primarydctable||'.'||v_primarydctable||'id recordid,'||v_primarydctable||'.username modifiedby,'||v_primarydctable||'.modifiedon,'||v_primarydctable||'.createdon,'||v_primarydctable||'.createdby,'||array_to_string(v_fldnamesary,',')
		   			 ||' from '
		   			 ||v_primarydctable||' '||v_filter_dcjoinuniq||' '||v_fldname_joinsuniq
		   			 ||' where '||v_primarydctable||'.cancel=''F'' and '
                     ||case when v_fldname_transidcnd>0 then v_primarydctable||'.transid='||''''||v_pflds_transid||''' and ' END
                     ||case when v_keyvalue_fname_srckey='T'  then v_keyvalue_fname_srctbl||'.'||v_keyvalue_fname_srcfld else v_keyvalue_fname end ||'='||v_keyvalue_fvalue
                     ||'				
					--axp_filter');

		   				v_fldnamesary:= v_emptyary;
		   				v_fldname_joinsary:= v_emptyary;	  
		   				v_fldname_dcjoinsary:=v_emptyary; 
		   				

       v_sql1 :='select * from(                        
                        select a.*,row_number() over(order by modifiedon desc) rno,'||ppageno||' as  pageno  
                           from ( '||v_sql||' )a where rownum <='||(ppagesize*ppageno)||' order by modifiedon desc             
                                ) b  where rno between '||(ppagesize*(ppageno-1)+1)||' and '||(ppagesize*ppageno);


	v_final_sqls.EXTEND;
	v_final_sqls(v_final_sqls.COUNT) := (v_sql1);
    END LOOP;

   	
--return v_fldname_tblflds; 
RETURN v_final_sqls;
END;

>>

<<

alter table axpages add oldappurl varchar2(500);

>>

<<

CREATE OR REPLACE VIEW "AXP_APPSEARCH_DATA_NEW"  AS 
SELECT 2 AS slno,
          hltype,
          structname,
          TRIM (REPLACE (searchtext, 'View', ' ')) AS searchtext,
          params,a.oldappurl
     FROM axp_appsearch_data_v2 join axpages a on    
   case axp_appsearch_data_v2.hltype when 'iview' then 'i'||axp_appsearch_data_v2.structname 
   when 'tstruct' then 't'||axp_appsearch_data_v2.structname 
   else axp_appsearch_data_v2.structname end = case when axp_appsearch_data_v2.hltype ='Page' then a.name else a.pagetype end 
    WHERE LOWER (PARAMS) NOT LIKE '%sysdate%'
    UNION ALL    
   SELECT 1.9 AS slno,
          hltype,
          structname,
          TRIM (REPLACE (searchtext, 'View', ' ')) AS searchtext,
          params,p.oldappurl
     FROM axp_appsearch_data a join axpages p on    
   case hltype when 'iview' then 'i'||a.structname 
   when 'tstruct' then 't'||a.structname 
   else a.structname end = case when hltype ='Page' then p.name else p.pagetype end 
    WHERE  not exists (Select 'x'  from   axp_appsearch_data_v2 b where a.structname=b.structname and a.params=b.params)    
   UNION ALL   
   SELECT 2,
          hltype,
          structname,
          TRIM (REPLACE (searchtext, 'View', ' ')) AS searchtext,
          REPLACE (
             REPLACE (
                REPLACE (
                   REPLACE (
                      REPLACE (
                         REPLACE (
                            REPLACE (
                               REPLACE (
                                  REPLACE (
                                     PARAMS,
                                     'trunc(add_months(sysdate,0-1),''MM'')',
                                     TRIM (
                                        TO_CHAR (
                                           TRUNC (
                                              ADD_MONTHS (SYSDATE, 0 - 1),
                                              'MM'),
                                           'dd/mm/yyyy'))),
                                  'last_day(add_months(trunc(sysdate),0-1))',
                                  TRIM (
                                     TO_CHAR (
                                        LAST_DAY (
                                           ADD_MONTHS (TRUNC (SYSDATE),
                                                       0 - 1)),
                                        'dd/mm/yyyy'))),
                               'trunc(sysdate)-1',
                               TRIM (
                                  TO_CHAR (TRUNC (SYSDATE) - 1, 'dd/mm/yyyy'))),
                            'trunc(sysdate)',
                            TRIM (TO_CHAR (TRUNC (SYSDATE), 'dd/mm/yyyy'))),
                         'trunc(sysdate,''IW'')',
                         TRIM (TO_CHAR (TRUNC (SYSDATE, 'IW'), 'dd/mm/yyyy'))),
                      'trunc(sysdate-7,''IW'')+6',
                      TRIM (
                         TO_CHAR (TRUNC (SYSDATE - 7, 'IW') + 6,
                                  'dd/mm/yyyy'))),
                   'trunc(sysdate-7,''IW'')',
                   TRIM (TO_CHAR (TRUNC (SYSDATE - 7, 'IW'), 'dd/mm/yyyy'))),
                'trunc(sysdate,''MM'')',
                TRIM (TO_CHAR (TRUNC (SYSDATE, 'MM'), 'dd/mm/yyyy'))),
             ' &',
             '&')
             AS params,a.oldappurl
     FROM axp_appsearch_data_v2 join axpages a on    
   case hltype when 'iview' then 'i'||axp_appsearch_data_v2.structname 
   when 'tstruct' then 't'||axp_appsearch_data_v2.structname 
   else axp_appsearch_data_v2.structname end = case when hltype ='Page' then a.name else a.pagetype end 
    WHERE LOWER (PARAMS) LIKE '%sysdate%'    
   UNION ALL   
   SELECT 1 AS ord,
          'tstruct' AS hltype,
          t.name AS structname,
          t.caption AS searchtext,
          NULL params,p.oldappurl
     FROM tstructs t JOIN axpages p ON 't'||t.name = p.PAGETYPE 
    WHERE t.blobno = 1
          AND EXISTS
                 (SELECT 'x'
                    FROM axp_vw_menu x
                   WHERE     x.pagetype LIKE 't%'
                         AND TRIM (SUBSTR (x.pagetype, 2, 20)) = t.name
                         AND x.visible NOT LIKE '%F%')                        
   UNION ALL   
   SELECT 0 AS ord,
          'iview' AS hltype,
          i.name AS structname,
          i.caption AS searchtext,
          NULL params,p.oldappurl
     FROM iviews i JOIN axpages p ON 'i'||i.name = p.PAGETYPE 
    WHERE i.blobno = 1
          AND EXISTS
                 (SELECT 'x'
                    FROM axp_vw_menu x
                   WHERE     x.pagetype LIKE 'i%'
                         AND TRIM (SUBSTR (x.pagetype, 2, 20)) = i.name
                         AND x.visible NOT LIKE '%F%')                        
UNION ALL 
SELECT 3 AS slno,
    'htmlpages' hltype,
    SUBSTR(axp_vw_menu.name,3) AS structname,
    axp_vw_menu.caption AS searchtext,
    NULL params,p.oldappurl
from axp_vw_menu JOIN axpages p ON axp_vw_menu.name = p.name  
where axp_vw_menu.pagetype='web' and axp_vw_menu.websubtype='htmlpage'
   ORDER BY 1;

>>   

<<
  
CREATE OR REPLACE VIEW AXP_APPSEARCH AS
  SELECT
	UNIQUE
          SEARCHTEXT,
	PARAMS|| CASE
		WHEN PARAMS IS NOT NULL
		AND LOWER(PARAMS) NOT LIKE '%~act%' THEN '~act=load'
		ELSE NULL
	END            AS PARAMS,
	HLTYPE,
	STRUCTNAME,
	USERNAME,oldappurl
FROM
	(
	SELECT
		s.slno,
		s.searchtext,
		s.params,
		s.hltype,
		s.structname,
		lg.username,s.oldappurl
	FROM
		axp_appsearch_data_NEW s,
		axuseraccess a,
		axusergroups g,
		axuserlevelgroups lg
	WHERE
		a.sname = s.structname
		AND a.rname = g.userroles
		AND g.groupname = lg.usergroup
		AND a.stype IN ('t', 'i')
	GROUP BY
		s.searchtext,
		s.params,
		s.hltype,
		s.structname,
		lg.username,
		s.slno,s.oldappurl
UNION
	SELECT
		b.slno,
		b.searchtext,
		b.params,
		b.hltype,
		b.structname,
		lg.username,b.oldappurl
	FROM
		axuserlevelgroups lg,
		(
		SELECT
			DISTINCT s.searchtext,
			s.params,
			s.hltype,
			s.structname,
			NULL slno,s.oldappurl
		FROM
			axp_appsearch_data_NEW s,
			axuseraccess a
		WHERE
			a.sname(+) = s.structname
			AND a.stype(+) IN ('t', 'i')) b
	WHERE
		lg.usergroup = 'default'
	ORDER BY
		slno,
		username);
>>