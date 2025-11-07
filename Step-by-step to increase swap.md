Step-by-step to increase swap:

```bash
# 1. Create a 32GB swap file (this will take a minute or two)
sudo fallocate -l 32G /swapfile-extra

# 2. Set correct permissions
sudo chmod 600 /swapfile-extra

# 3. Format it as swap
sudo mkswap /swapfile-extra

# 4. Activate it
sudo swapon /swapfile-extra

# 5. Verify it's active
swapon --show
free -h
```

After you've added the swap, you should see ~40GB total swap (8GB existing + 32GB new).

Then retry the conversion:

```bash
source activate-intel-gpu.sh
optimum-cli export openvino --model openai/gpt-oss-20b gpt_oss_20b_ir --weight-format int4
```

Note: The conversion will be MUCH slower with swap (expect 30-60+ minutes instead of 10-15), but it should complete without being killed.
