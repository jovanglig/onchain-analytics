# 🏷 Generating Wallet Tags for Solana Wallets  

## Description

This repository produces valuable labels for blockchain addresses. These labels are designed to help investors better understand interesting addresses on-chain, enabling them to make smarter and more informed decisions.

## Contents

This repository currently contains:
- A Goldsky configuration file for Solana data ingestion into Clickhouse.
- A dbt project with the following models:
  - `stg_instructions.sql`: Staging model for processing raw instructions.
  - `stg_tokens.sql`: Staging model for processing token metadata.
  - `stg_token_transfers.sql`: Staging model for processing token transfer data.
  - `stg_accounts.sql`: Staging model for processing account data.
  - `int_transfers.sql`: Intermediate model for aggregating and transforming token transfer data.

## How to Run

### 1. Setup the Environment

#### For VS Code Users
1. Open the repository in VS Code.
2. Ensure you have the "Remote - Containers" extension installed.
3. Reopen the folder in the devcontainer:
    - Press `F1` and select `Remote-Containers: Reopen in Container`.
4. The devcontainer will automatically set up the environment, including installing dependencies.
5. Optional: follow the instructions to setup the **dbt Power User Extension**, which includes checking the connection and installing dependencies. 

#### For Non-VS Code Users
1. Build the Docker container:
    ```bash
    docker build -t onchain-analytics .
    ```
2. Run the container:
    ```bash 
    docker run -it -v $(pwd):/workspace -w /workspace onchain-analytics
    ```

#### Without Docker
1. Clone the repository in a directory of your choice:
    ```bash
    git clone <repository-url>
    cd onchain-analytics
    ```
2. Set up a Python virtual environment:
    ```bash
    python3 -m venv .vensv
    source .venv/bin/activate
    ```
3. Install the required dependencies:
    ```bash
    pip install -r requirements.txt
    ```

### 2. View slides
1. View presentation:
    ```bash
    marp --preview docs/slides.md
    ```
    or 

    ```bash
    marp --pdf docs/slides.md
    ```

The last might now work from within a devcontainer.


### 3. Get access to Clickhouse
1. Reach out to jovanglig@proton.me to receive access to the Clickhouse instance.

### 4. Running dbt models
1. Make sure to include your Clickhouse password in .env and run from root
      
   ```bash
    source .env
First make sure to rename ```
    .env.example``` to ```.env```

2. Install dependencies:
    ```bash
    dbt deps
    ```
3. Run and test all models, this will build all models and downstream dependencies:
    ```bash
    dbt build
    ```

### Some dbt resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
