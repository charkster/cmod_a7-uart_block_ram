#!/usr/bin/python3

from __future__       import print_function
from scarf_uart_slave import scarf_uart_slave
import random, math

bram = scarf_uart_slave(slave_id=0x01, num_addr_bytes=2)
bram.write_list(addr=0x0000, write_byte_list=[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
print(bram.read_list(addr=0x0000, num_bytes=15))
print(bram.read_id())

num_values = 1024
random_list = []
for i in range(0,num_values):
	random_list.append(random.randint(0,255))

read_list = []
bram.write_list(addr=0x0000, write_byte_list=random_list)
read_list = bram.read_list(addr=0x0000, num_bytes=num_values)

for i in range(0,num_values):
	if (read_list[i] != random_list[i]):
		print("Misscompare at index {:d}, expected value 0x{:02x}, read value 0x{:02x}".format(i,random_list[i],read_list[i]))
