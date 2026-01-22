
BASE=$(shell git remote -v | cut -f 2- | sed -e "s%fachat/.*%fachat%g" | uniq )

all: spiimg loadrom.bin loadrom 

deep: usb65 cbm-x16dos
	make -C cbm-x16dos
	make -C usb65/platforms/upet
	make all

########################################################
# sub-repos

REPOS=cbm-edit-rom cbm-x16dos usb65 cbm-fastiec cbm-burnin-tests upet_ioext

# downloads all the repos it depends on
clone: $(REPOS)

# update cloned repos
update: $(REPOS)
	git pull
	for i in $(REPOS); do (cd $$i; git pull); done

########################################################

ROMDIR=roms

EDITROMS=$(ROMDIR)/edit40_c64kb.bin \
	$(ROMDIR)/edit80_c64kb.bin \
	$(ROMDIR)/edit40_grfkb_ext.bin \
	$(ROMDIR)/edit80_grfkb_ext.bin \
	$(ROMDIR)/edit40_c64kb_ext.bin \
	$(ROMDIR)/edit80_c64kb_ext.bin \
	$(ROMDIR)/edit40_b_ext.bin \
	$(ROMDIR)/edit80_b_ext.bin \

ORIGROMS=$(ROMDIR)/edit40g $(ROMDIR)/edit40b \
	$(ROMDIR)/edit80g $(ROMDIR)/edit80b \
	$(ROMDIR)/basic1 $(ROMDIR)/edit1 $(ROMDIR)/kernal1 \
	$(ROMDIR)/basic2 $(ROMDIR)/edit2g $(ROMDIR)/kernal2 \
	$(ROMDIR)/basic4 $(ROMDIR)/kernal4

TOOLS=romcheck

########################################################

spiimgc: rebuildclean spiimg 

spiimg: zero boot chargen_pet16 chargen_pet1_16 iplldr $(EDITROMS) $(ORIGROMS) $(ROMDIR)/kernal4c $(ROMDIR)/edit80_grfkb_ext_chk.bin $(ROMDIR)/edit80_chk.bin \
	usbcode dos.bin fieccode cbm-burnin-tests/pet_burnin_rom ioext-core.bin
	# ROM images
	cat iplldr					> $@	# 256b   : IPL loader
	cat boot					>> $@	# 8k-256 : boot code
	# standard character ROM (converted to 16 byte/char)
	cat chargen_pet16 				>> $@	# 8-16k  : 8k 16bytes/char PET character ROM
	# BASIC 1
	cat $(ROMDIR)/basic1 $(ROMDIR)/edit1 zero $(ROMDIR)/kernal1	>> $@	# 16-32k : BASIC1/Edit/Kernel ROMs (16k $c000-$ffff)
	# BASIC 2
	cat $(ROMDIR)/basic2 $(ROMDIR)/edit2g zero $(ROMDIR)/kernal2 	>> $@	# 32-48k : BASIC2/Edit/Kernel ROMs (16k $c000-$ffff)
	# BASIC 4
	cat $(ROMDIR)/basic4 				>> $@	# 48-60k : BASIC4 ROMS (12k $b000-$dfff)
	cat $(ROMDIR)/kernal4c				>> $@	# 60-64k : BASIC4 kernel (4k)
	#### 64k-
	# editor ROMs (each line 4k)
	cat $(ROMDIR)/edit40_grfkb_ext.bin  		>> $@	# sjgray ext 40 column editor w/ wedge by for(;;)
	cat $(ROMDIR)/edit40_c64kb_ext.bin	 	>> $@	# sjgray ext 40 column editor for C64 kbd (experimental)
	cat $(ROMDIR)/edit80_grfkb_ext_chk.bin		>> $@	# sjgray ext 80 column editor w/ wedge by for(;;)
	cat $(ROMDIR)/edit80_c64kb_ext.bin	 	>> $@	# sjgray ext 80 column editor for C64 kbd (experimental)
	cat $(ROMDIR)/edit40g zero 			>> $@	# original BASIC 4 editor ROM graph keybd
	cat $(ROMDIR)/edit40_c64kb.bin 		 	>> $@	# sjgray base 40 column editor for C64 kbd (experimental)
	cat $(ROMDIR)/edit80_chk.bin zero		>> $@	# (original) BASIC 4 80 column editor ROM (graph keybd)
	cat $(ROMDIR)/edit80_c64kb.bin zero	 	>> $@	# sjgray base 80 column editor for C64 kbd (experimental)
	# alternate BASIC 1 character ROM (as 16 bytes/char)
	cat chargen_pet1_16				>> $@	# BASIC 1 character set (8k)
	# USB support
	cat usbcode					>> $@	# 8k USB code
	# SD-Card support
	cat dos.bin					>> $@	# 16k SD-Card DOS
	#### 128k-
	cat $(ROMDIR)/edit40_b_ext.bin	 		>> $@	# sjgray ext 40 column editor for biz kbd (experimental)
	cat $(ROMDIR)/edit80_b_ext.bin	 		>> $@	# sjgray ext 80 column editor for biz kbd (experimental)
	cat $(ROMDIR)/edit40b zero 			>> $@	# original BASIC 4 editor ROM graph keybd
	cat $(ROMDIR)/edit80b zero 			>> $@	# original BASIC 4 editor ROM graph keybd
	#### Fast SIEC code
	cat fieccode					>> $@	# 4k
	#### Burnin tests
	cat cbm-burnin-tests/pet_burnin_rom		>> $@	# 8k
	#### basic4 ioext
	cat ioext-core.bin				>> $@	# 4k


