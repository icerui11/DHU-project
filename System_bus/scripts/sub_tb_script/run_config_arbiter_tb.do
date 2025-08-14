#set DUT C:/Users/yinrui/Desktop/Envison_DHU
#do $DUT/DHU-project/System_bus/scripts/sub_tb_script/run_config_arbiter_tb.do
# Create work library

# Compile source files
# 编译源文件
echo "Compiling source files..."
echo "编译源文件..."

# Compile package first
# 首先编译包文件
vcom -2008 $DUT/DHU-project/System_bus/RTL/config_controller/config_pkg.vhd
vcom -2008 $DUT/DHU-project/System_bus/RTL/config_controller/config_types_pkg.vhd

# Compile DUT
# 编译被测设备
vcom -2008 $DUT/DHU-project/System_bus/RTL/config_controller/config_arbiter.vhd

# Compile testbench
# 编译测试平台
vcom -2008 $DUT/DHU-project/System_bus/RTL/config_controller/sub_tb/config_arbiter_tb.vhd

# Start simulation
# 开始仿真
echo "Starting simulation..."
echo "开始仿真..."

vsim -t 1ns config_arbiter_tb -voptargs="+acc"

# Add signals to waveform
# 添加信号到波形窗口
add wave -position end  sim:/config_arbiter_tb/DUT/clk
add wave -position end  sim:/config_arbiter_tb/DUT/rst_n
add wave -position end  sim:/config_arbiter_tb/DUT/compressor_status_HR
add wave -position end  sim:/config_arbiter_tb/DUT/compressor_status_LR
add wave -position end  sim:/config_arbiter_tb/DUT/compressor_status_H
add wave -position end  sim:/config_arbiter_tb/DUT/config_done
add wave -position end  sim:/config_arbiter_tb/DUT/config_req
add wave -position end  sim:/config_arbiter_tb/DUT/grant
add wave -position end  sim:/config_arbiter_tb/DUT/grant_valid

# Run simulation
# 运行仿真
echo "Running testbench..."
echo "运行测试平台..."

run -all

# Zoom to fit
# 缩放以适应
wave zoom full

echo "Simulation completed. Check console output for test results."
echo "仿真完成。检查控制台输出以获取测试结果。"

echo "Test Summary:"
echo "测试摘要："
echo "- Reset functionality test"
echo "- Single compressor request test"  
echo "- Round-robin arbitration test"
echo "- No request handling test"
echo "- Priority order verification"
echo ""
echo "- 复位功能测试"
echo "- 单压缩器请求测试"
echo "- 轮询仲裁测试"
echo "- 无请求处理测试"
echo "- 优先级顺序验证"