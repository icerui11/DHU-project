#componet library and work directory
set ACTELLIBNAME SmartFusion2
set PROJECT_DIR "C:/Users/yinrui/Desktop/03Test/SpW_router/SpW_router_instant"

set lib_exist [file exists work]
if $lib_exist==1 {vdel -all -lib work}
vlib work
set lib_exist [file exists rmap]
if $lib_exist==1 {vdel -all -lib rmap}
vlib rmap
set lib_exist [file exists spw]
if $lib_exist==1 {vdel -all -lib spw}
vlib spw
set lib_exist [file exists std]
if $lib_exist==1 {vdel -all -lib std}
vlib std

#compile the design
