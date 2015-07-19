#*********************************************************************************************************
# nbench Makefile
# target -> nbench
#*********************************************************************************************************

#*********************************************************************************************************
# include config.mk
#*********************************************************************************************************
CONFIG_MK_EXIST = $(shell if [ -f ../config.mk ]; then echo exist; else echo notexist; fi;)
ifeq ($(CONFIG_MK_EXIST), exist)
include ../config.mk
else
CONFIG_MK_EXIST = $(shell if [ -f config.mk ]; then echo exist; else echo notexist; fi;)
ifeq ($(CONFIG_MK_EXIST), exist)
include config.mk
else
CONFIG_MK_EXIST =
endif
endif

#*********************************************************************************************************
# check configure
#*********************************************************************************************************
check_defined = \
    $(foreach 1,$1,$(__check_defined))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $(value 2), ($(strip $2)))))

$(call check_defined, CONFIG_MK_EXIST, Please configure this project in RealCoder or \
create a config.mk file!)
$(call check_defined, SYLIXOS_BASE_PATH, SylixOS base project path)
$(call check_defined, TOOLCHAIN_PREFIX, the prefix name of toolchain)
$(call check_defined, DEBUG_LEVEL, debug level(debug or release))

#*********************************************************************************************************
# configure area you can set the following config to you own system
# FPUFLAGS (-mfloat-abi=softfp -mfpu=vfpv3 ...)
# CPUFLAGS (-mcpu=arm920t ...)
# NOTICE: libsylixos, BSP and other kernel modules projects CAN NOT use vfp!
#*********************************************************************************************************
FPUFLAGS = -mfloat-abi=softfp -mfpu=vfpv3
CPUFLAGS = -mcpu=cortex-a8 $(FPUFLAGS)

#PG = -pg

#*********************************************************************************************************
# toolchain select
#*********************************************************************************************************
CC  = $(TOOLCHAIN_PREFIX)gcc
CXX = $(TOOLCHAIN_PREFIX)g++
AS  = $(TOOLCHAIN_PREFIX)gcc
AR  = $(TOOLCHAIN_PREFIX)ar
LD  = $(TOOLCHAIN_PREFIX)g++

#*********************************************************************************************************
# do not change the following code
# buildin internal application source
#*********************************************************************************************************
#*********************************************************************************************************
# src(s) file
#*********************************************************************************************************
SRCS = \
nbench-byte-2.2.3/emfloat.c \
nbench-byte-2.2.3/hardware.c \
nbench-byte-2.2.3/misc.c \
nbench-byte-2.2.3/nbench0.c \
nbench-byte-2.2.3/nbench1.c \
nbench-byte-2.2.3/sysspec.c \


#*********************************************************************************************************
# build path
#*********************************************************************************************************
ifeq ($(DEBUG_LEVEL), debug)
OUTDIR = Debug
else
OUTDIR = Release
endif

OUTPATH = ./$(OUTDIR)
OBJPATH = $(OUTPATH)/obj
DEPPATH = $(OUTPATH)/dep

#*********************************************************************************************************
# target
#*********************************************************************************************************
EXE = $(OUTPATH)/nbench

#*********************************************************************************************************
# nbench objects
#*********************************************************************************************************
OBJS = $(addprefix $(OBJPATH)/, $(addsuffix .o, $(basename $(SRCS))))
DEPS = $(addprefix $(DEPPATH)/, $(addsuffix .d, $(basename $(SRCS))))

#*********************************************************************************************************
# include path
#*********************************************************************************************************
INCDIR  = -I"$(SYLIXOS_BASE_PATH)/libsylixos/SylixOS"
INCDIR += -I"$(SYLIXOS_BASE_PATH)/libsylixos/SylixOS/include"
INCDIR += -I"$(SYLIXOS_BASE_PATH)/libsylixos/SylixOS/include/inet"

#*********************************************************************************************************
# compiler preprocess
#*********************************************************************************************************
DSYMBOL  = -DSYLIXOS -DLINUX="SylixOS is NOT Linux"

#*********************************************************************************************************
# depend dynamic library
#*********************************************************************************************************
DEPEND_DLL = -lvpmpdm

#*********************************************************************************************************
# depend dynamic library search path
#*********************************************************************************************************
DEPEND_DLL_PATH = -L"$(SYLIXOS_BASE_PATH)/libsylixos/$(OUTDIR)"

