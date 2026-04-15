use aiken/builtin
use aiken/cbor
use aiken/collection/list
use aiken/crypto.{keccak_256, verify_ecdsa_signature}
use aiken/primitive/bytearray
use aiken/primitive/string
use cardano/assets
use cardano/transaction.{Output}
use dia_cardano_oracle/config_logic

pub type OracleIntent {
  OracleIntent {
    intent_type: ByteArray,
    version: ByteArray,
    chain_id: Int,
    nonce: Int,
    expiry: Int,
    symbol: ByteArray,
    price: Int,
    timestamp: Int,
    source: ByteArray,
    signature: ByteArray,
    signer: ByteArray,
  }
}

pub type OracleDatum {
  OracleDatum {
    pair_id: ByteArray,
    price: Int,
    timestamp: Int,
    nonce: Int,
    intent_hash: ByteArray,
    signer: ByteArray,
    signer_public_key: ByteArray,
    signature: ByteArray,
    raw_intent: ByteArray,
  }
}

pub type OracleRedeemer {
  OracleRedeemer {
    intent: OracleIntent,
    signer_public_key: ByteArray,
  }
}

pub fn oracle_intent_hash(
  domain: config_logic.Domain,
  intent: OracleIntent,
) -> ByteArray {
  keccak_256(
    bytearray.concat(
      #"1901",
      bytearray.concat(domain_separator(domain), oracle_intent_struct_hash(intent)),
    ),
  )
}

pub fn pair_matches(datum: OracleDatum, redeemer: OracleRedeemer) -> Bool {
  datum.pair_id == redeemer.intent.symbol
}

pub fn signer_is_authorized(
  config_datum: config_logic.ConfigDatum,
  signer_public_key: ByteArray,
) -> Bool {
  list.has(config_datum.authorized_oracle_public_keys, signer_public_key)
}

pub fn pair_is_authorized(
  config_datum: config_logic.ConfigDatum,
  pair_token_name: ByteArray,
  redeemer: OracleRedeemer,
) -> Bool {
  list.any(
    config_datum.allowed_pairs,
    fn(pair) {
      and {
        pair.token_name == pair_token_name,
        pair.pair_code == redeemer.intent.symbol,
      }
    },
  )
}

pub fn is_fresh_update(datum: OracleDatum, redeemer: OracleRedeemer) -> Bool {
  and {
    redeemer.intent.timestamp > datum.timestamp,
    redeemer.intent.nonce > datum.nonce,
  }
}

pub fn output_matches_redeemer(next: OracleDatum, redeemer: OracleRedeemer) -> Bool {
  output_matches_redeemer_for_domain(next, redeemer, config_logic.sample_domain())
}

pub fn output_matches_redeemer_for_domain(
  next: OracleDatum,
  redeemer: OracleRedeemer,
  domain: config_logic.Domain,
) -> Bool {
  and {
    next.pair_id == redeemer.intent.symbol,
    next.price == redeemer.intent.price,
    next.timestamp == redeemer.intent.timestamp,
    next.nonce == redeemer.intent.nonce,
    next.intent_hash == oracle_intent_hash(domain, redeemer.intent),
    next.signer == redeemer.intent.signer,
    next.signer_public_key == redeemer.signer_public_key,
    next.signature == redeemer.intent.signature,
    next.raw_intent == raw_intent_bytes(redeemer.intent),
  }
}

pub fn preserves_pair_id(previous: OracleDatum, next: OracleDatum) -> Bool {
  previous.pair_id == next.pair_id
}

pub fn has_valid_signature(
  config_datum: config_logic.ConfigDatum,
  redeemer: OracleRedeemer,
) -> Bool {
  and {
    valid_intent(redeemer.intent),
    signer_is_authorized(config_datum, redeemer.signer_public_key),
    verify_ecdsa_signature(
      redeemer.signer_public_key,
      oracle_intent_hash(config_datum.domain_data, redeemer.intent),
      normalized_signature(redeemer.intent.signature),
    ),
  }
}

