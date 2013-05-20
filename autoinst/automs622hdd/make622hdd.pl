#!/usr/bin/perl
#
# Use MS-DOS 6.22 installation disks to construct a bootable hard drive image
#
# requires:
#     mtools
#     fdisk
#     dd
#     mkdosfs
#     qemu-img
#
# in-tree requirements:
#     ../../download-item.pl
#
# params
#     --size <n> in MB

my $target_size = 0;

for ($i=0;$i < @ARGV;) {
	my $a = $ARGV[$i++];

	if ($a =~ s/^-+//) {
		if ($a eq "size") {
			$target_size = $ARGV[$i++] + 0;
			$target_size *= 1024 * 1024;
			$target_size = 0 if $target_size < 1;
		}
		else {
			die "Unknown switch $a\n";
		}
	}
	else {
		die "Unhandled arg $a\n";
	}
}

my $rel = "../..";
my $diskbase = "$rel/build/msdos622hdd";

system("make") == 0 || die;

sub shellesc($) {
	my $a = shift @_;
	$a =~ s/([^0-9a-zA-Z\.\-])/\\$1/g;
	return $a;
}

# download images, Disk 1, Disk 2, Disk 3
system("../../download-item.pl --rel $rel --as msdos.622.install.1.disk.xz --url ".shellesc("Software/DOS/Microsoft MS-DOS/6.22/1.44MB/Disk 1.img.xz")) == 0 || die;
system("../../download-item.pl --rel $rel --as msdos.622.install.2.disk.xz --url ".shellesc("Software/DOS/Microsoft MS-DOS/6.22/1.44MB/Disk 2.img.xz")) == 0 || die;
system("../../download-item.pl --rel $rel --as msdos.622.install.3.disk.xz --url ".shellesc("Software/DOS/Microsoft MS-DOS/6.22/1.44MB/Disk 3.img.xz")) == 0 || die;

# construct the disk image
system("mkdir -p $rel/build") == 0 || die;

my $cyls = 1020,$act_cyls;
my $heads = 16;
my $sects = 63;
my $clustersize = -1;

if ($target_size > 0) {
	$cyls = int(($target_size / 512 / $heads / $sects) + 0.5);
	$cyls = 1 if $cyls == 0;
}

# MS-DOS cannot handle >= 1024 cylinders
while ($cyls >= 1024 && $heads < 128) {
	$heads *= 2;
	$cyls /= 2;
}
# if we still need to reduce, try the 255 head trick
if ($cyls >= 1024) {
	$cyls *= $heads;
	$heads = 255;
	$cyls /= $heads;
}

$act_cyls = int($cyls);
$x = 512 * $cyls * $heads * $sects;
if ($x >= (2049*1024*1024)) {
	# limit the partition to keep within MS-DOS 6.22's capabilities.
	# A partition larger than 2GB is not supported.
	$x = (2048*1024*1024);
	$cyls = $x / 512 / $heads / $sects;
}

$cyls = int($cyls + 0.5);
die if $cyls >= 1024;

print "Chosen disk geometry C/H/S: $cyls/$heads/$sects (disk $act_cyls)\n";

sub unpack_dos_tmp() {
# unpack the compressed files
	my @l = (
		"SY_","SYS",
		"EX_","EXE",
		"TX_","TXT",
		"CP_","CPI",
		"HL_","HLP",
		"OV_","OVL",
		"DL_","DLL",
		"CO_","COM",
		"GR_","GRP",
		"LS_","LST",
		"38_","386",
		"IN_","INI",
		"PR_","PRG"
	);
	for ($i=0;($i+2) <= @l;$i += 2) {
		my $old = $l[$i],$new = $l[$i+1],$nname;

		opendir(DIR,"dos.tmp") || die;
		while (my $n = readdir(DIR)) {
			next if $n =~ m/^\./;
			next unless -f "dos.tmp/$n";
			next unless $n =~ m/\.$old$/;
			$nname = $n;
			$nname =~ s/\.$old$/.$new/;

			print "$n -> $nname\n";
			system("./expand dos.tmp/$n dos.tmp/$nname") == 0 || die;
			unlink("dos.tmp/$n") || die;
		}
		closedir(DIR);
	}
}

my $part_offset = 0x200 * $sects;

print "Constructing HDD image: C/H/S $act_cyls/$heads/$sects\n";
system("rm -v $diskbase; dd if=/dev/zero of=$diskbase bs=512 count=1 seek=".(($act_cyls*$heads*$sects)-1));

print "Formatting disk image: \n";
system("mformat -m 0xF8 ".($clustersize > 0 ? ("-c ".$clustersize) : "")." -t $cyls -h $heads -s $sects -d 2 -i $diskbase\@\@$part_offset") == 0 || die;

# ugh... and it turns out mkdosfs leaves byte 0x24 set to zero among other stupid things
open(BIN,"+<","$diskbase") || die
binmode(BIN);

seek(BIN,$part_offset+0x18,0); print BIN pack("v",$sects); # let me tell you the TRUE sectors/track
seek(BIN,$part_offset+0x1A,0); print BIN pack("v",$heads); # and heads
seek(BIN,$part_offset+0x1C,0); print BIN pack("V",$sects); # and number of "hidden sectors" preceeding the partition
seek(BIN,$part_offset+0x24,0); print BIN pack("c",0x80); # this is a hard disk

close(BIN);

print "Unpacking disk 1:\n";
system("xz -c -d $rel/web.cache/msdos.622.install.1.disk.xz >tmp.dsk") == 0 || die;

