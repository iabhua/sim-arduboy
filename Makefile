
	# Copyright 2017 Delio Brignoli <brignoli.delio@gmail.com>

	# Arduboy board implementation using simavr.

	# This program is free software: you can redistribute it and/or modify
	# it under the terms of the GNU General Public License as published by
	# the Free Software Foundation, either version 3 of the License, or
	# (at your option) any later version.

	# This program is distributed in the hope that it will be useful,
	# but WITHOUT ANY WARRANTY; without even the implied warranty of
	# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	# GNU General Public License for more details.

	# You should have received a copy of the GNU General Public License
	# along with this program.  If not, see <http://www.gnu.org/licenses/>.

target = sim_arduboy
simavr-repo = ./simavr
simavr = ${simavr-repo}/simavr
simavr-parts = ${simavr-repo}/examples/parts

IPATH += ${simavr-parts}
IPATH += ${simavr}/sim

VPATH = ./src
VPATH += ${simavr-repo}/examples/parts

SIMAVR-OBJ := obj-${shell $(CC) -dumpmachine}
OBJ-PREFIX := obj
OBJ := ${OBJ-PREFIX}/${SIMAVR-OBJ}

LDFLAGS += -lSDL2 -lelf
ifeq (${shell uname}, Darwin)
LDFLAGS += -L${simavr}/${SIMAVR-OBJ} -lsimavr
else
LDFLAGS += -L${simavr}/${SIMAVR-OBJ} -l:libsimavr.a
endif

CFLAGS  += -O2 -Wall -Wextra -Wno-unused-parameter
CFLAGS  += -Wno-unused-result -Wno-missing-field-initializers
CFLAGS  += -Wno-sign-compare
CFLAGS  += -g

CPPFLAGS += --std=gnu99 -Wall
CPPFLAGS += ${patsubst %,-I%,${subst :, ,${IPATH}}}

# Be verbose when V=1
ifeq (${V}, 1)
E =
else
E = @
endif

include ${simavr-repo}/examples/Makefile.opengl

all: ${OBJ} libsimavr ${target}

libsimavr:
	${E}echo BUILD $@; make -C ${simavr} libsimavr
	@echo $@ done

${OBJ}:
	${E}echo MKDIR $@; mkdir -p ${OBJ}

board = ${OBJ}/${target}.elf

${board} : ${OBJ}/ssd1306_virt.o
${board} : ${OBJ}/ssd1306_gl.o
${board} : ${OBJ}/arduboy_sdl.o
${board} : ${OBJ}/arduboy_avr.o
${board} : ${OBJ}/cli.o

${target}: ${board}
	${E}echo COPY $< to $@; cp ${board} $@
	@echo $@ done

${OBJ}/%.o: %.c
	${E}echo CC $<; $(CC) $(CPPFLAGS) $(CFLAGS) -MMD $<  -c -o $@

${OBJ}/%.elf:
	${E}echo LD $<; $(CC) -MMD ${CFLAGS} -o $@ ${filter %.o,$^} $(LDFLAGS)

clean:
	${E}echo CLEAN simavr; make -C ${simavr-repo} clean
	${E}echo RMDIR ${OBJ-PREFIX}; rm -r ${OBJ-PREFIX}
	@echo $@ done

.PHONY: all libsimavr clean

# include the dependency files generated by gcc, if any
-include ${wildcard ${OBJ}/*.d}