pub fn valid_initial_oracle_datum(
  pair: config_logic.PairEntry,
  config_datum: config_logic.ConfigDatum,
  datum: OracleDatum,
) -> Bool {
  and {
    valid_oracle_state(datum),
    datum.pair_id == pair.pair_code,
    datum.price >= 0,
    datum.timestamp >= 0,
    datum.nonce >= 0,
    decode_raw_intent(datum.raw_intent)
      |> matches_initial_intent(config_datum, pair, datum),
  }
}

pub fn valid_oracle_state(datum: OracleDatum) -> Bool {
  and {
    !bytearray.is_empty(datum.pair_id),
    datum.price >= 0,
    datum.timestamp >= 0,
    datum.nonce >= 0,
    bytearray.length(datum.intent_hash) == 32,
    bytearray.length(datum.signer) == 20,
    !bytearray.is_empty(datum.signer_public_key),
    signature_has_supported_length(datum.signature),
    !bytearray.is_empty(datum.raw_intent),
  }
}

pub fn fees_paid(
  config_datum: config_logic.ConfigDatum,
  outputs: List<Output>,
) -> Bool {
  if config_datum.fee_amount == 0 {
    True
  } else {
    list.all(
      config_datum.fee_addresses,
      fn(fee_address) {
        list.any(
          outputs,
          fn(output) {
            and {
              output.address == fee_address,
              assets.quantity_of(
                output.value,
                assets.ada_policy_id,
                assets.ada_asset_name,
              ) >= config_datum.fee_amount,
            }
          },
        )
      },
    )
  }
}

pub fn valid_oracle_update(
  previous: OracleDatum,
  config_datum: config_logic.ConfigDatum,
  pair_token_name: ByteArray,
  redeemer: OracleRedeemer,
  next: OracleDatum,
) -> Bool {
  and {
    pair_matches(previous, redeemer),
    pair_is_authorized(config_datum, pair_token_name, redeemer),
    is_fresh_update(previous, redeemer),
    preserves_pair_id(previous, next),
    output_matches_redeemer_for_domain(next, redeemer, config_datum.domain_data),
    has_valid_signature(config_datum, redeemer),
  }
}

fn raw_intent_bytes(intent: OracleIntent) -> ByteArray {
  cbor.serialise(intent)
}

fn valid_intent(intent: OracleIntent) -> Bool {
  and {
    !bytearray.is_empty(intent.intent_type),
    !bytearray.is_empty(intent.version),
    intent.chain_id >= 0,
    intent.nonce >= 0,
    intent.expiry >= 0,
    !bytearray.is_empty(intent.symbol),
    intent.price >= 0,
    intent.timestamp >= 0,
    !bytearray.is_empty(intent.source),
    signature_has_supported_length(intent.signature),
    bytearray.length(intent.signer) == 20,
  }
}

fn signature_has_supported_length(signature: ByteArray) -> Bool {
  let length = bytearray.length(signature)
  length == 64 || length == 65
}

fn normalized_signature(signature: ByteArray) -> ByteArray {
  if bytearray.length(signature) == 65 {
    builtin.slice_bytearray(0, 64, signature)
  } else {
    signature
  }
}

fn matches_initial_intent(
  maybe_intent: Option<OracleIntent>,
  config_datum: config_logic.ConfigDatum,
  pair: config_logic.PairEntry,
  datum: OracleDatum,
) -> Bool {
  when maybe_intent is {
    Some(intent) ->
      and {
        valid_intent(intent),
        datum.signer == intent.signer,
        datum.signature == intent.signature,
        datum.pair_id == intent.symbol,
        intent.symbol == pair.pair_code,
        datum.price == intent.price,
        datum.timestamp == intent.timestamp,
        datum.nonce == intent.nonce,
        datum.intent_hash == oracle_intent_hash(config_datum.domain_data, intent),
        signer_is_authorized(config_datum, datum.signer_public_key),
        verify_ecdsa_signature(
          datum.signer_public_key,
          oracle_intent_hash(config_datum.domain_data, intent),
          normalized_signature(intent.signature),
        ),
      }

    None -> False
  }
}