zero: 
	dd if=/dev/zero of=zero bs=2048 count=1

chargen_pet16: charPet2Invers char8to16 $(ROMDIR)/chargen_pet
	./charPet2Invers < $(ROMDIR)/chargen_pet | ./char8to16 > chargen_pet16

chargen_pet1_16: charPet2Invers char8to16 $(ROMDIR)/chargen_pet1
	./charPet2Invers < $(ROMDIR)/chargen_pet1 | ./char8to16 > chargen_pet1_16

charPet2Invers: charPet2Invers.c
	gcc -o charPet2Invers charPet2Invers.c
	
char8to16: char8to16.c
	gcc -o char8to16 char8to16.c

iplldr: iplldr.a65
	xa -w -XMASM -P $@.lst -o $@ $<

boot: boot.a65 boot_menu.a65 boot_kbd.a65 boot_opts.a65 boot_opts.i65 boot_rom1.a65 boot_rom2.a65 boot_rom4.a65 boot_usb.a65 dosromcomp.a65 patch4.a65 boot_ser.a65
	xa -w -XCA65 -XMASM -Iusb65/platforms/upet -k -P $@.lst -o $@ $<

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

$(ROMDIR)/chargen_pet:
	curl -o $@ $(ARCHIVE)/firmware/computers/pet/characters-2.901447-10.bin

$(ROMDIR)/chargen_pet1:
	curl -o $@ $(ARCHIVE)/firmware/computers/pet/characters-1.901447-08.bin

$(ROMDIR)/edit1: $(ROMDIR)
	curl -o $@ $(ARCHIVE)/firmware/computers/pet/rom-1-e000.901447-05.bin

$(ROMDIR)/kernal1: $(ROMDIR)
	curl -o kernal1_f0 $(ARCHIVE)/firmware/computers/pet/rom-1-f000.901447-06.bin
	curl -o kernal1_f8 $(ARCHIVE)/firmware/computers/pet/rom-1-f800.901447-07.bin
	cat kernal1_f0 kernal1_f8 > $@
	rm kernal1_f0 kernal1_f8 

$(ROMDIR)/basic1: $(ROMDIR)
	curl -o basic1_c0 $(ARCHIVE)/firmware/computers/pet/rom-1-c000.901447-01.bin
	curl -o basic1_c8 $(ARCHIVE)/firmware/computers/pet/rom-1-c800.901447-02.bin
	curl -o basic1_d0 $(ARCHIVE)/firmware/computers/pet/rom-1-d000.901447-03.bin
	curl -o basic1_d8 $(ARCHIVE)/firmware/computers/pet/rom-1-d800.901447-04.bin
	cat basic1_c0 basic1_c8 basic1_d0 basic1_d8 > $@
	rm basic1_c0 basic1_c8 basic1_d0 basic1_d8 

$(ROMDIR)/edit2g: $(ROMDIR)
	curl -o $@ $(ARCHIVE)/firmware/computers/pet/edit-2-n.901447-24.bin

$(ROMDIR)/kernal2: $(ROMDIR)
	curl -o $@ $(ARCHIVE)/firmware/computers/pet/kernal-2.901465-03.bin

$(ROMDIR)/basic2: $(ROMDIR)
	curl -o basic2c $(ARCHIVE)/firmware/computers/pet/basic-2-c000.901465-01.bin
	curl -o basic2d $(ARCHIVE)/firmware/computers/pet/basic-2-d000.901465-02.bin
	cat basic2c basic2d > $@
	rm basic2c basic2d