# copy the boot sector of the install disk, being careful not to overwrite the BPB written by mkdosfs
print "Sys'ing the disk:\n";
system("dd conv=notrunc,nocreat if=tmp.dsk of=$diskbase bs=1 seek=".($part_offset   )." skip=0 count=11") == 0 || die;
system("dd conv=notrunc,nocreat if=tmp.dsk of=$diskbase bs=1 seek=".($part_offset+62)." skip=62 count=".(512-62)) == 0 || die;

# and copy IO.SYS and MSDOS.SYS over, assuming that mkdosfs has left the root directory completely empty
# so that our copy operation puts them FIRST in the root directory.
unlink("tmp.sys");
system("mcopy -i tmp.dsk ::IO.SYS tmp.sys") == 0 || die;
system("mcopy -i $diskbase\@\@$part_offset tmp.sys ::IO.SYS") == 0 || die;
system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::IO.SYS") == 0 || die;
unlink("tmp.sys");

unlink("tmp.sys");
system("mcopy -i tmp.dsk ::MSDOS.SYS tmp.sys") == 0 || die;
system("mcopy -i $diskbase\@\@$part_offset tmp.sys ::MSDOS.SYS") == 0 || die;
system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::MSDOS.SYS") == 0 || die;
unlink("tmp.sys");

unlink("tmp.sys");
system("mcopy -i tmp.dsk ::DRVSPACE.BIN tmp.sys") == 0 || die;
system("mcopy -i $diskbase\@\@$part_offset tmp.sys ::DRVSPACE.BIN") == 0 || die;
system("mattrib -a +r +s +h -i $diskbase\@\@$part_offset ::DRVSPACE.BIN") == 0 || die;
unlink("tmp.sys");

unlink("tmp.sys");
system("mcopy -i tmp.dsk ::COMMAND.COM tmp.sys") == 0 || die;
system("mcopy -i $diskbase\@\@$part_offset tmp.sys ::COMMAND.COM") == 0 || die;
system("mattrib -a +r +s -i $diskbase\@\@$part_offset ::COMMAND.COM") == 0 || die;
unlink("tmp.sys");

# create DOS subdirectory
system("mmd -i $diskbase\@\@$part_offset DOS") == 0 || die;
system("rm -Rfv dos.tmp; mkdir -p dos.tmp") == 0 || die;

# copy the other contents of the floppy (disk 1) to the DOS subdirectory
system("mcopy -b -Q -n -m -v -s -i tmp.dsk ::. dos.tmp/") == 0 || die;
unlink("tmp.dsk");

# copy the other contents of the floppy (disk 2) to the DOS subdirectory
print "Unpacking disk 2:\n";
system("xz -c -d $rel/web.cache/msdos.622.install.2.disk.xz >tmp.dsk") == 0 || die;
system("mcopy -b -Q -n -m -v -s -i tmp.dsk ::. dos.tmp/") == 0 || die;
unlink("tmp.dsk");

# copy the other contents of the floppy (disk 3) to the DOS subdirectory
print "Unpacking disk 3:\n";
system("xz -c -d $rel/web.cache/msdos.622.install.3.disk.xz >tmp.dsk") == 0 || die;
system("mcopy -b -Q -n -m -v -s -i tmp.dsk ::. dos.tmp/") == 0 || die;
unlink("tmp.dsk");

# unpack the compressed files
unpack_dos_tmp();

# copy them back into the hard disk image
system("mcopy -b -Q -n -m -v -s -i $diskbase\@\@$part_offset dos.tmp/. ::DOS/") == 0 || die;

# remove dos.tmp
system("rm -Rfv dos.tmp; mkdir -p dos.tmp") == 0 || die;

# next, add the OAK IDE CD-ROM driver
system("mcopy -i $diskbase\@\@$part_offset oakcdrom.sys ::DOS/OAKCDROM.SYS") == 0 || die;

# and the default CONFIG.SYS and AUTOEXEC.BAT files
system("mcopy -i $diskbase\@\@$part_offset config.sys.init ::CONFIG.SYS") == 0 || die;
system("mcopy -i $diskbase\@\@$part_offset autoexec.bat.init ::AUTOEXEC.BAT") == 0 || die;

# make a zero track and cat them together to make a full disk image
system("dd conv=notrunc,nocreat if=mbr.bin of=$diskbase bs=512 count=1") == 0 || die;

# and then edit the partition table directly. we WOULD use fdisk, but fdisk has this
# terrible fetish for forcing your first partition at least 2048 sectors away from the start
# of the disk, which is an utter waste of disk space. Fuck you fdisk.
open(BIN,"+<","$diskbase") || die
binmode(BIN);
seek(BIN,0x1BE,0);
print BIN pack("cccccccc",
	0x80, # status/physical drive
	0x01, # head 1
	0x01 | (0 << 6), # sector 1 cylinder 0 (high 2 bits)
	0x00, # cylinder 0 (low 8 bits)
	0x06, # partition type (0x06 = MS-DOS FAT16 >= 32MB)
	$heads-1, # end head
	$sects | ((($cyls - 1) >> 8) << 6), # end sector/cylinder
	($cyls - 1) & 0xFF); # end cylinder
print BIN pack("VV",$sects,($sects*$cyls*$heads)-$sects);
close(BIN);

# make VDI for VirtualBox, QEMU, etc
system("qemu-img convert -f raw -O vdi $diskbase $diskbase.vdi") == 0 || die;
