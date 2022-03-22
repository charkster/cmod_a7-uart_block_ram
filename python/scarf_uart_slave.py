from __future__  import print_function
from pyftdi.ftdi import Ftdi
import pyftdi.serialext
import time

class scarf_uart_slave:
	
	# Constructor
	def __init__(self, slave_id=0x00, num_addr_bytes=2, ftdi_port=pyftdi.serialext.serial_for_url('ftdi://ftdi:2232:210328AD3FF5/2', baudrate=12000000, bytesize=8, parity='N', stopbits=1, timeout=1), debug=False):
		self.slave_id         = slave_id
		self.num_addr_bytes   = num_addr_bytes
		self.ftdi_port        = ftdi_port
		self.read_buffer_max  = 31  - self.num_addr_bytes
		self.write_buffer_max = 255 - self.num_addr_bytes
		self.debug            = debug
		
	def read_list(self, addr=0x00, num_bytes=1):
		if (self.debug == True):
			print("Called read")
		if (num_bytes == 0):
			print("Error: num_bytes must be larger than zero")
			return []
		else:
			byte0 = (self.slave_id + 0x80) & 0xFF
			remaining_bytes = num_bytes
			read_list = []
			address = addr - self.read_buffer_max # expecting to add self.read_buffer_max
			while (remaining_bytes > 0):
				if (remaining_bytes >= self.read_buffer_max):
					step_size = self.read_buffer_max
					remaining_bytes = remaining_bytes - self.read_buffer_max
				else:
					step_size = remaining_bytes
					remaining_bytes = 0
				address = address + self.read_buffer_max
				addr_byte_list = []
				for addr_byte_num in range(self.num_addr_bytes):
					addr_byte_list.insert(0, address >> (8*addr_byte_num) & 0xFF )
				filler_bytes = [0x00] * int(step_size)
				self.ftdi_port.write(bytearray([byte0] + addr_byte_list + filler_bytes))
				time.sleep(0.1)
				tmp_read_list = list(self.ftdi_port.read(step_size + self.num_addr_bytes + 1))
				del tmp_read_list[0] # first byte is echoed slave_id
				del tmp_read_list[step_size] # last byte is filler
				read_list.extend(tmp_read_list)
			if (self.debug == True):
				address = addr
				for read_byte in read_list:
					print("Address 0x{:02x} Read data 0x{:02x}".format(address,read_byte))
					address += 1
			return read_list
	
	def write_list(self, addr=0x00, write_byte_list=[]):
		byte0 = self.slave_id & 0xFF
		remaining_bytes = len(write_byte_list)
		address = addr - self.write_buffer_max # expecting to add self.write_buffer_max
		while (remaining_bytes > 0):
			if (remaining_bytes >= self.write_buffer_max):
				step_size = self.write_buffer_max
				remaining_bytes = remaining_bytes - self.write_buffer_max
			else:
				step_size = remaining_bytes
				remaining_bytes = 0
			address = address + self.write_buffer_max
			addr_byte_list = []
			for addr_byte_num in range(self.num_addr_bytes):
				addr_byte_list.insert(0, address >> (8*addr_byte_num) & 0xFF )
			self.ftdi_port.write(bytearray([byte0] + addr_byte_list + write_byte_list[address-addr:address+step_size]))
			time.sleep(0.1)
		if (self.debug == True):
			print("Called write_bytes")
			address = addr
			for write_byte in write_byte_list:
				print("Wrote address 0x{:02x} data 0x{:02x}".format(address,write_byte))
				address += 1
		return 1
		
	def read_mod_write(self, addr=0x00, write_byte=0x00):
		read_list = self.read_list(addr=addr, num_bytes=1)
		mod_write_byte = read_list[0] | write_byte
		self.write_list(addr=addr, write_byte_list=[mod_write_byte])
		
	def read_and_clear(self,addr=0x00, clear_mask=0x00):
		read_list = self.read_list(addr=addr, num_bytes=1)
		mod_write_byte = read_list[0] & (~clear_mask)
		self.write_list(addr=addr, write_byte_list=[mod_write_byte])
		
	def read_id(self):
		byte0 = (self.slave_id + 0x80) & 0xFF
		self.ftdi_port.write(bytearray([byte0] + [0x00]))
		slave_id = list(self.ftdi_port.read(1))
		if (self.debug == True):
			print("Slave ID is 0x{:02x}".format(slave_id[0]))
		return slave_id[0]
		
