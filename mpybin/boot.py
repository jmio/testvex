import fb
import framebuf
import machine
# VexRiscv Framebuffer
FB = framebuf.FrameBuffer(fb.fb_data(),800,480,framebuf.RGB565)
FB.fill(0x00)
print("import os,fb,framebuf, FB is framebuffer instance.")
print("Clear framebuffer and framebuffer DMA Enabled.")

def demo():
	for i in range(0,480,10):
		FB.line(0,i,i*2,480,i*95)
