# Inject at 801a501c
# Injection is right before game engine loops
.include "../../Common/Common.s"
.include "../Playback.s"

# Info provided by tauKhan, relevant for fast forwarding
# 801a4db0: transfer input queue count to r27
# 801a4de4: engine loop start
# 801a501c: Engine loop check against the initial queue count, loop end
# 801a5024: screen render start

# scene controller checks. must be in VS mode (major) and in-game (minor)
lis r4, 0x8048 # load address to offset from for scene controller
lbz r3, -0x62D0(r4)
cmpwi r3, 0xe # the major scene for playback match
bne- PreviousCodeLine # if not in VS Mode, ignore everything
lbz r3, -0x62CD(r4)
cmpwi r3, 0x1 # the minor scene for in-game is 0x1
bne- PreviousCodeLine

lwz r3,frameDataBuffer(r13)
lbz r3,Status(r3)
cmpwi r3, CONST_FrameFetchResult_FastForward
beq FastForward # If we are not terminating, skip

# execute normal code line
PreviousCodeLine:
cmpw r26, r27
b Exit

FastForward:
# do a stupid cmp operation so that the blt at 801a5020 will branch
cmpwi r3, 0xFF

Exit:
