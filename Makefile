
BASE=$(shell git remote -v | cut -f 2- | sed -e "s%fachat/.*%fachat%g" | uniq )

all: spiimg loadrom.bin loadrom 

deep: usb65 cbm-x16dos
	make -C cbm-x16dos
	make -C usb65/platforms/upet
	make all

########################################################
# sub-repos

REPOS=cbm-edit-rom cbm-x16dos usb65 cbm-fastiec

# downloads all the repos it depends on
clone: $(REPOS)

# update cloned repos
update: $(REPOS)
	git pull
	for i in $(REPOS); do (cd $$i; git pull); done

########################################################

EDITROMS=edit40_c64kb.bin \
	edit80_c64kb.bin \
	edit40_grfkb_ext.bin \
	edit80_grfkb_ext.bin \
	edit40_c64kb_ext.bin \
	edit80_c64kb_ext.bin \
	edit40_b_ext.bin \
	edit80_b_ext.bin \

ORIGROMS=edit40g edit40b \
	edit80g edit80b \
	basic1 edit1 kernal1 \
	basic2 edit2g kernal2 \
	basic4 kernal4

TOOLS=romcheck

spiimgc: rebuildclean spiimg 

spiimg: zero boot chargen_pet16 chargen_pet1_16 iplldr $(EDITROMS) $(ORIGROMS) edit80_grfkb_ext_chk.bin edit80_chk.bin usbcode dos.bin
	# ROM images
	cat iplldr					> $@	# 256b   : IPL loader
	cat boot					>> $@	# 8k-256 : boot code
	# standard character ROM (converted to 16 byte/char)
	cat chargen_pet16 				>> $@	# 8-16k  : 8k 16bytes/char PET character ROM
	# BASIC 1
	cat basic1 edit1 zero kernal1			>> $@	# 16-32k : BASIC1/Edit/Kernel ROMs (16k $c000-$ffff)
	# BASIC 2
	cat basic2 edit2g zero kernal2 			>> $@	# 32-48k : BASIC2/Edit/Kernel ROMs (16k $c000-$ffff)
	# BASIC 4
	cat basic4 					>> $@	# 48-60k : BASIC4 ROMS (12k $b000-$dfff)
	cat kernal4					>> $@	# 60-64k : BASIC4 kernel (4k)
	#### 64k-
	# editor ROMs (each line 4k)
	cat edit40_grfkb_ext.bin  			>> $@	# sjgray ext 40 column editor w/ wedge by for(;;)
	cat edit40_c64kb_ext.bin	 		>> $@	# sjgray ext 40 column editor for C64 kbd (experimental)
	cat edit80_grfkb_ext_chk.bin			>> $@	# sjgray ext 80 column editor w/ wedge by for(;;)
	cat edit80_c64kb_ext.bin	 		>> $@	# sjgray ext 80 column editor for C64 kbd (experimental)
	cat edit40g zero 				>> $@	# original BASIC 4 editor ROM graph keybd
	cat edit40_c64kb.bin 		 		>> $@	# sjgray base 40 column editor for C64 kbd (experimental)
	cat edit80_chk.bin zero				>> $@	# (original) BASIC 4 80 column editor ROM (graph keybd)
	cat edit80_c64kb.bin zero	 		>> $@	# sjgray base 80 column editor for C64 kbd (experimental)
	# alternate BASIC 1 character ROM (as 16 bytes/char)
	cat chargen_pet1_16				>> $@	# BASIC 1 character set (8k)
	# USB support
	cat usbcode					>> $@	# 8k USB code
	# SD-Card support
	cat dos.bin					>> $@	# 16k SD-Card DOS
	#### 128k-
	cat edit40_b_ext.bin	 			>> $@	# sjgray ext 40 column editor for biz kbd (experimental)
	cat edit80_b_ext.bin	 			>> $@	# sjgray ext 80 column editor for biz kbd (experimental)
	cat edit40b zero 				>> $@	# original BASIC 4 editor ROM graph keybd
	cat edit80b zero 				>> $@	# original BASIC 4 editor ROM graph keybd


