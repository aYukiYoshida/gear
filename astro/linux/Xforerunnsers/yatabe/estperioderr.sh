#!/bin/sh

file_name=$1

awk '{printf "%s %s %.4f %.4f\n", $1, $2, $3, ((($3)^(2.0))/(45.0*86400.0))*(0.71/2.0)*((($4/15.0)-1.0)^(-0.63))}' ${file_name} > pulse_peri
od_with_error.dat

