#! /usr/bin/env bash

# $ sudo tree -pfi
# [dr-xr-xr-x] .
# [d--x--x--x] ./dir1
# [dr--r--r--] ./dir1/dir1A
# [-rw-rw-rw-] ./dir1/dir1A/file1
# [drwxrwxrwx] ./dir1/dir1B
# [-r--r--r--] ./dir1/dir1B/file2
# [drwxrwxrwx] ./dir2
# [-rw-rw-rw-] ./dir2/file3
# [lrwxrwxrwx] ./dir2/link1 -> ../dir1/dir1B/file2
# [drwxrwxrwx] ./dir3
# [lrwxrwxrwx] ./dir3/link2 -> ../dir1/dir1B/file2

# create this directory structure
mkdir -p dir1/dir1A dir1/dir1B dir2 dir3
touch dir1/dir1A/file1 dir1/dir1B/file2 dir2/file3
# create a symbolic link
ln -s ../dir1/dir1B/file2 dir2/link1
ln -s ../dir1/dir1B/file2 dir3/link2

# change permissions
chmod 666 dir1/dir1A/file1
chmod 444 dir1/dir1A
chmod 444 dir1/dir1B/file2
chmod 777 dir1/dir1B
chmod 111 dir1

chmod 666 dir2/file3
chmod 777 dir2/link1
chmod 777 dir2

chmod 777 dir3/link2
chmod 777 dir3

chmod 555 .
