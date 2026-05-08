# bench-linux

## What is it?

This is a bunch of scripts allowing anyone to build its own Alpine Linux distribution oriented on
clean and reproducible micro-benchmarking under Linux host.

Specifically, this is a Dockerfile that builds you a LiveCD Alpine Linux ISO with special
run configuration that isolates CPU 4 (by default, check [./mkimg.benchmark.sh](./mkimg.benchmark.sh))
from the Linux kernel and user-space tasks. Additionally, it stop the usage of "twin" CPUs that
could steal resources between them.

## Why is it needed?

On the real user-oriented Linux hosts, there are many sources of "noise" that may and will corrupt
any benchmarks:

- Background processes
- Hardware interrupts
- SMT ("hyperthreading")
- etc.

## Usage

### Build

You need Docker. Optionally, GNU make for convenience.

Check your systems CPU configurations (for example, using `htop`):

- You need to determine the number of available CPUs
- Also, pick the one CPU you will use for benchmarking
- If you have "performance" and "powersave" CPUs (for example, in a laptop),
    you need to run benchmarks under a "performance" CPU
- Also, your CPUs most likely supports SMT ("hyperthreading"),
  in this case "twins" will not be able to run something and
  commonly numbers of disabled CPUs are odd: for example, on my system 0, 2, 4, 6 are available
  while 1, 3, 5, 7 are twins and therefore disabled

If you have at least 5 CPU cores, the default config in [./mkimg.benchmark.sh](./mkimg.benchmark.sh)
is already good for you since it isolates CPU 4. Otherwise, change the parameters in `kernel_cmdline`.

If you are aggree with the default configuration,
you may check the [RELEASES](./releases) page for a prebuilt ISO.

Finally, type in your terminal being in the root of this repository:

```bash
make
```

If you are have no GNU make on your system, you may use the following:
```bash
docker build -t bench-linux . # add "--progress=plain" to debug
```

And after the image become built, extract the ISO from it:

```bash
mkdir -p output
container=$(docker create bench-linux)
docker cp $container:/iso/. ./output
docker rm $container
```

1. After it, you will get a directory `output` with the ISO inside

### Run

You may check the ISO using any hypervisor like VirtualBox

Once you want to run the system on your host, use `dd` to burn your flash drive or something else:

```bash
sudo dd if=output/alpine-benchmark-3.21-x86_64.iso of=DRIVE bs=4K # replace DRIVE with the path
```

Reboot into the burned drive. It could take about few minutes with hanging screen but after all
you will get the Alpine Linux welcome text

To perform a basic setup, use `setup-alpine`:

```bash
setup-alpine
```

On the question about SSH, type "none". It isn't necessary but you most likely will don't use it.

On the last question, type something like `/tmp/apkcache`. If you leave this question unchanged,
you will not be able to install packages in your LiveCD!

Use `apk` to update the package repository and install new packages. For example:

```bash
apk update
apk add bash git ssh opam # to benchmark OCaml-based application
```

Finally, you need to mount your main drive with the application code that you are going to benchmark.
For example, it could be a `/home` separated partition on your hard drive:

```bash
mkdir /mnt/home
mount /dev/nvme0n1p4 /mnt/home # determine the path to your drive before
cd /mnt/home
ls # check that you have your files
```

Also, it is convenient to use `file` in order to remember which `/dev`-file corresponds to your drive:

```bash
apk add file
ls /dev # /dev/nvme* represent NVMe SSD drives
file -s /dev/nvme0n1p1 # /dev/nvme0n1p1: DOS/MBR boot sector ... FAT (32 bit) ...
file -s /dev/nvme0n1p2 # /dev/nvme0n1p2: Linux swap file ...
file -s /dev/nvme0n1p3 # /dev/nvme0n1p3: Linux rev 1.0 ext4 filesystem data ... volume name "root"
file -s /dev/nvme0n1p4 # /dev/nvme0n1p4: Linux rev 1.0 ext4 filesystem data ... volume name "home"
```

### Benchmarking

After installation and building, you may also stop all unnecessary background tasks.
Determine them using `htop`

By default, `setup-alpine` start some services to allow networking and automatically actualize
the system clock:

```bash
/etc/init.d/syslog stop
/etc/init.d/chronyd stop
/etc/init.d/networking stop
```

The minimal process list in `htop` (in the tree mode, F5) looks like:

```
/sbin/init
|
+- /bin/login -f -- root
|  |
|  +- -sh
|     |
|     +- htop
|
+- /bin/login -f -- root
|  |
|  +- -sh
|
+- /bin/login -f -- root
|  |
|  +- -sh
|
+- /bin/login -f -- root
|  |
|  +- -sh
|
+- /bin/login -f -- root
|  |
|  +- -sh
|
+- /bin/login -f -- root
|  |
|  +- -sh
|
+- /sbin/acpid -f
```

Once you've stopped all unnecessary task, run your benchmarks on the picked CPU (by default, 4).
It could be done using `taskset` or by configuration inside the benchmark itself:

```bash
taskset -c 4 sleep 10 $ run "sleep 10" on the CPU 4
```

Also, ensure the usage of the "performance" power governor for the picked CPU, if applicable:

```bash
cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
# performance
```

Additionally, to be sure, you may set NICE -20 for you benchmark
or run it in REAL-TIME scheduling mode:

```bash
renice -20 -p $$ # set NICE -20 for the current shell

ulimit -r unlimited # ensure the ability to use real-time scheduling

chrt -f 99 sleep 10 # run "sleep 10" with SCHED_FIFO (interruptible) scheduling mode and the greatest priority
```

Good luck and have nice benchmarking experience!

## Contribution

Contributions are always welcome if you have something to improve in this minimal configuration!

While the initial configuration was derived using AI, it was completely rewritten manually and
fully-AI-produced contributions are undesirable to preserve the simplicity and understandability.

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.
