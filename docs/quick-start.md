# 🚀 Quick Start Guide

## **1. Minimal Installation**
```bash
git clone https://github.com/the-ahuja-lab/EvoAge.git
cd EvoAge
bash scripts/setup.sh --all
```

The setup helper creates separate backend/frontend conda environments, installs required packages, and prepares `.env` files from templates.

On a fresh machine, backend setup may take 20-75+ minutes and frontend setup may take 5-25 minutes. The script prints numbered stages and pip download progress while it runs.

If this first run ends with warnings about missing `.env` values, that is expected. The graph/services and real secrets are configured in the next steps.

Download the Neo4j graph dump:

```bash
bash scripts/download_neo4j_dump.sh
```

This downloads `kg_formation/neo4j/neo4j.dump.tar.gz` from Hugging Face and extracts `data/neo4j/neo4j.dump`. Because the file is large, you can run this command in a separate terminal from the repo root.

Then fill the Neo4j/Redis values in `Backend/.env`. At minimum:

```env
NEO4J_URI=neo4j://localhost:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=YOUR_NEO4J_PASSWORD
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_USERNAME=default
REDIS_PASSWORD=YOUR_REDIS_PASSWORD
```

Install/configure Redis and Neo4j as a normal user. The script will ask for sudo password only when it needs system-level access:

```bash
bash scripts/setup_services.sh
```

Fill the remaining model/data/API values in `Backend/.env`, then run:

```bash
bash scripts/setup.sh --check-only
```

`--check-only` verifies configuration and service connectivity; it does not start the backend/frontend app servers.

Start both the backend and frontend:

```bash
bash scripts/start_app.sh
```

The launcher runs both apps in the background, writes logs to `logs/`, stores PIDs in `.run/`, prints the URLs, and checks whether the URLs are reachable.

Default URLs:

- frontend app: `http://localhost:8501`
- backend API docs: `http://localhost:1026/docs`

To restart or stop:

```bash
bash scripts/start_app.sh --restart
bash scripts/start_app.sh --stop
```

## **2. Using the Knowledge Graph**

You can interact with the EvoAge Knowledge Graph in three primary ways:

### **1. Interactive Exploration (Streamlit Frontend)**
The easiest way to start exploring the Knowledge Graph is through the LLM-assisted web interface.
- **Start the Frontend manually if needed**: Navigate to the `Frontend/` directory, activate your `evoage_frontend` conda environment, and run:
  ```bash
  streamlit run streamlit_app.py --server.port=8501
  ```
- **Natural Language Querying**: Once the server is running, open `http://localhost:8501`. You can ask questions directly, e.g., *"What pathways link Rapamycin to lifespan extension?"*
- **Graph Visualization**: The frontend allows you to visually explore node connections across species, making it ideal for hypothesis generation.

### **2. Programmatic Access (FastAPI Backend)**
For developers integrating EvoAge into their computational pipelines, the REST API provides direct access to the Knowledge Graph Embeddings (KGE).
- **Start the Backend manually if needed**: Navigate to the `Backend/` directory, activate your `evoage_backend` conda environment, and run the server:
  ```bash
  poetry run gunicorn -w 1 -k uvicorn.workers.UvicornWorker app.main:app --bind 0.0.0.0:1026
  ```
- **Interactive API Docs**: Navigate to `http://localhost:1026/docs` to see the Swagger UI.
- **Capabilities**: Run queries for link prediction, test biological hypotheses, and score biological plausibility in batch operations.

### **3. Direct Graph Queries (Neo4j Cypher)**
For advanced data science tasks or direct graph algorithms, you can query the unified graph directly using Cypher.
- **Connect**: Open a `cypher-shell` or use the Neo4j Browser at `http://localhost:7474`.
- **Query Example**:
  ```cypher
  // Example: Find orthologs associated with a specific aging hallmark
  MATCH (h:HumanGene)-[:ORTHOLOG]->(m:ModelOrganismGene)-[:ASSOCIATED_WITH]->(p:Phenotype {name: "Aging"})
  RETURN h.symbol, m.symbol LIMIT 10;
  ```

---

## **Quick File Overview**

### **1. [Home / Index](index.md)**
- 📊 Project overview and statistics
- 🚀 Quick start code examples
- 🏗️ Architecture diagram (text-based)
- 📖 Navigation to all sections
- 💻 System requirements

### **2. [Installation & Setup](installation.md)**
- 🔧 System prerequisites
- 🐍 Conda environment setup (with full `environment.yml` template)
- 🖥️ HPC cluster configuration (PBS/Torque)
- ⚙️ Configuration file templates
- ✔️ Installation verification script

### **3. [Data Collection](data-collection.md)**
- 📦 Master source table (48+ databases, version-pinned)
- 🗂️ Functional grouping by category
- 📁 Reproducibility & provenance tracking

### **4. [Preprocessing](preprocessing.md)**
- 🧬 Two paradigms (relation-typed CSV vs. raw RDF/OWL triples)
- 🛠️ Case-insensitive gene symbol resolution, chemical SMILES, and disease cascade lookup
- 📊 Entity mapping validation & output schemas

### **5. [Relation Processing](relation-processing.md)**
- 🔗 Relation-by-relation merging cascading logic
- 🛠️ Deduplication preserving cross-source provenance (`::` joined tags)
- 📊 Standardized 13-column canonical schemas

### **6. [Ortholog Mapping](ortholog-mapping.md)**
- 🧬 Ensembl Compara ortholog mapping (biomaRt & gprofiler2 cascade)
- 🔗 1-to-1 vs. 1-to-many ortholog strategies
- 🛠️ Homology queries and bijective row explosions for 1-to-many options

### **7. [KG Construction](kg-construction.md)**
- 🧬 Splitting unified multi-species graphs into Aging-specific vs. Biomedical KGs
- 🔗 Substring matching and default biomedical fallback buckets

### **8. [Tensors & Splitting](kg-tensors-and-splitting.md)**
- 🧠 PyTorch tensor generation, global node and relation ID mapping
- ⚙️ Deteriministic, parallelized ID builders
- 💾 Bi bijective int64 deduping representation
- 📝 Leakage-free train/valid/test splitting lineages (AB_test)

---
