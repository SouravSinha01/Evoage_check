# EvoAge shell-based setup flow

This folder contains helper scripts for users who want to set up EvoAge with fewer manual commands while still keeping verification checks visible.

Run all scripts from the repository root.

Do not run these scripts with `sudo bash`. Run them as a normal user. The service setup script calls `sudo` only when it needs system-level access, and your terminal will ask for the sudo password at that point.

## 1. Prepare Python environments and `.env` files

```bash
bash scripts/setup.sh --all
```

This creates/checks the backend and frontend conda environments, installs  dependencies. 

- `Backend/.env`
- `Frontend/.env`

At the end of this first step, some checks may print concise warnings for missing Neo4j, Redis, JWT, model-path, or API-key values. That is expected before the graph dump and services are configured.

## 2. Download and extract the Neo4j dump

```bash
bash scripts/download_neo4j_dump.sh
```

The script downloads this Hugging Face file: [Evoage_HuggingFace_files](https://huggingface.co/datasets/gauravahuja77/EvoAge/tree/main)
- Extracts the neo4j dump file

```text
kg_formation/neo4j/neo4j.dump.tar.gz
```
Note : if interupted mid download, the file needs to be removed & redownloaded with the same script

## 3. Fill service values in `Backend/.env`

After the dump is ready, fill the Neo4j and Redis values in `Backend/.env`.

For both local and SSH/server installs, the recommended default is to keep Neo4j and Redis private to the same machine:

```env
NEO4J_URI=neo4j://localhost:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=YOUR_NEO4J_PASSWORD

REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_USERNAME=default
REDIS_PASSWORD=YOUR_REDIS_PASSWORD
```

Use the server IP/domain only for the backend and frontend app URLs.

For an SSH/server setup, replace `SERVER_IP_OR_DOMAIN` with the server IP or domain that users will open in their browser:
For an local setup, Everything works fine keeping localhost.

```env
API_BASE=http://SERVER_IP_OR_DOMAIN:1026
FRONTEND_URL=http://SERVER_IP_OR_DOMAIN:8501
```

In `Frontend/.env`, set:

```env
API_BASE_URL=http://SERVER_IP_OR_DOMAIN:1026
```

For local-only testing, use `localhost` for the app URLs too:

```env
API_BASE=http://localhost:1026
FRONTEND_URL=http://localhost:8501
API_BASE_URL=http://localhost:1026
```

Recommended SSH/server connectivity model:

```text
User browser
  -> http://SERVER_IP_OR_DOMAIN:8501
  -> Streamlit frontend on the server
  -> http://SERVER_IP_OR_DOMAIN:1026
  -> FastAPI backend on the server
  -> neo4j://localhost:7687
  -> Neo4j on the same server

FastAPI backend
  -> localhost:6379
  -> Redis on the same server
```

This exposes only the frontend/backend app ports. Neo4j and Redis stay internal unless you intentionally configure them otherwise.

## 4. Install/configure Redis and Neo4j, then restore the dump

```bash
bash scripts/setup_services.sh
```

This script reads Neo4j/Redis values from `Backend/.env`.

It uses the extracted dump automatically:

```text
data/neo4j/neo4j.dump
```

It performs:

- base system package install/check
- Redis install/configuration
- Redis password setup
- Redis restart and `PING` check
- Neo4j install
- Neo4j version display
- Neo4j stop before dump restore
- initial Neo4j password setup
- APOC plugin install
- APOC config update
- Neo4j dump restore
- Neo4j data/plugin ownership repair after restore
- Neo4j restart after APOC and restore
- wait for Neo4j database query readiness
- Neo4j login check
- graph node-count check

If Neo4j starts but queries fail with `AccessDeniedException` under `/var/lib/neo4j/data`, repair ownership manually:

```bash
sudo systemctl stop neo4j
sudo chown -R neo4j:neo4j /var/lib/neo4j/data
sudo chown -R neo4j:neo4j /var/lib/neo4j/plugins
sudo chmod -R u+rwX,g+rX /var/lib/neo4j/data
sudo systemctl start neo4j
```

Then test:

```bash
cypher-shell -a bolt://localhost:7687 -u neo4j -p 'YOUR_NEO4J_PASSWORD' "SHOW DATABASES;"
```

If your `/etc/neo4j/neo4j.conf` uses a custom `server.directories.data` or `server.directories.plugins`, run the same ownership commands on those configured paths instead. The script detects those configured paths automatically and fixes the permission issues as well.

## 5. Fill remaining backend values

Before strict verification, fill the remaining required values in `Backend/.env`, especially:

- model/data paths
- DGL/DGL-KE paths
- hypothesis-testing paths
- JWT secret
- LLM/API key settings
- email settings if using email/reset-password features

## 6. Run final setup checks

```bash
bash scripts/setup.sh --check-only
```

This does not reinstall anything and does not start the app.

It validates: all the required files, dependencies, packages.

- If backend/frontend URLs are not reachable during `--check-only`, that is expected before the app is started. The urls will work with the next command




## 7. Start backend and frontend

```bash
bash scripts/start_app.sh
```

This starts the backend and frontend in the background, writes logs/PID files, prints URLs, and checks whether the URLs become reachable.

Runtime defaults:
- backend printed/checked URL comes from `Frontend/.env` `API_BASE_URL`, then `Backend/.env` `API_BASE`
- frontend printed/checked URL comes from `Backend/.env` `FRONTEND_URL`
- if both localhost and server-IP values exist, the server-IP URL is preferred for display/checks
- if those values are missing/placeholders, the fallback URLs are `http://localhost:1026` and `http://localhost:8501`
- the script always also prints localhost fallback URLs
- if the server-IP URL fails but localhost works, the app is running and the remaining issue is network/firewall/IP exposure

Before starting the backend, the script checks the DGL-EvoKG model/data files configured in `Backend/.env`:

- `MODEL_PATH`
- `MODEL_PATH/config.json`
- `ENT_DICT_PATH`
- `REL_DICT_PATH`
- `NODE_MAPPINGS_PATH`
- `DGLKE_DUMMY_HEAD_LIST`
- `DGLKE_DUMMY_REL_LIST`

If these files are missing, the backend will not start. Download or copy the required DGL-EvoKG artifacts from:

```text
https://huggingface.co/datasets/gauravahuja77/EvoAge/tree/main
```

Then set `ROOT_DIR_PATH` in `Backend/.env` to the directory containing `Model/`, `Node_Mapping/`, and `Dummy_Input/`.

For SSH/server access from another machine, bind the app servers to the network interface and print server-IP URLs:

- Do not replace the Neo4j/Redis localhost values with `SERVER_IP_OR_DOMAIN` unless another machine needs to connect directly to those database services.

Runtime files:

- logs: `logs/backend.log`, `logs/frontend.log`
- PIDs: `.run/backend.pid`, `.run/frontend.pid`

## Useful commands:

```bash
bash scripts/start_app.sh --restart
bash scripts/start_app.sh --stop
bash scripts/setup.sh --check-only
```

## Full command sequence

```bash
bash scripts/setup.sh --all
bash scripts/download_neo4j_dump.sh

# Fill Backend/.env and Frontend/.env

bash scripts/setup_services.sh
bash scripts/setup.sh --check-only
bash scripts/start_app.sh
```
