MHT GateWay is a router/gateway software primarily that is used for home/office purposes with a simple desktop for accesing the internet and the system's console.

The key differentiator between other router/gateway software in the market and MHT Gateway is that it is both a router/gateway and also a desktop that uses a kernel specific approach where there will not be too many moving software components.
MHT GateWay will have 3 layers to the minimum.
  - Kernel layer
  - System Application Layer
    - there will also be other system applications that are custom built that are tied together as a single package and are not provided as separate software.
    - Toolchain is provided to expand the functionality.
  - Desktop GUI (based on XFCE)

if any further additional programs are needed then the user has the flexibility to compile and install the additional software.

This is something like you are purchasing something (i.e., a home or a dog) to keep it simple.

The current router/gateway software in the market get different software from different sources and package them and provide it to the end user. This is more robust and more advanced where individual companies/developers create their own framework and provide each software that is compiled/packaged and provided to the consumer. This has long-term implications. The idea is converge these applications into a single framwork as much as possible.

The idea of this approach is that only one specific framework is used for all software that is used in the router/gateway with a desktop. though they do not provide the complete feature set at the initiation. they are:
  - less maintainence
  - less bugs
  - no complexity involved

Kernel 3.16.85 is used as the main build system kernel.

The inspiration came from Andrew S Tanenbaum's speech of code complexity:
https://www.youtube.com/watch?v=jMkR9VF2GNY (EuroBSDcon - A reimplementation of NetBSD based on a microkernel - Andy Tanenbaum)

**FAQ:**
Why only one linux kernel version?
The idea is to learn linux and enhance the kernel to different platforms as if it was a purchased kernel. we believe in one kernel from Linus Torvalds and the Linux Foundation.

**DHCP/DNS Functionality**
There will be 4 types of profiles of user's devices.
- with full internet access.
- without ads.
- with restricted sites access.
- without internet at all.

**Looking for C/Core Java Developers who can be part of the project. Please feel free to email at ramesh at gk at hotmail dot com.**
