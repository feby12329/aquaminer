# Build aquaminer, fetching dependencies as needed


NAME := aquachain-miner
VERSION := $(shell git rev-parse --short HEAD)
ifeq ($(VERSION),)
VERSION := "dev"
endif
VERSION := $(shell cat VERSION)-$(VERSION)
WD := $(PWD)

# CURLDIR is the path to curl lib 
# (it has ./bin/curl-config and ./lib/libcurl.a)
# if depends/curl is used, it will be fetched and compiled
CURLDIR?=depends/libcurl
CURLFLAGS ?= $(shell ${CURLDIR}/bin/curl-config --static-libs)

CXXFLAGS := -O3 -std=c++11 -pedantic -Wall -Werror -Iinclude -I. -Iaquahash/include -Ispdlog/include -I${CURLDIR}/include -Idepends -Idepends/jsoncpp/dist/json -pthread -static -DVERSION=\""$(VERSION)"\"
CFLAGS += -O3
SRCDIR := src
OBJDIR := _obj
GMPMD5=e3e08ac185842a882204ba3c37985127

# 'make config=avx2' to build avx2 version
suffix := -unknown
ifeq ($(config), avx2)
CFLAGS += -mavx2
suffix := -avx2
else ifeq ($(config), avx)
CFLAGS += -mavx
suffix := -avx
else ifeq ($(config), debug)
CFLAGS += -ggdb
suffix := -debug
else
CFLAGS := -mno-sse3 -mno-avx -mno-avx2
suffix := -plain
endif
$(info Building: $(NAME)-$(VERSION)$(suffix))

# combine cflags
ALLFLAGS := $(CFLAGS) $(CXXFLAGS)

# static link aquahash and spdlog (others are installed with apt-get, or other way)
STATICLIBS := spdlog/libspdlog.a aquahash/libaquahash.a depends/libgmp/libgmp.a depends/jsoncpp/lib_json/libjsoncpp.a
LDFLAGS := $(AQUA_LDFLAGS) $(STATICLIBS) $(CURLFLAGS) -static -lpthread 
$(info LDFLAGS=$(LDFLAGS))


CPP_SOURCES := $(wildcard $(SRCDIR)/*.cpp)
#CPP_OBJECTS := $(CPP_SOURCES:.cpp)
CPP_OBJECTS := $(addprefix $(OBJDIR)/,$(notdir $(CPP_SOURCES:.cpp=.o)))
$(info Sources: $(CPP_SOURCES))
$(info Objects: $(CPP_OBJECTS))

help:
	@echo help
default: bin/$(NAME)-$(VERSION)$(suffix)

bin/$(NAME)-$(VERSION)$(suffix): deps $(CPP_OBJECTS)
	mkdir -p bin
	@echo LINKING
	$(CXX) $(ALLFLAGS) -o $@ $(CPP_OBJECTS) $(LDFLAGS)

deps:	$(STATICLIBS) include/cli11/CLI11.hpp $(CURLDIR) 
.PHONY += deps
$(OBJDIR)/%.o: $(SRCDIR)/%.cpp $(STATICLIBS) $(CURLDIR)
	@echo COMPILING $<
	@mkdir -p $(OBJDIR)
	$(CXX) $(ALLFLAGS) -c -o $@ $<

aquahash/libaquahash.a: aquahash
	$(info building aquahash: $(CFLAGS))
	env CFLAGS="$(CFLAGS) -DARGON2_NO_THREADS -DARGON2_NO_SECURE_WIPE" \
	  OPTTARGET=0 $(MAKE) -C aquahash libaquahash.a

depends/jsoncpp:
	git clone https://github.com/open-source-parsers/jsoncpp $@

depends/jsoncpp/lib_json/libjsoncpp.a: depends/jsoncpp
	cd depends/jsoncpp && ./amalgamate.py
	cd depends/jsoncpp && cmake src
	cd depends/jsoncpp && ${MAKE}

depends/libgmp/libgmp.a: depends/libgmp
	cd $< && ./configure && ${MAKE} && cp .libs/libgmp.a .
deps/gmp-6.2.0.tar.lz:
	mkdir -p deps
	cd deps && wget https://gmplib.org/download/gmp/gmp-6.2.0.tar.lz
depends/libgmp: checkchecksum deps/gmp-6.2.0.tar.lz
	cd depends && tar xaf ../deps/gmp-6.2.0.tar.lz
	rm -rf depends/libgmp
	mv depends/gmp-6.2.0 depends/libgmp
checkchecksum: deps/gmp-6.2.0.tar.lz
	echo checking checksums
	cd deps && md5sum -c ../scripts/md5check.sum 
	echo checksum matched

.PHONY += checkchecksum

include/cli11/CLI11.hpp:
	$(info fetching CLI11 header)
	mkdir -p include/cli11/
	wget -O include/cli11/CLI11.hpp https://github.com/CLIUtils/CLI11/releases/download/v1.9.0/CLI11.hpp

clean:
	rm -vf src/*.o src/*.a
	rm -rvf bin
	rm -rvf $(OBJDIR)

aquahash:
	$(info fetching aquahash source)
	git clone https://github.com/aquachain/aquahash aquahash

spdlog/libspdlog.a: spdlog
	$(info building libspdlog.a)
	cd spdlog && cmake . && make -j2 spdlog CXXFLAGS="$(CFLAGS)"
	cd ${WD} && ls -all spdlog/libspdlog.a

spdlog: 
	wget -O spdlog.zip https://github.com/gabime/spdlog/archive/v1.5.0.zip
	rm -rvf spdlog spdlog-*
	unzip spdlog.zip
	mv spdlog-1.5.0 spdlog
	rm spdlog.zip

distclean:
	$(MAKE) clean
	rm -rvf aquahash spdlog vend deps aquachain-miner bin include/cli11
	rm -rvf /tmp/curl


depends/libcurl:
	bash scripts/setup_libs.bash

debug:
	$(MAKE) config=debug
