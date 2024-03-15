##### Search for file with certain date range

* `find -newermt "28 MAay 2012" -not -newermt "20 May 2012" -exec grep something -l`

#### Unzip GZ files

* `gunzip -k file.gz`
    * -k keeps the original .gz file

#### Copy Files Between Machines

* `scp username@machine:/path/to/file(s) /path/to/local/folder`


#### Search File

##### Insert text before or after a specific text pattern
* `sed '/cdef/r add.txt' input.txt`
  * Where `add.txt` contains text you want to insert.
  * And `input.txt` is the file to which you want to insert.
  * And `cdef` is what we are trying to search.
* `sed "/cdef/aline1\nline2" input.txt` if you don't have a lot to insert
