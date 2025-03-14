SHELL = /bin/bash
ifeq ($(PARAM_FILE), )
	PARAM_FILE:=$(MW_PATH)/mpi_param.mk
	include $(PARAM_FILE)
endif

include $(MW_PATH)/sample/sample.mk

SAMPLE_COMMON_DIR=$(MW_PATH)/sample/common

PANEL_INC = $(MW_PATH)/component/panel/$(shell echo $(CVIARCH) | tr A-Z a-z)
SDIR = $(SAMPLE_COMMON_DIR)
SRCS := $(wildcard $(SDIR)/*.c)
#EXCLUDE += $(SDIR)/sample_common_peripheral.c
#SRCS := $(filter-out $(EXCLUDE), $(SRCS))
INCS = -I$(MW_INC) -I$(ISP_INC) -I$(KERNEL_INC) -I$(PANEL_INC) -Iinclude -I$(MW_PATH)/3rdparty/inih
OBJS = $(patsubst %.c, %.o, $(SRCS))
DEPS = $(SRCS:.c=.d)
TARGET_A = $(CURDIR)/libsample.a
TARGET_SO = $(CURDIR)/libsample.so

EXTRA_CFLAGS += $(INCS)

ifeq ($(DEBUG), 1)
	EXTRA_CFLAGS += -g -O0
endif

include $(BUILD_PATH)/.config

.PHONY : prepare clean all

all : prepare $(TARGET_A) $(TARGET_SO)

prepare:
	@cp -rf $(ALIOS_PATH)/components/cvi_sensor/sensor_cfg/sensor_cfg.h $(SAMPLE_COMMON_DIR)

$(SDIR)/%.o: $(SDIR)/%.c
	@echo "MW_PATH: $(MW_PATH)"
	@$(CC) $(DEPFLAGS) $(CFLAGS) $(EXTRA_CFLAGS) -c $< -o $@
	@echo [$(notdir $(CC))] $(notdir $@)

$(TARGET_A): $(OBJS)
	@$(AR) $(ARFLAGS) $(TARGET_A) $(OBJS)
	@echo -e $(YELLOW)[LINK]$(END)[$(notdir $(AR))] $(notdir $(TARGET_A))

$(TARGET_SO): $(OBJS)
	@$(LD) $(LDFLAGS) $(EXTRA_LDFLAGS) -o $(TARGET_SO) --start-group $(OBJS) --end-group
	@echo -e $(GREEN)[LINK]$(END)[$(notdir $(LD))] $(notdir $(TARGET_SO))

clean:
	@rm -f $(OBJS) $(TARGET_A) $(TARGET_SO)

install:
	@cp $(TARGET_A) $(TARGET_SO) ../install/lib
	@cp $(TARGET_A) $(TARGET_SO) ../src

