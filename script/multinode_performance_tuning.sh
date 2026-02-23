#!/bin/bash
set -euo pipefail

echo "[*] Applying multi-node GPU performance optimizations..."

###############################################
# 1. Install UCX + RDMA + NCCL plugins
###############################################

sudo apt-get update -y
sudo apt-get install -y \
    rdma-core \
    infiniband-diags \
    ibverbs-providers \
    libibverbs1 \
    libibverbs-dev \
    libmlx5-1 \
    ucx \
    ucx-tools \
    libnccl2 \
    libnccl-dev \
    nccl-rdma-sharp-plugins || true

###############################################
# 2. Enable RDMA and Mellanox drivers
###############################################

if systemctl list-unit-files | grep -q rdma; then
    sudo systemctl enable rdma || true
    sudo systemctl start rdma || true
fi

if lsmod | grep -q mlx5_core; then
    echo "[*] Mellanox mlx5 driver already loaded."
else
    sudo modprobe mlx5_core || true
fi

###############################################
# 3. Network sysctl tuning for high throughput
###############################################

sudo tee /etc/sysctl.d/99-multinode-tuning.conf >/dev/null <<EOF
net.core.rmem_max=268435456
net.core.wmem_max=268435456
net.core.netdev_max_backlog=250000
net.core.somaxconn=65535
net.ipv4.tcp_rmem=4096 87380 268435456
net.ipv4.tcp_wmem=4096 65536 268435456
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_mtu_probing=1
EOF

sudo sysctl --system

###############################################
# 4. NCCL tuning defaults for multi-node
###############################################

sudo tee /etc/profile.d/nccl_multinode.sh >/dev/null <<EOF
export NCCL_DEBUG=INFO
export NCCL_IB_DISABLE=0
export NCCL_SOCKET_IFNAME=eth0
export NCCL_IB_HCA=mlx5
export NCCL_IB_GID_INDEX=3
export NCCL_NET_GDR_LEVEL=2
export NCCL_TOPO_DUMP_FILE=/var/log/nccl_topo.xml
EOF

###############################################
# 5. UCX tuning for distributed training
###############################################

sudo tee /etc/profile.d/ucx_tuning.sh >/dev/null <<EOF
export UCX_TLS=rc,ud,sm,self
export UCX_NET_DEVICES=mlx5_0:1
export UCX_RNDV_THRESH=8192
export UCX_IB_GID_INDEX=3
export UCX_MAX_RNDV_RAILS=2
EOF

###############################################
# 6. Optional: Enable SHARP (if fabric supports it)
###############################################

if [ -d "/opt/mellanox/sharp" ]; then
    sudo systemctl enable sharpd || true
    sudo systemctl start sharpd || true
fi

###############################################
# 7. Pre-warm NCCL topology cache
###############################################

if command -v nccl-tests >/dev/null 2>&1; then
    echo "[*] Pre-warming NCCL topology..."
    NCCL_TOPO_DUMP_FILE=/var/log/nccl_topo.xml \
        nccl-tests/all_reduce_perf -b 8 -e 64M -f 2 -g 1 || true
fi

echo "[*] Multi-node performance tuning complete."