fn decode_raw_intent(raw_intent: ByteArray) -> Option<OracleIntent> {
  when cbor.deserialise(raw_intent) is {
    Some(data) -> {
      expect intent: OracleIntent = data
      Some(intent)
    }

    None -> None
  }
}

fn domain_separator(domain: config_logic.Domain) -> ByteArray {
  keccak_256(
    abi_words([
      keccak_256(
        string.to_bytearray(
          @"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)",
        ),
      ),
      keccak_256(domain.name),
      keccak_256(domain.version),
      uint256_word(domain.source_chain_id),
      address_word(domain.verifying_contract),
      zero_word(),
    ]),
  )
}

fn oracle_intent_struct_hash(intent: OracleIntent) -> ByteArray {
  keccak_256(
    abi_words([
      keccak_256(
        string.to_bytearray(
          @"OracleIntent(string intentType,string version,uint256 chainId,uint256 nonce,uint256 expiry,string symbol,uint256 price,uint256 timestamp,string source)",
        ),
      ),
      keccak_256(intent.intent_type),
      keccak_256(intent.version),
      uint256_word(intent.chain_id),
      uint256_word(intent.nonce),
      uint256_word(intent.expiry),
      keccak_256(intent.symbol),
      uint256_word(intent.price),
      uint256_word(intent.timestamp),
      keccak_256(intent.source),
    ]),
  )
}