#*********************************************************************************************************
# compiler optimize
#*********************************************************************************************************
ifeq ($(DEBUG_LEVEL), debug)
OPTIMIZE = -O0 -g3 -gdwarf-2
else
OPTIMIZE = -O3 -g1 -gdwarf-2											# Do NOT use -O3 and -Os
endif										    						# -Os is not align for function
																		# loop and jump.
#*********************************************************************************************************
# depends and compiler parameter (cplusplus in kernel MUST NOT use exceptions and rtti)
#*********************************************************************************************************
DEPENDFLAG  = -MM
CXX_EXCEPT  = -fno-exceptions -fno-rtti
COMMONFLAGS = $(CPUFLAGS) $(OPTIMIZE) -Wall -fmessage-length=0 -fsigned-char -fno-short-enums
ASFLAGS     = -x assembler-with-cpp $(DSYMBOL) $(INCDIR) $(COMMONFLAGS) -c
CFLAGS      = $(DSYMBOL) $(INCDIR) $(COMMONFLAGS) -fPIC -c
CXXFLAGS    = $(DSYMBOL) $(INCDIR) $(CXX_EXCEPT) $(COMMONFLAGS) -fPIC -c
ARFLAGS     = -r

#*********************************************************************************************************
# define some useful variable
#*********************************************************************************************************
DEPEND          = $(CC)  $(DEPENDFLAG) $(CFLAGS)
DEPEND.d        = $(subst -g ,,$(DEPEND))
COMPILE.S       = $(AS)  $(ASFLAGS)
COMPILE_VFP.S   = $(AS)  $(ASFLAGS)
COMPILE.c       = $(CC)  $(CFLAGS)
COMPILE.cxx     = $(CXX) $(CXXFLAGS)

#*********************************************************************************************************
# target
#*********************************************************************************************************
all: $(EXE)
		@echo create "$(EXE)" success.

#*********************************************************************************************************
# include depends
#*********************************************************************************************************
ifneq ($(MAKECMDGOALS), clean)
ifneq ($(MAKECMDGOALS), clean_project)
sinclude $(DEPS)
endif
endif

#*********************************************************************************************************
# create depends files
#*********************************************************************************************************
$(DEPPATH)/%.d: %.c
		@echo creating $@
		@if [ ! -d "$(dir $@)" ]; then mkdir -p "$(dir $@)"; fi
		@rm -f $@; \
		echo -n '$@ $(addprefix $(OBJPATH)/, $(dir $<))' > $@; \
		$(DEPEND.d) $< >> $@ || rm -f $@; exit;

$(DEPPATH)/%.d: %.cpp
		@echo creating $@
		@if [ ! -d "$(dir $@)" ]; then mkdir -p "$(dir $@)"; fi
		@rm -f $@; \
		echo -n '$@ $(addprefix $(OBJPATH)/, $(dir $<))' > $@; \
		$(DEPEND.d) $< >> $@ || rm -f $@; exit;

#*********************************************************************************************************
# compile source files
#*********************************************************************************************************
$(OBJPATH)/%.o: %.S
		@if [ ! -d "$(dir $@)" ]; then mkdir -p "$(dir $@)"; fi
		$(COMPILE.S) $< $(PG) -o $@

$(OBJPATH)/%.o: %.c
		@if [ ! -d "$(dir $@)" ]; then mkdir -p "$(dir $@)"; fi
		$(COMPILE.c) $< $(PG) -o $@

$(OBJPATH)/%.o: %.cpp
		@if [ ! -d "$(dir $@)" ]; then mkdir -p "$(dir $@)"; fi
		$(COMPILE.cxx) $< $(PG) -o $@

#*********************************************************************************************************
# link nbench object files
#*********************************************************************************************************
$(EXE): $(OBJS)
		$(LD) $(CPUFLAGS) $(PG) -nostdlib -fPIC -shared -o $(EXE) $(OBJS) \
		$(DEPEND_DLL_PATH) $(DEPEND_DLL) -lm -lgcc

#*********************************************************************************************************
# clean
#*********************************************************************************************************
.PHONY: clean
.PHONY: clean_project

#*********************************************************************************************************
# clean objects
#*********************************************************************************************************
clean:
		-rm -rf $(EXE)
		-rm -rf $(OBJS)
		-rm -rf $(OBJPATH)
		-rm -rf $(DEPPATH)

#*********************************************************************************************************
# clean project
#*********************************************************************************************************
clean_project:
		-rm -rf $(OUTPATH)

#*********************************************************************************************************
# END
#*********************************************************************************************************
