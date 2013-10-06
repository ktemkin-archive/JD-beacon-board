
#Specify the frequency of the board's CPU, in Hz.
F_CPU=16000000UL

#Specify the compiler chain and options we'll be using.
CC=avr-gcc
CFLAGS=-mmcu=atmega32u4 -Os -Wall -g -DF_CPU=$(F_CPU)
LDFLAGS=-mmcu=atmega32u4

all: main.hex

#Program the board to the teensy.
teensy: main.hex
	echo "Press the button on your Teensy board to continue programming..."
	teensy-loader-cli $(LDFLAGS) -w main.hex

dfu: main.hex
	dfu-programmer atmega32u4 erase
	dfu-programmer atmega32u4 flash main.hex
	echo "Be sure that any PC software using the device has been closed,"
	echo "then unplug and re-attach the relevant device."

main.hex: main
	avr-objcopy -O ihex $^ $@

main: timers.o timers.h lights.o lights.h ir_comm.o ir_comm.h state.h pc_comm.h pc_comm.c usb_serial/usb_serial.o usb_serial/usb_serial.h main.o


