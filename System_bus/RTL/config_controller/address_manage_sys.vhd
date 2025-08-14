-- 改进的地址管理系统，使用结构化的方法来处理多核心配置
-- Improved address management system using structured approach for multi-core configuration

-- 配置目标类型，清晰地定义支持的配置模式
-- Configuration target type, clearly defining supported configuration modes
type config_target_type is (
    TARGET_HR_DUAL,    -- HR: CCSDS123_1 + CCSDS121 (高分辨率双核心)
    TARGET_LR_DUAL,    -- LR: CCSDS123_2 + CCSDS121 (低分辨率双核心)  
    TARGET_H_SINGLE    -- H:  CCSDS121 only (仅超光谱核心)
);

-- 核心配置描述符，包含每个配置目标的所有必要信息
-- Core configuration descriptor containing all necessary info for each target
type core_config_descriptor is record
    target_type      : config_target_type;        -- 目标类型 | Target type
    total_regs       : unsigned(3 downto 0);      -- 总寄存器数 | Total register count
    ccsds123_regs    : unsigned(3 downto 0);      -- CCSDS123寄存器数 | CCSDS123 register count
    ccsds121_regs    : unsigned(3 downto 0);      -- CCSDS121寄存器数 | CCSDS121 register count
    ccsds123_base    : std_logic_vector(31 downto 0); -- CCSDS123基地址 | CCSDS123 base address
    ccsds121_base    : std_logic_vector(31 downto 0); -- CCSDS121基地址 | CCSDS121 base address
    ram_base_addr    : std_logic_vector(4 downto 0);  -- RAM基地址 | RAM base address
end record;

-- 配置描述符数组，预定义所有支持的配置
-- Configuration descriptor array, predefining all supported configurations
type config_descriptor_array is array (config_target_type) of core_config_descriptor;

-- 常量配置表，这种方法使配置管理变得非常清晰
-- Constant configuration table, this approach makes configuration management very clear
constant CONFIG_DESCRIPTORS : config_descriptor_array := (
    TARGET_HR_DUAL => (
        target_type   => TARGET_HR_DUAL,
        total_regs    => to_unsigned(10, 4),  -- 6 + 4 寄存器
        ccsds123_regs => to_unsigned(6, 4),   -- CCSDS123 配置寄存器数量
        ccsds121_regs => to_unsigned(4, 4),   -- CCSDS121 配置寄存器数量
        ccsds123_base => ccsds123_1_base,     -- 来自generic的基地址
        ccsds121_base => ccsds121_base,       -- 来自generic的基地址
        ram_base_addr => "00000"              -- HR配置数据在RAM中的起始地址
    ),
    
    TARGET_LR_DUAL => (
        target_type   => TARGET_LR_DUAL,
        total_regs    => to_unsigned(10, 4),
        ccsds123_regs => to_unsigned(6, 4),
        ccsds121_regs => to_unsigned(4, 4),
        ccsds123_base => ccsds123_2_base,
        ccsds121_base => ccsds121_base,
        ram_base_addr => "01010"              -- LR配置数据在RAM中的起始地址(偏移10)
    ),
    
    TARGET_H_SINGLE => (
        target_type   => TARGET_H_SINGLE,
        total_regs    => to_unsigned(4, 4),   -- 仅4个CCSDS121寄存器
        ccsds123_regs => to_unsigned(0, 4),   -- 没有CCSDS123寄存器
        ccsds121_regs => to_unsigned(4, 4),
        ccsds123_base => (others => '0'),     -- 未使用
        ccsds121_base => ccsds121_base,
        ram_base_addr => "10100"              -- H配置数据在RAM中的起始地址(偏移20)
    )
);

-- 地址生成器状态记录
-- Address generator state record
type addr_gen_type is record
    current_target    : config_target_type;           -- 当前配置目标 | Current configuration target
    current_core      : std_logic;                    -- '0'=CCSDS123, '1'=CCSDS121
    reg_index         : unsigned(3 downto 0);         -- 当前寄存器索引 | Current register index
    write_addr        : std_logic_vector(31 downto 0); -- 当前写地址 | Current write address
    ram_addr          : std_logic_vector(4 downto 0);  -- 当前RAM地址 | Current RAM address
    phase_complete    : std_logic;                     -- 当前阶段完成标志 | Current phase complete flag
end record;

signal addr_gen : addr_gen_type;

-- 智能地址生成器函数，根据当前状态计算下一个地址
-- Intelligent address generator function, calculates next address based on current state
function get_next_address(
    current_addr_gen : addr_gen_type;
    config_desc      : core_config_descriptor
) return addr_gen_type is
    variable next_addr_gen : addr_gen_type;
