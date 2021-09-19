# -*- coding: utf-8 -*-
"""
Spyderエディタ

これは一時的なスクリプトファイルです
"""

import PIL
import numpy as np
import math
import os
import sys
import tkinter.filedialog
from intelhex import IntelHex
from functools import reduce

FRAMEBUFFERSIZE = (800,480) # HIGHRES 5inch
#FRAMEBUFFERSIZE = (512,272) # LOWRES 4.3inch
FRAMEBUFFERADDR = 0x40000000

# 複数選択可能なダイアログを開く
def ShowFileDialogMulti() :
    ex = tkinter.filedialog.askopenfilename()
    return ex

jpgfilename = ShowFileDialogMulti()

img = PIL.Image.open(jpgfilename)
img = img.resize(FRAMEBUFFERSIZE)

ary = np.array(img)

# Split the three channels
r,g,b = np.split(ary,3,axis=2)
r=r.reshape(-1)
g=g.reshape(-1)
b=b.reshape(-1)

# Standard RGB to grayscale
bitmap = list()
for rd,gd,bd in zip(r,g,b):
    d = ((bd >> 3) << 11) + ((gd >> 2) << 5) + (rd >> 3)
    bitmap.append(d & 0x00FF)
    bitmap.append((d & 0xFF00) >> 8)
#bitmap = list(map(lambda x: (x[0] & 0xE0)+((x[1] >> 3)& 0x18)+((x[2] >> 5)&0x07),zip(r,g,b)))
a=IntelHex()
a.frombytes(bytes(bitmap),offset=FRAMEBUFFERADDR)
HEXFILENAME = os.path.splitext(jpgfilename)[0] + ".hex"
with open(HEXFILENAME,"w") as wf:
    a.write_hex_file(wf)