$(ROMDIR)/basic4: $(ROMDIR)
	curl -o basic4b $(ARCHIVE)/firmware/computers/pet/basic-4-b000.901465-23.bin 
	curl -o basic4c $(ARCHIVE)/firmware/computers/pet/basic-4-c000.901465-20.bin 
	curl -o basic4d $(ARCHIVE)/firmware/computers/pet/basic-4-d000.901465-21.bin 
	cat basic4b basic4c basic4d > $@
	rm basic4b basic4c basic4d

$(ROMDIR)/kernal4:  $(ROMDIR)
	curl -o $@ $(ARCHIVE)/firmware/computers/pet/kernal-4.901465-22.bin

$(ROMDIR)/kernal4c: $(ROMDIR)/kernal4 romcheck
	./romcheck -s 0xf0 -i 0xdff -o $@ $<


$(ROMDIR)/edit40g: $(ROMDIR)
	curl -o $@ $(ARCHIVE)/firmware/computers/pet/edit-4-40-n-50Hz.901498-01.bin
$(ROMDIR)/edit40b: $(ROMDIR)
	curl -o $@ $(ARCHIVE)/firmware/computers/pet/edit-4-40-b-60Hz.ts.bin
	
$(ROMDIR)/edit80g: $(ROMDIR)
	curl -o $@ $(ARCHIVE)/firmware/computers/pet/edit-4-80-n-50Hz.4016_to_8016.bin
$(ROMDIR)/edit80b: $(ROMDIR)
	curl -o $@ $(ARCHIVE)/firmware/computers/pet/edit-4-80-b-60Hz.901474-03.bin

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

$(ROMDIR)/edit80_grfkb_ext_chk.bin: $(ROMDIR)/edit80_grfkb_ext.bin romcheck
	./romcheck -s 0xe0 -l 0x800 -i 0x7ff -o $@ $<

$(ROMDIR)/edit80_chk.bin: $(ROMDIR)/edit80g romcheck
	./romcheck -s 0xe0 -l 0x800 -i 0x7ff -o $@ $<

##########################################################################	
# file handling for devices like I2C, serial

upet-ioext: 
	git clone $(BASE)/upet_ioext.git

ioext-core.bin: ioext-core.a65 upet_ioext/*
	xa -XCA65 -DIOEXT_FILENAME=512 -I upet_ioext -o $@ ioext-core.a65


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
	(cd cbm-fastiec; git checkout)

fieccode.o65: fieccode.a65 iecdispatch.a65 cbm-fastiec 
	xa -R -c -XMASM -bz 48 -bt 8192 -bd 12032 -o $@ $<

fieccode: fieccode.o65
	reloc65 -X -v -o $@ $<
	
##########################################################################	
# Burnin tests

cbm-burnin-tests:
	git clone $(BASE)/cbm-burnin-tests.git
	(cd cbm-burnin-tests; git checkout)

cbm-burnin-tests/pet_burnin_rom: cbm-burnin-tests 
	(cd cbm-burnin-tests; make)

	
##########################################################################	
# USB driver code
	
usb65:
	git clone $(BASE)/usb65.git
	(cd usb65; git checkout upet)

usb65/platforms/upet/petrom:
	make -C usb65/platforms/upet petrom

usbcode: usbcode.a65 usb65/platforms/upet/petrom
	xa -o $@ $<

##########################################################################	
# load other PET Editor ROM and reboot

loadrom: loadrom.bas
	petcat -w40 -o $@ $<

loadrom.bin: loadrom.a65
	xa -o $@ $<

${TOOLS}: % : %.c
	cc -Wall -pedantic -o $@ $<
 
# Clean

clean:
	rm -f romtest01 romtest01a romtest02 romtest02a zero chargen_pet16 char8to16 charPet2Invers
	rm -f chargen_pet1_16 kernal4c
	rm -f iplldr edit80_chk.bin edit80_grfkb_ext_chk.bin 
	rm -f romcheck loadrom loadrom.bin boot 
	rm -f usbcode 
	rm -f dos.bin iplldr.lst 
	rm -f fieccode.o65 fieccode
	rm -f zero usbcode upet.log romcheck loadrom loadrom.bin iplldr ioext-core.bin
	rm -f *.lst

rebuildclean: clean
	rm -f $(EDITROMS) $(ORIGROMS)
	rm -f $(ROMDIR)/chargen_pet $(ROMDIR)/chargen_pet1 $(ROMDIR)/kernal4c
	rm -f $(ROMDIR)/edit80_grfkb_ext_chk.bin $(ROMDIR)/edit80_chk.bin


