#!/bin/sh

name=$1
password=$2

smbpasswd -a $name<<EOF
$password
$password
EOF
