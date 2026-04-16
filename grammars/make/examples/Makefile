# Comment line
# Another comment

# Variable assignments
CC = gcc
CFLAGS := -Wall -Wextra
LDFLAGS ?= -lm
SOURCES += main.c utils.c
PREFIX ::= /usr/local
OBJECTS != ls *.o

# Multi-line variable
LONG_VAR = \
	first \
	second \
	third

# Define block
define MULTI_LINE
	echo "line 1"
	echo "line 2"
endef

# Variable references
BUILD_DIR = $(PREFIX)/bin
INSTALL_PATH = ${HOME}/bin
ESCAPED_DOLLAR = $$PATH

# Special targets
.PHONY: all clean install
.SUFFIXES: .c .o
.DEFAULT:
.PRECIOUS: %.o
.INTERMEDIATE: %.tmp
.SECONDARY:
.DELETE_ON_ERROR:
.SILENT: install
.EXPORT_ALL_VARIABLES:
.NOTPARALLEL:

# Pattern rules
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Regular targets
all: main
	@echo "Build complete"

main: $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $^

clean:
	rm -f *.o main

install: main
	install -m 755 main $(PREFIX)/bin/

# Double-colon rule
check::
	@echo "Running checks..."

# Conditionals
ifdef DEBUG
CFLAGS += -g -DDEBUG
endif

ifndef VERBOSE
.SILENT:
endif

ifeq ($(CC),gcc)
CFLAGS += -std=gnu11
endif

ifneq ($(OS),Windows_NT)
CFLAGS += -fPIC
endif

# Include
-include deps.mk
include config.mk
sinclude optional.mk

# Override
override CFLAGS += -O2

# Export / unexport
export CC
unexport LDFLAGS

# Private
private LOCAL_VAR = secret

# Undefine
undefine TEMP_VAR

# Vpath
vpath %.c src
vpath %.h include

# Target with semicolon recipe
quick: ; @echo "done"

# Strings in recipes
test:
	echo "double quoted string"
	echo 'single quoted string'

# Autoconf-style @substitution@
config:
	sed 's/@VERSION@/1.0/g' config.in > config.out
