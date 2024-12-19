class RMAPPacket:
    def __init__(self):
        # Header parts
        self.header_lower = [0] * 4  # For logical addr, pid, instruction, key
        self.header_upper = [0] * 11  # For remaining header fields
        self.reply_bytes = [0] * 12   # Maximum 12 reply address bytes
        self.reply_size = 0
        self.has_reply_addr = False
        self.is_write = False

    def set_logical_addr(self, addr: int):
        """Set target logical address (0-255)"""
        if 0 <= addr <= 255:
            self.header_lower[0] = addr
        else:
            raise ValueError("Logical address must be between 0 and 255")

    def set_pid(self, pid: int):
        """Set protocol ID (0-255)"""
        if 0 <= pid <= 255:
            self.header_lower[1] = pid
        else:
            raise ValueError("Protocol ID must be between 0 and 255")

    def set_instruction(self, rw: str, verify: bool, reply: bool, increment_addr: bool, addr_len: str):
        """Set instruction byte
        rw: 'read' or 'write'
        verify: True/False for verify bit
        reply: True/False for reply bit
        increment_addr: True/False for increment address bit
        addr_len: '00', '01', '10', or '11' for reply address length
        """
        inst_byte = 0b01000000

        if rw == "write":
            inst_byte |= (1 << 5)
            self.is_write = True
        elif rw != "read":
            raise ValueError("rw must be 'read' or 'write'")

        if verify:
            inst_byte |= (1 << 4)
        if reply:
            inst_byte |= (1 << 3)
        if increment_addr:
            inst_byte |= (1 << 2)

        # Handle reply address length
        if addr_len == "00":
            self.reply_size = 0
            self.has_reply_addr = False
        elif addr_len == "01":
            self.reply_size = 4
            self.has_reply_addr = True
            inst_byte |= 0b01
        elif addr_len == "10":
            self.reply_size = 8
            self.has_reply_addr = True
            inst_byte |= 0b10
        elif addr_len == "11":
            self.reply_size = 12
            self.has_reply_addr = True
            inst_byte |= 0b11
        else:
            raise ValueError("Invalid address length")

        self.header_lower[2] = inst_byte

    def set_key(self, key: int):
        """Set key byte (0-255)"""
        if 0 <= key <= 255:
            self.header_lower[3] = key
        else:
            raise ValueError("Key must be between 0 and 255")

    def set_reply_addresses(self, bytes_list: list):
        """Set reply address bytes if reply addressing is enabled"""
        if self.has_reply_addr:
            if len(bytes_list) != self.reply_size:
                raise ValueError(f"Expected {self.reply_size} reply bytes, got {len(bytes_list)}")
            for i in range(self.reply_size):
                if 0 <= bytes_list[i] <= 255:
                    self.reply_bytes[i] = bytes_list[i]
                else:
                    raise ValueError("Reply bytes must be between 0 and 255")

    def set_init_address(self, addr: int):
        """Set initiator logical address (0-255)"""
        if 0 <= addr <= 255:
            self.header_upper[0] = addr
        else:
            raise ValueError("Initiator address must be between 0 and 255")

    def set_trans_id(self, trans_id: int):
        """Set transaction ID (0-65535)"""
        if 0 <= trans_id <= 65535:
            self.header_upper[1] = (trans_id >> 8) & 0xFF  # MSB
            self.header_upper[2] = trans_id & 0xFF         # LSB
        else:
            raise ValueError("Transaction ID must be between 0 and 65535")

    def set_mem_address(self, address: int):
        """Set 32-bit memory address + extended address field"""
        if 0 <= address <= 0xFFFFFFFF:
            self.header_upper[3] = address & 0xFF          # Extended address
            self.header_upper[4] = (address >> 24) & 0xFF  # Address MSB
            self.header_upper[5] = (address >> 16) & 0xFF
            self.header_upper[6] = (address >> 8) & 0xFF
            self.header_upper[7] = address & 0xFF          # Address LSB
        else:
            raise ValueError("Memory address must be between 0 and 0xFFFFFFFF")

    def set_data_length(self, length: int):
        """Set data length field (0-16777215)"""
        if 0 <= length <= 0xFFFFFF:
            self.header_upper[8] = (length >> 16) & 0xFF   # MSB
            self.header_upper[9] = (length >> 8) & 0xFF
            self.header_upper[10] = length & 0xFF          # LSB
        else:
            raise ValueError("Data length must be between 0 and 16777215")

    def get_header(self) -> bytes:
        """Return complete header as bytes"""
        header = bytes(self.header_lower)
        if self.has_reply_addr:
            header += bytes(self.reply_bytes[:self.reply_size])
        header += bytes(self.header_upper)
        return header

    def calculate_header_crc(self) -> int:
        """Calculate and return header CRC-8 RMAP"""
        header = self.get_header()
        crc = 0
        for byte in header:
            for _ in range(8):
                msb = crc & 0x80
                crc = (crc << 1) & 0xFF
                if msb:
                    crc ^= 0x07
                crc ^= (byte >> 7) & 1
                byte = (byte << 1) & 0xFF
        return crc

# Example usage
def example():
    rmap = RMAPPacket()
    
    # Set header fields
    rmap.set_logical_addr(0xFE)
    rmap.set_pid(1)
    rmap.set_instruction("write", True, True, True, "01")  # Write with verify, reply, increment, 4 reply bytes
    rmap.set_key(0x00)
    rmap.set_reply_addresses([0x01, 0x02, 0x03, 0x04])
    rmap.set_init_address(0x67)
    rmap.set_trans_id(1)
    rmap.set_mem_address(0xA0000000)
    rmap.set_data_length(16)

    # Get complete header
    header = rmap.get_header()
    crc = rmap.calculate_header_crc()
    
    print("Header:", " ".join(f"{b:02X}" for b in header))
    print("Header CRC:", f"{crc:02X}")

if __name__ == "__main__":
    example()