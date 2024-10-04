# i2c
測試平台iverilog
compile
iverilog -o i2c -f i2c.f -D ADDRACK
run
vvp i2c

test condition
ADDRNACK: address not acknowledge
WDATA_NO_STOP: writing 
RDATA_NO_STOP: reading
WDATA_RESTART: write 1 byte then restart
RDATA_RESTART: read 1 byte then restart
WDATA_STOP: write 1 byte then stop
RDATA_STOP: read 1 byte then restart
WDATA_STRETCH: stretch while writing
RDATA_STRETCH: stretch while reading
