
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

main.hex: main
	avr-objcopy -O ihex $^ $@

main: lights.o lights.h ir_comm.o ir_comm.h state.h pc_comm.h pc_comm.c usb_serial/usb_serial.o usb_serial/usb_serial.h main.o


