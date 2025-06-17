---
marp: true
theme: default
paginate: true
mermaid: true
style: |
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');

  section {
    background: #000000;
    color: #00FF00;
    font-family: 'Inter', sans-serif;
  }

  h1, h2, h3, h4, h5, h6 {
    color: #00ffa7;
  }

  p, li {
    color: #FFFFFF;
    font-size: 0.8em
  }
---

# 🏷 Generating Wallet Tags for Solana Wallets  
 Helping investors make smarter decisions through on-chain labels

---

## 💡 Problem Statement

> **Create a pipeline that produces valuable labels for blockchain addresses. These labels should be useful to an investor who wants to better understand interesting addresses on chain, and help them make smarter decisions.**

---

## 🎯 User-Centric Design


- **What makes a label valuable?**
  - Helps investors identify high-signal wallets based on PnL and activity patterns.
  - Distinguishes wallet types (e.g., DEX traders, funds, whales, long-term holders).
  - Enables actionable insights by reflecting wallet activity over different time horizons (1h, 1d, 3d, 7d, 30d).
  - Supports segmentation — group wallets with similar behavior for deeper analysis.
  - Facilitates filtering and sorting in UI tools to help users focus on relevant wallets.

---

- **End-user focus**
  - Tags should be **clear, consistent, and interpretable** — ideally unique and mutually exclusive where possible.
  - Provide a **wide range of tags** tailored to different user needs:  
    - *Investors* → `Smart Money`, `Whale`, `Fund`  
    - *Protocol builders* → `Heavy User`, `Bot`  
    - *Researchers* → `Bridge User`, `Mixing Activity`
  - Insights must be **timely** — labels should reflect *current* wallet activity, updated regularly (1h, 1d, 3d, 7d, 30d)
  - Enable users to **create segments of wallets** by similar patterns for discovery and monitoring.

---

## ⚠️ Considerations & challenges

- Finding good quality indexed Solana dataset (not an EVM chain)
- Produce a data model that captures the complex relationship between transactions, accounts, token transfers & instructions 
- Ensure the data platform supports high TPS (Solana = high-throughput chain) and high read
- Handle blockchain reorganizations (e.g. forks, chain reorgs) gracefully.
- What are useful tags based on trading behavior, what should the time horizons be? (1h, 1d, 1w, 1m?)
- Prevent feature leakage in tagging models (e.g. avoid double counting signals like transaction count and volume).
- Keep tags fresh without excessive recomputation → balance between batch and incremental updates.

---


## 🚀 Milestones & Tasks

### Milestones:
1️⃣ Set up streaming + storage  
2️⃣ Build aggregated wallet activity models  
3️⃣ Wallet heuristics train + deploy wallet tagger  
4️⃣ Serve labels to end-users

---

### Tasks per Milestone

- **1️⃣ Streaming + Storage**
  - Connect Goldsky to ClickHouse (append-only mode).
  - Set up base tables with dbt (transactions, instructions, token accounts).

- **2️⃣ Aggregation & Features**
  - DBT models: wallet-level aggregates (balance, tx count, token types).
  - Handle time windows (1h, 1d, 3d, 7d, 30d).

- **3️⃣ Machine Learning**
  - Feature engineering: volume, DEX interactions, clustering.
  - XGBoost classifier + graph embeddings.

- **4️⃣ Label Serving**
  - API.
  - Materialized views for fast queries.

---

## 🏗️ Architecture


