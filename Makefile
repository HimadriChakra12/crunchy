PROFILE_DIR := $(shell pwd)
WORK_DIR    := $(HOME)/crunchy-work
OUT_DIR     := /tmp/crunchy-out
ISO         := $(shell ls $(OUT_DIR)/*.iso 2>/dev/null | head -n1)

# set this to your actual VM's name (VBoxManage list vms) and its
# storage controller name (VBoxManage showvminfo <name> | grep -i controller)
VBOX_VM         ?= crunchy-test
VBOX_CONTROLLER ?= IDE

.PHONY: all build clean unmount run shell

all: build

# unmount any stale chroot binds left by an interrupted previous build
unmount:
	-sudo umount -R $(WORK_DIR)/x86_64/airootfs/sys 2>/dev/null
	-sudo umount -R $(WORK_DIR)/x86_64/airootfs/proc 2>/dev/null
	-sudo umount -R $(WORK_DIR)/x86_64/airootfs/dev 2>/dev/null

clean: unmount
	sudo rm -rf $(WORK_DIR) $(OUT_DIR)

build: clean
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
