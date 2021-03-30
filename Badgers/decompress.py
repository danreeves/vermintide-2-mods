import os
import json
import zlib

HEADER = 'bsiz0000'

def decompile(file):
    file_path = os.path.join("/mnt/c/dev/vmb/mods/Badgers/units/Badger/anims/", file)
    try:
        with open(file_path, 'rb') as f:
            data = f.read()
            if data[:4] == 'bsiz':
                data = zlib.decompress(data[8:])

            f = open(file_path + "_decompiled", "a")
            f.write(data)
            f.close()
    except:
        print "Something went wrong"

def recompile(file):
    file_path = os.path.join("/mnt/c/dev/vmb/mods/Badgers/units/Badger/anims/", file)
    try:
        with open(file_path, 'rb') as f:
            data = f.read()
            compressed_data = zlib.compress(data)

            f = open(file_path.replace("_decompiled", ""), "a")
            f.write(compressed_data)
            f.close()
    except:
        print "Something went wrong"

#  decompile("idle.bsi")
recompile("idle.bsi_decompiled")
