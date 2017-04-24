SHELL := /bin/sh
FW_DIR	:= $(TARGET_DIR)/lib/firmware/rtl_bt/
MDL_DIR	:= $(TARGET_DIR)/lib/modules/$(KVER)
DRV_DIR	:= $(MDL_DIR)/kernel/drivers/bluetooth
EXTRA_CFLAGS += -DCONFIG_BT_RTL

#Handle the compression option for modules in 3.18+
ifneq ("","$(wildcard $(DRV_DIR)/*.ko.gz)")
COMPRESS_GZIP := y
endif
ifneq ("","$(wildcard $(DRV_DIR)/*.ko.xz)")
COMPRESS_XZ := y
endif

ifneq ($(TARGET_DIR),)
DEPMOD_PREFIX = -b $(TARGET_DIR)
else
DEPMOD_PREFIX = 
endif

DEPMOD ?= depmod

ifneq ($(KERNELRELEASE),)

	obj-m := btusb.o btrtl.o 

ifneq ($(CONFIG_BT_BCM),)
	obj-m += btbcm.o
endif

ifneq ($(CONFIG_BT_INTEL),)
  obj-m += btintel.o
endif


else
	PWD := $(shell pwd)
	KVER ?= $(shell uname -r)
	KSRC ?= /lib/modules/$(KVER)/build

all: 
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KSRC) M=$(PWD) modules

clean:
	rm -rf *.o *.mod.c *.mod.o *.ko *.symvers *.order *.a
endif

install:
	echo "INSTALLING firmware..."
	@mkdir -p $(FW_DIR)
	@mkdir -p $(DRV_DIR)
	@cp -f *_fw.bin $(FW_DIR)/.
	@cp -f *.ko $(DRV_DIR)/.
ifeq ($(COMPRESS_GZIP), y)
	@gzip -f $(DRV_DIR)/btusb.ko
	@gzip -f $(DRV_DIR)/btbcm.ko
	@gzip -f $(DRV_DIR)/btintel.ko
	@gzip -f $(DRV_DIR)/btrtl.ko
endif
ifeq ($(COMPRESS_XZ), y)
	@xz -f $(DRV_DIR)/btusb.ko
	@xz -f $(DRV_DIR)/btbcm.ko
	@xz -f $(DRV_DIR)/btintel.ko
	@xz -f $(DRV_DIR)/btrtl.ko
endif
	$(DEPMOD) $(DEPMOD_PREFIX) -a $(KVER)
	@echo "installed revised btusb"

uninstall:
	rm -f $(DRV_DIR)/btusb.ko*
	depmod -a $(MDL_DIR)
	echo "uninstalled revised btusb"
