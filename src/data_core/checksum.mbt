///|
pub(all) enum ChecksumKind {
  Sha256
  TextSumV1
  BytesSumV1
  NoChecksum
  UnknownChecksumKind
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn checksum_kind_label(kind : ChecksumKind) -> String {
  match kind {
    Sha256 => "sha256"
    TextSumV1 => "text-sum-v1"
    BytesSumV1 => "bytes-sum-v1"
    NoChecksum => "none"
    UnknownChecksumKind => "unknown"
  }
}

///|
pub fn declared_checksum(
  kind : ChecksumKind,
  value : String,
) -> DeclaredChecksum {
  { kind, value }
}

///|
pub(all) struct DeclaredChecksum {
  kind : ChecksumKind
  value : String
} derive(Debug, Eq, ToJson, FromJson)
