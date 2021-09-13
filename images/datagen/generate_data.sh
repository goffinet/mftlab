#!/bin/bash

origin="$1"
destination="$2"
transfer_name="$3"
base_path=/data/${origin}/${destination}/${transfer_name}

install_fakedata() {
if [[ ! $(which fakedata) ]] ; then
dnf -y install wget
mkdir /usr/local/bin/fakedata
wget https://github.com/lucapette/fakedata/releases/download/v1.1.2/fakedata_1.1.2_linux_amd64.tar.gz -O /usr/local/bin/fakedata/fakedata.tar.gz
cd /usr/local/bin/fakedata/
tar xvfz fakedata.tar.gz
ln -s /usr/local/bin/fakedata/fakedata /usr/bin/fakedata
rm -rf /usr/local/bin/fakedata/fakedata.tar.gz ; cd
fi
}

set_path(){
origin_path=${base_path}/input/new
if [[ ! -f "${base_path}" ]] ; then
mkdir -p ${base_path}
fi
for direction in input output ; do
if [[ ! -f "${base_path}/${direction}" ]] ; then
mkdir -p ${base_path}/${direction}
for state in new old tmp ; do
if [[ ! -f "${base_path}/${direction}/${state}" ]] ; then
mkdir -p ${base_path}/${direction}/${state}
fi
done
fi
done
}

install_fakedata
set_path

while true ; do
fakedata -l$(shuf -i 1-1000 -n 1) --format=csv email country name.last name.first username email int int int industry animal.cat animal country > ${origin_path}/data.$((`date '+%s%N'`/1000)).csv
chmod 777 ${origin_path}/*
sleep $(shuf -i 60-300 -n 1)
fakedata -l$(shuf -i 1000-10000 -n 1) --format=csv email country name.last name.first username email int int int industry animal.cat animal country > ${origin_path}/data.$((`date '+%s%N'`/1000)).csv
chmod 777 ${origin_path}/*
sleep $(shuf -i 60-300 -n 1)
dd if=/dev/urandom bs=1024 count=$(shuf -i 1-1000 -n 1) of=${origin_path}/data.$((`date '+%s%N'`/1000)).bin
chmod 777 ${origin_path}/*
sleep $(shuf -i 60-300 -n 1)
done
