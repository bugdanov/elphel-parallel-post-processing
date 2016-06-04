#!/bin/bash
#
# elphel-parallel-processing - Elphel camera array images post processing using GNU parallel
#
# Copyright (c) 2014 FOXEL SA - http://foxel.ch
# Please read <http://foxel.ch/license> for more information.
#
#
# Author(s):
#
#      Luc Deschenaux <l.deschenaux@foxel.ch>
#      Kevin Velickovic <k.velickovic@foxel.ch>
#
#
# This file is part of the FOXEL project <http://foxel.ch>.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# Additional Terms:
#
#      You are required to preserve legal notices and author attributions in
#      that material or in the Appropriate Legal Notices displayed by works
#      containing it.
#
#      You are required to attribute the work as explained in the "Usage and
#      Attribution" section of <http://foxel.ch/license>.

[ -n "$DEBUG" ] && set -x

usage() {
  if [ "$1" == "-h" ] ; then
    echo "$(basename $0) [OPTIONS...] <src_dir> <dest_dir> <timestamp>" >&2
    exit 1
  fi

  cat >&2 << EOF
SYNOPSIS:
    $(basename $0) [OPTIONS...] <src_dir> <dest_dir> <timestamp>

DESCRIPTION:
      Stitch EQR tiles matching <timestamp> from <src_dir> and save
      the resulting tiff panorama in <dest_dir>, along with a jpeg
      version. Method "multiblend" is very fast, but may yield less
      good results.

OPTIONS SUMMARY:
    -h,--help                       display this
    -b,--black <black point>        set black point
    -w,--white <white point>        set white point
    -g,--gamma <gamma>              set gamma
    -q,--quality <quality>          set jpeg quality
    -m,--method enblend|multiblend  set blending method
    -j,--nojpeg                     disable jpeg conversion
    -e,--eqrformat                  EQR format (RGB24 INT16 INT32 FLOAT32)
EOF
  exit 1
}

# parse command line options
if ! options=$(getopt -o hb:w:g:q:m:je: -l help,black:,white:,gamma:,quality:,method:,nojpeg,eqrformat: -- "$@")
then
    # something went wrong, getopt will put out an error message for us
    exit 1
fi
 
eval set -- "$options"
 
while [ $# -gt 0 ] ; do
    case $1 in
    -h|--help) usage $1 ;;
    -b|--black) BLACKPOINT=$2 ; shift ;;
    -w|--white) WHITEPOINT=$2 ; shift ;;
    -g|--gamma) GAMMA=$2 ; shift ;;
    -q|--quality) QUALITY=$2 ; shift ;;
    -m|--method) METHOD=$2 ; shift ;;
    -j|--nojpeg) NOJPEG=1; shift ;;
    -e|--eqrformat) EQRFORMAT=$2; shift ;;
    (--) shift; break ;;
    (-*) echo "$(basename $0): error - unrecognized option $1" 1>&2; exit 1 ;;
    (*) break ;;
    esac
    shift
done

[ $# -ne 3 ] && usage -h

# positional parameters
SRCDIR=$1
DSTDIR=$2
TIMESTAMP=$3

# check whether timestamp is already processed
[ -f $DSTDIR/result_${TIMESTAMP}.tif ] && exit 0

# default values
[ -z "$QUALITY" ] && QUALITY=98
[ -z "$GAMMA" ] && GAMMA=1
[ -z "$EQRFORMAT" ] && EQRFORMAT=INT16
[ -z "$BLACKPOINT" ] && BLACKPOINT=0
if [ -z "$WHITEPOINT" ] ; then
  echo "$(basename $0): warning - you should set --white point manually" ;
  case $EQRFORMAT in
    RBG24) WHITEPOINT=100 ;;                                                                                         
    INT16) WHITEPOINT=25 ;;                                                                                         
    *) WHITEPOINT=100 ;;
  esac
fi
[ -z "$METHOD" ] && METHOD=enblend

# initialisation

