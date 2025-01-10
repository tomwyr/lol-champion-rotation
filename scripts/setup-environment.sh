#!/bin/bash

set -e

mkdir -p assets && cd assets

echo "$FIREBASE_AUTH_KEY" | base64 --decode > firebaseAuthKey.json
