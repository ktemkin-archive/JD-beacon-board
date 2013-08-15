CC=avr-gcc
CFLAGS=-mmcu=atmega32u4 -Os -Wall -g
LDFLAGS=-mmcu=atmega32u4

all: main.hex

#Program the board to the teensy.
teensy: main.hex
	teensy-loader-cli $(LDFLAGS) -w main.hex

main.hex: main
	avr-objcopy -O ihex $^ $@

main: lights.o lights.h ir_comm.o ir_comm.h state.h pc_comm.h pc_comm.c usb_serial/usb_serial.o usb_serial/usb_serial.h main.o


