# anshul333y's nixos installer script

#part1
printf '\033c'

# partition, format and mount partitions
efi=/dev/nvme0n1p1
root=/dev/nvme0n1p2
home=/dev/nvme0n1p3
swap=/dev/nvme0n1p4

mkfs.fat -F 32 -n boot $efi
mkfs.ext4 -F -L arch $root
mkfs.ext4 -F -L anshul333y $home
mkswap -L swap $swap

mount $root /mnt
mkdir -p /mnt/boot/efi
mkdir -p /mnt/home
mount $efi /mnt/boot/efi
mount $home /mnt/home
swapon $swap

# nixos-generate-config
nixos-generate-config --root /mnt

# nixos-install
nixos-install --no-root-passwd
exit
