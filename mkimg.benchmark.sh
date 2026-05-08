export PROFILENAME=benchmark

profile_benchmark() {
    profile_standard
    profile_abbrev=bench

    # Kernel command line for maximum benchmarking stability.
    # - nosmt: disable Hyper-Threading (only physical cores remain)
    # - isolcpus, irqaffinity, nohz_full, rcu_nocbs: isolate CPU 4
    # - nosoftlockup, nmi_watchdog=0: disable kernel detectors
    # - clocksource=tsc tsc=reliable: high-precision clock source
    kernel_cmdline="$kernel_cmdline \
        console=tty0 console=ttyS0,115200 \
        nosmt \
        isolcpus=nohz,domain,managed_irq,4 \
        irqaffinity=0-3 \
        nohz_full=4 \
        rcu_nocbs=4 \
        nosoftlockup \
        nmi_watchdog=0 \
        clocksource=tsc \
        tsc=reliable"

    syslinux_prompt=0
    syslinux_timeout=0

    modloop_addons="$modloop_addons linux-firmware util-linux agetty htop"
    apks="$apks linux-firmware util-linux agetty htop"
    apkovl=genapkowl-benchmark.sh

    local _k _a
    for _k in $kernel_flavors; do
        apks="$apks linux-$_k"

        for _a in $kernel_addons; do
            apks="$apks $_a-$_k"
        done
    done
}
