
set -euo pipefail

: "${SSH_KEY:?Falta SSH_KEY}"
: "${DEPLOY_HOST:?Falta DEPLOY_HOST}"
: "${DEPLOY_USER:?Falta DEPLOY_USER}"
: "${DEPLOY_KNOWN_HOSTS:?Falta DEPLOY_KNOWN_HOSTS}"

install -m 700 -d "$HOME/.ssh"
umask 077
printf '%s\n' "$SSH_KEY" > "$HOME/.ssh/id_deploy"
printf '%s\n' "$DEPLOY_KNOWN_HOSTS" > "$HOME/.ssh/known_hosts"

cat > "$HOME/.ssh/config" <<EOF
Host deploy
  HostName $DEPLOY_HOST
  User $DEPLOY_USER
  IdentityFile $HOME/.ssh/id_deploy
  IdentitiesOnly yes
  StrictHostKeyChecking yes
EOF

echo "SSH configurado para $DEPLOY_USER@$DEPLOY_HOST"
