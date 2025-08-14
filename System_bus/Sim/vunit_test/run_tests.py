# tests/vunit_tests/run_tests.py
from vunit import VUnit
import os

# 创建VUnit实例
vu = VUnit.from_argv()
vu.add_vhdl_builtins()

# 添加源文件
src_path = os.path.join(os.path.dirname(__file__), '..', '..', 'src')
vu.add_library("compression_config").add_source_files(
    os.path.join(src_path, "compression_config", "*.vhd")
)

# 添加测试台
tb_path = os.path.join(src_path, "testbenches")
vu.add_library("tb_lib").add_source_files(
    os.path.join(tb_path, "*.vhd")
)

# 配置测试
lib = vu.library("tb_lib")

# 配置控制器测试
config_tb = lib.test_bench("tb_configuration_controller")
config_tb.add_config(
    name="basic_test",
    generics=dict(
        TEST_CASE="basic_configuration"
    )
)
config_tb.add_config(
    name="error_test", 
    generics=dict(
        TEST_CASE="error_handling"
    )
)

# 参数内存测试
mem_tb = lib.test_bench("tb_parameter_mem")
for size in [256, 512, 1024]:
    mem_tb.add_config(
        name=f"mem_size_{size}",
        generics=dict(
            DEPTH=size,
            TEST_CASE="memory_operations"
        )
    )

# 运行测试
vu.main()