PROFILE_DIR := $(shell pwd)
WORK_DIR    := $(HOME)/crunchy-work
OUT_DIR     := $(HOME)/release/
ISO         := $(shell ls $(OUT_DIR)/*.iso 2>/dev/null | head -n1)

VBOX_VM         ?= crunchy-test
VBOX_CONTROLLER ?= IDE

.PHONY: all build clean unmount run shell update-base reapply-boot-tweaks update

all: build

update-base:
	sudo pacman -Sy --needed archiso
	rsync -a --delete /usr/share/archiso/configs/releng/syslinux/ $(PROFILE_DIR)/syslinux/
	rsync -a --delete /usr/share/archiso/configs/releng/efiboot/ $(PROFILE_DIR)/efiboot/
	rsync -a --delete /usr/share/archiso/configs/releng/grub/ $(PROFILE_DIR)/grub/
	@echo ">> boot-loader boilerplate refreshed from releng."
	@echo ">> re-apply your cow_spacesize / hidden-menu / timeout edits to"
	@echo "   syslinux/*.cfg, efiboot/loader/*, grub/grub.cfg if this overwrote them."

reapply-boot-tweaks:
	sed -i '/archisobasedir/ s/$$/ cow_spacesize=6G/' $(PROFILE_DIR)/syslinux/*.cfg
	sed -i '/archisobasedir/ s/$$/ cow_spacesize=6G/' $(PROFILE_DIR)/efiboot/loader/entries/*.conf
	sed -i 's/^TIMEOUT .*/TIMEOUT 1/' $(PROFILE_DIR)/syslinux/archiso_sys-linux.cfg
	sed -i '/^TIMEOUT/a MENU HIDDEN' $(PROFILE_DIR)/syslinux/archiso_sys-linux.cfg
	sed -i 's/^timeout .*/timeout 0/' $(PROFILE_DIR)/efiboot/loader/loader.conf
	@echo ">> boot tweaks re-applied."

update: update-base reapply-boot-tweaks build

unmount:
	-sudo umount -R $(WORK_DIR)/x86_64/airootfs/sys 2>/dev/null
	-sudo umount -R $(WORK_DIR)/x86_64/airootfs/proc 2>/dev/null
	-sudo umount -R $(WORK_DIR)/x86_64/airootfs/dev 2>/dev/null

clean: unmount
	sudo rm -rf $(WORK_DIR) $(OUT_DIR)

build: clean
	mkdir -p $(OUT_DIR)/
	sudo mkarchiso -v -w $(WORK_DIR) -o $(OUT_DIR) $(PROFILE_DIR)
	@ls -lh $(OUT_DIR)/*.iso

# power off the VM (ignore error if already off), repoint its optical
# drive at the freshly built ISO, then boot it
run:
	-VBoxManage controlvm $(VBOX_VM) poweroff
	@sleep 2
	VBoxManage storageattach $(VBOX_VM) --storagectl $(VBOX_CONTROLLER) \
		--port 0 --device 0 --type dvddrive --medium "$(ISO)"
	VBoxManage startvm $(VBOX_VM)

# just unmount + wipe without rebuilding, if a build died mid-way
shell:
	@echo "ISO: $(ISO)"
