################################################################################
#                      Inject at address 8016e74c
# Function is StartMelee and we are loading game information right before
# it gets read to initialize the match
################################################################################

#replaced code line is executed at the end

################################################################################
#                   subroutine: gameInfoLoad
# description: reads game info from slippi and loads those into memory
# addresses that will be used
################################################################################
#create stack frame and store link register
mflr r0
stw r0, 0x4(r1)
stwu r1,-0x20(r1)

# initialize transfer with slippi device
bl startExiTransfer

# request game information from slippi
li r3,0x36
bl sendByteExi

# build version number. Each byte is one digit
# any change in command data should result in a minor version change
# current version: 0.1.0.0
lis r3, 0x0001
addi r3, r3, 0x0000
bl sendWordExi

#------------- GAME INFO BLOCK -------------
# this iterates through the static game info block that is used to pull data
# from to initialize the game. it writes out the whole thing (0x138 long)
li r4, 0
START_LOOP:
add r3, r31, r4
lwz r3, 0x0(r3)
bl sendWordExi

addi r4, r4, 0x4
cmpwi r4, 0x138
blt+ START_LOOP

#------------- OTHER INFO -------------
# write out random seed
lis r3, 0x804D
lwz r3, 0x5F90(r3) #load random seed
bl sendWordExi

bl endExiTransfer

CLEANUP:
#restore registers and sp
lwz r0, 0x24(r1)
addi r1, r1, 0x20
mtlr r0

b GECKO_END

################################################################################
#                  subroutine: startExiTransfer
#  description: prepares port B exi to be written to
################################################################################
startExiTransfer:
lis r11, 0xCC00 #top bytes of address of EXI registers

#disable read/write protection on memory pages
lhz r10, 0x4010(r11)
ori r10, r10, 0xFF
sth r10, 0x4010(r11) # disable MP3 memory protection

#set up EXI
li r10, 0xB0 #bit pattern to set clock to 8 MHz and enable CS for device 0
stw r10, 0x6814(r11) #start transfer, write to parameter register

blr

################################################################################
#                    subroutine: sendByteExi
#  description: sends one byte over port B exi
#  inputs: r3 byte to send
################################################################################
sendByteExi:
lis r11, 0xCC00 #top bytes of address of EXI registers
li r10, 0x5 #bit pattern to write to control register to write one byte

#write value in r3 to EXI
slwi r3, r3, 24 #the byte to send has to be left shifted
stw r3, 0x6824(r11) #store current byte into transfer register
stw r10, 0x6820(r11) #write to control register to begin transfer

#wait until byte has been transferred
EXI_CHECK_RECEIVE_WAIT:
lwz r10, 0x6820(r11)
andi. r10, r10, 1
bne EXI_CHECK_RECEIVE_WAIT

blr

################################################################################
#                    subroutine: sendWordExi
#  description: sends one word over port B exi
#  inputs: r3 word to send
################################################################################
sendWordExi:
lis r11, 0xCC00 #top bytes of address of EXI registers
li r10, 0x35 #bit pattern to write to control register to write four bytes

#write value in r3 to EXI
stw r3, 0x6824(r11) #store current bytes into transfer register
stw r10, 0x6820(r11) #write to control register to begin transfer

#wait until byte has been transferred
EXI_CHECK_RECEIVE_WAIT_WORD:
lwz r10, 0x6820(r11)
andi. r10, r10, 1
bne EXI_CHECK_RECEIVE_WAIT_WORD

blr

################################################################################
#                  subroutine: endExiTransfer
#  description: stops port B writes
################################################################################
endExiTransfer:
lis r11, 0xCC00 #top bytes of address of EXI registers

li r10, 0
stw r10, 0x6814(r11) #write 0 to the parameter register

blr

GECKO_END:
lis r3, 0x8017 #execute replaced code line