# Briey SoC on Sipeed Tang Primer

## About Briey Soc
+ The [Briey SoC](https://github.com/SpinalHDL/VexRiscv#briey-soc) is a sample SoC included in the [VexRiscv](https://github.com/SpinalHDL/VexRiscv).

## Similar Projects
- [Briey SoC on ICESugar Pro(Lattice ECP5)](https://github.com/jmio/ECP5_Brieysoc)

## Supported HW
+ UART (Briey SoC, 115200bps)
   + Both rxd1 and rxd2 can be used in the same way (Internally OR).
[I have rewritten the firmware of the M5Stack CardKB to support UART](https://github.com/jmio/CardKB_Serial) and connected it to rxd2, so I can use it standalone!
```
set_pin_assignment {rxd1}  { LOCATION = J13; IOSTANDARD = LVCMOS33;  } #
set_pin_assignment {rxd2}  { LOCATION = M12; IOSTANDARD = LVCMOS33;  } #
set_pin_assignment {txd} { LOCATION = H13; IOSTANDARD = LVCMOS33;  } #
```
+ SDRAM (Briey SoC)
+ LCD (SDRAM FrameBuffer:480x800 16bpp for Tang Nano 4.3 inch LCD)
+ Touch Panel Driver for LCD (NS2009 on Tang Primer)
+ TFCARD (Intel Hex Loader Support on Sample FW)
+ JTAG DEBUG (VexRiscv)
```
set_pin_assignment {io_jtag_tdo} { LOCATION = A4; IOSTANDARD = LVCMOS33;  }   ##TDO, B24_N, A4
set_pin_assignment {io_jtag_tck} { LOCATION = C5; IOSTANDARD = LVCMOS33;  }   ##TCK, B21_P, C5
set_pin_assignment {io_jtag_tdi} { LOCATION = B6; IOSTANDARD = LVCMOS33;  }   ##TDI, B21_N, B6
set_pin_assignment {io_jtag_tms} { LOCATION = C9; IOSTANDARD = LVCMOS33;  }   ##TMS, B10_N, C9

```


## HW Build Tool
+ Anlogic TD 5.0.3 (Test on Windows)

## FW Build Tool , JTAG Debug
+ VS Code (IDE : Tested on Windows)

+ GNU MCU Eclipse RISC-V Embedded GCC 8.2.0 (Tested on Windows)

+ make.exe

+ openocd for vexriscv (Windows Binary included)
https://github.com/SpinalHDL/openocd_riscv  

    + libUSB FT2232 Dongle (Need [HBird_Driver.exe](https://bigbits.oss-cn-qingdao.aliyuncs.com/Arduino_for_Licheetang_with_hbird_e203_mini/Driver/HBird_Driver.exe))
    + DAPLink Dongle (You can [made with LPC11U35](https://jmio.github.io/use_11u35_as_daplink.html)) 

+ The folder names are embedded in "tasks.json" and "launch.json", so you need to rewrite them.
Make sure that riscv-none-embed-gcc, make and openocd work properly.

+ [Memory Map File](./SipeedTangBriey_MemoryMap.xlsx)

Example of embedding
```
            "debugServerArgs": "-c \"set VEXRISCV_YAML C:/(PROJECT FOLDER)/testvex/briey/Briey.yaml\" -f ${workspaceFolder}/vexriscv_dual.cfg",

                {"text": "-file-exec-and-symbols C:/(PROJECT FOLDER)/testvex/briey/progmem.elf","description": "set architecture","ignoreFailures": false},
 
```

## Create Custom Briey.v for this project
1. Clone VexRiscv Repo.
```
cd 
git clone https://github.com/SpinalHDL/VexRiscv.git
git checkout 2de35e6116e623e2d5465f753a1c84104fa127cb
(ignore warning)
```
2. Copy Briey.scala included in the project to the demo folder of VexRiscv and reconfigure it with sbt.

```
cp ~/(This Project)/Briey.scala ~/VexRiscv/src/main/scala/vexriscv/demo/
cd ~/VexRiscv/
sbt "runMain vexriscv.demo.BrieyTangPrimer"
```

3. Replace the $readmem section of the generated Briey.v with the following (included in the project as progmemh.v.txt)

```
    initial begin
        $readmemh("briey/progmem0.hex",ram_symbol0);
        $readmemh("briey/progmem1.hex",ram_symbol1);
        $readmemh("briey/progmem2.hex",ram_symbol2);
        $readmemh("briey/progmem3.hex",ram_symbol3);
    end
```

4. Copy the generated cpu0.yaml as Briey.yaml to the "Briey" folder under the project (or as specified in launch.json). 

## Sample FW

+ Monitor Command
```
?:HELP
D:Dump     - D(Begin),(End)
F:Fill     - F(Begin),(End),(Val)
G:Go       - G<STARTENTRY:fromihex>
R:Read Intel Hex
S:Set      - S(Addr)
=:SD DIR   - =
!:SD IHEX  - !(Filename)
T:TP TEST   (Hit Key to End)
```

+ Run MicroPython Port Demo

   + [micropython port for this monitor](https://github.com/jmio/micropython)

```
cd port/rv32
make V=1
```

then v.hex and v.elf created at ports/rv32/build/.

![MicroPythonImage](https://github.com/jmio/testvex/blob/main/mpybin/fbdemo.jpg)

1. Copy "mpybin/v.hex" and "mpybin/boot.py" to TFCARD
2. Type "!V.HEX" on monitor prompt to load HEX into SDRAM
3. Type "G" on monitor prompt to Run MicroPython Binary on SDRAM
4. Run "demo()" on MicroPython Prompt to Run FrameBuffer Demo on "boot.py" 

## Reference
Knowledge of riscv jtag debugging and the "create_mif.rb" script
+ https://tomverbeure.github.io/2021/07/18/VexRiscv-OpenOCD-and-Traps.html
 
 