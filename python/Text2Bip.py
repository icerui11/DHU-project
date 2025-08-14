#!/usr/bin/env python3

import sys
import struct
import re

def convert_txt_to_bip(input_file, output_file):
    """将TXT文件转换为BIP格式 | Convert TXT file to BIP format"""
    try:
        with open(input_file, 'r') as f_in:
            lines = f_in.readlines()
        
        # 过滤注释和空行 | Filter comments and empty lines
        data = []
        for line in lines:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            data.append(line)
        
        with open(output_file, 'wb') as f_out:
            # 写入BIP头 | Write BIP header
            f_out.write(b'BIP;')           # BIP标识符 | BIP identifier
            f_out.write(struct.pack('<I', 1))  # 版本号 | Version number
            
            # 写入数据长度 | Write data length
            f_out.write(struct.pack('<I', len(data)))
            
            # 写入数据 | Write data
            for value in data:
                if re.match(r'^0x[0-9A-Fa-f]+$', value):
                    # 十六进制值 | Hexadecimal value
                    int_value = int(value, 16)
                elif re.match(r'^0b[01]+$', value):
                    # 二进制值 | Binary value
                    int_value = int(value, 2)
                else:
                    # 十进制值 | Decimal value
                    int_value = int(value)
                
                f_out.write(struct.pack('<I', int_value))
        
        print(f"Conversion completed successfully: {input_file} -> {output_file}")
        return True
    
    except Exception as e:
        print(f"Error during conversion: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input_txt_file> <output_bip_file>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    convert_txt_to_bip(input_file, output_file)