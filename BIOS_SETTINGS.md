# BIOS Settings for RT Kernel

The BIOS settings depend on the hardware vendor.  Hardware vendors usually publish a document for RT BIOS settings, or at least a `low latency` guide.  Most of the tunings boil down to not slowing the CPU and not allowing SMIs (service management interrupts: stealing the CPU to do BIOS work):

1) No “scrubbing” of memory (aka actively scanning memory for errors)
2) No power savings policies (aka don’t let the BIOS control the CPU frequency)
3) No emulated devices using the CPU
4) Turn off hyperthreading

NOTE: If the performance is not as expected, validate SMIs are disable. The best way to validate that is to run `hwlatdetect` before proceeding to `cyclitest` (e.g. booting with RHEL8 to run `hwlatdetect`). The output of `hwlatdetect` should provide information regrding if the BIOS config has or has not eliminated SMIs (service management interrupts).

