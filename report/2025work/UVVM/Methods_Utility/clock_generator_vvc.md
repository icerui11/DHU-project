# clock generator VVC

example: start_clock(CLOCK_GENERATOR_VCCT, 1, "Start clock generator");

set_clock_period(CLOCK_GENERATOR_VVCT, 1, 10ns, "change clock period to 10ns");

## procedure

procedure start_clock(
    signal   VVCT             : inout t_vvc_target_record;
    constant vvc_instance_idx : in integer;
    constant msg              : in string;
    constant scope            : in string := C_VVC_CMD_SCOPE_DEFAULT
  ) is
      constant proc_name : string := "start_clock";
      constant proc_call : string := proc_name & "(" & to_string(VVCT, vvc_instance_idx) -- First part common for all
                                                    & ")";
begin
      set_general_target_and_command_fields(VVCT, vvc_instance_idx, proc_call, msg, QUEUED, START_CLOCK);
      send_command_to_vvc(VVCT, scope => scope);
end procedure start_clock;
