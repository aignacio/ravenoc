[![Regression Tests](https://github.com/aignacio/ravenoc/actions/workflows/regression.yaml/badge.svg)](https://github.com/aignacio/ravenoc/actions/workflows/regression.yaml) [![LibreCores](https://www.librecores.org/aignacio/ravenoc/badge.svg?style=flat)](https://www.librecores.org/aignacio/ravenoc)
<img align="right" alt="ravenoc_logo" src="docs/img/ravenoc_readme.svg"/>

# RaveNoC - configurable Network-on-Chip
## Table of Contents
* [Introduction](#intro)
* [Integration](#usg)
* [uArch description](#uarch)
* [FAQ](#faq)
* [License](#lic)

## <a name="intro"></a> Introduction
RaveNoC is a configurable HDL for mesh NoCs topology that allows the user to change parameters and setup new configurations. In summary, the features of the RaveNoC are:
1. Mesh topology (2D-XY)
2. Valid/ready flow control
3. Switching: Pipelined wormhole
4. Virtual channel flow control
5. Slave I/F AMBA AXI4
6. Different IRQs that can be muxed/masked individually
7. Configurable parameters:
    - Flit/AXI data width
    - Number of buffers in the input module
    - Number of virtual channels
    - Order of priority in the VCs
    - Dimensions of the NoC (Rows_X_Cols)
    - Routing algorithm
    - Maximum size of packets

## <a name="usg"></a> Integration
The RTL top [file](src/ravenoc.sv) exports arrays of inputs/outputs of an AXI4 slave interface that matches the number of routers in the NoC i.e Rows X Cols. Also as an input parameter of **ravenoc** module, there is `AXI_CDC_REQ` array which is used to specify if each router need or not the CDC [async gp fifo](https://zipcpu.com/blog/2018/07/06/afifo.html) due to cross clock domain aspect. 

There is a single clock/async. reset for the NoC and an array of clocks/async. resets for the AXIs due to the fact that every router can have a different clock domain. An additional input called `bypass_cdc` is used in the [testbench](tb/README.md) but it is not recommended to be used during integration once if CDC is not required, the user should change the `AXI_CDC_REQ` parameter as mentioned in the specific array index.

For every router a set of CSRs (Control and Status registers) are available which can be individually programmable per unit. The list of CSRs available are:
|       CSR       |                           Address                          |             Description             | Default | Permissions |
|:---------------:|:----------------------------------------------------------:|:-----------------------------------:|:-------:|:-----------:|
| RAVENOC_VERSION |  [`AXI_CSR_BASE_ADDR](src/include/ravenoc_defines.svh)+'h0 | RaveNoC HW version                  |   1.0   |  Read-Only  |
| ROUTER_ROW_X_ID |  [`AXI_CSR_BASE_ADDR](src/include/ravenoc_defines.svh)+'h4 | Row / X - ID of the Router          |    0    |  Read-Only  |
| ROUTER_COL_Y_ID |  [`AXI_CSR_BASE_ADDR](src/include/ravenoc_defines.svh)+'h8 | Column / Y - ID of the Router       |    0    |  Read-Only  |
|  IRQ_RD_STATUS  |  [`AXI_CSR_BASE_ADDR](src/include/ravenoc_defines.svh)+'hC | Returns the IRQ value per VC        |    --   |  Read-Only  |
|    IRQ_RD_MUX   | [`AXI_CSR_BASE_ADDR](src/include/ravenoc_defines.svh)+'h10 | Controls the input mix of IRQs      | DEFAULT |     R/W     |
|   IRQ_RD_MASK   | [`AXI_CSR_BASE_ADDR](src/include/ravenoc_defines.svh)+'h14 | Controls the input mask of the IRQs |  'hFFFF |     R/W     |

See the SV structs to understand the possible values for the [**IRQ_RD_MUX**](src/include/ravenoc_structs.svh).

In the top level there is also available an array of IRQs (Interrupt Request Signals) that is a struct which is connected to every router / AXIs of the NoC. All the IRQs are related to the AXI read VC buffers of the router. Two CSRs mentioned previously are important to configure the IRQ behavior in each router. The **IRQ_RD_MUX** selects which is the input source for the IRQs, that can be the `empty`,`full` flags of the read axi buffers or a comparison with the number of flits available to be read at the read buffer. And the **IRQ_RD_MASK** is an input mask that does the AND logical operation with every bit of the output of IRQ_RD_MUX and in case this one is set to comparison, the mask will represent the reference value. The image below tries to explain the text:
![IRQs RaveNoC](docs/img/irqs_ravenoc.svg)

### Configurable parameters 
The following parameters are configurable and can be passed by compilation time as system verilog macros. Please check that not all parameters are indicated to change unless to look inside the code to understand how it is used or wants to build something custom for one specific application. To check which are the default values for all the parameters, see the main [defines file](src/include/ravenoc_defines.svh).
|     SV Macro    |                             Description                            |  Default Value  |                    Range                   |
|:---------------:|:------------------------------------------------------------------:|:---------------:|:------------------------------------------:|
| FLIT_DATA_WIDTH | Flit data width in bits, AXI data width will must match            |        32       |          (32,64) - 128 not tested          |
|    FLIT_BUFF    | Number of flits buffered in each virtual channel input fifo        |        2        |     (1,2,4,8...) - Must be a power of 2    |
|    N_VIRT_CHN   | Number of virtual channels                                         |        3        |           (1,2,3,4...) - Up to 32          |
|    H_PRIORITY   | Priority order on the virtual channels                             | ZERO_HIGH_PRIOR |      ZERO_HIGH_PRIOR or ZERO_LOW_PRIOR     |
| NOC_CFG_SZ_ROWS | Number of rows in the NoC - X                                      |        2        | 1 (if cols > 1),2,3,4... - Any int. value  |
| NOC_CFG_SZ_COLS | Number of cols in the NoC - Y                                      |        2        |  1 (if rows > 1),2,3,4... - Any int. value |
|   ROUTING_ALG   | Routing algorithm of the input module                              |    "X_Y_ALG"    |           "X_Y_ALG" or "Y_X_ALG"           |
|    MAX_SZ_PKT   | Max number of flits per packet                                     |       256       |                Min. val == 1               |
| AUTO_ADD_PKT_SZ | If set, NoC will auto append pkt size on the header flit           |        0        |       0 - user sets the pot size or 1      |
|  RD_AXI_BFF(x)  | Math macro to gen the the num. of buffers per RD VCs on AXI4 slave |  x<=2?(1<<x):4  |                     --                     |
|     CDC_TAPS    | Number of FIFO slots in the async gp fifo used for CDC             |        2        |         >=2 - Must be a power of 2         |

## <a name="uarch"></a> RTL micro architecture
The NoC has been constructed in a way that most part of the modules are replicated through generate SV constructions, thus the behavior is generic and it was designed in a way that the user could reuse as much as possible in different hierarchies. Each router is composed by input modules, output modules, one CSR (control and status register), a NI (network interface) and an AXI interface. The diagrams below exemplifies the modules mentioned and how the connections are done at router level.
![Mesh Example](docs/img/router_diag.svg)
Through each router, we have 5x output modules and 5x input modules, each one connected to other that are not from the same direction (i.e other 4x ports). One router is capable of routing a packet composed by one (single head flit) or more flits through his ports (west, east, north, south or local). Each port will always select a router for the current flit in the correspondent virtual channel to route but never in the same direction i.e it'll never return from where it came from. This also applies to the local port (the one in diagonal in the previous diagram). So if a flit is pushed through the router it's because it has a destination valid and the flit should move in between the input modules internal FIFOs. Router connections internally are showed below:
![Mesh Example](docs/img/router_int_con.svg)
### <a name="inmod"></a> Input module
One router has exactly 5x input modules, each input module can have one or more virtual channels, each virtual channel has a FIFO inside that's also configurable and it's responsible to store the flits that comes from his input interface. In the case of the router connections of west, east, north, south it's input interface comes from another router, in the local port it'll be from the network interface that's generating the flits. Every time a **head** flit arrives in the input module, the input router inside this module will decode its destination by looking to the current node address of the router and the target one in the header. Depending upon the selected algorithm for the routing, it'll select one of 4x possible output modules. There's no sequential logic latency in the data path from the input to the FIFOs, meaning that once the flit is in the input, in the next clock cycle it'll be stored in the correct FIFO. Also it's important to highlight that each virtual channel has it's own independent FIFO and when a higher priority virtual channel message comes, the lower priority flits are preempted inside their FIFOs, allowing only the highest priority flit pass through. If the FIFOs are full, each independent one will set zero the correspondent *ready* interface signal to generate back pressure on the connections in. If there's space available and the interface has valid signals, then a flit will come through the input module and this module will (in the next clock cycle) for it's route to the output.
![Mesh Example](docs/img/in_mod.svg)
### <a name="outmod"></a> Output module
The output module has no sequential elements like FFs to store the flits, so it means by that every time a route has been established, it'll connect the correspondent FIFO input module to the next router in the NoC. Each output module has a round-robin arbiter per virtual channel, so in a long time, it'll keep fairness between the different input modules of the same virtual channel. The same concept applied in the input module of preemptive virtual channels is used in the output module, where a flit coming from a higher priority virtual channel will have precedence over the lower ones. Thus the input module routing is responsible for locking the current route by it's own, on each independent virtual channel, once it should be restored after the higher flit has been transferred. 
![Mesh Example](docs/img/out_mod.svg)

## <a name="lic"></a> License
RaveNoC is licensed under the permissive MIT license.Please refer to the [LICENSE](LICENSE) file for details.
