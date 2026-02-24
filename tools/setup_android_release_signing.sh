#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
KEYSTORE_DIR="$ANDROID_DIR/keystore"
KEYSTORE_PATH="$KEYSTORE_DIR/sportpass-release.jks"
KEY_ALIAS="sportpass-release"
DNAME="CN=SportPass Release,O=SportPass,C=SY"
VALIDITY_DAYS="10950" # 30 years
FORCE="false"

STORE_PASSWORD="${STORE_PASSWORD:-}"
KEY_PASSWORD="${KEY_PASSWORD:-}"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Options:
  --force                  Overwrite existing keystore/key.properties.
  --alias <alias>          Key alias (default: sportpass-release).
  --keystore <path>        Keystore path (default: android/keystore/sportpass-release.jks).
  --dname <dname>          Distinguished name for cert.
  --validity <days>        Certificate validity in days (default: 10950).
  --store-pass <pass>      Keystore password (or use STORE_PASSWORD env).
  --key-pass <pass>        Key password (or use KEY_PASSWORD env).
  -h, --help               Show help.

Notes:
  - Creates android/key.properties (ignored by git).
  - Creates a local secrets note at android/keystore/release_signing_credentials.txt
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE="true"
      shift
      ;;
    --alias)
      KEY_ALIAS="$2"
      shift 2
      ;;
    --keystore)
      KEYSTORE_PATH="$2"
      shift 2
      ;;
    --dname)
      DNAME="$2"
      shift 2
      ;;
    --validity)
      VALIDITY_DAYS="$2"
      shift 2
      ;;
    --store-pass)
      STORE_PASSWORD="$2"
      shift 2
      ;;
    --key-pass)
      KEY_PASSWORD="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! command -v keytool >/dev/null 2>&1; then
  echo "Error: keytool not found. Install JDK first." >&2
  exit 1
fi

mkdir -p "$(dirname "$KEYSTORE_PATH")"

KEY_PROPERTIES_PATH="$ANDROID_DIR/key.properties"
if [[ "$FORCE" != "true" ]]; then
  if [[ -f "$KEYSTORE_PATH" || -f "$KEY_PROPERTIES_PATH" ]]; then
    echo "Error: keystore or key.properties already exists. Use --force to overwrite." >&2
    exit 1
  fi
fi

if [[ -z "$STORE_PASSWORD" ]]; then
  STORE_PASSWORD="$(openssl rand -base64 48 | tr -d '\n' | tr '/+' 'XY' | cut -c1-40)"
fi
if [[ -z "$KEY_PASSWORD" ]]; then
  KEY_PASSWORD="$STORE_PASSWORD"
fi

# key.properties uses path relative to android/
case "$KEYSTORE_PATH" in
  "$ANDROID_DIR"/*)
    STORE_FILE_REL="${KEYSTORE_PATH#"$ANDROID_DIR"/}"
    ;;
  *)
    echo "Error: keystore path must be inside android/ directory." >&2
    exit 1
    ;;
esac

keytool -genkeypair \
  -v \
  -keystore "$KEYSTORE_PATH" \
  -storetype PKCS12 \
  -alias "$KEY_ALIAS" \
  -keyalg RSA \
  -keysize 4096 \
  -validity "$VALIDITY_DAYS" \
  -dname "$DNAME" \
  -storepass "$STORE_PASSWORD" \
  -keypass "$KEY_PASSWORD"

cat > "$KEY_PROPERTIES_PATH" <<KEYPROPS
storeFile=$STORE_FILE_REL
storePassword=$STORE_PASSWORD
keyAlias=$KEY_ALIAS
keyPassword=$KEY_PASSWORD
KEYPROPS

chmod 600 "$KEY_PROPERTIES_PATH"
chmod 600 "$KEYSTORE_PATH"

CREDENTIALS_NOTE="$KEYSTORE_DIR/release_signing_credentials.txt"
cat > "$CREDENTIALS_NOTE" <<NOTE
SportPass Android Release Signing Credentials
===========================================
Generated at: $(date -Iseconds)

Keystore: $KEYSTORE_PATH
Alias: $KEY_ALIAS
DName: $DNAME
Validity days: $VALIDITY_DAYS

storePassword: $STORE_PASSWORD
keyPassword: $KEY_PASSWORD

IMPORTANT:
- Backup this file and the keystore securely (offline vault).
- Losing them means you cannot update the app with the same package id.
NOTE
chmod 600 "$CREDENTIALS_NOTE"

echo "Release signing configured successfully."
echo "Keystore: $KEYSTORE_PATH"
echo "key.properties: $KEY_PROPERTIES_PATH"
echo "Credentials note: $CREDENTIALS_NOTE"
