AXI4-Lite Slave Interface: RTL Design & UVM Verification

A fully synthesizeable SystemVerilog AMBA AXI4-Lite slave interface, exhaustively verified using a class-based UVM testbench and accelerated for open-source simulation via Verilator.

Architecture & Protocol Features

RTL State Machine: Zero-wait state, 256-depth (8-bit address, 32-bit data) memory-mapped slave logic.

Handshake Synchronization: Strict AMBA 4 protocol adherence with fully independent VALID/READY signal generation across all five channels.

Channel Inversions: Seamless logic recovery and rapid bus turnaround during concurrent Read-After-Write (RAW) and Write-After-Read (WAR) transitions.

UVM Verification Strategy

Constrained-Random Stimulus: Dynamic sequence libraries injecting isolated transfers, sustained pipeline bursts, and highly randomized 32-bit data payloads.

Automated Scoreboarding: Passive monitors continuously reconstruct transaction packets and route them to a central scoreboard for cycle-accurate data integrity validation.

Functional Coverage Model (cg_axi_lite): Real-time, multi-dimensional tracking of address space saturation, transition states, and protocol boundary limits.
