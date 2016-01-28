# $Id: Makefile,v 2.2 2006/05/15 17:12:11 rbb Exp $
#
# Copyright 2003 SRC Computers, Inc.  All Rights Reserved.
#
#       Manufactured in the United States of America.
#
# SRC Computers, Inc.
# 4240 N Nevada Avenue
# Colorado Springs, CO 80907
# (v) (719) 262-0213
# (f) (719) 262-0223
#
# No permission has been granted to distribute this software
# without the express permission of SRC Computers, Inc.
#
# This program is distributed WITHOUT ANY WARRANTY OF ANY KIND.
#
# -----------------------------------

# ----------------------------------
# User defines FILES, MAPFILES, and BIN here
# ----------------------------------
FILES       = main.c

MAPFILES    = ex_vec_streams.mc

BIN         = ex_vec_streams

MAPTARGET = map_m


#-----------------------------------
# User defined directory of code routines
# that are to be inlined
#------------------------------------

#INLINEDIR	=

# -----------------------------------
# User supplied MCC and MFTN flags
# -----------------------------------

MCCFLAGS 	= -log 
MFTNFLAGS	= -log

# -----------------------------------
# User supplied flags for C & Fortran compilers
# -----------------------------------

CC		= gcc 	# icc   for Intel cc for Gnu
LD		= gcc	# for C codes

LDFLAGS		=	# Flags to include libs if needed
# -----------------------------------
# VCS simulation settings
# (Set as needed, otherwise just leave commented out)
# -----------------------------------

#USEVCS		= yes	# YES or yes to use vcs instead of vcsi
#VCSDUMP	= yes	# YES or yes to generate vcd+ trace dump
# -----------------------------------
# MODELSIM simulation settings
# (Set as needed, otherwise just leave commented out)
# -----------------------------------

#USEMDL		= yes	# YES or yes to use modelsim instead of vcs/vcsi
#USEMDLGUI	= yes	# YES or yes to use modelsim GUI interface
#MDLDUMP	= yes	# YES or yes to generate vcd trace dump
# -----------------------------------
# No modifications are required below
# -----------------------------------
MAKIN   ?= $(MC_ROOT)/opt/srcci/comp/lib/AppRules.make
include $(MAKIN)
