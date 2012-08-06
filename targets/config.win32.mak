# Windows 32-bit protected mode target (Win32s)

WCC=env $(WATENV) $(OWCC386)
WCL=env $(WATENV) $(OWCL386)
WRC=env $(WATENV) $(OWRC)
WLIB=env $(WATENV) $(OWLIB)
WLINK=env $(WATENV) $(OWLINK)
WBIND=env $(WATENV) $(OWBIND)
WSTRIP=env $(WATENV) $(OWSTRIP)
exe_suffix=.exe
obj_suffix=.obj
lib_suffix=.lib

WATENV += "INCLUDE=$(OPENWATCOM)/h;$(OPENWATCOM)/h/nt;$(OPENWATCOM)/h/nt/ddk;$(OPENWATCOM)/h/win"

# make flags
TARGET_WINDOWS=1
TARGET_WINDOWS_WIN32=1
TARGET_BITS=32
TARGET_PROTMODE=1

# target-dependent
TARGET_EXTLIB=0
TARGET_CPUONLY=0
W_CPULEVEL=0
W_MMODE=l

TARGET_DEBUG=0
W_DEBUG=-d0 -s

# eval the targetdir
_win32_t1=$(subst 86,,$(patsubst win32/%,%,$(target_subdir)))
_win32_t=$(subst 31_,,$(subst 30_,,$(subst 20_,,$(subst 10_,,$(_win32_t1)))))

ifeq ($(findstring 30,$(_win32_t1)),30)
  $(error Windows 3.0 not supported)
endif
ifeq ($(findstring 31,$(_win32_t1)),31)
  $(error Windows 3.1 not supported)
endif
ifeq ($(findstring 95,$(_win32_t1)),95) # 4.0
  TARGET_WINDOWS_VERSION=40
  TARGET_WINDOWS_WLINK_OSVERSION=option osversion=4.0
endif
ifeq ($(findstring 98,$(_win32_t1)),98) # 4.10
  TARGET_WINDOWS_VERSION=41
  TARGET_WINDOWS_WLINK_OSVERSION=option osversion=4.10
endif
ifeq ($(findstring me,$(_win32_t1)),me) # 4.90
  TARGET_WINDOWS_VERSION=49
  TARGET_WINDOWS_WLINK_OSVERSION=option osversion=4.90
endif
ifeq ($(findstring nt,$(_win32_t1)),nt) # When people think "Windows NT" they usually think Windows NT 4.0 or higher
# TODO: Alternate build targets for Windows NT 3.5, Windows NT 3.1
  TARGET_WINDOWS_VERSION=40
  TARGET_WINDOWS_WLINK_OSVERSION=option osversion=4.0
  TARGET_WINDOWS_NT=1
endif

ifeq ($(findstring 3,$(_win32_t)),3)
  W_CPULEVEL=3
endif
ifeq ($(findstring 4,$(_win32_t)),4)
  W_CPULEVEL=4
endif
ifeq ($(findstring 5,$(_win32_t)),5)
  W_CPULEVEL=5
endif
ifeq ($(findstring 6,$(_win32_t)),6)
  W_CPULEVEL=6
endif

ifeq ($(findstring c,$(_win32_t)),c)
  W_MMODE=c
endif
ifeq ($(findstring s,$(_win32_t)),s)
  W_MMODE=s
endif
ifeq ($(findstring m,$(_win32_t)),m)
  W_MMODE=m
endif
ifeq ($(findstring l,$(_win32_t)),l)
  W_MMODE=l
endif
ifeq ($(findstring h,$(_win32_t)),h)
  W_MMODE=h
endif
ifeq ($(findstring f,$(_win32_t)),f)
  W_MMODE=f
endif

ifeq ($(findstring o,$(_win32_t)),o)
TARGET_CPUONLY=1
endif

ifeq ($(findstring x,$(_win32_t)),x)
TARGET_EXTLIB=1
endif

ifeq ($(findstring d,$(_win32_t)),d)
TARGET_DEBUG=1
W_DEBUG=-d3
endif

# compiler flags
_win32_defs = -dTARGET_WINDOWS=1 -dTARGET_WINDOWS_WIN32=1 -dTARGET_BITS=32 -dTARGET_PROTMODE=1 -dTARGET_CPU=$(W_CPULEVEL) -dTARGET_WINDOWS_GUI=1
ifeq ($(TARGET_CPUONLY),1)
_win32_defs += -dTARGET_CPUONLY=1
endif
ifeq ($(TARGET_EXTLIB),1)
_win32_defs += -dTARGET_EXTLIB=1
endif
ifeq ($(TARGET_DEBUG),1)
_win32_defs += -dTARGET_DEBUG=1
endif
ifneq ($(TARGET_WINDOWS_VERSION),)
_win32_defs += -dTARGET_WINDOWS_VERSION=$(TARGET_WINDOWS_VERSION)
endif
ifneq ($(TARGET_WINDOWS_NT),)
_win32_defs += -dTARGET_WINDOWS_NT=$(TARGET_WINDOWS_NT)
endif

WLINKFLAGS=
ifeq ($(TARGET_WINDOWS_VERSION),31)
WRCFLAGS=-q -r -31 
else
WRCFLAGS=-q -r -30
endif
WCCFLAGS=-e=2 -zq -m$(W_MMODE) $(W_DEBUG) -bt=windows -oilrtfm -wx -$(W_CPULEVEL) $(_win32_defs) -q -fr=nul
WASMFLAGS=-e=2 -zq -m$(W_MMODE) $(W_DEBUG) -bt=windows -wx -$(W_CPULEVEL) $(_win32_defs) -q
NASMFLAGS=-DTARGET_WINDOWS=1 -DTARGET_WINDOWS_GUI=1 -DTARGET_WINDOWS_WIN32=1 -DTARGET_BITS=32 -DTARGET_PROTMODE=1 -DMMODE=$(W_MMODE) -DCPUONLY=$(TARGET_CPUONLY) -DEXTLIB=$(TARGET_EXTLIB) -DDEBUG=$(TARGET_DEBUG) -DTARGET_CPU=$(W_CPULEVEL) -DTARGET_WINDOWS_VERSION=$(TARGET_WINDOWS_VERSION) -DTARGET_WINDOWS_NT=$(TARGET_WINDOWS_NT)
WLINK_SYSTEM=nt_win
WLINKFLAGS=$(TARGET_WINDOWS_WLINK_OSVERSION)
WLINK_SEGMENTS=

# TODO: Copy params for console-mode apps
WCCFLAGS_CONSOLE=$(WCCFLAGS)
WASMFLAGS_CONSOLE=$(WASMFLAGS)
NASMFLAGS_CONSOLE=$(NASMFLAGS)
WLINKFLAGS_CONSOLE=$(WLINKFLAGS)
WLINK_SYSTEM_CONSOLE=$(WLINK_SYSTEM)

