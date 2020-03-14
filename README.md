# RaveNoC

### How to build System C library?

SystemC library enforces users to use a specific version of C++, so this project uses c++14, thus you should build System C through the same version with the following commands:

```bash
cmake -DCMAKE_CXX_STANDARD=14 -DCMAKE_BUILD_TYPE=Debug -DENABLE_PTHREADS=1 ..
cmake --build .
```