zero: 
	dd if=/dev/zero of=zero bs=2048 count=1

chargen_pet16: charPet2Invers char8to16 chargen_pet
	./charPet2Invers < chargen_pet | ./char8to16 > chargen_pet16

chargen_pet1_16: charPet2Invers char8to16 chargen_pet1
	./charPet2Invers < chargen_pet1 | ./char8to16 > chargen_pet1_16

charPet2Invers: charPet2Invers.c
	gcc -o charPet2Invers charPet2Invers.c
	
char8to16: char8to16.c
	gcc -o char8to16 char8to16.c

iplldr: iplldr.a65
	xa -w -XMASM -P $@.lst -o $@ $<

boot: boot.a65 boot_menu.a65 boot_kbd.a65 boot_opts.a65 boot_rom1.a65 boot_rom2.a65 boot_rom4.a65 boot_usb.a65 dosromcomp.a65 patch4.a65
	xa -w -XCA65 -XMASM -k -P $@.lst -o $@ $<

romtest02: romtest02.a65
	xa -w -o romtest02 romtest02.a65

romtest01: romtest01.a65
	xa -w -o romtest01 romtest01.a65 

romtest01a: romtest01a.a65
	xa -w -o romtest01a romtest01a.a65 

romtest02a: romtest02a.a65
	xa -w -o romtest02a romtest02a.a65 

##########################################################################	
# Original PET ROMs

ARCHIVE=http://www.zimmers.net/anonftp/pub/cbm

chargen_pet:
	curl -o chargen_pet $(ARCHIVE)/firmware/computers/pet/characters-2.901447-10.bin

chargen_pet1:
	curl -o chargen_pet1 $(ARCHIVE)/firmware/computers/pet/characters-1.901447-08.bin

edit1:
	curl -o edit1 $(ARCHIVE)/firmware/computers/pet/rom-1-e000.901447-05.bin

kernal1:
	curl -o kernal1_f0 $(ARCHIVE)/firmware/computers/pet/rom-1-f000.901447-06.bin
	curl -o kernal1_f8 $(ARCHIVE)/firmware/computers/pet/rom-1-f800.901447-07.bin
	cat kernal1_f0 kernal1_f8 > kernal1
	rm kernal1_f0 kernal1_f8 

basic1:
	curl -o basic1_c0 $(ARCHIVE)/firmware/computers/pet/rom-1-c000.901447-01.bin
	curl -o basic1_c8 $(ARCHIVE)/firmware/computers/pet/rom-1-c800.901447-02.bin
	curl -o basic1_d0 $(ARCHIVE)/firmware/computers/pet/rom-1-d000.901447-03.bin
	curl -o basic1_d8 $(ARCHIVE)/firmware/computers/pet/rom-1-d800.901447-04.bin
	cat basic1_c0 basic1_c8 basic1_d0 basic1_d8 > basic1
	rm basic1_c0 basic1_c8 basic1_d0 basic1_d8 

edit2g:
	curl -o edit2g $(ARCHIVE)/firmware/computers/pet/edit-2-n.901447-24.bin

kernal2:
	curl -o kernal2 $(ARCHIVE)/firmware/computers/pet/kernal-2.901465-03.bin

basic2:
	curl -o basic2c $(ARCHIVE)/firmware/computers/pet/basic-2-c000.901465-01.bin
	curl -o basic2d $(ARCHIVE)/firmware/computers/pet/basic-2-d000.901465-02.bin
	cat basic2c basic2d > basic2
	rm basic2c basic2d

basic4:
	curl -o basic4b $(ARCHIVE)/firmware/computers/pet/basic-4-b000.901465-23.bin 
	curl -o basic4c $(ARCHIVE)/firmware/computers/pet/basic-4-c000.901465-20.bin 
	curl -o basic4d $(ARCHIVE)/firmware/computers/pet/basic-4-d000.901465-21.bin 
	cat basic4b basic4c basic4d > basic4
	rm basic4b basic4c basic4d

