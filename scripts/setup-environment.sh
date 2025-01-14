#!/bin/bash

set -e

mkdir -p Resources && cd Resources

echo "$FIREBASE_AUTH_KEY" | base64 --decode > firebaseAuthKey.json
