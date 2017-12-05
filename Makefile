
img=hd60m.img

BUILD_DIR = ./build
ENTRY_POINT = 0xc0001500
AS = nasm
CC = gcc
LD = ld
LIB = -I lib/ -I lib/kernel/ -I lib/user/ -I kernel/ -I device/
ASFLAGS = -f elf
CFLAGS = -Wall $(LIB) -c -fno-builtin -W -Wstrict-prototypes \
         -Wmissing-prototypes 
LDFLAGS = -Ttext $(ENTRY_POINT) -e main -Map $(BUILD_DIR)/kernel.map
OBJS = $(BUILD_DIR)/main.o $(BUILD_DIR)/init.o $(BUILD_DIR)/interrupt.o \
      $(BUILD_DIR)/timer.o $(BUILD_DIR)/kernel.o $(BUILD_DIR)/print.o \
      $(BUILD_DIR)/debug.o

##############     c代码编译     ###############
$(BUILD_DIR)/main.o: kernel/main.c lib/kernel/print.h \
        lib/stdint.h kernel/init.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/init.o: kernel/init.c kernel/init.h lib/kernel/print.h \
        lib/stdint.h kernel/interrupt.h device/timer.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/interrupt.o: kernel/interrupt.c kernel/interrupt.h \
        lib/stdint.h kernel/global.h lib/kernel/io.h lib/kernel/print.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/timer.o: device/timer.c device/timer.h lib/stdint.h\
         lib/kernel/io.h lib/kernel/print.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/debug.o: kernel/debug.c kernel/debug.h \
        lib/kernel/print.h lib/stdint.h kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@

##############    汇编代码编译    ###############
$(BUILD_DIR)/kernel.o: kernel/kernel.S
	$(AS) $(ASFLAGS) $< -o $@
$(BUILD_DIR)/print.o: lib/kernel/print.S
	$(AS) $(ASFLAGS) $< -o $@

##############    链接所有目标文件    #############
$(BUILD_DIR)/kernel.bin: $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

.PHONY : mk_dir hd clean all

mk_dir:
	if [ ! -d $(BUILD_DIR) ];then mkdir $(BUILD_DIR);fi

mbr_loader:
	nasm -I boot/include/ -o boot/mbr.bin boot/mbr.S
	nasm -I boot/include/ -o boot/loader.bin boot/loader.S

build: $(BUILD_DIR)/kernel.bin

all: mk_dir build mbr_loader

image:
	@-rm -rf $(img)
	bximage -hd -mode="flat" -size=30 -q $(img)
	dd if=./boot/mbr.bin of=$(img) bs=512 count=1 conv=notrunc
	dd if=./boot/loader.bin of=$(img) bs=512 seek=2 count=3 conv=notrunc
	dd if=$(BUILD_DIR)/kernel.bin of=$(img) bs=512 seek=9 count=200 conv=notrunc

clean:
	@-rm -rf $(BUILD_DIR)
	@-rm -rf dev/*.img dev/*.bin dev/*.o dev/*~
	@-rm -rf boot/*.img boot/*.bin boot/*.o boot/*~
	@-rm -rf boot/include/*.img boot/include/*.bin boot/include/*.o boot/include/*~
	@-rm -rf lib/*.img lib/*.bin lib/*.o lib/*~
	@-rm -rf lib/kernel/*.img lib/kernel/*.bin lib/kernel/*.o lib/kernel/*~
	@-rm -rf kernel/*.img kernel/*.bin kernel/*.o kernel/*~
	@-rm -rf *.o *.bin *.img *~
