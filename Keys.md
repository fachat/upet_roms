
# Keymaps for the different supported keyboards

Names starting with "KP" are keypad versions of the key, e.g. "KP0" is the "0" on the key pad

| Abbreviation | Key |
----------------------
| RET | Return |
| SPC | Space |
| RSH | Right Shift |
| LSH | Left Shift |
| RVS | Reverse/Off key |
| STP | RUN/STOP key |
| UAR | Up Arrow |
| LAR | Left Arrow |
| DEL | INS/DEL key |
| CUD | Cursor Up/Down |
| CRL | Cursor Left/Right |
| HME | CLR/Home |
| RPT | Repeat |
| TAB | Tab key |
| ESC | Escape key |
| CTR | CTRL key |
| PI | Pi key |

Calculating the index in the key map table is done using this formula

    POS = (ROW-1)*8 + COL 

## N-type keyboard (AKA "graphics" keyboard)

          COL
    ROW    1   2   3   4   5   6   7   8  
     1    KP= KP.     STP  <  SPC  [  RVS  
     2    KP- KP0 RSH  >       ]   @  SHL
     3    KP+ KP2      ?   ,   N   V   X
     4    KP3 KP1 RET  ;   M   B   C   Z
     5    KP* KP5      :   K   H   F   S
     6    KP6 KP4      L   J   G   D   A
     7    KP/ KP8      P   I   Y   R   W
     8    KP7 KP9 UAR  O   U   T   E   Q
     9    DEL CUD      )   \   '   $   "
    10    CRL HME LAR  (   &   %   #   !

* POS(6) = 

## B-type keyboard (AKA "business" keyboard)

          COL
    ROW    1   2   3   4   5   6   7   8  
     1             :  STP  9   6   3  LAR
     2    KP1  /      HME  M  SPC  X  RVS
     3    KP2 RPT     KP0  ,   N   V   Z
     4    KP3 RSH     KP.  .   B   C  LSH
     5    KP4  [   O  CUD  U   T   E   Q
     6    DEL  P   I   \   Y   R   W  TAB
     7    KP6  @   L  RET  J   G   D   A  
     8    KP5  ;   K   ]   H   F   S  ESC
     9    KP9     UAR KP7  0   7   4   1
    10            CRL KP8  -   8   5   2


## C64 keyboard (using the PET keyboard scanner)

          COL
    ROW    1   2   3   4   5   6   7   8  
     1 
     2
     3    F7  HME  -   0   8   6   4   2
     4    F5  UAR  @   O   U   T   E   Q
     5    F3   =   :   K   H   F   S  TAB
     6    F1  RSH  .   M   B   C   Z  SPC
     7    CUD  /   ,   N   V   X  LSH STP
     8    CRL  ;   L   J   G   D   A  CTR
     9    RET  *   P   I   Y   R   W  PI
    10    DEL  \   +   9   7   5   3   1

# Keyboard Type autodetection

To detect the keyboard type automatically,
a key must be pressed that is valid in exactly
one of the three matrices. For the N-type keyboard
this must be 1,2,4,6,8,X, as well as left shift and S (for Settings). For the B- and C64 type
keyboards this must at this time be 4,6,8,X left shift and S.
Also, H is used to go into "hardware" more, i.e. burnin and diagnostics

The following table gives the identified unique keys with prefix

* N = N-type keyboard
* B = B-type keyboard
* C = C64-type keyboard

          COL
    ROW    1   2   3   4   5   6   7   8  
     1
     2    B1*     NSR             BX  NSL
     3    B2* N2          C8  C6  C4  NX*
     4        N1+     CO+             BSL
     5    B4              CH  NH  CS  NS 
     6    N6  N4*                 
     7    B6  N8              CX  CSL        
     8        N9      NO  BH      BS
     9    B9  
    10                B8+             C1


The entries marked with an asterisk are unsupported.

* N1 conflicts with B-type right shift
* N4 conflicts with C64 right shift
* CO conflicts with B-type O, which is why Options is replaced with Settings now
* B8 conflicts with C9, which is why X is now used for the (planned) eXtended version...
* NX conflicts with C2 (which is not used)