LEVELS="${BLACKPOINT}%,${WHITEPOINT}%,$GAMMA"
t=$TIMESTAMP

TMP=$(mktemp -u --tmpdir=/dev/shm).stitch
mkdir -p $TMP || exit

trap "rm -r $TMP 2>/dev/null" EXIT SIGINT SIGTERM

# stitch and convert

case $METHOD in
multiblend)
{
     set -e
     multiblend --wideblend --nocrop -o $TMP/result_${t}.tif \
        $SRCDIR/${t}-04-DECONV-${EQRFORMAT}_EQR-RIGHT.tiff \
        $SRCDIR/${t}-05-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-06-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-07-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-00-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-01-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-02-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-03-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-04-DECONV-${EQRFORMAT}_EQR-LEFT.tiff \
        $SRCDIR/${t}-12-DECONV-${EQRFORMAT}_EQR-RIGHT.tiff \
        $SRCDIR/${t}-13-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-14-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-15-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-08-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-09-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-10-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-11-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-12-DECONV-${EQRFORMAT}_EQR-LEFT.tiff \
        $SRCDIR/${t}-20-DECONV-${EQRFORMAT}_EQR-RIGHT.tiff \
        $SRCDIR/${t}-21-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-22-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-23-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-16-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-17-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-18-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-19-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-20-DECONV-${EQRFORMAT}_EQR-LEFT.tiff

     if [ -z "$NOJPEG" ] ; then
       OUTFILE=result_${t}-$BLACKPOINT-$WHITEPOINT-$GAMMA.jpeg
       convert $TMP/result_${t}.tif -level $LEVELS -quality $QUALITY $TMP/$OUTFILE
       mv $TMP/$OUTFILE $DSTDIR/$OUTFILE
     fi

     mv $TMP/result_${t}.tif $DSTDIR/result_${t}.tif

     echo $t >> $DSTDIR/stitched.txt

} 2>&1
;;

enblend)
{
     set -e
     enblend-mp -w -o $TMP/result_${t}_top.tif \
        $SRCDIR/${t}-04-DECONV-${EQRFORMAT}_EQR-RIGHT.tiff \
        $SRCDIR/${t}-05-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-06-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-07-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-00-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-01-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-02-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-03-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-04-DECONV-${EQRFORMAT}_EQR-LEFT.tiff
     
     enblend-mp -w -o $TMP/result_${t}_mid.tif \
        $SRCDIR/${t}-12-DECONV-${EQRFORMAT}_EQR-RIGHT.tiff \
        $SRCDIR/${t}-13-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-14-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-15-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-08-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-09-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-10-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-11-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-12-DECONV-${EQRFORMAT}_EQR-LEFT.tiff

     enblend-mp -w -o $TMP/result_${t}_bot.tif \
        $SRCDIR/${t}-20-DECONV-${EQRFORMAT}_EQR-RIGHT.tiff \
        $SRCDIR/${t}-21-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-22-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-23-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-16-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-17-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-18-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-19-DECONV-${EQRFORMAT}_EQR.tiff \
        $SRCDIR/${t}-20-DECONV-${EQRFORMAT}_EQR-LEFT.tiff

     enblend-mp --wrap='vertical' -o $TMP/result_${t}.tif \
        $TMP/result_${t}_top.tif \
        $TMP/result_${t}_mid.tif \
        $TMP/result_${t}_bot.tif

     rm $TMP/result_${t}_{top,mid,bot}.tif

     if [ -z "$NOJPEG" ] ; then
       OUTFILE=result_${t}-$BLACKPOINT-$WHITEPOINT-$GAMMA.jpeg
       convert $TMP/result_${t}.tif -level $LEVELS -quality $QUALITY $TMP/$OUTFILE
       mv $TMP/$OUTFILE $DSTDIR/
     fi

     mv $TMP/result_${t}.tif $DSTDIR/     

     echo $t >> $DSTDIR/stitched.txt

} 2>&1
;;

esac

rm -r $TMP 2>/dev/null
