# pl-sql
commons package has following procedures:	
	  UTIL_GEN_INSERTS
      Accepts select statement and generates insert statements
    UTIL_GET_ENA_DIS_TAB_TRIG       
      It is usefull   
	  shredClob
       TOAD and SQL developer can't properly generate insert statements for large clob columns. Clob has to be cut on smaller pieces. 
       This function does that and is used by UTIL_GEN_INSERTS
		UTIL_EXPORT_CLOB_TO_FILE											
       Oracle supports writing 32k clobs in one chunk. This function shreds files into smaller chunks and flushes them to disk.
		UTIL_GET_HTML_TABLE
      Generates html table based on select statement
		UTIL_GET_HTML								
      Generates simple html report based on UTIL_GET_HTML_TABLE (sql statement)	 
      
		UTIL_GET_XML_FROM_REFCUR											
		UTIL_GET_CLOB_FROM_REFCUR                
