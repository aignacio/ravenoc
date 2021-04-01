# RaveNoC Testbench

* [RaveNoC wrapper](#rwrapper)
* [Test list](#tlist)
* [Base classes](#bclasses)
* [Create your own test](#addtest)
* [Modules & Versions](#version)

On this folder we have all the tests that were developed for the RaveNoC, so far at this moment we have 8 tests which cover different aspects of the NoC behavior. Inside the folder **common_noc** we have 2 base classes that are used along all the tests to create packets and the testbench itself.

```bash
├── common_noc
│   ├── __init__.py
│   ├── constants.py
│   ├── ravenoc_pkt.py
│   └── testbench.py
├── test_all_buffers.py
├── test_irqs.py
├── test_max_data.py
├── test_noc_csr.py
├── test_ravenoc_basic.py
├── test_throughput.py
├── test_virt_chn_qos.py
└── test_wrong_ops.py
```

## <a name="tlist"></a> Test list


| Test ID |      Test name     |                                       Short description                                       |
|:-------:|:------------------:|:---------------------------------------------------------------------------------------------:|
|    1    | test_ravenoc_basic | Basic test that sends a packet over the NoC and checks it                                     |
|    2    |   test_wrong_ops   | Checks if the AXI-S/NoC is capable of throwing an errors when illegal operations are executed |
|    3    |    test_max_data   | Test if the NoC is capable to transfer a pkt with the max. size                               |
|    4    |   test_throughput  | Test to compute the max throughput of the NoC                                                 |
|    5    |  test_all_buffers  | Test if all buffers of all routers are able to transfer flits                                 |
|    6    |  test_virt_chn_qos | Test the QoS of VCs in the NoC                                                                |
|    7    |    test_noc_csr    | Check all WR/RD CSRs inside the NoC                                                           |
|    8    |      test_irqs     | Test that checks the IRQs modes inside the NoC                                                |

Test corners:

| Test ID |      Test name     | AXI sl. NoC | NoC sl. AXI | NoC equal AXI | No idle cycles | W/ idle cycles | No backpressure | W/ backpressure |
|:-------:|:------------------:|:-----------:|:-----------:|:-------------:|:--------------:|:--------------:|:---------------:|:---------------:|
|    1    | test_ravenoc_basic |      X      |      X      |       X       |        X       |        X       |        X        |        X        |
|    2    |   test_wrong_ops   |      X      |      X      |       X       |        X       |        X       |        X        |        X        |
|    3    |    test_max_data   |      X      |      X      |       X       |        X       |        X       |        X        |        X        |
|    4    |   test_throughput  |      X      |      X      |       X       |        -       |        -       |        -        |        -        |
|    5    |  test_all_buffers  |      X      |      X      |       X       |        -       |        -       |        -        |        -        |
|    6    |  test_virt_chn_qos |      X      |      X      |       X       |        -       |        -       |        -        |        -        |
|    7    |    test_noc_csr    |      X      |      X      |       X       |        X       |        X       |        X        |        X        |
|    8    |      test_irqs     |      X      |      X      |       X       |        X       |        X       |        X        |        X        |

## <a name="version"></a> Modules & Versions

All the tests were written using the following versions of the dependencies (python modules). It might work or not with newer versions but in the worst case, try with the ones below used during the development.

|  Dependencies | Version |
|:-------------:|:-------:|
| cocotb-bus    |  0.1.1  |
| cocotbext-axi |  0.1.10 |
| cocotb-test   |  0.2.0  |
| cocotb        |  1.5.1  |
