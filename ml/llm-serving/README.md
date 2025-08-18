# LLM Serving
## Note
- [latitude.so](https://github.com/latitude-dev/latitude-llm) prompt management setup does not work

## Setup
### Provision EC2 GPU Node
```bash
cd infra/terraform/environments/test
cp .env.example .env
# update env var

# Provision EC2 GPU Node
just up env='test'

# add ssh config to your local machine for vscode remote development
just config-ssh env='test'

# SSH into EC2 GPU Node
just ssh env='test'
```

### Setup EC2 GPU Node
```bash
# install just on the server
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin

# install env on the server
mkdir workspace && cd workspace && git clone https://github.com/jessepinkman9900/code-snippets.git
cd code-snippets/ml/llm-serving && just init email='<email for github>'
source ~/.bashrc
```

### Downloading models
```bash
# on ec2 instance
cp .env.example .env
# update env var

just init-serving
source .venv/bin/activate

# download model
dotenvx run -f .env -- hf download google/gemma-3-1b-it
dotenvx run -f .env -- hf download google/gemma-3-4b-it

# list downloaded models
dotenvx run -f .env -- hf cache scan
```

## vLLM Serving
### Bare Metal
```bash
# on ec2 instance
# install vllm
just init-serving
source .venv/bin/activate
vllm --help

# set env var
cp .env.example .env

# serve model
dotenvx run -f .env -- vllm serve google/gemma-3-1b-it --gpu-memory-utilization 0.6
# --gpu-memory-utilization: fraction of GPU memory to use. default 0.9


# benchmark server
dotenvx run -f .env -- vllm bench serve --model google/gemma-3-1b-it --dataset-name random --random-input-len 256 --request-rate 4
```

#### Benchmark Results

```bash
dotenvx run -f .env -- vllm serve google/gemma-3-1b-it --gpu-memory-utilization 0.9 --max-model-len 2048 --max-num-seqs 32 --max-num-batched-tokens 4096 --enable-chunked-prefill --dtype float16
dotenvx run -f .env -- vllm bench serve --model google/gemma-3-1b-it --dataset-name random --random-input-len 256 --request-rate 12
```
```
============ Serving Benchmark Result ============
Successful requests:                     1000      
Benchmark duration (s):                  84.84     
Total input tokens:                      254747    
Total generated tokens:                  118937    
Request throughput (req/s):              11.79     
Output token throughput (tok/s):         1401.82   
Total Token throughput (tok/s):          4404.32   
---------------Time to First Token----------------
Mean TTFT (ms):                          30.30     
Median TTFT (ms):                        28.93     
P99 TTFT (ms):                           48.43     
-----Time per Output Token (excl. 1st token)------
Mean TPOT (ms):                          13.21     
Median TPOT (ms):                        13.34     
P99 TPOT (ms):                           14.52     
---------------Inter-token Latency----------------
Mean ITL (ms):                           13.22     
Median ITL (ms):                         13.25     
P99 ITL (ms):                            15.30     
==================================================
```

### Docker Compose
```bash
# on ec2 instance
cp .env.example .env
# update env var

# pull docker images - very big
docker pull vllm/vllm-openai:v0.10.0
docker pull ghcr.io/open-webui/open-webui:v0.6.22

# docker compose up
cd docker/vllm-openui
dotenvx run -f .env -- docker compose up -d
```

### Evals
```bash
just vllm-eval tasks='gsm8k'
```
```
|Tasks|Version|     Filter     |n-shot|  Metric   |   |Value |   |Stderr|
|-----|------:|----------------|-----:|-----------|---|-----:|---|-----:|
|gsm8k|      3|flexible-extract|     5|exact_match|↑  |0.2563|±  | 0.012|
|     |       |strict-match    |     5|exact_match|↑  |0.2555|±  | 0.012|
```
