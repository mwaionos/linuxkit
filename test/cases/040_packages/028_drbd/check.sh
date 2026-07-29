#!/bin/sh

failed() {
	printf "drbd test suite FAILED\n"
	exit 1
}

modprobe drbd || failed
[ -e /proc/drbd ] || failed

IMG=/tmp/drbd-test.img
dd if=/dev/zero of="$IMG" bs=1M count=64 >/dev/null 2>&1 || failed
losetup /dev/loop0 "$IMG" || failed

HOST="$(uname -n)"
mkdir -p /etc/drbd.d
cat > /etc/drbd.d/test0.res <<EOF
resource test0 {
    on ${HOST} {
        node-id   0;
        device    /dev/drbd0;
        disk      /dev/loop0;
        address   127.0.0.1:7900;
        meta-disk internal;
    }
}
EOF

drbdadm create-md test0 --force || failed
drbdadm up test0 || failed
drbdadm status test0 | grep -q "test0" || failed
drbdadm down test0 || failed

losetup -d /dev/loop0 || failed
rm -f "$IMG"

printf "drbd test suite PASSED\n"
