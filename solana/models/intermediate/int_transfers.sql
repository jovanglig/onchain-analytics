{{ config(
    materialized='incremental',
    unique_key=['id', 'index']
) }}

with tr as (
  select
    *,
    date(block_timestamp) as block_date
  from
    {{ ref('stg_instructions') }}
  where
    program = 'spl-token'
    and instruction_type not in ('burn', 'mintto', 'closeaccount')
    {% if is_incremental() %}
    and block_timestamp >= (select max(block_timestamp) from {{ this }})
    {% endif %}
),

amounts as (
  select
    tx_signature,
    block_slot,
    block_hash,
    block_timestamp,
    block_date,
    index,
    parsed,
    program,
    instruction_type,
    params,

    -- extract values from json object
    JSONExtractString(params, 'authority') as authority,
    JSONExtractString(params, 'account') as account,
    JSONExtractString(params, 'mint') as mint,
    JSONExtractString(params, 'destination') as destination,
    JSONExtractString(params, 'source') as source,
    
    -- try extracting token amount if present
    toFloat64OrNull(JSONExtractString(params, 'amount')) as token_amount_raw,

    toFloat64OrNull(
  JSONExtractString(JSONExtractString(params, 'tokenAmount'), 'amount')
    ) as token_amount

  from tr
),

-- identify wallet (authority) from the first instruction per tx
wallets as (
  select
    tx_signature,
    authority as wallet
  from (
    select *,
      row_number() over (partition by tx_signature order by index asc) as rn
    from amounts
  )
  where rn = 1
),

-- identify the "destination" account from last instruction per tx
destinations as (
  select
    tx_signature,
    destination
  from (
    select *,
      row_number() over (partition by tx_signature order by index desc) as rn
    from amounts
  )
  where rn = 1
),

-- first mint seen in each tx
first_mints as (
  select
    tx_signature,
    mint as first_mint
  from (
    select *,
      row_number() over (partition by tx_signature order by index asc) as rn
    from amounts
    where mint is not null and mint != ''
  )
  where rn = 1
),

-- second distinct mint seen in the same tx (not equal to first)
second_mints as (
  select
    a.tx_signature,
    a.mint as second_mint
  from (
    select *,
      row_number() over (partition by tx_signature order by index asc) as rn
    from amounts
  ) a
  inner join first_mints fm on a.tx_signature = fm.tx_signature
  where a.mint is not null and a.mint != '' and a.mint != fm.first_mint
  qualify row_number() over (partition by a.tx_signature order by a.index asc) = 1
),

tokens as (
  select
    mint,
    name,
    symbol,
    uri
  from {{ ref('stg_tokens') }}
),

aggregated as (
  select
    a.tx_signature,
    w.wallet,
    fm.first_mint as token_out,
    tko.name as token_out_name,
    tko.symbol as token_out_symbol,
    tko.uri as token_out_uri,
    sm.second_mint as token_in,
    tki.name as token_in_name,
    tki.symbol as token_in_symbol,
    tki.uri as token_in_uri,
    sum(
      case when a.authority = w.wallet then coalesce(a.token_amount, a.token_amount_raw) / pow(10, 9) else 0 end
    ) as token_amount_out,

    sum(
      case when a.destination = wtc.destination then coalesce(a.token_amount, a.token_amount_raw) / pow(10, 9) else 0 end
    ) as token_amount_in

  from amounts a
  left join first_mints fm on a.tx_signature = fm.tx_signature
  left join second_mints sm on a.tx_signature = sm.tx_signature
  left join destinations wtc on a.tx_signature = wtc.tx_signature
  left join wallets w on a.tx_signature = w.tx_signature
  left join tokens tko on tko.mint = fm.first_mint
  left join tokens tki on tki.mint = sm.second_mint
  group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
)

select * from aggregated