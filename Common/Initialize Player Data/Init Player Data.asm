#To be inserted at 80068eec
.include "../../Common/Common.s"

#Backup Data Pointer After Creation
  addi	r30, r3, 0

#Get Player Data Length
  load	r4,0x80458fd0
  lwz	r4,0x20(r4)
  branchl	r12,0x8000c160

exit:
  mr	r3,r30
  lis	r4, 0x8046
