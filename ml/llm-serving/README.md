# LLM Serving

## Setup
```bash
# Provision EC2 GPU Node
just up env='test'

# add ssh config to your local machine for vscode remote development
just config-ssh env='test'

# SSH into EC2 GPU Node
just ssh env='test'

# install just on the server
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin

# install env on the server
mkdir workspace && cd workspace && git clone https://github.com/jessepinkman9900/code-snippets.git
cd code-snippets/ml/llm-serving
just init email='<email for github>'
```

## Model Serving
```bash
# set env var
cp .env.example .env

# download model
dotenvx run -f .env -- uv run src/download-model.py --help
dotenvx run -f .env -- uv run src/download-model.py --model google/gemma-2-2b-it

# serve model
dotenvx run -f .env -- uv run src/serve-model.py --help
dotenvx run -f .env -- uv run src/serve-model.py --model google/gemma-2-2b-it
```
