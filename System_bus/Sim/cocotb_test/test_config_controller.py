# tests/cocotb_tests/test_config_controller.py
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.result import TestFailure
import random

class ConfigControllerTB:
    def __init__(self, dut):
        self.dut = dut
        
    async def reset(self):
        """复位DUT"""
        self.dut.rst_n.value = 0
        await Timer(100, units='ns')
        self.dut.rst_n.value = 1
        await Timer(100, units='ns')
        
    async def write_config_byte(self, addr, data):
        """写入8位配置数据"""
        self.dut.config_if_in_add.value = addr
        self.dut.config_if_in_w_data.value = data
        self.dut.config_if_in_write_en.value = 1
        await RisingEdge(self.dut.clk)
        self.dut.config_if_in_write_en.value = 0
        
    async def read_config_reg(self, addr):
        """读取配置寄存器"""
        self.dut.config_if_in_add.value = addr
        self.dut.config_if_in_read_en.value = 1
        await RisingEdge(self.dut.clk)
        self.dut.config_if_in_read_en.value = 0
        await Timer(10, units='ns')
        return self.dut.config_if_out_r_data.value
        
    async def configure_ccsds121(self):
        """配置CCSDS121参数"""
        # 配置4个32位字 (16字节)
        config_data = [
            0x12, 0x34, 0x56, 0x78,  # Word 0
            0x9A, 0xBC, 0xDE, 0xF0,  # Word 1
            0x11, 0x22, 0x33, 0x44,  # Word 2
            0x55, 0x66, 0x77, 0x88   # Word 3
        ]
        
        for i, data in enumerate(config_data):
            await self.write_config_byte(i, data)
            
    async def start_configuration(self):
        """启动配置过程"""
        # 写入控制寄存器
        control_val = (1 << 0) | (1 << 2)  # Enable 121 + Start config
        await self.write_config_byte(0x60, control_val)

@cocotb.test()
async def test_basic_configuration(dut):
    """基本配置测试"""
    tb = ConfigControllerTB(dut)
    
    # 启动时钟
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 复位
    await tb.reset()
    
    # 配置CCSDS121
    await tb.configure_ccsds121()
    
    # 启动配置
    await tb.start_configuration()
    
    # 等待配置完成
    timeout = 1000
    while timeout > 0:
        status = await tb.read_config_reg(0x70)
        if status & 0x01:  # Config done bit
            break
        await Timer(10, units='ns')
        timeout -= 1
        
    if timeout == 0:
        raise TestFailure("Configuration timeout")
        
    dut._log.info("Configuration completed successfully")

@cocotb.test()
async def test_error_handling(dut):
    """错误处理测试"""
    tb = ConfigControllerTB(dut)
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    await tb.reset()
    
    # 模拟AHB错误响应
    dut.ahb_master_in_hresp.value = 0b01  # ERROR
    
    await tb.configure_ccsds121()
    await tb.start_configuration()
    
    # 检查错误状态
    await Timer(500, units='ns')
    status = await tb.read_config_reg(0x70)
    
    if not (status & 0x02):  # Error bit
        raise TestFailure("Error not detected")
        
    dut._log.info("Error handling test passed")