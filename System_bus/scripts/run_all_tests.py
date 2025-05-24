# scripts/run_all_tests.py
#!/usr/bin/env python3

import subprocess
import sys
import os
from pathlib import Path

def run_command(cmd, cwd=None):
    """运行命令并返回结果"""
    try:
        result = subprocess.run(
            cmd, 
            shell=True, 
            cwd=cwd,
            capture_output=True, 
            text=True,
            check=True
        )
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, e.stderr

def main():
    """主测试流程"""
    project_root = Path(__file__).parent.parent
    
    print("=== 开始运行所有测试 ===")
    
    # 1. 运行Cocotb测试
    print("\n1. 运行Cocotb测试...")
    cocotb_dir = project_root / "tests" / "cocotb_tests"
    success, output = run_command("python -m pytest test_*.py -v", cwd=cocotb_dir)
    
    if success:
        print("✓ Cocotb测试通过")
        print(output)
    else:
        print("✗ Cocotb测试失败")
        print(output)
        return 1
    
    # 2. 运行VUnit测试
    print("\n2. 运行VUnit测试...")
    vunit_dir = project_root / "tests" / "vunit_tests"
    success, output = run_command("python run_tests.py", cwd=vunit_dir)
    
    if success:
        print("✓ VUnit测试通过")
    else:
        print("✗ VUnit测试失败")
        print(output)
        return 1
    
    print("\n=== 所有测试完成 ===")
    return 0

if __name__ == "__main__":
    sys.exit(main())