fn abi_words(words: List<ByteArray>) -> ByteArray {
  list.foldl(words, #"", fn(word, acc) { bytearray.concat(acc, word) })
}

fn uint256_word(value: Int) -> ByteArray {
  builtin.integer_to_bytearray(True, 32, value)
}

fn address_word(value: ByteArray) -> ByteArray {
  bytearray.concat(builtin.integer_to_bytearray(True, 12, 0), value)
}

fn zero_word() -> ByteArray {
  builtin.integer_to_bytearray(True, 32, 0)
}

fn sample_intent() -> OracleIntent {
  OracleIntent {
    intent_type: #"4f7261636c65557064617465",
    version: #"312e30",
    chain_id: 100640,
    nonce: 1760960522308165264,
    expiry: 1760964122,
    symbol: #"555344432f555344",
    price: 99992561,
    timestamp: 1760960522,
    source: #"444941204f7261636c65",
    signature: #"7e3ab9c6c59f1997f007063e96120ab198bb4129875e49b4f48298c533771d0e6266a261ea108343a4ed02a6823ab3602bcdedd4b891226c2f452b4a158ac1011b",
    signer: #"f64d333c19b007519c7b9316680ed26578f98c08",
  }
}

fn sample_signer_public_key() -> ByteArray {
  #"03aafe60df69602d2600363bf9830b9ba09f199e7c1c1bda7c0be88a3ed341b807"
}

fn sample_usdc_pair() -> config_logic.PairEntry {
  config_logic.PairEntry {
    token_name: #"555344435f555344",
    pair_code: #"555344432f555344",
  }
}

fn sample_usdc_config() -> config_logic.ConfigDatum {
  config_logic.ConfigDatum {
    valid_config_signers: config_logic.sample_config().valid_config_signers,
    authorized_oracle_public_keys: config_logic.sample_config().authorized_oracle_public_keys,
    fee_addresses: config_logic.sample_config().fee_addresses,
    fee_amount: config_logic.sample_config().fee_amount,
    domain_data: config_logic.sample_config().domain_data,
    allowed_pairs: [sample_usdc_pair()],
  }
}

fn sample_datum() -> OracleDatum {
  let intent = sample_intent()

  OracleDatum {
    pair_id: intent.symbol,
    price: intent.price,
    timestamp: intent.timestamp,
    nonce: intent.nonce,
    intent_hash: oracle_intent_hash(config_logic.sample_domain(), intent),
    signer: intent.signer,
    signer_public_key: sample_signer_public_key(),
    signature: intent.signature,
    raw_intent: raw_intent_bytes(intent),
  }
}

fn sample_redeemer() -> OracleRedeemer {
  OracleRedeemer {
    intent: sample_intent(),
    signer_public_key: sample_signer_public_key(),
  }
}

fn unauthorized_redeemer() -> OracleRedeemer {
  OracleRedeemer {
    intent: sample_intent(),
    signer_public_key: #"03ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
  }
}

fn stale_timestamp_redeemer() -> OracleRedeemer {
  let intent = sample_intent()

  OracleRedeemer {
    intent: OracleIntent {
      intent_type: intent.intent_type,
      version: intent.version,
      chain_id: intent.chain_id,
      nonce: intent.nonce,
      expiry: intent.expiry,
      symbol: intent.symbol,
      price: intent.price,
      timestamp: intent.timestamp - 1,
      source: intent.source,
      signature: intent.signature,
      signer: intent.signer,
    },
    signer_public_key: sample_signer_public_key(),
  }
}

fn stale_nonce_redeemer() -> OracleRedeemer {
  let intent = sample_intent()

  OracleRedeemer {
    intent: OracleIntent {
      intent_type: intent.intent_type,
      version: intent.version,
      chain_id: intent.chain_id,
      nonce: intent.nonce - 1,
      expiry: intent.expiry,
      symbol: intent.symbol,
      price: intent.price,
      timestamp: intent.timestamp,
      source: intent.source,
      signature: intent.signature,
      signer: intent.signer,
    },
    signer_public_key: sample_signer_public_key(),
  }
}

test oracle_intent_hash_is_32_bytes() {
  bytearray.length(oracle_intent_hash(config_logic.sample_domain(), sample_intent())) == 32
}

test oracle_intent_hash_matches_real_dia_fixture() {
  oracle_intent_hash(config_logic.sample_domain(), sample_intent()) ==
    #"966f6b54e8a00a2e7a2c8a3fd6a2a4d9b999b087ead69d6f23d949f909c912ba"
}

test signer_authorization_works_for_configured_public_keys() {
  signer_is_authorized(config_logic.sample_config(), sample_signer_public_key())
}

test pair_authorization_works_against_config_pairs() {
  pair_is_authorized(
    config_logic.ConfigDatum {
      valid_config_signers: config_logic.sample_config().valid_config_signers,
      authorized_oracle_public_keys: config_logic.sample_config().authorized_oracle_public_keys,
      fee_addresses: config_logic.sample_config().fee_addresses,
      fee_amount: config_logic.sample_config().fee_amount,
      domain_data: config_logic.sample_config().domain_data,
      allowed_pairs: [
        config_logic.PairEntry {
          token_name: #"555344435f555344",
          pair_code: #"555344432f555344",
        },
      ],
    },
    #"555344435f555344",
    sample_redeemer(),
  )
}

test stale_timestamp_rejected() {
  !is_fresh_update(sample_datum(), stale_timestamp_redeemer())
}

test stale_nonce_rejected() {
  !is_fresh_update(sample_datum(), stale_nonce_redeemer())
}

test unauthorized_signer_key_rejected() {
  !signer_is_authorized(config_logic.sample_config(), unauthorized_redeemer().signer_public_key)
}

test valid_signature_passes_for_real_dia_intent_fixture() {
  has_valid_signature(config_logic.sample_config(), sample_redeemer())
}

test valid_initial_oracle_datum_passes_for_real_dia_intent_fixture() {
  valid_initial_oracle_datum(sample_usdc_pair(), sample_usdc_config(), sample_datum())
}
