
{{ config(
    materialized='incremental',
    unique_key='id'
) }}

with source as (
    select 
        {{ dbt_utils.star(
            source('solana', 'token_transfers'),
            except=['block_timestamp']
        ) }},
        cast(block_timestamp as datetime64) as block_timestamp 
    from {{ source('solana', 'tokens') }}
)

select
    *
from source

{% if is_incremental() %}
where block_timestamp >= (select max(block_timestamp) from {{ this }})
{% endif %}