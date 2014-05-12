
#Specify the frequency of the board's CPU, in Hz.
F_CPU=16000000UL

#Specify the compiler chain and options we'll be using.
CC=avr-gcc
CFLAGS=-mmcu=atmega32u4 -Os -Wall -g -DF_CPU=$(F_CPU) --std=c99 #-DSILENT_OPERATION
LDFLAGS=-mmcu=atmega32u4
OBJCOPY=avr-objcopy


#
# Device Firmware Upgrade subrountine;
# used for programming a given file via DFU.
#
define do_dfu =
	dfu-programmer atmega32u4 erase
	dfu-programmer atmega32u4 flash $^
	@echo
	@echo "Be sure that any PC software using the device has been closed,"
	@echo "then unplug and re-attach the relevant device."
endef


all: main.hex size

#Program a teensy board with the Beacon software.
teensy: main.hex
	@echo "Press the button on your Teensy board to continue programming..."
	teensy-loader-cli $(LDFLAGS) -w main.hex

#Program an actual beacon board using Atmel's DFU.
dfu: main.hex
	$(call do_dfu)

#Program a beacon board with the "responder" test.
responder_dfu: responder.hex
	$(call do_dfu)

#Create a hex file, which is used by many of the tools.
%.hex: %.elf
	$(OBJCOPY) -O ihex $^ $@

#Dependency list for the main program.
main.elf: timers.h timers.o lights.o lights.h ir_comm.o ir_comm.h state.h pc_comm.h pc_comm.c usb_serial/usb_serial.o usb_serial/usb_serial.h frequency.h main.h 

#Dependency lists for each of the test programs.
responder.elf: timers.h timers.o lights.o lights.h ir_comm.o ir_comm.h frequency.h

#Dependencies for the internal libraries.
ir_comm.o: timers.o timers.h
pc_comm.o: usb_serial/usb_serial.o usb_serial/usb_serial.h

#Rule to create elf (executable and linkable format binaries.
%.elf: %.o
	$(CC) $(LDFLAGS) $^ -o $@

size: 
	avr-size --mcu=atmega32u4 -C main.elf


	