kernal4t: 
	curl -o kernal4t $(ARCHIVE)/firmware/computers/pet/kernal-4.901465-22.bin

kernal4: kernal4t romcheck
	./romcheck -s 0xf0 -i 0xdff -o kernal4 kernal4t


edit40g:
	curl -o edit40g $(ARCHIVE)/firmware/computers/pet/edit-4-40-n-50Hz.901498-01.bin
edit40b:
	curl -o edit40b $(ARCHIVE)/firmware/computers/pet/edit-4-40-b-60Hz.ts.bin
	
edit80g:
	curl -o edit80g $(ARCHIVE)/firmware/computers/pet/edit-4-80-n-50Hz.4016_to_8016.bin
edit80b:
	curl -o edit80b $(ARCHIVE)/firmware/computers/pet/edit-4-80-b-60Hz.901474-03.bin

##########################################################################	
# Steve's modified/re-created editor ROMs

cbm-edit-rom: 
	git clone $(BASE)/cbm-edit-rom.git
	cp cbm-edit-rom/edit.asm cbm-edit-rom/edit.asm.org

${EDITROMS}: %.bin: %.asm #cbm-edit-rom
	-test ! -e cbm-edit-rom && make cbm-edit-rom
	rm -f cbm-edit-rom/editrom.bin
	rm -f cbm-edit-rom/cpetrom.bin
	cp $< cbm-edit-rom/edit.asm
	cd cbm-edit-rom && acme -r editrom.txt editrom.asm
	-test -e cbm-edit-rom/cpetrom.bin && mv cbm-edit-rom/cpetrom.bin cbm-edit-rom/editrom.bin
	cp cbm-edit-rom/editrom.bin $@

edit80_grfkb_ext_chk.bin: edit80_grfkb_ext.bin romcheck
	./romcheck -s 0xe0 -l 0x800 -i 0x7ff -o $@ $<

edit80_chk.bin: edit80g romcheck
	./romcheck -s 0xe0 -l 0x800 -i 0x7ff -o $@ $<

##########################################################################	
# SD-Card and DOS

cbm-x16dos: 
	git clone $(BASE)/cbm-x16dos.git

cbm-x16dos/build/UPET/dos.bin: cbm-x16dos
	(cd $<; make)

dos.bin: cbm-x16dos/build/UPET/dos.bin
	cp $< $@

dosromcomp.a65: cbm-x16dos

##########################################################################	
# Fast IEC driver code

cbm-fastiec:
	git clone $(BASE)/cbm-fastiec.git
	#(cd cbm-fastiec; git checkout upet)

##########################################################################	
# USB driver code
	
usb65/platforms/upet/petromcomp usb65/platforms/upet/petrom: usb65
	(cd usb65/platforms/upet; make petromcomp petrom)

usb65:
	git clone $(BASE)/usb65.git
	(cd usb65; git checkout upet)

usbcode: usbcode.a65 usb65/platforms/upet/petrom
	xa -o $@ $<

##########################################################################	
# load other PET Editor ROM and reboot

loadrom: loadrom.lst
	petcat -w40 -o $@ $<

loadrom.bin: loadrom.a65
	xa -o $@ $<

${TOOLS}: % : %.c
	cc -Wall -pedantic -o $@ $<
 
# Clean

clean:
	rm -f romtest01 romtest01a romtest02 romtest02a zero chargen_pet16 char8to16 charPet2Invers
	rm -f chargen_pet1 chargen_pet1_16
	rm -f iplldr edit80_chk.bin edit80_grfkb_ext_chk.bin kernal4t
	rm -f romcheck loadrom loadrom.bin boot 
	rm -f usbcode 
	rm -f dos.bin iplldr.lst 

rebuildclean:
	rm -f $(EDITROMS) $(ORIGROMS)


