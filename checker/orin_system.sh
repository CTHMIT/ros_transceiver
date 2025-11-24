echo "=== L4T (Jetson Linux) ==="
head -n 1 /etc/nv_tegra_release 2>/dev/null || echo "no nv_tegra_release"
dpkg-query --show nvidia-l4t-core 2>/dev/null || true

echo -e "\n=== JetPack ==="
apt-cache show nvidia-jetpack 2>/dev/null | grep Version || echo "nvidia-jetpack not found"

echo -e "\n=== OS / Kernel ==="
cat /etc/os-release | sed -n '1,6p'
uname -r

echo -e "\n=== CUDA / cuDNN / TensorRT ==="
nvcc --version | sed -n '1,4p' 2>/dev/null || echo "nvcc not found"
dpkg -l | grep libcudnn || echo "cudnn not found"
dpkg -l | egrep 'tensorrt|nvinfer' || echo "tensorrt not found"

echo -e "\n=== OpenCV / GStreamer ==="
python3 - <<'PY'
try:
    import cv2
    print("OpenCV:", cv2.__version__)
except Exception as e:
    print("OpenCV: not found")
PY
gst-launch-1.0 --version 2>/dev/null | head -n 1 || echo "gstreamer not found"

echo -e "\n=== ROS2 ==="
ls /opt/ros/ >/dev/null 2>&1 && ls /opt/ros/ || echo "ros2 not found"

echo -e "\n=== Docker ==="
if command -v docker &> /dev/null; then
    docker --version
else
    echo "docker not found"
fi

if docker compose version &> /dev/null; then
    docker compose version
else
    echo "docker compose not found"
fi

