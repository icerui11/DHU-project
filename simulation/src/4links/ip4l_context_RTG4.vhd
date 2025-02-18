-- context for OpenSource SpaceWire Packages 
-- comment sections as required

-- SpW Codec Context 
context spw_context is
	library spw;
	use spw.spw_data_types.all;
	use spw.spw_codes.all;
	
	library std;
	use std.env.finish;	-- allows finish keyword to be called to end a simulation without error assertions...
	
end context spw_context;

-- RMAP Target/Initiator Context
context rmap_context is 
    library rmap;
    use rmap.rmap_initiator_lib.all;
    
    library spw;
	use spw.spw_data_types.all;
	use spw.spw_codes.all;
	
	library std;
	use std.env.finish;
    
end context rmap_context;

-- RMAP Router Context 
context router_context is
    library router;
    use router.router_pckg.all;	
	use router.router_records.all;
	
	library rmap;
    use rmap.rmap_initiator_lib.all;
	
	library spw;
	use spw.spw_data_types.all;
	use spw.spw_codes.all;

	library std;
	use std.env.finish;
	
	
end context router_context;
