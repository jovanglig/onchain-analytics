
WITH tr AS (
  SELECT
    *,
    date(block_timestamp) AS block_date
  FROM
    {{ ref('stg_instructions') }}
  WHERE
    date(block_timestamp) = '2025-06-14'
    AND block_slot = '346776224'
    AND tx_signature = '29dXQS5gZ9EsM1pnKPaFWZ4Axk3pS78pouafLJbNGGFoNEmKvzTJk7hTjLgAaZgdPoEjgbpDpoEAYMfnxj9FUxKe'
    AND program = 'spl-token'
    AND instruction_type NOT IN ('burn', 'mintTo', 'closeAccount')
),

amounts AS (
  SELECT
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
    toFloat64OrNull(
      JSONExtractString(
        anyIf(tupleElement(param, 2), tupleElement(param, 1) = 'amount')
      )
    ) AS token_amount_raw,

    toFloat64OrNull(extract(
      anyIf(tupleElement(param, 2), tupleElement(param, 1) = 'tokenAmount'),
      'amount:([0-9]+)'
    )) AS token_amount,

    anyIf(tupleElement(param, 2), tupleElement(param, 1) = 'authority') AS authority,
    anyIf(tupleElement(param, 2), tupleElement(param, 1) = 'destination') AS destination,
    anyIf(tupleElement(param, 2), tupleElement(param, 1) = 'source') AS source,
    anyIf(tupleElement(param, 2), tupleElement(param, 1) = 'mint') AS mint

  FROM tr ARRAY JOIN params AS param
  GROUP BY
    tx_signature,
    block_slot,
    block_hash,
    block_timestamp,
    block_date,
    index,
    instruction_type,
    parsed,
    program,
    params
  ORDER BY index
),

wallet_cte AS (
  SELECT authority AS wallet
  FROM amounts
  WHERE index = 0
  LIMIT 1
),

wallet_token_contract AS (
  SELECT 
    destination
  FROM amounts
  WHERE index = (SELECT max(index) FROM amounts)
),

first_mint_cte AS (
  SELECT mint AS first_mint
  FROM amounts
  WHERE mint IS NOT NULL AND mint != ''
  ORDER BY index
  LIMIT 1
),

second_mint_cte AS (
  SELECT mint AS second_mint
  FROM amounts, first_mint_cte
  WHERE mint IS NOT NULL
    AND mint != ''
    AND mint != first_mint
  ORDER BY index
  LIMIT 1
),

aggregated AS (
  SELECT
    a.tx_signature,
    w.wallet,
    fm.first_mint AS token_out,
    sm.second_mint AS token_in,

    sumIf(
      coalesce(a.token_amount, a.token_amount_raw) / pow(10, 9),
      a.authority = w.wallet
    ) AS token_amount_out,

    sumIf(
      coalesce(a.token_amount, a.token_amount_raw) / pow(10, 9),
      a.destination = wtc.destination
    ) AS token_amount_in

  FROM amounts a
  CROSS JOIN wallet_cte w
  CROSS JOIN first_mint_cte fm
  CROSS JOIN second_mint_cte sm
  CROSS JOIN wallet_token_contract wtc
  GROUP BY 1, 2, 3, 4
)

SELECT * FROM aggregated;