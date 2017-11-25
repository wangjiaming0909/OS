bin=mbr.bin
mbr=boot/mbr.s
include=boot/include/
hd=hd60m.img
all:$(hd)

$(bin):$(mbr)
	nasm -I $(include) -o $(bin) $(mbr)

$(hd): $(bin)
	dd if=$(bin) of=hd60m.img bs=512 count=1 conv=notrunc