begin
    next_addr_gen := current_addr_gen;
    
    -- 根据当前核心和寄存器索引计算下一个地址
    -- Calculate next address based on current core and register index
    if current_addr_gen.current_core = '0' then
        -- 当前在CCSDS123核心
        -- Currently in CCSDS123 core
        if current_addr_gen.reg_index < config_desc.ccsds123_regs - 1 then
            -- 继续在CCSDS123核心内
            -- Continue within CCSDS123 core
            next_addr_gen.reg_index := current_addr_gen.reg_index + 1;
            next_addr_gen.write_addr := 
                std_logic_vector(unsigned(config_desc.ccsds123_base) + 
                                (current_addr_gen.reg_index + 1) * 4);
        else
            -- 切换到CCSDS121核心
            -- Switch to CCSDS121 core
            if config_desc.ccsds121_regs > 0 then
                next_addr_gen.current_core := '1';
                next_addr_gen.reg_index := (others => '0');
                next_addr_gen.write_addr := config_desc.ccsds121_base;
            else
                next_addr_gen.phase_complete := '1';
            end if;
        end if;
    else
        -- 当前在CCSDS121核心
        -- Currently in CCSDS121 core
        if current_addr_gen.reg_index < config_desc.ccsds121_regs - 1 then
            -- 继续在CCSDS121核心内
            -- Continue within CCSDS121 core
            next_addr_gen.reg_index := current_addr_gen.reg_index + 1;
            next_addr_gen.write_addr := 
                std_logic_vector(unsigned(config_desc.ccsds121_base) + 
                                (current_addr_gen.reg_index + 1) * 4);
        else
            -- 所有寄存器配置完成
            -- All registers configured
            next_addr_gen.phase_complete := '1';
        end if;
    end if;
    
    -- RAM地址始终递增
    -- RAM address always increments
    next_addr_gen.ram_addr := 
        std_logic_vector(unsigned(current_addr_gen.ram_addr) + 1);
    
    return next_addr_gen;
end function get_next_address;

-- 配置目标解码器进程，根据压缩器状态确定配置目标
-- Configuration target decoder process, determines target based on compressor status
config_target_decoder: process(compressor_status_HR, compressor_status_LR, compressor_status_H)
    variable target : config_target_type;
    variable target_valid : std_logic;
begin
    target_valid := '0';
    
    -- 优先级编码：HR > LR > H
    -- Priority encoding: HR > LR > H
    if compressor_status_HR.config_req = '1' then
        target := TARGET_HR_DUAL;
        target_valid := '1';
    elsif compressor_status_LR.config_req = '1' then
        target := TARGET_LR_DUAL;
        target_valid := '1';
    elsif compressor_status_H.config_req = '1' then
        target := TARGET_H_SINGLE;
        target_valid := '1';
    end if;
    
    -- 输出解码结果
    -- Output decoding results
    current_config_target <= target;
    config_target_valid <= target_valid;
end process config_target_decoder;

-- 主地址生成进程，管理整个配置序列的地址生成
-- Main address generation process, manages address generation for entire configuration sequence
address_generator_proc: process(clk, rst_n)
    variable current_descriptor : core_config_descriptor;
begin
    if rst_n = '0' then
        addr_gen.current_target <= TARGET_HR_DUAL;
        addr_gen.current_core <= '0';
        addr_gen.reg_index <= (others => '0');
        addr_gen.write_addr <= (others => '0');
        addr_gen.ram_addr <= (others => '0');
        addr_gen.phase_complete <= '0';
    elsif rising_edge(clk) then
        case ctrl_reg.state is
            when CONFIG_REQ =>
                -- 初始化地址生成器
                -- Initialize address generator
                addr_gen.current_target <= current_config_target;
                addr_gen.current_core <= '0';  -- 总是从CCSDS123开始(如果有的话)
                addr_gen.reg_index <= (others => '0');
                addr_gen.phase_complete <= '0';
                
                -- 根据目标类型设置初始地址
                -- Set initial addresses based on target type
                current_descriptor := CONFIG_DESCRIPTORS(current_config_target);
                addr_gen.ram_addr <= current_descriptor.ram_base_addr;
                
                if current_descriptor.ccsds123_regs > 0 then
                    addr_gen.write_addr <= current_descriptor.ccsds123_base;
                else
                    addr_gen.current_core <= '1';
                    addr_gen.write_addr <= current_descriptor.ccsds121_base;
                end if;
                
            when AHB_WRITE_SINGLE | AHB_WRITE_BURST =>
                -- 每次成功写入后生成下一个地址
                -- Generate next address after each successful write
                if ctrl.o.update = '1' and ctrl.o.hready = '1' then
                    current_descriptor := CONFIG_DESCRIPTORS(addr_gen.current_target);
                    addr_gen <= get_next_address(addr_gen, current_descriptor);
                end if;
                
            when others =>
                -- 保持当前状态
                -- Maintain current state
        end case;
    end if;
end process address_generator_proc;